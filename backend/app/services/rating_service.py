"""Rating calculation service"""

import math
from datetime import datetime
from typing import List, Optional
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.constants import RatingConfig
from app.models import (
    Match,
    MatchResultOutcome,
    Player,
    PlayerMatchRating,
    PlayerSeasonRating,
    Team,
    TeamPlayer,
)
from app.models.player import PlayerType
from app.repositories import RatingRepository, SeasonRepository, TeamRepository


class RatingService:
    """Service for calculating and updating player ratings"""

    def __init__(
        self,
        db: AsyncSession,
        rating_repo: RatingRepository,
        season_repo: SeasonRepository,
        team_repo: TeamRepository,
    ):
        self.db = db
        self.rating_repo = rating_repo
        self.season_repo = season_repo
        self.team_repo = team_repo

    async def calculate_match_ratings(
        self,
        match: Match,
        team_a: Team,
        team_b: Team,
        season_players: List[Player],
    ) -> List[PlayerMatchRating]:
        """
        Calculate ratings for all season players after a match.
        This includes players who didn't attend (they get penalties).
        """
        # Get team rosters
        team_a_players = await self.team_repo.get_team_players(team_a.id)
        team_b_players = await self.team_repo.get_team_players(team_b.id)

        team_a_player_ids = {tp.player_id for tp in team_a_players}
        team_b_player_ids = {tp.player_id for tp in team_b_players}

        # Calculate average ratings for each team
        team_a_avg_rating = await self._calculate_team_average_rating(
            match.season_id, team_a_player_ids
        )
        team_b_avg_rating = await self._calculate_team_average_rating(
            match.season_id, team_b_player_ids
        )

        # Update team average ratings
        team_a.average_skill_rating = team_a_avg_rating
        team_b.average_skill_rating = team_b_avg_rating

        ratings = []

        for player in season_players:
            # Determine player's match outcome
            attended_match = player.id in (team_a_player_ids | team_b_player_ids)

            if attended_match:
                # Player attended - determine their team and result
                if player.id in team_a_player_ids:
                    player_team = team_a
                    opponent_team = team_b
                else:
                    player_team = team_b
                    opponent_team = team_a

                match_result = self._get_match_result_for_player(
                    player_team, match.result
                )
                team_avg = player_team.average_skill_rating
                opponent_avg = opponent_team.average_skill_rating
            else:
                # Player didn't attend
                match_result = MatchResultOutcome.DID_NOT_ATTEND
                team_avg = None
                opponent_avg = None

            # Check third time attendance (from match.third_time_attendances)
            attended_third_time = any(
                tta.player_id == player.id and tta.attended
                for tta in match.third_time_attendances
            )

            # Get player's current season rating
            season_rating = await self.season_repo.get_player_season_rating(
                player.id, match.season_id
            )
            if not season_rating:
                # Create initial season rating
                season_rating = PlayerSeasonRating(
                    player_id=player.id,
                    season_id=match.season_id,
                    current_rating=RatingConfig.INITIAL_RATING,
                    matches_completed=0,
                    matches_attended=0,
                    rating_locked=True,
                )
                season_rating = await self.season_repo.create_player_season_rating(
                    season_rating
                )

            # Get match number for this player
            match_number = season_rating.matches_completed + 1

            # Calculate rating change
            rating_before = season_rating.current_rating
            rating_change, attendance_bonus, third_time_bonus, penalty = (
                await self._calculate_rating_change(
                    player.id,
                    match.season_id,
                    match_number,
                    attended_match,
                    attended_third_time,
                    match_result,
                    team_avg,
                    opponent_avg,
                    player.player_type,
                )
            )

            # Calculate new rating
            if match_number <= RatingConfig.MIN_MATCHES_FOR_RATING:
                # Rating is locked for first 3 matches
                rating_after = RatingConfig.INITIAL_RATING
            else:
                # Get last 3 match ratings (including current)
                last_ratings = await self.rating_repo.get_last_n_ratings(
                    player.id, match.season_id, RatingConfig.RATING_WINDOW_SIZE - 1
                )

                # Start from initial rating
                rating_after = RatingConfig.INITIAL_RATING

                # Apply changes from last N-1 matches
                for prev_rating in last_ratings:
                    rating_after += prev_rating.rating_change

                # Apply current match change
                rating_after += rating_change

                # Clamp to bounds
                rating_after = max(
                    RatingConfig.MIN_RATING,
                    min(RatingConfig.MAX_RATING, rating_after),
                )

            # Create PlayerMatchRating record
            player_match_rating = PlayerMatchRating(
                player_id=player.id,
                match_id=match.id,
                season_id=match.season_id,
                match_number=match_number,
                match_date=match.match_date,
                attended_match=attended_match,
                attended_third_time=attended_third_time,
                match_result=match_result,
                team_average_rating=team_avg,
                opponent_average_rating=opponent_avg,
                rating_before=rating_before,
                rating_after=rating_after,
                rating_change=rating_change,
                elo_k_factor=RatingConfig.ELO_K_FACTOR,
                attendance_bonus=attendance_bonus,
                third_time_bonus=third_time_bonus,
                non_attendance_penalty=penalty,
                calculated_at=datetime.utcnow(),
            )

            ratings.append(player_match_rating)

            # Update PlayerSeasonRating
            season_rating.current_rating = rating_after
            season_rating.matches_completed = match_number
            if attended_match:
                season_rating.matches_attended += 1
            if match_number >= RatingConfig.MIN_MATCHES_FOR_RATING:
                season_rating.rating_locked = False
            season_rating.last_calculated_at = datetime.utcnow()

            await self.season_repo.update_player_season_rating(season_rating)

        # Bulk create rating records
        await self.rating_repo.bulk_create_ratings(ratings)

        return ratings

    async def _calculate_team_average_rating(
        self, season_id: UUID, player_ids: set[UUID]
    ) -> float:
        """Calculate the average rating of a team"""
        if not player_ids:
            return RatingConfig.INITIAL_RATING

        total_rating = 0.0
        for player_id in player_ids:
            season_rating = await self.season_repo.get_player_season_rating(
                player_id, season_id
            )
            if season_rating:
                total_rating += season_rating.current_rating
            else:
                total_rating += RatingConfig.INITIAL_RATING

        return total_rating / len(player_ids)

    def _get_match_result_for_player(
        self, player_team: Team, match_result
    ) -> MatchResultOutcome:
        """Determine the match result from a player's perspective"""
        if not match_result:
            return MatchResultOutcome.DID_NOT_ATTEND

        if match_result.result_type.value == "draw":
            return MatchResultOutcome.DRAW
        elif match_result.winning_team_id == player_team.id:
            return MatchResultOutcome.WIN
        else:
            return MatchResultOutcome.LOSS

    async def _calculate_rating_change(
        self,
        player_id: UUID,
        season_id: UUID,
        match_number: int,
        attended_match: bool,
        attended_third_time: bool,
        match_result: MatchResultOutcome,
        team_avg_rating: Optional[float],
        opponent_avg_rating: Optional[float],
        player_type: PlayerType,
    ) -> tuple[float, float, float, float]:
        """
        Calculate the rating change for a player after a match.
        Returns: (total_change, attendance_bonus, third_time_bonus, penalty)

        Special handling for invited players:
        - No penalty for non-attendance (rating stays same)
        - No third time bonus (even if they attended)
        - Normal ELO calculation when they attend
        """
        # For first 3 matches, no rating change
        if match_number <= RatingConfig.MIN_MATCHES_FOR_RATING:
            return (0.0, 0.0, 0.0, 0.0)

        attendance_bonus = 0.0
        third_time_bonus = 0.0
        penalty = 0.0
        elo_change = 0.0

        if not attended_match:
            # Player didn't attend
            if player_type == PlayerType.INVITED:
                # Invited players: no penalty, rating stays the same
                return (0.0, 0.0, 0.0, 0.0)
            else:
                # Regular players: apply penalty
                penalty = RatingConfig.NON_ATTENDANCE_PENALTY
                return (penalty, 0.0, 0.0, penalty)

        # Player attended - calculate ELO change
        attendance_bonus = RatingConfig.ATTENDANCE_BONUS

        # Third time bonus only for regular players
        if attended_third_time and player_type == PlayerType.REGULAR:
            third_time_bonus = RatingConfig.THIRD_TIME_BONUS

        # Calculate ELO change based on match result
        if team_avg_rating is not None and opponent_avg_rating is not None:
            # Calculate expected score
            rating_diff = opponent_avg_rating - team_avg_rating
            expected_score = 1 / (
                1 + math.pow(10, rating_diff / RatingConfig.RATING_SCALING_FACTOR)
            )

            # Actual score
            if match_result == MatchResultOutcome.WIN:
                actual_score = 1.0
            elif match_result == MatchResultOutcome.DRAW:
                actual_score = 0.5
            else:  # LOSS
                actual_score = 0.0

            # ELO formula
            elo_change = RatingConfig.ELO_K_FACTOR * (actual_score - expected_score)

        # Total change
        total_change = elo_change + attendance_bonus + third_time_bonus

        return (total_change, attendance_bonus, third_time_bonus, penalty)

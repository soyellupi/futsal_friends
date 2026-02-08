"""Leaderboard service"""

from typing import List
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.constants import PointsConfig
from app.models import (
    Match,
    MatchResultOutcome,
    Player,
    PlayerMatchRating,
    PlayerSeasonRating,
    ThirdTimeAttendance,
)
from app.models.match import MatchStatus
from app.models.player import PlayerType
from app.repositories import SeasonRepository
from app.schemas.leaderboard import PlayerStats


class LeaderboardService:
    """Service for calculating leaderboard statistics"""

    def __init__(self, db: AsyncSession, season_repo: SeasonRepository):
        self.db = db
        self.season_repo = season_repo

    async def calculate_season_leaderboard(
        self, season_id: UUID
    ) -> List[PlayerStats]:
        """Calculate leaderboard for a season"""
        # Get all player season ratings
        season_ratings = await self.season_repo.get_season_ratings(season_id, skip=0, limit=1000)

        leaderboard = []

        for season_rating in season_ratings:
            # Get player to check type
            result = await self.db.execute(
                select(Player).where(Player.id == season_rating.player_id)
            )
            player = result.scalar_one()

            # Skip invited players from leaderboard
            if player.player_type == PlayerType.INVITED or not player.is_active:
                continue

            # Get player match ratings for statistics
            result = await self.db.execute(
                select(PlayerMatchRating)
                .where(
                    PlayerMatchRating.player_id == season_rating.player_id,
                    PlayerMatchRating.season_id == season_id,
                )
            )
            match_ratings = list(result.scalars().all())

            # Calculate statistics
            wins = sum(
                1
                for r in match_ratings
                if r.match_result == MatchResultOutcome.WIN
            )
            draws = sum(
                1
                for r in match_ratings
                if r.match_result == MatchResultOutcome.DRAW
            )
            losses = sum(
                1
                for r in match_ratings
                if r.match_result == MatchResultOutcome.LOSS
            )

            # Third time from normal matches (via PlayerMatchRating)
            third_time_from_matches = sum(1 for r in match_ratings if r.attended_third_time)

            # Third time from unplayable matches (via ThirdTimeAttendance)
            unplayable_third_time_result = await self.db.execute(
                select(ThirdTimeAttendance)
                .join(Match)
                .where(
                    ThirdTimeAttendance.player_id == season_rating.player_id,
                    Match.season_id == season_id,
                    Match.status == MatchStatus.UNPLAYABLE,
                    ThirdTimeAttendance.attended == True,
                )
            )
            third_time_from_unplayable = len(list(unplayable_third_time_result.scalars().all()))

            # Total third time attended
            third_time_attended = third_time_from_matches + third_time_from_unplayable

            # Calculate total points
            total_points = (
                (season_rating.matches_attended * PointsConfig.POINTS_MATCH_ATTENDANCE)
                + (wins * PointsConfig.POINTS_WIN)
                + (draws * PointsConfig.POINTS_DRAW)
                + (losses * PointsConfig.POINTS_LOSS)
                + (third_time_attended * PointsConfig.POINTS_THIRD_TIME)
            )

            # Calculate attendance rate
            attendance_rate = (
                (season_rating.matches_attended / season_rating.matches_completed * 100)
                if season_rating.matches_completed > 0
                else 0.0
            )

            player_stats = PlayerStats(
                player_id=season_rating.player_id,
                player_name=player.name,
                current_rating=season_rating.current_rating,
                matches_completed=season_rating.matches_completed,
                matches_attended=season_rating.matches_attended,
                wins=wins,
                draws=draws,
                losses=losses,
                third_time_attended=third_time_attended,
                total_points=total_points,
                attendance_rate=round(attendance_rate, 2),
            )

            leaderboard.append(player_stats)

        # Sort by total points (descending), then by rating
        leaderboard.sort(key=lambda x: (-x.total_points, -x.current_rating))

        return leaderboard

    async def get_player_stats(
        self, player_id: UUID, season_id: UUID
    ) -> PlayerStats:
        """Get statistics for a single player"""
        season_rating = await self.season_repo.get_player_season_rating(
            player_id, season_id
        )

        if not season_rating:
            # Player hasn't participated this season
            result = await self.db.execute(
                select(Player).where(Player.id == player_id)
            )
            player = result.scalar_one()

            return PlayerStats(
                player_id=player_id,
                player_name=player.name,
                current_rating=3.0,
                matches_completed=0,
                matches_attended=0,
                wins=0,
                draws=0,
                losses=0,
                third_time_attended=0,
                total_points=0,
                attendance_rate=0.0,
            )

        # Get player match ratings
        result = await self.db.execute(
            select(PlayerMatchRating)
            .where(
                PlayerMatchRating.player_id == player_id,
                PlayerMatchRating.season_id == season_id,
            )
        )
        match_ratings = list(result.scalars().all())

        # Get player to check type
        result = await self.db.execute(
            select(Player).where(Player.id == player_id)
        )
        player = result.scalar_one()

        # Calculate statistics
        wins = sum(
            1 for r in match_ratings if r.match_result == MatchResultOutcome.WIN
        )
        draws = sum(
            1 for r in match_ratings if r.match_result == MatchResultOutcome.DRAW
        )
        losses = sum(
            1 for r in match_ratings if r.match_result == MatchResultOutcome.LOSS
        )

        # Invited players: ignore third time attendance
        if player.player_type == PlayerType.INVITED:
            third_time_attended = 0
        else:
            # Third time from normal matches (via PlayerMatchRating)
            third_time_from_matches = sum(1 for r in match_ratings if r.attended_third_time)

            # Third time from unplayable matches (via ThirdTimeAttendance)
            unplayable_third_time_result = await self.db.execute(
                select(ThirdTimeAttendance)
                .join(Match)
                .where(
                    ThirdTimeAttendance.player_id == player_id,
                    Match.season_id == season_id,
                    Match.status == MatchStatus.UNPLAYABLE,
                    ThirdTimeAttendance.attended == True,
                )
            )
            third_time_from_unplayable = len(list(unplayable_third_time_result.scalars().all()))

            # Total third time attended
            third_time_attended = third_time_from_matches + third_time_from_unplayable

        # Calculate total points
        total_points = (
            (season_rating.matches_attended * PointsConfig.POINTS_MATCH_ATTENDANCE)
            + (wins * PointsConfig.POINTS_WIN)
            + (draws * PointsConfig.POINTS_DRAW)
            + (losses * PointsConfig.POINTS_LOSS)
            + (third_time_attended * PointsConfig.POINTS_THIRD_TIME)
        )

        # Calculate attendance rate
        attendance_rate = (
            (season_rating.matches_attended / season_rating.matches_completed * 100)
            if season_rating.matches_completed > 0
            else 0.0
        )

        return PlayerStats(
            player_id=player_id,
            player_name=player.name,
            current_rating=season_rating.current_rating,
            matches_completed=season_rating.matches_completed,
            matches_attended=season_rating.matches_attended,
            wins=wins,
            draws=draws,
            losses=losses,
            third_time_attended=third_time_attended,
            total_points=total_points,
            attendance_rate=round(attendance_rate, 2),
        )

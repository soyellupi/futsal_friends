"""Team balancing service"""

import random
from typing import List
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.constants import RatingConfig
from app.models import Player, PlayerSeasonRating, Team, TeamName, TeamPlayer
from app.repositories import SeasonRepository, TeamRepository


class TeamService:
    """Service for creating and balancing teams"""

    def __init__(
        self,
        db: AsyncSession,
        team_repo: TeamRepository,
        season_repo: SeasonRepository,
    ):
        self.db = db
        self.team_repo = team_repo
        self.season_repo = season_repo

    async def create_balanced_teams(
        self,
        match_id: UUID,
        season_id: UUID,
        player_ids: List[UUID],
    ) -> tuple[Team, Team]:
        """
        Create two balanced teams based on player ratings.
        Uses a greedy algorithm to minimize rating difference.
        """
        if len(player_ids) < 2:
            raise ValueError("Need at least 2 players to create teams")

        # Get player ratings
        player_ratings = []
        for player_id in player_ids:
            season_rating = await self.season_repo.get_player_season_rating(
                player_id, season_id
            )
            rating = (
                season_rating.current_rating
                if season_rating
                else RatingConfig.INITIAL_RATING
            )
            player_ratings.append((player_id, rating))

        # Sort players by rating (highest first)
        player_ratings.sort(key=lambda x: x[1], reverse=True)

        # Snake draft algorithm for balanced teams
        team_a_players = []
        team_b_players = []
        team_a_rating = 0.0
        team_b_rating = 0.0

        # Use greedy approach: assign each player to the team with lower total rating
        for player_id, rating in player_ratings:
            if team_a_rating <= team_b_rating:
                team_a_players.append(player_id)
                team_a_rating += rating
            else:
                team_b_players.append(player_id)
                team_b_rating += rating

        # Calculate average ratings
        team_a_avg = team_a_rating / len(team_a_players) if team_a_players else 0.0
        team_b_avg = team_b_rating / len(team_b_players) if team_b_players else 0.0

        # Create Team A
        team_a = Team(
            match_id=match_id,
            name=TeamName.TEAM_A,
            average_skill_rating=team_a_avg,
        )
        team_a = await self.team_repo.create(team_a)

        # Create Team B
        team_b = Team(
            match_id=match_id,
            name=TeamName.TEAM_B,
            average_skill_rating=team_b_avg,
        )
        team_b = await self.team_repo.create(team_b)

        # Add players to Team A
        for player_id in team_a_players:
            team_player = TeamPlayer(
                team_id=team_a.id,
                player_id=player_id,
            )
            await self.team_repo.add_player_to_team(team_player)

        # Add players to Team B
        for player_id in team_b_players:
            team_player = TeamPlayer(
                team_id=team_b.id,
                player_id=player_id,
            )
            await self.team_repo.add_player_to_team(team_player)

        return team_a, team_b

    async def shuffle_teams(
        self,
        match_id: UUID,
        season_id: UUID,
        player_ids: List[UUID],
        max_attempts: int = 100,
    ) -> tuple[Team, Team]:
        """
        Create balanced teams with randomization for variety.
        Tries multiple random combinations and picks the most balanced.
        """
        if len(player_ids) < 2:
            raise ValueError("Need at least 2 players to create teams")

        # Get player ratings
        player_ratings = {}
        for player_id in player_ids:
            season_rating = await self.season_repo.get_player_season_rating(
                player_id, season_id
            )
            player_ratings[player_id] = (
                season_rating.current_rating
                if season_rating
                else RatingConfig.INITIAL_RATING
            )

        best_split = None
        best_difference = float("inf")

        # Try multiple random splits
        for _ in range(max_attempts):
            # Shuffle players
            shuffled = player_ids.copy()
            random.shuffle(shuffled)

            # Split in half
            mid = len(shuffled) // 2
            team_a_ids = shuffled[:mid]
            team_b_ids = shuffled[mid:]

            # Calculate average ratings
            team_a_avg = sum(player_ratings[pid] for pid in team_a_ids) / len(
                team_a_ids
            )
            team_b_avg = sum(player_ratings[pid] for pid in team_b_ids) / len(
                team_b_ids
            )

            # Calculate difference
            difference = abs(team_a_avg - team_b_avg)

            # Track best split
            if difference < best_difference:
                best_difference = difference
                best_split = (team_a_ids, team_b_ids, team_a_avg, team_b_avg)

        team_a_ids, team_b_ids, team_a_avg, team_b_avg = best_split

        # Create Team A
        team_a = Team(
            match_id=match_id,
            name=TeamName.TEAM_A,
            average_skill_rating=team_a_avg,
        )
        team_a = await self.team_repo.create(team_a)

        # Create Team B
        team_b = Team(
            match_id=match_id,
            name=TeamName.TEAM_B,
            average_skill_rating=team_b_avg,
        )
        team_b = await self.team_repo.create(team_b)

        # Add players to teams
        for player_id in team_a_ids:
            team_player = TeamPlayer(team_id=team_a.id, player_id=player_id)
            await self.team_repo.add_player_to_team(team_player)

        for player_id in team_b_ids:
            team_player = TeamPlayer(team_id=team_b.id, player_id=player_id)
            await self.team_repo.add_player_to_team(team_player)

        return team_a, team_b

    async def get_team_rating_difference(
        self, team_a: Team, team_b: Team
    ) -> float:
        """Calculate the rating difference between two teams"""
        return abs(
            (team_a.average_skill_rating or 0.0) - (team_b.average_skill_rating or 0.0)
        )

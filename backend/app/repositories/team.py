"""Team repository"""

from typing import List, Optional
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload

from app.models import Team, TeamPlayer
from app.repositories.base import BaseRepository


class TeamRepository(BaseRepository[Team]):
    """Team repository with custom queries"""

    def __init__(self, db: AsyncSession):
        super().__init__(Team, db)

    async def get_match_teams(self, match_id: UUID) -> List[Team]:
        """Get both teams for a match"""
        result = await self.db.execute(
            select(Team)
            .where(Team.match_id == match_id)
            .options(joinedload(Team.players))
        )
        return list(result.scalars().unique().all())

    async def get_team_with_players(self, team_id: UUID) -> Optional[Team]:
        """Get team with all players loaded"""
        result = await self.db.execute(
            select(Team)
            .where(Team.id == team_id)
            .options(joinedload(Team.players))
        )
        return result.scalars().unique().one_or_none()

    async def get_team_players(self, team_id: UUID) -> List[TeamPlayer]:
        """Get all players in a team"""
        result = await self.db.execute(
            select(TeamPlayer).where(TeamPlayer.team_id == team_id)
        )
        return list(result.scalars().all())

    async def add_player_to_team(
        self, team_player: TeamPlayer
    ) -> TeamPlayer:
        """Add a player to a team"""
        self.db.add(team_player)
        await self.db.flush()
        await self.db.refresh(team_player)
        return team_player

    async def remove_player_from_team(
        self, team_id: UUID, player_id: UUID
    ) -> bool:
        """Remove a player from a team"""
        result = await self.db.execute(
            select(TeamPlayer).where(
                TeamPlayer.team_id == team_id,
                TeamPlayer.player_id == player_id,
            )
        )
        team_player = result.scalar_one_or_none()
        if team_player:
            await self.db.delete(team_player)
            await self.db.flush()
            return True
        return False

    async def get_player_team_for_match(
        self, match_id: UUID, player_id: UUID
    ) -> Optional[Team]:
        """Get the team a player is on for a specific match"""
        result = await self.db.execute(
            select(Team)
            .join(TeamPlayer)
            .where(
                Team.match_id == match_id,
                TeamPlayer.player_id == player_id,
            )
        )
        return result.scalar_one_or_none()

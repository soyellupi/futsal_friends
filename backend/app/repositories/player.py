"""Player repository"""

from typing import List, Optional
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Player, PlayerSeasonRating
from app.repositories.base import BaseRepository


class PlayerRepository(BaseRepository[Player]):
    """Player repository with custom queries"""

    def __init__(self, db: AsyncSession):
        super().__init__(Player, db)

    async def get_by_name(self, name: str) -> Optional[Player]:
        """Get a player by name"""
        result = await self.db.execute(
            select(Player).where(Player.name == name)
        )
        return result.scalar_one_or_none()

    async def get_active_players(
        self, skip: int = 0, limit: int = 100
    ) -> List[Player]:
        """Get all active players"""
        result = await self.db.execute(
            select(Player)
            .where(Player.is_active == True)
            .offset(skip)
            .limit(limit)
        )
        return list(result.scalars().all())

    async def get_players_with_season_rating(
        self, season_id: UUID, skip: int = 0, limit: int = 100
    ) -> List[tuple[Player, Optional[PlayerSeasonRating]]]:
        """Get players with their season ratings"""
        result = await self.db.execute(
            select(Player, PlayerSeasonRating)
            .outerjoin(
                PlayerSeasonRating,
                (Player.id == PlayerSeasonRating.player_id)
                & (PlayerSeasonRating.season_id == season_id),
            )
            .where(Player.is_active == True)
            .offset(skip)
            .limit(limit)
        )
        return list(result.all())

    async def search_by_name(
        self, name_query: str, skip: int = 0, limit: int = 100
    ) -> List[Player]:
        """Search players by name (case-insensitive partial match)"""
        result = await self.db.execute(
            select(Player)
            .where(Player.name.ilike(f"%{name_query}%"))
            .offset(skip)
            .limit(limit)
        )
        return list(result.scalars().all())

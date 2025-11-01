"""Season repository"""

from typing import List, Optional
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import PlayerSeasonRating, Season
from app.repositories.base import BaseRepository


class SeasonRepository(BaseRepository[Season]):
    """Season repository with custom queries"""

    def __init__(self, db: AsyncSession):
        super().__init__(Season, db)

    async def get_active_season(self) -> Optional[Season]:
        """Get the currently active season"""
        result = await self.db.execute(
            select(Season).where(Season.is_active == True)
        )
        return result.scalar_one_or_none()

    async def get_by_year(self, year: int) -> List[Season]:
        """Get seasons by year"""
        result = await self.db.execute(
            select(Season).where(Season.year == year).order_by(Season.start_date)
        )
        return list(result.scalars().all())

    async def get_player_season_rating(
        self, player_id: UUID, season_id: UUID
    ) -> Optional[PlayerSeasonRating]:
        """Get a player's rating for a specific season"""
        result = await self.db.execute(
            select(PlayerSeasonRating).where(
                PlayerSeasonRating.player_id == player_id,
                PlayerSeasonRating.season_id == season_id,
            )
        )
        return result.scalar_one_or_none()

    async def get_season_ratings(
        self, season_id: UUID, skip: int = 0, limit: int = 100
    ) -> List[PlayerSeasonRating]:
        """Get all player ratings for a season"""
        result = await self.db.execute(
            select(PlayerSeasonRating)
            .where(PlayerSeasonRating.season_id == season_id)
            .order_by(PlayerSeasonRating.current_rating.desc())
            .offset(skip)
            .limit(limit)
        )
        return list(result.scalars().all())

    async def create_player_season_rating(
        self, player_season_rating: PlayerSeasonRating
    ) -> PlayerSeasonRating:
        """Create a new player season rating"""
        self.db.add(player_season_rating)
        await self.db.flush()
        await self.db.refresh(player_season_rating)
        return player_season_rating

    async def update_player_season_rating(
        self, player_season_rating: PlayerSeasonRating
    ) -> PlayerSeasonRating:
        """Update a player season rating"""
        await self.db.flush()
        await self.db.refresh(player_season_rating)
        return player_season_rating

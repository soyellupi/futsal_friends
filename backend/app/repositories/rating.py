"""Player rating repository"""

from typing import List, Optional
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import PlayerMatchRating
from app.repositories.base import BaseRepository


class RatingRepository(BaseRepository[PlayerMatchRating]):
    """Player rating repository with custom queries"""

    def __init__(self, db: AsyncSession):
        super().__init__(PlayerMatchRating, db)

    async def get_player_match_rating(
        self, player_id: UUID, match_id: UUID
    ) -> Optional[PlayerMatchRating]:
        """Get a player's rating for a specific match"""
        result = await self.db.execute(
            select(PlayerMatchRating).where(
                PlayerMatchRating.player_id == player_id,
                PlayerMatchRating.match_id == match_id,
            )
        )
        return result.scalar_one_or_none()

    async def get_player_season_ratings(
        self, player_id: UUID, season_id: UUID, skip: int = 0, limit: int = 100
    ) -> List[PlayerMatchRating]:
        """Get all match ratings for a player in a season"""
        result = await self.db.execute(
            select(PlayerMatchRating)
            .where(
                PlayerMatchRating.player_id == player_id,
                PlayerMatchRating.season_id == season_id,
            )
            .order_by(PlayerMatchRating.match_date.asc())
            .offset(skip)
            .limit(limit)
        )
        return list(result.scalars().all())

    async def get_last_n_ratings(
        self, player_id: UUID, season_id: UUID, n: int = 3
    ) -> List[PlayerMatchRating]:
        """Get the last N match ratings for a player in a season"""
        result = await self.db.execute(
            select(PlayerMatchRating)
            .where(
                PlayerMatchRating.player_id == player_id,
                PlayerMatchRating.season_id == season_id,
            )
            .order_by(PlayerMatchRating.match_date.desc())
            .limit(n)
        )
        # Return in chronological order (oldest first)
        return list(reversed(list(result.scalars().all())))

    async def get_match_ratings(self, match_id: UUID) -> List[PlayerMatchRating]:
        """Get all player ratings for a specific match"""
        result = await self.db.execute(
            select(PlayerMatchRating).where(PlayerMatchRating.match_id == match_id)
        )
        return list(result.scalars().all())

    async def get_season_match_count(
        self, player_id: UUID, season_id: UUID
    ) -> int:
        """Get the number of matches a player has in a season"""
        result = await self.db.execute(
            select(PlayerMatchRating)
            .where(
                PlayerMatchRating.player_id == player_id,
                PlayerMatchRating.season_id == season_id,
            )
        )
        return len(list(result.scalars().all()))

    async def create_rating(
        self, rating: PlayerMatchRating
    ) -> PlayerMatchRating:
        """Create a new player match rating"""
        self.db.add(rating)
        await self.db.flush()
        await self.db.refresh(rating)
        return rating

    async def bulk_create_ratings(
        self, ratings: List[PlayerMatchRating]
    ) -> List[PlayerMatchRating]:
        """Create multiple player match ratings"""
        self.db.add_all(ratings)
        await self.db.flush()
        for rating in ratings:
            await self.db.refresh(rating)
        return ratings

"""Match result repository"""

from typing import List, Optional
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload

from app.models import MatchResult
from app.repositories.base import BaseRepository


class ResultRepository(BaseRepository[MatchResult]):
    """Match result repository with custom queries"""

    def __init__(self, db: AsyncSession):
        super().__init__(MatchResult, db)

    async def get_by_match_id(self, match_id: UUID) -> Optional[MatchResult]:
        """Get result by match ID"""
        result = await self.db.execute(
            select(MatchResult).where(MatchResult.match_id == match_id)
        )
        return result.scalar_one_or_none()

    async def get_result_with_teams(self, match_id: UUID) -> Optional[MatchResult]:
        """Get result with team details loaded"""
        result = await self.db.execute(
            select(MatchResult)
            .where(MatchResult.match_id == match_id)
            .options(
                joinedload(MatchResult.team_a),
                joinedload(MatchResult.team_b),
                joinedload(MatchResult.winning_team),
            )
        )
        return result.scalar_one_or_none()

    async def get_season_results(
        self, season_id: UUID, skip: int = 0, limit: int = 100
    ) -> List[MatchResult]:
        """Get all results for a season"""
        result = await self.db.execute(
            select(MatchResult)
            .join(MatchResult.match)
            .where(MatchResult.match.has(season_id=season_id))
            .order_by(MatchResult.recorded_at.desc())
            .offset(skip)
            .limit(limit)
        )
        return list(result.scalars().all())

    async def get_team_results(
        self, team_id: UUID
    ) -> List[MatchResult]:
        """Get all results for a team"""
        result = await self.db.execute(
            select(MatchResult).where(
                (MatchResult.team_a_id == team_id)
                | (MatchResult.team_b_id == team_id)
            )
        )
        return list(result.scalars().all())

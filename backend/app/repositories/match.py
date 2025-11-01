"""Match repository"""

from datetime import datetime
from typing import List, Optional
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload

from app.models import Match, MatchAttendance, MatchStatus, RSVPStatus, ThirdTimeAttendance
from app.repositories.base import BaseRepository


class MatchRepository(BaseRepository[Match]):
    """Match repository with custom queries"""

    def __init__(self, db: AsyncSession):
        super().__init__(Match, db)

    async def get_by_season(
        self, season_id: UUID, skip: int = 0, limit: int = 100
    ) -> List[Match]:
        """Get all matches for a season"""
        result = await self.db.execute(
            select(Match)
            .where(Match.season_id == season_id)
            .order_by(Match.match_date.desc())
            .offset(skip)
            .limit(limit)
        )
        return list(result.scalars().all())

    async def get_upcoming_matches(
        self, season_id: UUID, skip: int = 0, limit: int = 100
    ) -> List[Match]:
        """Get upcoming matches for a season"""
        result = await self.db.execute(
            select(Match)
            .where(
                Match.season_id == season_id,
                Match.match_date > datetime.utcnow(),
                Match.status.in_([MatchStatus.SCHEDULED, MatchStatus.CONFIRMED]),
            )
            .order_by(Match.match_date.asc())
            .offset(skip)
            .limit(limit)
        )
        return list(result.scalars().all())

    async def get_completed_matches(
        self, season_id: UUID, skip: int = 0, limit: int = 100
    ) -> List[Match]:
        """Get completed matches for a season"""
        result = await self.db.execute(
            select(Match)
            .where(
                Match.season_id == season_id,
                Match.status == MatchStatus.COMPLETED,
            )
            .order_by(Match.match_date.desc())
            .offset(skip)
            .limit(limit)
        )
        return list(result.scalars().all())

    async def get_match_with_details(self, match_id: UUID) -> Optional[Match]:
        """Get match with all related data loaded"""
        result = await self.db.execute(
            select(Match)
            .where(Match.id == match_id)
            .options(
                joinedload(Match.attendances),
                joinedload(Match.third_time_attendances),
                joinedload(Match.teams),
                joinedload(Match.result),
            )
        )
        return result.scalars().unique().one_or_none()

    async def get_match_attendance(
        self, match_id: UUID, player_id: UUID
    ) -> Optional[MatchAttendance]:
        """Get a player's attendance record for a match"""
        result = await self.db.execute(
            select(MatchAttendance).where(
                MatchAttendance.match_id == match_id,
                MatchAttendance.player_id == player_id,
            )
        )
        return result.scalar_one_or_none()

    async def get_match_attendances(self, match_id: UUID) -> List[MatchAttendance]:
        """Get all attendance records for a match"""
        result = await self.db.execute(
            select(MatchAttendance).where(MatchAttendance.match_id == match_id)
        )
        return list(result.scalars().all())

    async def get_confirmed_attendees(self, match_id: UUID) -> List[MatchAttendance]:
        """Get players who confirmed attendance"""
        result = await self.db.execute(
            select(MatchAttendance).where(
                MatchAttendance.match_id == match_id,
                MatchAttendance.rsvp_status == RSVPStatus.CONFIRMED,
            )
        )
        return list(result.scalars().all())

    async def get_actual_attendees(self, match_id: UUID) -> List[MatchAttendance]:
        """Get players who actually attended"""
        result = await self.db.execute(
            select(MatchAttendance).where(
                MatchAttendance.match_id == match_id,
                MatchAttendance.attended == True,
            )
        )
        return list(result.scalars().all())

    async def create_attendance(
        self, attendance: MatchAttendance
    ) -> MatchAttendance:
        """Create a match attendance record"""
        self.db.add(attendance)
        await self.db.flush()
        await self.db.refresh(attendance)
        return attendance

    async def update_attendance(
        self, attendance: MatchAttendance
    ) -> MatchAttendance:
        """Update a match attendance record"""
        await self.db.flush()
        await self.db.refresh(attendance)
        return attendance

    async def get_third_time_attendance(
        self, match_id: UUID, player_id: UUID
    ) -> Optional[ThirdTimeAttendance]:
        """Get a player's third time attendance record"""
        result = await self.db.execute(
            select(ThirdTimeAttendance).where(
                ThirdTimeAttendance.match_id == match_id,
                ThirdTimeAttendance.player_id == player_id,
            )
        )
        return result.scalar_one_or_none()

    async def get_third_time_attendances(
        self, match_id: UUID
    ) -> List[ThirdTimeAttendance]:
        """Get all third time attendance records for a match"""
        result = await self.db.execute(
            select(ThirdTimeAttendance).where(
                ThirdTimeAttendance.match_id == match_id
            )
        )
        return list(result.scalars().all())

    async def create_third_time_attendance(
        self, attendance: ThirdTimeAttendance
    ) -> ThirdTimeAttendance:
        """Create a third time attendance record"""
        self.db.add(attendance)
        await self.db.flush()
        await self.db.refresh(attendance)
        return attendance

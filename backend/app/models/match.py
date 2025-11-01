"""Match model"""

import enum
import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, Enum, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class MatchStatus(str, enum.Enum):
    """Match status enum"""

    SCHEDULED = "scheduled"
    CONFIRMED = "confirmed"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class Match(Base):
    """Match model representing a futsal match"""

    __tablename__ = "matches"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    season_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("seasons.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    match_date: Mapped[datetime] = mapped_column(
        DateTime, nullable=False, index=True
    )
    status: Mapped[MatchStatus] = mapped_column(
        Enum(MatchStatus, name="match_status"),
        default=MatchStatus.SCHEDULED,
        nullable=False,
        index=True,
    )
    rsvp_deadline: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    location: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    # Relationships
    season: Mapped["Season"] = relationship("Season", back_populates="matches")
    attendances: Mapped[list["MatchAttendance"]] = relationship(
        "MatchAttendance", back_populates="match", cascade="all, delete-orphan"
    )
    third_time_attendances: Mapped[list["ThirdTimeAttendance"]] = relationship(
        "ThirdTimeAttendance", back_populates="match", cascade="all, delete-orphan"
    )
    teams: Mapped[list["Team"]] = relationship(
        "Team", back_populates="match", cascade="all, delete-orphan"
    )
    result: Mapped[Optional["MatchResult"]] = relationship(
        "MatchResult", back_populates="match", uselist=False, cascade="all, delete-orphan"
    )
    player_ratings: Mapped[list["PlayerMatchRating"]] = relationship(
        "PlayerMatchRating", back_populates="match", cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:
        return (
            f"<Match(id={self.id}, date={self.match_date}, "
            f"status={self.status.value})>"
        )

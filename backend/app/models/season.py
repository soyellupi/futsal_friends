"""Season and PlayerSeasonRating models"""

import uuid
from datetime import date, datetime
from typing import Optional

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Season(Base):
    """Season model representing a futsal season (typically yearly)"""

    __tablename__ = "seasons"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    year: Mapped[int] = mapped_column(Integer, nullable=False, index=True)
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    is_active: Mapped[bool] = mapped_column(
        Boolean, default=True, nullable=False, index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    # Relationships
    matches: Mapped[list["Match"]] = relationship(
        "Match", back_populates="season", cascade="all, delete-orphan"
    )
    player_ratings: Mapped[list["PlayerSeasonRating"]] = relationship(
        "PlayerSeasonRating", back_populates="season", cascade="all, delete-orphan"
    )
    match_ratings: Mapped[list["PlayerMatchRating"]] = relationship(
        "PlayerMatchRating", back_populates="season", cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:
        return f"<Season(id={self.id}, name='{self.name}', year={self.year})>"


class PlayerSeasonRating(Base):
    """Player rating for a specific season"""

    __tablename__ = "player_season_ratings"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    player_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("players.id", ondelete="CASCADE"), nullable=False, index=True
    )
    season_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("seasons.id", ondelete="CASCADE"), nullable=False, index=True
    )
    current_rating: Mapped[float] = mapped_column(
        Float, default=3.0, nullable=False
    )
    matches_completed: Mapped[int] = mapped_column(
        Integer, default=0, nullable=False
    )
    matches_attended: Mapped[int] = mapped_column(
        Integer, default=0, nullable=False
    )
    rating_locked: Mapped[bool] = mapped_column(
        Boolean, default=True, nullable=False
    )
    last_calculated_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime, nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    # Relationships
    player: Mapped["Player"] = relationship("Player", back_populates="season_ratings")
    season: Mapped["Season"] = relationship("Season", back_populates="player_ratings")

    # Constraints
    __table_args__ = (
        UniqueConstraint("player_id", "season_id", name="uq_player_season"),
        CheckConstraint("current_rating >= 1.0 AND current_rating <= 5.0", name="ck_rating_range"),
        CheckConstraint("matches_attended <= matches_completed", name="ck_attendance_count"),
    )

    def __repr__(self) -> str:
        return (
            f"<PlayerSeasonRating(player_id={self.player_id}, "
            f"season_id={self.season_id}, rating={self.current_rating})>"
        )

"""Player model"""

import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import Boolean, DateTime, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Player(Base):
    """Player model representing a futsal player"""

    __tablename__ = "players"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    # Relationships
    season_ratings: Mapped[list["PlayerSeasonRating"]] = relationship(
        "PlayerSeasonRating", back_populates="player", cascade="all, delete-orphan"
    )
    match_ratings: Mapped[list["PlayerMatchRating"]] = relationship(
        "PlayerMatchRating", back_populates="player", cascade="all, delete-orphan"
    )
    match_attendances: Mapped[list["MatchAttendance"]] = relationship(
        "MatchAttendance", back_populates="player", cascade="all, delete-orphan"
    )
    third_time_attendances: Mapped[list["ThirdTimeAttendance"]] = relationship(
        "ThirdTimeAttendance", back_populates="player", cascade="all, delete-orphan"
    )
    team_assignments: Mapped[list["TeamPlayer"]] = relationship(
        "TeamPlayer", back_populates="player", cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:
        return f"<Player(id={self.id}, name='{self.name}')>"

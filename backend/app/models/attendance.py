"""Attendance models for matches and third time"""

import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class MatchAttendance(Base):
    """Match attendance tracking"""

    __tablename__ = "match_attendances"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    match_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("matches.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    player_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("players.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    attended: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    # Relationships
    match: Mapped["Match"] = relationship("Match", back_populates="attendances")
    player: Mapped["Player"] = relationship("Player", back_populates="match_attendances")

    # Constraints
    __table_args__ = (
        UniqueConstraint("match_id", "player_id", name="uq_match_player_attendance"),
    )

    def __repr__(self) -> str:
        return (
            f"<MatchAttendance(match_id={self.match_id}, player_id={self.player_id}, "
            f"attended={self.attended})>"
        )


class ThirdTimeAttendance(Base):
    """Third time (post-match social) attendance tracking"""

    __tablename__ = "third_time_attendances"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    match_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("matches.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    player_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("players.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    attended: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, nullable=False
    )

    # Relationships
    match: Mapped["Match"] = relationship("Match", back_populates="third_time_attendances")
    player: Mapped["Player"] = relationship("Player", back_populates="third_time_attendances")

    # Constraints
    __table_args__ = (
        UniqueConstraint("match_id", "player_id", name="uq_match_player_third_time"),
    )

    def __repr__(self) -> str:
        return (
            f"<ThirdTimeAttendance(match_id={self.match_id}, "
            f"player_id={self.player_id}, attended={self.attended})>"
        )

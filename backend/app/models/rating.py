"""Player rating models"""

import enum
import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    DateTime,
    Enum,
    Float,
    ForeignKey,
    Index,
    Integer,
    UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class MatchResultOutcome(str, enum.Enum):
    """Match result outcome from player's perspective"""

    WIN = "win"
    DRAW = "draw"
    LOSS = "loss"
    DID_NOT_ATTEND = "did_not_attend"


class PlayerMatchRating(Base):
    """Player rating for a specific match with ELO calculation details"""

    __tablename__ = "player_match_ratings"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    player_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("players.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    match_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("matches.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    season_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("seasons.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    match_number: Mapped[int] = mapped_column(Integer, nullable=False)
    match_date: Mapped[datetime] = mapped_column(DateTime, nullable=False, index=True)

    # Attendance tracking
    attended_match: Mapped[bool] = mapped_column(Boolean, nullable=False)
    attended_third_time: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    # Match outcome
    match_result: Mapped[MatchResultOutcome] = mapped_column(
        Enum(MatchResultOutcome, name="match_result_outcome"), nullable=False
    )

    # Team ratings (for ELO calculation)
    team_average_rating: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    opponent_average_rating: Mapped[Optional[float]] = mapped_column(Float, nullable=True)

    # Rating values
    rating_before: Mapped[float] = mapped_column(Float, nullable=False)
    rating_after: Mapped[float] = mapped_column(Float, nullable=False)
    rating_change: Mapped[float] = mapped_column(Float, nullable=False)

    # ELO calculation components (for transparency)
    elo_k_factor: Mapped[float] = mapped_column(Float, nullable=False)
    attendance_bonus: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    third_time_bonus: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    non_attendance_penalty: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)

    # Timestamps
    calculated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, nullable=False
    )

    # Relationships
    player: Mapped["Player"] = relationship("Player", back_populates="match_ratings")
    match: Mapped["Match"] = relationship("Match", back_populates="player_ratings")
    season: Mapped["Season"] = relationship("Season", back_populates="match_ratings")

    # Constraints
    __table_args__ = (
        UniqueConstraint("player_id", "match_id", name="uq_player_match_rating"),
        CheckConstraint("rating_before >= 1.0 AND rating_before <= 5.0", name="ck_rating_before_range"),
        CheckConstraint("rating_after >= 1.0 AND rating_after <= 5.0", name="ck_rating_after_range"),
        CheckConstraint("match_number > 0", name="ck_match_number_positive"),
        # Composite index for "last 3 matches" queries
        Index(
            "ix_player_season_match_date_desc",
            "player_id",
            "season_id",
            "match_date",
            postgresql_ops={"match_date": "DESC"},
        ),
    )

    def __repr__(self) -> str:
        return (
            f"<PlayerMatchRating(player_id={self.player_id}, match_id={self.match_id}, "
            f"rating={self.rating_after}, change={self.rating_change:+.2f})>"
        )

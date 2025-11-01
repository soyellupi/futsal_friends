"""Match result model"""

import enum
import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, Enum, ForeignKey, Integer
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class ResultType(str, enum.Enum):
    """Result type enum"""

    WIN = "win"
    DRAW = "draw"


class MatchResult(Base):
    """Match result model storing match outcomes"""

    __tablename__ = "match_results"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    match_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("matches.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
        index=True,
    )
    team_a_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("teams.id", ondelete="CASCADE"),
        nullable=False,
    )
    team_b_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("teams.id", ondelete="CASCADE"),
        nullable=False,
    )
    team_a_score: Mapped[int] = mapped_column(Integer, nullable=False)
    team_b_score: Mapped[int] = mapped_column(Integer, nullable=False)
    winning_team_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("teams.id", ondelete="CASCADE"),
        nullable=True,
    )
    result_type: Mapped[ResultType] = mapped_column(
        Enum(ResultType, name="result_type"), nullable=False
    )
    recorded_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    # Relationships
    match: Mapped["Match"] = relationship("Match", back_populates="result")
    team_a: Mapped["Team"] = relationship(
        "Team", foreign_keys=[team_a_id], back_populates="results_as_team_a"
    )
    team_b: Mapped["Team"] = relationship(
        "Team", foreign_keys=[team_b_id], back_populates="results_as_team_b"
    )
    winning_team: Mapped[Optional["Team"]] = relationship(
        "Team", foreign_keys=[winning_team_id], back_populates="results_as_winner"
    )

    def __repr__(self) -> str:
        return (
            f"<MatchResult(match_id={self.match_id}, "
            f"score={self.team_a_score}-{self.team_b_score}, "
            f"result={self.result_type.value})>"
        )

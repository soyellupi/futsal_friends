"""Team models"""

import enum
import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, Enum, Float, ForeignKey, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class TeamName(str, enum.Enum):
    """Team name enum for the two teams per match"""

    TEAM_A = "black"
    TEAM_B = "pink"


class Team(Base):
    """Team model representing one of two teams in a match"""

    __tablename__ = "teams"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    match_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("matches.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    name: Mapped[TeamName] = mapped_column(
        Enum(TeamName, name="team_name"), nullable=False
    )
    average_skill_rating: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, nullable=False
    )

    # Relationships
    match: Mapped["Match"] = relationship("Match", back_populates="teams")
    players: Mapped[list["TeamPlayer"]] = relationship(
        "TeamPlayer", back_populates="team", cascade="all, delete-orphan"
    )
    results_as_team_a: Mapped[list["MatchResult"]] = relationship(
        "MatchResult",
        foreign_keys="MatchResult.team_a_id",
        back_populates="team_a",
    )
    results_as_team_b: Mapped[list["MatchResult"]] = relationship(
        "MatchResult",
        foreign_keys="MatchResult.team_b_id",
        back_populates="team_b",
    )
    results_as_winner: Mapped[list["MatchResult"]] = relationship(
        "MatchResult",
        foreign_keys="MatchResult.winning_team_id",
        back_populates="winning_team",
    )

    # Constraints
    __table_args__ = (
        UniqueConstraint("match_id", "name", name="uq_match_team_name"),
    )

    def __repr__(self) -> str:
        return (
            f"<Team(id={self.id}, match_id={self.match_id}, "
            f"name={self.name.value}, avg_rating={self.average_skill_rating})>"
        )


class TeamPlayer(Base):
    """Junction table for team-player assignments"""

    __tablename__ = "team_players"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    team_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("teams.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    player_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("players.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    position: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, nullable=False
    )

    # Relationships
    team: Mapped["Team"] = relationship("Team", back_populates="players")
    player: Mapped["Player"] = relationship("Player", back_populates="team_assignments")

    # Constraints
    __table_args__ = (
        UniqueConstraint("team_id", "player_id", name="uq_team_player"),
    )

    def __repr__(self) -> str:
        return (
            f"<TeamPlayer(team_id={self.team_id}, player_id={self.player_id}, "
            f"position={self.position})>"
        )

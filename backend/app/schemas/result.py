"""Match result schemas"""

from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field, field_validator

from app.models.result import ResultType


class MatchResultBase(BaseModel):
    """Base match result schema"""

    team_a_score: int = Field(..., ge=0, description="Team A score")
    team_b_score: int = Field(..., ge=0, description="Team B score")


class MatchResultCreate(MatchResultBase):
    """Schema for creating a match result"""

    match_id: UUID = Field(..., description="Match ID")

    @field_validator("team_a_score", "team_b_score")
    @classmethod
    def validate_score(cls, v: int) -> int:
        """Validate score is non-negative"""
        if v < 0:
            raise ValueError("Score must be non-negative")
        return v


class MatchResultUpdate(BaseModel):
    """Schema for updating a match result"""

    team_a_score: Optional[int] = Field(None, ge=0, description="Team A score")
    team_b_score: Optional[int] = Field(None, ge=0, description="Team B score")


class MatchResultResponse(MatchResultBase):
    """Schema for match result response"""

    id: UUID
    match_id: UUID
    team_a_id: UUID
    team_b_id: UUID
    winning_team_id: Optional[UUID]
    result_type: ResultType
    recorded_at: datetime
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class MatchResultWithDetails(MatchResultResponse):
    """Match result with team details"""

    team_a_name: str = Field(..., description="Team A players summary")
    team_b_name: str = Field(..., description="Team B players summary")
    winning_team_name: Optional[str] = Field(None, description="Winning team name")

    model_config = {"from_attributes": True}

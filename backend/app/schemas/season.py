"""Season schemas"""

from datetime import date, datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field


class SeasonBase(BaseModel):
    """Base season schema"""

    name: str = Field(..., min_length=1, max_length=100, description="Season name")
    year: int = Field(..., ge=2000, le=2100, description="Season year")
    start_date: date = Field(..., description="Season start date")


class SeasonCreate(SeasonBase):
    """Schema for creating a season"""

    end_date: Optional[date] = Field(None, description="Season end date")


class SeasonUpdate(BaseModel):
    """Schema for updating a season"""

    name: Optional[str] = Field(None, min_length=1, max_length=100, description="Season name")
    end_date: Optional[date] = Field(None, description="Season end date")
    is_active: Optional[bool] = Field(None, description="Season active status")


class SeasonResponse(SeasonBase):
    """Schema for season response"""

    id: UUID
    end_date: Optional[date]
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class PlayerSeasonRatingResponse(BaseModel):
    """Schema for player season rating"""

    id: UUID
    player_id: UUID
    season_id: UUID
    current_rating: float
    matches_completed: int
    matches_attended: int
    rating_locked: bool
    last_calculated_at: Optional[datetime]
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}

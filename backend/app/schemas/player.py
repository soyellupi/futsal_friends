"""Player schemas"""

from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field


class PlayerBase(BaseModel):
    """Base player schema"""

    name: str = Field(..., min_length=1, max_length=100, description="Player name")


class PlayerCreate(PlayerBase):
    """Schema for creating a player"""

    pass


class PlayerUpdate(BaseModel):
    """Schema for updating a player"""

    name: Optional[str] = Field(None, min_length=1, max_length=100, description="Player name")
    is_active: Optional[bool] = Field(None, description="Player active status")


class PlayerResponse(PlayerBase):
    """Schema for player response"""

    id: UUID
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class PlayerWithRating(PlayerResponse):
    """Player response with current season rating"""

    current_rating: Optional[float] = Field(None, description="Current rating in active season")
    matches_played: int = Field(0, description="Matches completed in active season")
    matches_attended: int = Field(0, description="Matches attended in active season")

    model_config = {"from_attributes": True}

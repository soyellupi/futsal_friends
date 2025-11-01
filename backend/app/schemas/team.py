"""Team schemas"""

from datetime import datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, Field

from app.models.team import TeamName


class TeamPlayerBase(BaseModel):
    """Base team player schema"""

    player_id: UUID = Field(..., description="Player ID")


class TeamPlayerCreate(TeamPlayerBase):
    """Schema for creating team player assignment"""

    position: Optional[str] = Field(None, max_length=50, description="Player position")


class TeamPlayerResponse(TeamPlayerBase):
    """Schema for team player response"""

    id: UUID
    team_id: UUID
    position: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}


class TeamPlayerWithDetails(TeamPlayerResponse):
    """Team player with player details"""

    player_name: str
    player_rating: Optional[float] = Field(None, description="Player's current rating")

    model_config = {"from_attributes": True}


class TeamBase(BaseModel):
    """Base team schema"""

    match_id: UUID = Field(..., description="Match ID")
    name: TeamName = Field(..., description="Team name (A or B)")


class TeamCreate(TeamBase):
    """Schema for creating a team"""

    player_ids: List[UUID] = Field(..., description="List of player IDs for this team")


class TeamResponse(TeamBase):
    """Schema for team response"""

    id: UUID
    average_skill_rating: Optional[float]
    created_at: datetime

    model_config = {"from_attributes": True}


class TeamWithPlayers(TeamResponse):
    """Team response with player details"""

    players: List[TeamPlayerWithDetails] = Field(default_factory=list)

    model_config = {"from_attributes": True}


class TeamBalanceRequest(BaseModel):
    """Request to create balanced teams"""

    match_id: UUID = Field(..., description="Match ID")
    player_ids: List[UUID] = Field(..., min_length=2, description="Players to assign to teams")


class TeamBalanceResponse(BaseModel):
    """Response with balanced teams"""

    team_a: TeamWithPlayers
    team_b: TeamWithPlayers
    rating_difference: float = Field(..., description="Average rating difference between teams")

    model_config = {"from_attributes": True}

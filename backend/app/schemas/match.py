"""Match schemas"""

from datetime import datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, Field

from app.models.match import MatchStatus
from app.models.player import PlayerType
from app.models.team import TeamName


class MatchBase(BaseModel):
    """Base match schema"""

    match_date: datetime = Field(..., description="Match date and time")
    location: Optional[str] = Field(None, max_length=200, description="Match location")
    notes: Optional[str] = Field(None, description="Match notes")


class MatchCreate(MatchBase):
    """Schema for creating a match"""

    season_id: UUID = Field(..., description="Season ID")
    rsvp_deadline: Optional[datetime] = Field(None, description="RSVP deadline")


class MatchUpdate(BaseModel):
    """Schema for updating a match"""

    match_date: Optional[datetime] = Field(None, description="Match date and time")
    status: Optional[MatchStatus] = Field(None, description="Match status")
    rsvp_deadline: Optional[datetime] = Field(None, description="RSVP deadline")
    location: Optional[str] = Field(None, max_length=200, description="Match location")
    notes: Optional[str] = Field(None, description="Match notes")


class MatchResponse(MatchBase):
    """Schema for match response"""

    id: UUID
    season_id: UUID
    status: MatchStatus
    rsvp_deadline: Optional[datetime]
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class MatchWithDetails(MatchResponse):
    """Match response with attendance and team details"""

    confirmed_count: int = Field(0, description="Number of confirmed attendees")
    attending_count: int = Field(0, description="Number of actual attendees")
    has_teams: bool = Field(False, description="Whether teams have been created")
    has_result: bool = Field(False, description="Whether result has been recorded")

    model_config = {"from_attributes": True}


class MatchPlayerDetail(BaseModel):
    """Player details for match view"""

    id: UUID
    name: str
    rating: Optional[float] = Field(None, description="Player's ELO rating before match")
    current_rating: Optional[float] = Field(None, description="Player's current ELO rating")
    player_type: PlayerType = Field(PlayerType.REGULAR, description="Player type (regular or invited)")
    position: Optional[str] = Field(None, description="Player position (e.g., 'goalkeeper')")

    model_config = {"from_attributes": True}


class MatchTeamDetail(BaseModel):
    """Team details for match view"""

    id: UUID
    name: TeamName
    score: Optional[int] = Field(None, description="Team score")
    players: List[MatchPlayerDetail] = Field(default_factory=list)
    average_rating: Optional[float] = Field(None, description="Average team rating")

    model_config = {"from_attributes": True}


class ThirdTimeAttendee(BaseModel):
    """Third time attendee details"""

    id: UUID
    name: str

    model_config = {"from_attributes": True}


class MatchDetailResponse(MatchResponse):
    """Complete match details including teams, players, result, and third-time attendance"""

    teams: List[MatchTeamDetail] = Field(default_factory=list)
    third_time_attendees: List[ThirdTimeAttendee] = Field(default_factory=list)

    model_config = {"from_attributes": True}

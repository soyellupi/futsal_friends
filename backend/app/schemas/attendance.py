"""Attendance schemas"""

from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field

from app.models.attendance import RSVPStatus


class MatchAttendanceBase(BaseModel):
    """Base match attendance schema"""

    match_id: UUID = Field(..., description="Match ID")
    player_id: UUID = Field(..., description="Player ID")


class MatchAttendanceCreate(MatchAttendanceBase):
    """Schema for creating match attendance"""

    rsvp_status: RSVPStatus = Field(
        RSVPStatus.PENDING, description="RSVP status"
    )


class MatchAttendanceUpdate(BaseModel):
    """Schema for updating match attendance"""

    rsvp_status: Optional[RSVPStatus] = Field(None, description="RSVP status")
    attended: Optional[bool] = Field(None, description="Whether player attended")


class MatchAttendanceResponse(MatchAttendanceBase):
    """Schema for match attendance response"""

    id: UUID
    rsvp_status: RSVPStatus
    rsvp_at: Optional[datetime]
    attended: bool
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class ThirdTimeAttendanceBase(BaseModel):
    """Base third time attendance schema"""

    match_id: UUID = Field(..., description="Match ID")
    player_id: UUID = Field(..., description="Player ID")


class ThirdTimeAttendanceCreate(ThirdTimeAttendanceBase):
    """Schema for creating third time attendance"""

    attended: bool = Field(True, description="Whether player attended")


class ThirdTimeAttendanceResponse(ThirdTimeAttendanceBase):
    """Schema for third time attendance response"""

    id: UUID
    attended: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class PlayerAttendanceSummary(BaseModel):
    """Summary of player's attendance for a match"""

    player_id: UUID
    player_name: str
    rsvp_status: RSVPStatus
    match_attended: bool
    third_time_attended: bool
    current_rating: Optional[float] = Field(None, description="Player's current rating")

    model_config = {"from_attributes": True}

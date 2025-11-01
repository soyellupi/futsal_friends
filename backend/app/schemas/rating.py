"""Rating schemas"""

from datetime import datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, Field

from app.models.rating import MatchResultOutcome


class PlayerMatchRatingResponse(BaseModel):
    """Schema for player match rating response"""

    id: UUID
    player_id: UUID
    match_id: UUID
    season_id: UUID
    match_number: int
    match_date: datetime
    attended_match: bool
    attended_third_time: bool
    match_result: MatchResultOutcome
    team_average_rating: Optional[float]
    opponent_average_rating: Optional[float]
    rating_before: float
    rating_after: float
    rating_change: float
    elo_k_factor: float
    attendance_bonus: float
    third_time_bonus: float
    non_attendance_penalty: float
    calculated_at: datetime
    created_at: datetime

    model_config = {"from_attributes": True}


class PlayerMatchRatingWithDetails(PlayerMatchRatingResponse):
    """Player match rating with player and match details"""

    player_name: str
    match_date_formatted: str = Field(..., description="Formatted match date")

    model_config = {"from_attributes": True}


class RatingHistoryResponse(BaseModel):
    """Rating history for a player"""

    player_id: UUID
    player_name: str
    season_id: UUID
    season_name: str
    ratings: List[PlayerMatchRatingResponse]
    current_rating: float
    matches_completed: int
    matches_attended: int

    model_config = {"from_attributes": True}

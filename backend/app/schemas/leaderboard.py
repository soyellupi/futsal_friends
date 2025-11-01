"""Leaderboard schemas"""

from uuid import UUID

from pydantic import BaseModel, Field


class PlayerStats(BaseModel):
    """Player statistics for leaderboard"""

    player_id: UUID
    player_name: str
    current_rating: float
    matches_completed: int
    matches_attended: int
    wins: int
    draws: int
    losses: int
    third_time_attended: int
    total_points: int
    attendance_rate: float = Field(..., description="Percentage of matches attended")

    model_config = {"from_attributes": True}


class LeaderboardResponse(BaseModel):
    """Leaderboard response"""

    season_id: UUID
    season_name: str
    season_year: int
    players: list[PlayerStats]
    total_matches: int = Field(..., description="Total matches in the season")

    model_config = {"from_attributes": True}


class LeaderboardEntry(BaseModel):
    """Single leaderboard entry with ranking"""

    rank: int
    player_stats: PlayerStats

    model_config = {"from_attributes": True}


class LeaderboardWithRanking(BaseModel):
    """Leaderboard with ranking"""

    season_id: UUID
    season_name: str
    season_year: int
    entries: list[LeaderboardEntry]
    total_matches: int

    model_config = {"from_attributes": True}

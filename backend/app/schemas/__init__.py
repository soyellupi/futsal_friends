"""Pydantic schemas package"""

# Player schemas
from app.schemas.player import (
    PlayerCreate,
    PlayerResponse,
    PlayerUpdate,
    PlayerWithRating,
)

# Season schemas
from app.schemas.season import (
    PlayerSeasonRatingResponse,
    SeasonCreate,
    SeasonResponse,
    SeasonUpdate,
)

# Match schemas
from app.schemas.match import (
    MatchCreate,
    MatchResponse,
    MatchUpdate,
    MatchWithDetails,
)

# Attendance schemas
from app.schemas.attendance import (
    MatchAttendanceCreate,
    MatchAttendanceResponse,
    MatchAttendanceUpdate,
    PlayerAttendanceSummary,
    ThirdTimeAttendanceCreate,
    ThirdTimeAttendanceResponse,
)

# Team schemas
from app.schemas.team import (
    TeamBalanceRequest,
    TeamBalanceResponse,
    TeamCreate,
    TeamPlayerCreate,
    TeamPlayerResponse,
    TeamPlayerWithDetails,
    TeamResponse,
    TeamWithPlayers,
)

# Result schemas
from app.schemas.result import (
    MatchResultCreate,
    MatchResultResponse,
    MatchResultUpdate,
    MatchResultWithDetails,
)

# Rating schemas
from app.schemas.rating import (
    PlayerMatchRatingResponse,
    PlayerMatchRatingWithDetails,
    RatingHistoryResponse,
)

# Leaderboard schemas
from app.schemas.leaderboard import (
    LeaderboardEntry,
    LeaderboardResponse,
    LeaderboardWithRanking,
    PlayerStats,
)

__all__ = [
    # Player
    "PlayerCreate",
    "PlayerUpdate",
    "PlayerResponse",
    "PlayerWithRating",
    # Season
    "SeasonCreate",
    "SeasonUpdate",
    "SeasonResponse",
    "PlayerSeasonRatingResponse",
    # Match
    "MatchCreate",
    "MatchUpdate",
    "MatchResponse",
    "MatchWithDetails",
    # Attendance
    "MatchAttendanceCreate",
    "MatchAttendanceUpdate",
    "MatchAttendanceResponse",
    "ThirdTimeAttendanceCreate",
    "ThirdTimeAttendanceResponse",
    "PlayerAttendanceSummary",
    # Team
    "TeamCreate",
    "TeamResponse",
    "TeamWithPlayers",
    "TeamPlayerCreate",
    "TeamPlayerResponse",
    "TeamPlayerWithDetails",
    "TeamBalanceRequest",
    "TeamBalanceResponse",
    # Result
    "MatchResultCreate",
    "MatchResultUpdate",
    "MatchResultResponse",
    "MatchResultWithDetails",
    # Rating
    "PlayerMatchRatingResponse",
    "PlayerMatchRatingWithDetails",
    "RatingHistoryResponse",
    # Leaderboard
    "PlayerStats",
    "LeaderboardResponse",
    "LeaderboardEntry",
    "LeaderboardWithRanking",
]

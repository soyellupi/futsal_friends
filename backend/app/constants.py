"""Application constants"""


class RatingConfig:
    """Rating system configuration constants"""

    # Initial rating for all players at season start
    INITIAL_RATING: float = 3.0

    # Rating bounds (1-5 scale)
    MIN_RATING: float = 1.0
    MAX_RATING: float = 5.0

    # ELO system parameters
    ELO_K_FACTOR: float = 0.5  # Rating volatility factor
    RATING_SCALING_FACTOR: float = 2.0  # For ELO expected score calculation

    # Bonuses and penalties
    ATTENDANCE_BONUS: float = 0.1  # Bonus for attending the match
    THIRD_TIME_BONUS: float = 0.05  # Bonus for attending post-match social
    NON_ATTENDANCE_PENALTY: float = -0.2  # Penalty for missing a match

    # Minimum matches before rating changes
    MIN_MATCHES_FOR_RATING: int = 3  # Rating locked until this many matches

    # Rolling window for rating calculation
    RATING_WINDOW_SIZE: int = 3  # Number of recent matches to consider


class PointsConfig:
    """Leaderboard points configuration"""

    # Points awarded for different outcomes
    POINTS_MATCH_ATTENDANCE: int = 1
    POINTS_WIN: int = 3
    POINTS_DRAW: int = 1
    POINTS_LOSS: int = 0
    POINTS_THIRD_TIME: int = 1

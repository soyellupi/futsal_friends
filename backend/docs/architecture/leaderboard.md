# Leaderboard System

This document explains how player statistics and leaderboard rankings are calculated.

## Overview

The leaderboard provides a comprehensive view of player performance throughout a season, combining multiple metrics into a points-based system.

## Metrics Tracked

### 1. Match Attendance
- **Definition**: Number of matches player actually attended
- **Importance**: Commitment and participation
- **Points**: 1 point per match attended

### 2. Wins
- **Definition**: Matches where player's team won
- **Points**: 3 points per win

### 3. Draws
- **Definition**: Matches that ended in a tie
- **Points**: 1 point per draw

### 4. Losses
- **Definition**: Matches where player's team lost
- **Points**: 0 points per loss

### 5. Third Time Attendance
- **Definition**: Post-match social gatherings attended
- **Points**: 1 point per third time

### 6. Current Rating
- **Definition**: Player's current skill rating (1.0 - 5.0)
- **Use**: Tie-breaker, team balancing

### 7. Attendance Rate
- **Definition**: Percentage of matches attended out of total completed
- **Formula**: `(matches_attended / matches_completed) * 100`

## Points Calculation

### Total Points Formula

```
Total Points =
    (Match Attendance × 1) +
    (Wins × 3) +
    (Draws × 1) +
    (Losses × 0) +
    (Third Time Attendance × 1)
```

### Configuration

Points values are defined in `app/constants.py`:

```python
class PointsConfig:
    POINTS_MATCH_ATTENDANCE = 1
    POINTS_WIN = 3
    POINTS_DRAW = 1
    POINTS_LOSS = 0
    POINTS_THIRD_TIME = 1
```

## Example Calculation

### Player Statistics

```
Player: John Doe
Matches Completed: 10
Matches Attended: 9
Wins: 5
Draws: 2
Losses: 2
Third Time Attended: 7
```

### Points Breakdown

```
Match Attendance:    9 × 1 = 9 points
Wins:                5 × 3 = 15 points
Draws:               2 × 1 = 2 points
Losses:              2 × 0 = 0 points
Third Time:          7 × 1 = 7 points
                     ─────────────────
Total Points:                 33 points

Attendance Rate: (9 / 10) × 100 = 90%
Current Rating: 3.5
```

## Leaderboard Ranking

### Primary Sort: Total Points (Descending)

Players are ranked by total points, highest first:

```
Rank 1: Alice    - 45 points
Rank 2: Bob      - 38 points
Rank 3: Charlie  - 33 points
Rank 4: Diana    - 28 points
```

### Tie-Breaker: Current Rating

If players have equal points, higher rating wins:

```
Charlie: 33 points, Rating 3.5
Diana:   33 points, Rating 3.2
→ Charlie ranks higher
```

### Example Leaderboard

| Rank | Player  | Points | Rating | Attended | Wins | Draws | Losses | 3rd Time | Att. Rate |
|------|---------|--------|--------|----------|------|-------|--------|----------|-----------|
| 1    | Alice   | 45     | 3.8    | 10/10    | 7    | 2     | 1      | 10       | 100%      |
| 2    | Bob     | 38     | 3.6    | 10/10    | 6    | 2     | 2      | 8        | 100%      |
| 3    | Charlie | 33     | 3.5    | 9/10     | 5    | 2     | 2      | 7        | 90%       |
| 4    | Diana   | 33     | 3.2    | 8/10     | 5    | 1     | 2      | 9        | 80%       |
| 5    | Eve     | 28     | 3.0    | 8/10     | 4    | 2     | 2      | 6        | 80%       |

## Data Sources

### PlayerSeasonRating

```python
player_season_rating = {
    "current_rating": 3.5,
    "matches_completed": 10,
    "matches_attended": 9
}
```

### PlayerMatchRating

```python
match_ratings = [
    {"match_result": "win", "attended_third_time": True},
    {"match_result": "win", "attended_third_time": True},
    {"match_result": "loss", "attended_third_time": False},
    # ... more matches
]

# Calculate from match ratings:
wins = count(match_result == "win")
draws = count(match_result == "draw")
losses = count(match_result == "loss")
third_time_attended = count(attended_third_time == True)
```

## Implementation

### LeaderboardService

**File**: `app/services/leaderboard_service.py`

```python
class LeaderboardService:
    async def calculate_season_leaderboard(
        self, season_id: UUID
    ) -> List[PlayerStats]:
        """
        Calculate complete leaderboard for a season.

        Returns list of PlayerStats sorted by:
        1. Total points (desc)
        2. Current rating (desc)
        """
        # Get all player season ratings
        # For each player:
        #   - Query PlayerMatchRating records
        #   - Count wins, draws, losses
        #   - Count third time attendance
        #   - Calculate total points
        #   - Calculate attendance rate
        # Sort by points and rating
        return leaderboard

    async def get_player_stats(
        self, player_id: UUID, season_id: UUID
    ) -> PlayerStats:
        """
        Get statistics for a single player.
        """
        # Query player season rating
        # Query player match ratings
        # Calculate all statistics
        return player_stats
```

### PlayerStats Schema

```python
class PlayerStats(BaseModel):
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
    attendance_rate: float  # Percentage
```

## Querying the Leaderboard

### Get Season Leaderboard

```python
@router.get("/seasons/{season_id}/leaderboard")
async def get_leaderboard(season_id: UUID):
    service = LeaderboardService(db, ...)
    leaderboard = await service.calculate_season_leaderboard(season_id)
    return LeaderboardResponse(
        season_id=season_id,
        season_name="2025 Season",
        season_year=2025,
        players=leaderboard,
        total_matches=15
    )
```

### Get Player Stats

```python
@router.get("/players/{player_id}/stats")
async def get_player_stats(player_id: UUID, season_id: UUID):
    service = LeaderboardService(db, ...)
    stats = await service.get_player_stats(player_id, season_id)
    return stats
```

## Leaderboard Scenarios

### Scenario 1: Perfect Attendance, Many Wins

```
Player: Alice
- Attended: 10/10 (100%)
- Wins: 7, Draws: 2, Losses: 1
- Third Time: 10

Points:
Match Attendance: 10 × 1 = 10
Wins:             7 × 3  = 21
Draws:            2 × 1  = 2
Third Time:       10 × 1 = 10
Total:                     43 points

→ Top of leaderboard
```

### Scenario 2: Poor Attendance

```
Player: Bob
- Attended: 4/10 (40%)
- Wins: 3, Draws: 0, Losses: 1
- Third Time: 2

Points:
Match Attendance: 4 × 1  = 4
Wins:             3 × 3  = 9
Third Time:       2 × 1  = 2
Total:                     15 points

→ Lower in leaderboard despite good win rate
```

### Scenario 3: High Participation, Frequent Losses

```
Player: Charlie
- Attended: 10/10 (100%)
- Wins: 2, Draws: 3, Losses: 5
- Third Time: 10

Points:
Match Attendance: 10 × 1 = 10
Wins:             2 × 3  = 6
Draws:            3 × 1  = 3
Third Time:       10 × 1 = 10
Total:                     29 points

→ Middle of leaderboard (rewarded for participation)
```

## Balancing Attendance vs. Performance

The points system balances:

### Attendance (Max: ~20-30% of total)
- Encourages showing up
- Rewards commitment
- Values social participation (third time)

### Performance (Max: ~70-80% of total)
- Wins are most valuable (3 points)
- Draws provide modest points (1 point)
- Losses provide nothing

### Example Weight Distribution

For a 10-match season with perfect attendance:

```
Maximum Possible Points (10 wins):
Attendance:  10 points (20%)
Wins:        30 points (60%)
Third Time:  10 points (20%)
Total:       50 points

Realistic Distribution:
Attendance:  10 points
Performance: 15-20 points (5-7 wins)
Third Time:  7-10 points
Total:       32-40 points
```

## Performance Optimization

### Database Query

Single query to get all player ratings:

```sql
SELECT * FROM player_season_ratings
WHERE season_id = ?
ORDER BY current_rating DESC
```

Then for each player, query match ratings:

```sql
SELECT * FROM player_match_ratings
WHERE player_id = ? AND season_id = ?
```

### Caching Strategy

For frequently accessed leaderboards:

```python
# Cache leaderboard for 5 minutes
@cache(ttl=300)
async def get_cached_leaderboard(season_id):
    return await calculate_season_leaderboard(season_id)
```

### Materialized View (Future)

For very large seasons:

```sql
CREATE MATERIALIZED VIEW season_leaderboard AS
SELECT
    player_id,
    SUM(CASE WHEN match_result = 'win' THEN 3 ELSE 0 END) as win_points,
    COUNT(*) FILTER (WHERE attended_match) as attendance_points,
    ...
FROM player_match_ratings
GROUP BY player_id;
```

## Testing

### Unit Tests

```python
def test_points_calculation():
    stats = PlayerStats(
        matches_attended=10,
        wins=5,
        draws=2,
        losses=3,
        third_time_attended=8
    )

    expected_points = (10 * 1) + (5 * 3) + (2 * 1) + (3 * 0) + (8 * 1)
    assert stats.total_points == expected_points
    assert stats.total_points == 35

def test_attendance_rate():
    stats = PlayerStats(
        matches_completed=10,
        matches_attended=8
    )

    assert stats.attendance_rate == 80.0

def test_leaderboard_sorting():
    players = [
        PlayerStats(total_points=30, current_rating=3.5),
        PlayerStats(total_points=35, current_rating=3.0),
        PlayerStats(total_points=30, current_rating=3.8),
    ]

    sorted_players = sort_leaderboard(players)

    # Should be sorted by points, then rating
    assert sorted_players[0].total_points == 35
    assert sorted_players[1].total_points == 30
    assert sorted_players[1].current_rating == 3.8  # Higher rating
```

### Integration Tests

```python
async def test_full_season_leaderboard(db):
    # Create season
    # Create 10 matches
    # Record various results for multiple players
    # Calculate leaderboard
    # Verify sorting and points
```

## UI Considerations

### Leaderboard Display

```
┌─────────────────────────────────────────────────────────────┐
│                    2025 Season Leaderboard                  │
├──────┬───────────┬────────┬────────┬──────────┬────────────┤
│ Rank │ Player    │ Points │ Rating │ W/D/L    │ Attendance │
├──────┼───────────┼────────┼────────┼──────────┼────────────┤
│  1   │ Alice     │   45   │  3.8   │ 7/2/1    │   100%     │
│  2   │ Bob       │   38   │  3.6   │ 6/2/2    │   100%     │
│  3   │ Charlie   │   33   │  3.5   │ 5/2/2    │    90%     │
│  4   │ Diana     │   33   │  3.2   │ 5/1/2    │    80%     │
│  5   │ Eve       │   28   │  3.0   │ 4/2/2    │    80%     │
└──────┴───────────┴────────┴────────┴──────────┴────────────┘
```

### Player Profile

```
┌──────────────────────────────────────┐
│        John Doe - Season Stats       │
├──────────────────────────────────────┤
│ Rank:           #3                   │
│ Total Points:   33                   │
│ Current Rating: 3.5 ⭐⭐⭐            │
│                                      │
│ Matches:        9/10 attended (90%)  │
│ Record:         5W - 2D - 2L         │
│ Third Time:     7/9 attended (78%)   │
│                                      │
│ Points Breakdown:                    │
│   Match Attendance:  9 pts           │
│   Wins (5):         15 pts           │
│   Draws (2):         2 pts           │
│   Third Time (7):    7 pts           │
│   Total:            33 pts           │
└──────────────────────────────────────┘
```

## Future Enhancements

Potential improvements:

1. **Achievements/Badges**: Special recognition for milestones
2. **Streaks**: Track consecutive match attendance
3. **MVP Awards**: Best player of the week/month
4. **Historical Comparison**: Compare across seasons
5. **Predicted Finish**: Project final standings
6. **Custom Scoring**: Allow customizable point values

## See Also

- [Rating System](rating-system.md) - How skill ratings are calculated
- [Database Schema](../database/schema.md) - Data structures
- [System Overview](overview.md) - Architecture context

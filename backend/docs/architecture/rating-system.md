# Rating System

This document explains the dynamic ELO-based rating system used for player skill assessment and team balancing.

## Overview

The Futsal Friends rating system uses a **rolling 3-match window** with an **ELO-inspired algorithm** adapted for team sports. Ratings range from **1.0 to 5.0**, with 3.0 as the default starting point.

### Key Characteristics

- **Scale**: 1.0 (lowest) to 5.0 (highest)
- **Initial Rating**: 3.0 for all players
- **Window**: Last 3 matches determine current rating
- **Season Reset**: All ratings return to 3.0 at season start
- **Universal Updates**: ALL season players' ratings update after each match (not just attendees)

## Rating Lifecycle

### Phase 1: Initialization (Matches 1-3)

For the first 3 matches of a season:

```
Rating = 3.0 (LOCKED)
```

**Why Locked?**
- Insufficient data for accurate assessment
- Prevents wild swings from small sample size
- Ensures fair team balancing in early season
- Players need time to establish baseline performance

**What's Tracked:**
- Match attendance
- Win/draw/loss outcomes
- Third time attendance
- All data is recorded in `PlayerMatchRating`

### Phase 2: Active Rating (Match 4+)

After 3 matches, rating becomes **active** and calculated from last 3 matches:

```
Current Rating = Initial Rating (3.0) + Sum of last 3 rating changes
```

**Example:**

| Match | Result | Attendance | Third Time | Change | Calculation | Rating |
|-------|--------|------------|------------|--------|-------------|--------|
| 1     | Win    | Yes        | Yes        | 0.0    | 3.0 + 0.0   | 3.0 ✓ |
| 2     | Loss   | Yes        | No         | 0.0    | 3.0 + 0.0   | 3.0 ✓ |
| 3     | Win    | Yes        | Yes        | 0.0    | 3.0 + 0.0   | 3.0 ✓ |
| 4     | Win    | Yes        | Yes        | +0.25  | 3.0 + (0 + 0 + 0.25) | 3.25 |
| 5     | Win    | Yes        | No         | +0.20  | 3.0 + (0 + 0.25 + 0.20) | 3.45 |
| 6     | Loss   | Yes        | Yes        | -0.05  | 3.0 + (0.25 + 0.20 - 0.05) | 3.40 |
| 7     | No     | No         | No         | -0.20  | 3.0 + (0.20 - 0.05 - 0.20) | 2.95 |

✓ = Rating locked

## Rating Calculation Formula

### Step 1: Determine Match Outcome

For each player after a match:

```python
if player_attended_match:
    if player_team_won:
        outcome = WIN (actual_score = 1.0)
    elif draw:
        outcome = DRAW (actual_score = 0.5)
    else:
        outcome = LOSS (actual_score = 0.0)
else:
    outcome = DID_NOT_ATTEND
```

### Step 2: Calculate ELO Change (For Attendees)

```python
# Expected score based on team ratings
rating_diff = opponent_team_avg - player_team_avg
expected_score = 1 / (1 + 10^(rating_diff / scaling_factor))

# ELO change
elo_change = K_FACTOR * (actual_score - expected_score)
```

**Constants:**
- `K_FACTOR = 0.5` (rating volatility)
- `SCALING_FACTOR = 2.0` (adapted for 1-5 scale)

**Example:**

```python
# Team A avg: 3.2, Team B avg: 3.0
# Player on Team A wins

rating_diff = 3.0 - 3.2 = -0.2
expected = 1 / (1 + 10^(-0.2 / 2.0))
         = 1 / (1 + 10^(-0.1))
         = 1 / (1 + 0.794)
         = 0.557 (55.7% expected to win)

actual = 1.0 (won)

elo_change = 0.5 * (1.0 - 0.557)
           = 0.5 * 0.443
           = +0.22
```

### Step 3: Add Bonuses/Penalties

```python
# Attendance bonus (for showing up)
if attended_match:
    attendance_bonus = +0.1
else:
    attendance_bonus = 0.0

# Third time bonus (social participation)
if attended_third_time:
    third_time_bonus = +0.05
else:
    third_time_bonus = 0.0

# Non-attendance penalty
if not attended_match:
    penalty = -0.2
else:
    penalty = 0.0
```

### Step 4: Calculate Total Change

```python
if attended_match:
    total_change = elo_change + attendance_bonus + third_time_bonus
else:
    total_change = penalty
```

**Examples:**

**Scenario A: Attended, Won, Third Time**
```
elo_change = +0.22
attendance_bonus = +0.1
third_time_bonus = +0.05
total_change = +0.37
```

**Scenario B: Attended, Lost, No Third Time**
```
elo_change = -0.15
attendance_bonus = +0.1
third_time_bonus = 0.0
total_change = -0.05
```

**Scenario C: Did Not Attend**
```
elo_change = 0.0
attendance_bonus = 0.0
third_time_bonus = 0.0
penalty = -0.2
total_change = -0.2
```

### Step 5: Calculate New Rating (For Match 4+)

```python
# Get last 3 match rating changes
last_3_changes = get_last_3_match_ratings(player, season)

# Start from initial rating
new_rating = INITIAL_RATING  # 3.0

# Apply last 3 changes
for rating_record in last_3_changes:
    new_rating += rating_record.rating_change

# Clamp to bounds
new_rating = max(MIN_RATING, min(MAX_RATING, new_rating))
```

**Example with full history:**

```python
Match 4: change = +0.25
Match 5: change = +0.20
Match 6: change = -0.05

new_rating = 3.0 + 0.25 + 0.20 + (-0.05)
           = 3.40
```

## Configuration Values

All rating constants are defined in `app/constants.py`:

```python
class RatingConfig:
    # Rating scale
    INITIAL_RATING = 3.0
    MIN_RATING = 1.0
    MAX_RATING = 5.0

    # ELO parameters
    ELO_K_FACTOR = 0.5
    RATING_SCALING_FACTOR = 2.0

    # Bonuses and penalties
    ATTENDANCE_BONUS = 0.1
    THIRD_TIME_BONUS = 0.05
    NON_ATTENDANCE_PENALTY = -0.2

    # System rules
    MIN_MATCHES_FOR_RATING = 3
    RATING_WINDOW_SIZE = 3
```

## Why This System?

### 1. Rolling Window (Last 3 Matches)

**Advantages:**
- ✅ Reflects **current form**, not historical performance
- ✅ Responsive to improvement/decline
- ✅ Fair for returning players
- ✅ Simple to understand
- ✅ Efficient to calculate

**Alternatives Considered:**
- ❌ **Cumulative ELO**: Historical bias, slow adaptation
- ❌ **Exponential decay**: Complex, less transparent
- ❌ **Season average**: Doesn't reflect current skill

### 2. 1-5 Scale

**Advantages:**
- ✅ Intuitive (similar to star ratings)
- ✅ Easy to communicate to players
- ✅ Suitable range for small groups
- ✅ Prevents extreme values

**Alternative:**
- ❌ **Traditional ELO (400-2800)**: Intimidating, harder to grasp

### 3. Universal Updates

**Why update ALL players, not just attendees?**

- ✅ Non-attendees lose rating (penalty encourages attendance)
- ✅ Consistent state across all players
- ✅ Accurate team balancing uses latest data
- ✅ Historical tracking is complete

### 4. Attendance Bonuses

**Why reward attendance?**

- ✅ Encourages participation
- ✅ Recognizes commitment
- ✅ Small boost for showing up
- ✅ Balances win/loss focus

## Edge Cases

### Case 1: Perfect Upset

Weak team (avg 2.0) beats strong team (avg 4.0):

```python
expected_score = 1 / (1 + 10^((4.0 - 2.0) / 2.0))
               = 1 / (1 + 10^1.0)
               = 1 / 11
               = 0.09 (9% chance to win)

actual_score = 1.0 (won!)

elo_change = 0.5 * (1.0 - 0.09)
           = +0.455

With bonuses: +0.455 + 0.1 + 0.05 = +0.605
```

Large positive change for unexpected win!

### Case 2: Expected Win

Strong player (4.0) beats weak opponent (2.0):

```python
expected_score = 0.91 (91% chance to win)
actual_score = 1.0 (won)

elo_change = 0.5 * (1.0 - 0.91)
           = +0.045

With bonuses: +0.045 + 0.1 + 0.05 = +0.195
```

Small change for expected outcome.

### Case 3: Multiple Consecutive Absences

```
Match 4: Attended, won → +0.25
Match 5: Absent → -0.2
Match 6: Absent → -0.2
Match 7: Absent → -0.2

At match 7:
new_rating = 3.0 + (-0.2) + (-0.2) + (-0.2)
           = 2.4
```

Rating drops significantly for non-participation.

### Case 4: Rating Floor/Ceiling

```python
# Player at 4.9, gets +0.3 change
new_rating = 4.9 + 0.3 = 5.2
clamped_rating = min(5.0, 5.2) = 5.0  # Hits ceiling

# Player at 1.1, gets -0.3 change
new_rating = 1.1 - 0.3 = 0.8
clamped_rating = max(1.0, 0.8) = 1.0  # Hits floor
```

### Case 5: Unplayable Match

When a match cannot be played (weather, too few players, etc.), it can be marked as `UNPLAYABLE`:

```
Match Week 5: status = UNPLAYABLE

Effects:
- No PlayerMatchRating records created
- No rating changes for any player
- No penalties for non-attendance
- matches_completed NOT incremented
- Third time attendance CAN still be recorded
- Third time points count for leaderboard
```

**Comparison with other statuses:**

| Aspect | COMPLETED | UNPLAYABLE | CANCELLED |
|--------|-----------|------------|-----------|
| Teams created | Yes | No | No |
| Result recorded | Yes | No | No |
| Ratings calculated | Yes | No | No |
| Non-attendance penalty | Yes (-0.2) | No | No |
| Third time attendance | Yes | Yes | No |
| Third time bonus (rating) | +0.05 | No (no ratings) | No |
| Third time points (leaderboard) | +1 | +1 | No |
| Occupies match_week | Yes | Yes | Yes |

## Implementation

### RatingService

**File**: `app/services/rating_service.py`

**Key Methods:**

```python
class RatingService:
    async def calculate_match_ratings(
        self, match, team_a, team_b, season_players
    ):
        """
        Calculate ratings for ALL season players after a match.

        Args:
            match: The completed match
            team_a: Team A
            team_b: Team B
            season_players: All players in the season

        Returns:
            List[PlayerMatchRating]: Rating records for all players

        Raises:
            ValueError: If match status is UNPLAYABLE
        """
        # Reject unplayable matches
        if match.status == MatchStatus.UNPLAYABLE:
            raise ValueError("Cannot calculate ratings for unplayable match")

        # For each season player:
        # 1. Determine if they attended
        # 2. Get their match outcome
        # 3. Calculate rating change
        # 4. Update PlayerSeasonRating
        # 5. Create PlayerMatchRating record
```

### Database Records

**PlayerMatchRating** stores complete calculation details:

```python
PlayerMatchRating(
    player_id=...,
    match_id=...,
    season_id=...,
    match_number=4,
    attended_match=True,
    attended_third_time=True,
    match_result=MatchResultOutcome.WIN,
    team_average_rating=3.2,
    opponent_average_rating=3.0,
    rating_before=3.0,
    rating_after=3.37,
    rating_change=0.37,
    elo_k_factor=0.5,
    attendance_bonus=0.1,
    third_time_bonus=0.05,
    non_attendance_penalty=0.0,
    calculated_at=datetime.utcnow()
)
```

**PlayerSeasonRating** stores current state:

```python
PlayerSeasonRating(
    player_id=...,
    season_id=...,
    current_rating=3.37,
    matches_completed=4,
    matches_attended=4,
    rating_locked=False,  # Unlocked after match 3
    last_calculated_at=datetime.utcnow()
)
```

## Testing the Rating System

### Unit Tests

```python
def test_rating_locked_first_3_matches():
    # Matches 1-3 should keep rating at 3.0
    assert rating_after_match_1 == 3.0
    assert rating_after_match_2 == 3.0
    assert rating_after_match_3 == 3.0

def test_rating_active_after_3_matches():
    # Match 4+ should calculate from last 3
    assert rating_after_match_4 != 3.0

def test_non_attendance_penalty():
    # Missing match should apply -0.2
    change = calculate_rating_change(attended=False)
    assert change.total == -0.2

def test_rating_bounds():
    # Should clamp to 1.0 - 5.0
    assert calculate_rating(10.0) == 5.0
    assert calculate_rating(-1.0) == 1.0
```

### Integration Tests

```python
async def test_full_rating_workflow():
    # Create season
    # Create 4 matches
    # Record results
    # Verify ratings calculated correctly
    # Check PlayerMatchRating records
    # Verify PlayerSeasonRating updated
```

## Performance Implications

### After Each Match

```
Time Complexity: O(N * 3)
- N = number of season players
- 3 = last 3 matches query

Space Complexity: O(N)
- N PlayerMatchRating records created
- N PlayerSeasonRating records updated
```

### Optimization

```python
# Batch insert for ratings
await rating_repo.bulk_create_ratings(ratings)

# Use indexed queries
# Composite index on (player_id, season_id, match_date DESC)
```

## Future Enhancements

Potential improvements:

1. **Variable K-Factor**: Higher for new players, lower for established
2. **Position-Based Ratings**: Different ratings for different positions
3. **Confidence Intervals**: Show rating uncertainty
4. **Rating History Graph**: Visualize rating evolution
5. **Predictive Analytics**: Win probability based on team ratings

## See Also

- [Team Balancing](team-balancing.md) - How ratings are used for teams
- [Leaderboard](leaderboard.md) - How ratings appear in rankings
- [Database Schema](../database/schema.md) - Rating table structures
- [System Overview](overview.md) - Architecture context

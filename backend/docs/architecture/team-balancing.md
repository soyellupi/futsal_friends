# Team Balancing Algorithm

This document explains how teams are automatically created and balanced based on player skill ratings.

## Overview

The team balancing system creates two fair teams from match attendees using their current skill ratings. The goal is to minimize the rating difference between teams to ensure competitive matches.

## Problem Statement

**Input:**
- List of N players attending the match
- Each player has a current rating (1.0 - 5.0)

**Output:**
- Team A: N/2 players (rounded down if odd)
- Team B: Remaining players
- Both teams have similar average ratings

**Goal:**
```
Minimize: |avg_rating(Team A) - avg_rating(Team B)|
```

## Algorithm: Greedy Balancing

We use a **greedy algorithm** that assigns each player to the team with the lower current total rating.

### Algorithm Steps

```
1. Sort players by rating (highest to lowest)
2. Initialize two empty teams (A and B)
3. Initialize team totals (total_A = 0, total_B = 0)
4. For each player in sorted order:
   - If total_A ≤ total_B:
       Add player to Team A
       total_A += player_rating
   - Else:
       Add player to Team B
       total_B += player_rating
5. Calculate average ratings for each team
6. Create Team A and Team B with assignments
```

### Pseudocode

```python
def create_balanced_teams(player_ratings):
    # Sort by rating (highest first)
    sorted_players = sort(player_ratings, reverse=True)

    team_a = []
    team_b = []
    total_a = 0.0
    total_b = 0.0

    for player_id, rating in sorted_players:
        if total_a <= total_b:
            team_a.append(player_id)
            total_a += rating
        else:
            team_b.append(player_id)
            total_b += rating

    avg_a = total_a / len(team_a) if team_a else 0.0
    avg_b = total_b / len(team_b) if team_b else 0.0

    return team_a, team_b, avg_a, avg_b
```

## Example

### Scenario: 8 Players

**Players and Ratings:**
```
Player A: 4.2
Player B: 3.8
Player C: 3.5
Player D: 3.3
Player E: 3.0
Player F: 2.8
Player G: 2.5
Player H: 2.2
```

**Balancing Process:**

| Step | Player | Rating | Team A Total | Team B Total | Assigned To |
|------|--------|--------|--------------|--------------|-------------|
| 1    | A      | 4.2    | 0.0          | 0.0          | Team A (4.2) |
| 2    | B      | 3.8    | 4.2          | 0.0          | Team B (3.8) |
| 3    | C      | 3.5    | 4.2          | 3.8          | Team B (7.3) |
| 4    | D      | 3.3    | 4.2          | 7.3          | Team A (7.5) |
| 5    | E      | 3.0    | 7.5          | 7.3          | Team B (10.3) |
| 6    | F      | 2.8    | 7.5          | 10.3         | Team A (10.3) |
| 7    | G      | 2.5    | 10.3         | 10.3         | Team A (12.8) |
| 8    | H      | 2.2    | 12.8         | 10.3         | Team B (12.5) |

**Final Teams:**

```
Team A: A (4.2), D (3.3), F (2.8), G (2.5)
- Total: 12.8
- Average: 12.8 / 4 = 3.2

Team B: B (3.8), C (3.5), E (3.0), H (2.2)
- Total: 12.5
- Average: 12.5 / 4 = 3.125

Difference: |3.2 - 3.125| = 0.075
```

Excellent balance! Only 0.075 average rating difference.

## Algorithm Analysis

### Time Complexity

```
O(N log N)
```
- Sorting players: O(N log N)
- Assignment loop: O(N)
- Total: O(N log N)

### Space Complexity

```
O(N)
```
- Storage for two teams: O(N)

### Optimality

This greedy algorithm **does not guarantee** the optimal solution (NP-hard problem), but it provides:

- ✅ Fast computation
- ✅ Good results in practice
- ✅ Simple to understand
- ✅ Deterministic (same input = same output)

**Example where greedy is suboptimal:**

```
Players: A(5.0), B(4.0), C(3.0), D(3.0)

Greedy Result:
Team A: A(5.0), D(3.0) → Avg: 4.0
Team B: B(4.0), C(3.0) → Avg: 3.5
Difference: 0.5

Optimal Result:
Team A: A(5.0), C(3.0) → Avg: 4.0
Team B: B(4.0), D(3.0) → Avg: 3.5
Difference: 0.5
```

In this case, greedy happens to find optimal. For most real-world scenarios with more players, greedy provides good enough balance.

## Alternative Algorithm: Randomized Balancing

For variety and to prevent predictable teams, we also offer a **randomized approach with optimization**.

### Shuffle Algorithm

```python
def shuffle_balanced_teams(player_ratings, attempts=100):
    best_split = None
    best_difference = float('inf')

    for _ in range(attempts):
        # Random shuffle
        shuffled = shuffle(player_ratings)

        # Split in half
        mid = len(shuffled) // 2
        team_a = shuffled[:mid]
        team_b = shuffled[mid:]

        # Calculate averages
        avg_a = sum(ratings[team_a]) / len(team_a)
        avg_b = sum(ratings[team_b]) / len(team_b)

        # Check if better
        difference = abs(avg_a - avg_b)
        if difference < best_difference:
            best_difference = difference
            best_split = (team_a, team_b, avg_a, avg_b)

    return best_split
```

### Comparison

| Aspect | Greedy | Randomized (100 attempts) |
|--------|--------|---------------------------|
| Speed | ⚡ Fast (single pass) | 🐌 Slower (100 shuffles) |
| Balance | ✅ Good | ✅ Very good |
| Variety | ❌ Deterministic | ✅ Different each time |
| Predictability | ❌ Always same | ✅ Unpredictable |

**Use Cases:**
- **Greedy**: Default, fast, consistent
- **Randomized**: Special events, mixing things up, when variety matters

## Implementation

### TeamService

**File**: `app/services/team_service.py`

```python
class TeamService:
    async def create_balanced_teams(
        self, match_id, season_id, player_ids
    ) -> tuple[Team, Team]:
        """
        Create two balanced teams using greedy algorithm.
        """
        # Get player ratings from season
        # Sort by rating
        # Greedy assignment
        # Create Team records
        # Create TeamPlayer records
        return team_a, team_b

    async def shuffle_teams(
        self, match_id, season_id, player_ids, max_attempts=100
    ) -> tuple[Team, Team]:
        """
        Create balanced teams with randomization.
        """
        # Try multiple random splits
        # Pick best balanced split
        # Create teams
        return team_a, team_b
```

### Database Storage

Teams are stored in the database:

```python
# Team A
team_a = Team(
    match_id=match_id,
    name=TeamName.TEAM_A,
    average_skill_rating=3.2  # Calculated average
)

# Team A Players
for player_id in team_a_player_ids:
    team_player = TeamPlayer(
        team_id=team_a.id,
        player_id=player_id,
        position=None  # Optional
    )
```

## Handling Edge Cases

### Odd Number of Players

```python
players = [A, B, C, D, E]  # 5 players

team_a = [A, D, E]     # 3 players
team_b = [B, C]        # 2 players
```

One team gets the extra player. Greedy ensures balance is maintained.

### Two Players

```python
players = [A(4.0), B(2.0)]

team_a = [A]  # Avg: 4.0
team_b = [B]  # Avg: 2.0

# Large difference, but unavoidable with 2 players
```

### All Same Rating

```python
players = [A(3.0), B(3.0), C(3.0), D(3.0)]

team_a = [A, B]  # Avg: 3.0
team_b = [C, D]  # Avg: 3.0

# Perfect balance
```

### Rating Range

```python
players = [A(5.0), B(1.0)]

team_a = [A]  # Avg: 5.0
team_b = [B]  # Avg: 1.0

# Maximum possible difference
```

## Usage in Workflow

### Match Creation Flow

```
1. Match is created (status = SCHEDULED)
   ↓
2. Players RSVP
   ↓
3. RSVP deadline passes
   ↓
4. Organizer views confirmed attendees
   ↓
5. System creates balanced teams
   → TeamService.create_balanced_teams(confirmed_players)
   ↓
6. Teams are created in database
   ↓
7. Match status → CONFIRMED
   ↓
8. Match is played
   ↓
9. Result is recorded
   ↓
10. Ratings are calculated using team averages
```

### API Endpoint

```python
@router.post("/matches/{match_id}/teams")
async def create_teams(
    match_id: UUID,
    request: TeamBalanceRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Create balanced teams for a match.

    Request:
    {
        "match_id": "uuid",
        "player_ids": ["uuid1", "uuid2", ...]
    }

    Response:
    {
        "team_a": {...},
        "team_b": {...},
        "rating_difference": 0.075
    }
    """
    team_service = TeamService(db, ...)
    team_a, team_b = await team_service.create_balanced_teams(
        match_id, season_id, request.player_ids
    )
    return response
```

## Visualizing Balance

### Rating Distribution

```
Team A (Avg: 3.2):
█████████████ A (4.2)
████████      D (3.3)
███████       F (2.8)
██████        G (2.5)

Team B (Avg: 3.125):
█████████     B (3.8)
████████      C (3.5)
███████       E (3.0)
█████         H (2.2)
```

### Difference Metric

```
Excellent:  < 0.1 difference
Good:       < 0.3 difference
Fair:       < 0.5 difference
Poor:       ≥ 0.5 difference
```

## Testing

### Unit Tests

```python
def test_balanced_teams_equal_averages():
    players = [(p1, 3.0), (p2, 3.0), (p3, 3.0), (p4, 3.0)]
    team_a, team_b, avg_a, avg_b = create_balanced_teams(players)

    assert avg_a == 3.0
    assert avg_b == 3.0
    assert len(team_a) == 2
    assert len(team_b) == 2

def test_balanced_teams_mixed_ratings():
    players = [(p1, 5.0), (p2, 4.0), (p3, 2.0), (p4, 1.0)]
    team_a, team_b, avg_a, avg_b = create_balanced_teams(players)

    difference = abs(avg_a - avg_b)
    assert difference < 0.5  # Good balance

def test_odd_number_of_players():
    players = [(p1, 4.0), (p2, 3.0), (p3, 2.0)]
    team_a, team_b, _, _ = create_balanced_teams(players)

    assert len(team_a) + len(team_b) == 3
    assert abs(len(team_a) - len(team_b)) <= 1
```

### Integration Tests

```python
async def test_create_teams_in_database(db):
    # Create match
    # Get player ratings
    # Create teams via TeamService
    # Verify teams in database
    # Verify TeamPlayer assignments
    # Check average ratings stored correctly
```

## Future Enhancements

Potential improvements:

1. **Position-Aware Balancing**: Balance by position (goalkeeper, defender, forward)
2. **Historical Performance**: Consider past team performance together
3. **Player Preferences**: Allow friend pairs to play together
4. **Chemistry Factor**: Track which combinations work well
5. **Machine Learning**: Learn optimal team compositions over time

## Performance Considerations

### Real-Time Computation

For typical group sizes (10-20 players):
- Greedy: < 1ms
- Randomized (100 attempts): < 100ms

Fast enough for real-time API responses.

### Scaling

For large groups (50+ players):
- Consider caching ratings
- Use faster random sampling
- Precompute during off-peak times

## See Also

- [Rating System](rating-system.md) - How player ratings are calculated
- [Match Workflow](../api/repositories.md) - Full match lifecycle
- [Database Schema](../database/schema.md) - Team and TeamPlayer tables
- [System Overview](overview.md) - Architecture context

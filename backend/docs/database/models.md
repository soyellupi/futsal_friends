# SQLAlchemy Models

This document describes the SQLAlchemy ORM models used in the Futsal Friends application.

## Overview

Models are defined using SQLAlchemy 2.0 with modern typed syntax (`Mapped` annotations). All models inherit from a declarative `Base` class and use async sessions.

## Model Location

All models are located in `/backend/app/models/`:

```
app/models/
├── __init__.py
├── player.py            # Player model
├── season.py            # Season and PlayerSeasonRating models
├── match.py             # Match model with status enum
├── attendance.py        # MatchAttendance and ThirdTimeAttendance models
├── team.py              # Team and TeamPlayer models
├── result.py            # MatchResult model
└── rating.py            # PlayerMatchRating model
```

## Core Models

### Player

**File**: `app/models/player.py`

Represents a futsal player.

```python
from app.models import Player

# Create a new player
player = Player(name="John Doe")

# Relationships available:
player.season_ratings        # List[PlayerSeasonRating]
player.match_ratings         # List[PlayerMatchRating]
player.match_attendances     # List[MatchAttendance]
player.third_time_attendances # List[ThirdTimeAttendance]
player.team_assignments      # List[TeamPlayer]
```

**Key Fields:**
- `id`: UUID primary key
- `name`: Player name (indexed for search)
- `is_active`: Active status flag
- `created_at`, `updated_at`: Timestamps

**Usage Examples:**

```python
# Get active players
active_players = await db.execute(
    select(Player).where(Player.is_active == True)
)

# Search by name
results = await db.execute(
    select(Player).where(Player.name.ilike("%john%"))
)
```

---

### Season

**File**: `app/models/season.py`

Represents a futsal season (typically yearly).

```python
from app.models import Season

season = Season(
    name="2025 Season",
    year=2025,
    start_date=date(2025, 1, 1),
    is_active=True
)

# Relationships:
season.matches              # List[Match]
season.player_ratings       # List[PlayerSeasonRating]
season.match_ratings        # List[PlayerMatchRating]
```

**Key Fields:**
- `year`: Indexed for quick lookup
- `is_active`: Only one season should be active at a time
- `start_date`, `end_date`: Season duration

**Business Logic:**
- Only one active season at a time (enforced at application level)
- Starting a new season resets all player ratings to 3.0

---

### PlayerSeasonRating

**File**: `app/models/season.py`

Tracks a player's current rating for a specific season.

```python
from app.models import PlayerSeasonRating

rating = PlayerSeasonRating(
    player_id=player_id,
    season_id=season_id,
    current_rating=3.0,
    matches_completed=0,
    rating_locked=True
)

# Relationships:
rating.player    # Player
rating.season    # Season
```

**Key Fields:**
- `current_rating`: 1.0 - 5.0 (calculated from last 3 matches)
- `rating_locked`: True for first 3 matches, then False
- `matches_completed`: Total matches in season
- `matches_attended`: Matches actually attended

**Constraints:**
- Unique on (player_id, season_id)
- Check: 1.0 ≤ current_rating ≤ 5.0
- Check: matches_attended ≤ matches_completed

---

### Match

**File**: `app/models/match.py`

Represents a futsal match.

```python
from app.models import Match, MatchStatus

match = Match(
    season_id=season_id,
    match_date=datetime.now(),
    status=MatchStatus.SCHEDULED,
    rsvp_deadline=deadline,
    location="Sports Complex A"
)

# Relationships:
match.season                # Season
match.attendances           # List[MatchAttendance]
match.third_time_attendances # List[ThirdTimeAttendance]
match.teams                 # List[Team] (should be 2)
match.result                # MatchResult (optional)
match.player_ratings        # List[PlayerMatchRating]
```

**Status Enum:**
```python
class MatchStatus(str, enum.Enum):
    SCHEDULED = "scheduled"
    CONFIRMED = "confirmed"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
    UNPLAYABLE = "unplayable"
```

**Workflow:**
1. Match created with status=SCHEDULED
2. Players RSVP before rsvp_deadline
3. Status changes to CONFIRMED when ready
4. Match is played, result recorded
5. Status changes to COMPLETED
6. Ratings calculated for all season players

**Alternative Flow (Unplayable):**
1. Match created with status=SCHEDULED
2. Match cannot be played (weather, too few players, etc.)
3. Status changes to UNPLAYABLE
4. No teams, result, or ratings are recorded
5. Third time attendance can still be recorded and counts for leaderboard points

---

### MatchAttendance

**File**: `app/models/attendance.py`

Tracks match attendance.

```python
from app.models import MatchAttendance

attendance = MatchAttendance(
    match_id=match_id,
    player_id=player_id,
    attended=True
)

# Relationships:
attendance.match    # Match
attendance.player   # Player
```

---

### Team

**File**: `app/models/team.py`

One of two teams in a match.

```python
from app.models import Team, TeamName

team = Team(
    match_id=match_id,
    name=TeamName.TEAM_A,
    average_skill_rating=3.2
)

# Relationships:
team.match              # Match
team.players            # List[TeamPlayer]
team.results_as_team_a  # List[MatchResult]
team.results_as_team_b  # List[MatchResult]
team.results_as_winner  # List[MatchResult]
```

**Team Name Enum:**
```python
class TeamName(str, enum.Enum):
    TEAM_A = "team_a"
    TEAM_B = "team_b"
```

**Usage:**
- Each match has exactly 2 teams
- Teams created by balancing algorithm
- `average_skill_rating` used for ELO calculations

---

### TeamPlayer

**File**: `app/models/team.py`

Junction table for team-player assignments.

```python
from app.models import TeamPlayer

assignment = TeamPlayer(
    team_id=team_id,
    player_id=player_id,
    position="Forward"  # Optional
)

# Relationships:
assignment.team     # Team
assignment.player   # Player
```

**Constraints:**
- Unique on (team_id, player_id)
- Player can only be on one team per match

---

### MatchResult

**File**: `app/models/result.py`

Match outcome and scores.

```python
from app.models import MatchResult, ResultType

result = MatchResult(
    match_id=match_id,
    team_a_id=team_a.id,
    team_b_id=team_b.id,
    team_a_score=5,
    team_b_score=3,
    winning_team_id=team_a.id,
    result_type=ResultType.WIN
)

# Relationships:
result.match         # Match
result.team_a        # Team
result.team_b        # Team
result.winning_team  # Team (nullable)
```

**Result Type Enum:**
```python
class ResultType(str, enum.Enum):
    WIN = "win"
    DRAW = "draw"
```

**Business Rules:**
- `winning_team_id` is None when `result_type = DRAW`
- `result_type` determined from scores automatically

---

### ThirdTimeAttendance

**File**: `app/models/attendance.py`

Post-match social gathering attendance.

```python
from app.models import ThirdTimeAttendance

third_time = ThirdTimeAttendance(
    match_id=match_id,
    player_id=player_id,
    attended=True
)

# Relationships:
third_time.match    # Match
third_time.player   # Player
```

**Key Points:**
- Independent from match attendance
- Players can attend third time even if they didn't play
- Provides +0.05 rating bonus (for completed matches)
- Can be recorded for UNPLAYABLE matches (counts for leaderboard points, no rating bonus)

---

### PlayerMatchRating

**File**: `app/models/rating.py`

Complete rating history for each player at each match.

```python
from app.models import PlayerMatchRating, MatchResultOutcome

rating = PlayerMatchRating(
    player_id=player_id,
    match_id=match_id,
    season_id=season_id,
    match_number=4,
    match_date=match.match_date,
    attended_match=True,
    attended_third_time=True,
    match_result=MatchResultOutcome.WIN,
    team_average_rating=3.2,
    opponent_average_rating=3.0,
    rating_before=3.0,
    rating_after=3.25,
    rating_change=0.25,
    elo_k_factor=0.5,
    attendance_bonus=0.1,
    third_time_bonus=0.05,
    non_attendance_penalty=0.0
)

# Relationships:
rating.player   # Player
rating.match    # Match
rating.season   # Season
```

**Match Result Enum:**
```python
class MatchResultOutcome(str, enum.Enum):
    WIN = "win"
    DRAW = "draw"
    LOSS = "loss"
    DID_NOT_ATTEND = "did_not_attend"
```

**Key Points:**
- Created for **ALL season players** after each completed match
- NOT created for UNPLAYABLE matches (no ratings calculated)
- Stores complete calculation details for transparency
- `rating_change = 0` for first 3 matches
- Used to calculate current rating from last 3 matches

---

## Relationships

### One-to-Many Examples

```python
# Get all matches in a season
season = await db.get(Season, season_id)
matches = season.matches

# Get all players on a team
team = await db.get(Team, team_id)
players = team.players  # List[TeamPlayer]
```

### Many-to-One Examples

```python
# Get match's season
match = await db.get(Match, match_id)
season = match.season

# Get team player's details
team_player = await db.get(TeamPlayer, assignment_id)
player = team_player.player
team = team_player.team
```

### Eager Loading

Use `joinedload` for efficient queries:

```python
from sqlalchemy.orm import joinedload

# Load match with all related data
result = await db.execute(
    select(Match)
    .where(Match.id == match_id)
    .options(
        joinedload(Match.attendances),
        joinedload(Match.teams),
        joinedload(Match.result)
    )
)
match = result.scalar_one()
```

## Database Session

### Async Session

All database operations use async sessions:

```python
from app.database import get_db

async def my_function(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Player))
    players = result.scalars().all()
    return players
```

### Creating Records

```python
# Create new player
player = Player(name="John Doe")
db.add(player)
await db.flush()  # Get ID without committing
await db.refresh(player)  # Refresh to get defaults

# Session will auto-commit on successful endpoint completion
```

### Updating Records

```python
player = await db.get(Player, player_id)
player.name = "Jane Doe"
await db.flush()
await db.refresh(player)
```

### Deleting Records

```python
player = await db.get(Player, player_id)
await db.delete(player)
await db.flush()
```

## Best Practices

### 1. Use Repositories

Don't query models directly in endpoints. Use repositories:

```python
# Good
from app.repositories import PlayerRepository

player_repo = PlayerRepository(db)
player = await player_repo.get_by_id(player_id)

# Avoid
player = await db.get(Player, player_id)
```

### 2. Eager Load Relationships

Prevent N+1 queries:

```python
# Good
result = await db.execute(
    select(Match).options(joinedload(Match.teams))
)

# Avoid (causes N+1 queries)
matches = await db.execute(select(Match))
for match in matches:
    teams = match.teams  # Separate query for each match
```

### 3. Use Transactions

Critical operations should be transactional:

```python
async with db.begin():
    # Create match
    match = Match(...)
    db.add(match)
    await db.flush()

    # Create teams
    team_a = Team(match_id=match.id, ...)
    team_b = Team(match_id=match.id, ...)
    db.add_all([team_a, team_b])

    # If any operation fails, everything rolls back
```

### 4. Handle Constraints

```python
from sqlalchemy.exc import IntegrityError

try:
    player = Player(name="Duplicate Name")
    db.add(player)
    await db.flush()
except IntegrityError:
    await db.rollback()
    raise ValueError("Player already exists")
```

## Testing Models

Example test:

```python
import pytest
from app.models import Player

@pytest.mark.asyncio
async def test_create_player(async_session):
    player = Player(name="Test Player")
    async_session.add(player)
    await async_session.commit()

    assert player.id is not None
    assert player.name == "Test Player"
    assert player.is_active is True
```

## See Also

- [Database Schema](schema.md) - Complete schema documentation
- [Repositories](../api/repositories.md) - Data access patterns
- [Database Migrations](migrations.md) - Migration management

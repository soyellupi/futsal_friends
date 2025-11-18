# Repositories Usage Guide

This document explains how to use the repository layer for data access.

## Overview

Repositories provide a clean abstraction over database operations, encapsulating query logic and providing a consistent API for data access.

## Repository Pattern Benefits

✅ **Separation of Concerns**: Business logic separate from data access
✅ **Testability**: Easy to mock repositories in tests
✅ **Consistency**: Standardized data access patterns
✅ **Query Optimization**: Centralized location for query tuning
✅ **Reusability**: Common operations defined once

## Base Repository

All repositories inherit from `BaseRepository` which provides common CRUD operations.

**File**: `app/repositories/base.py`

### Common Methods

```python
from app.repositories.base import BaseRepository

class BaseRepository(Generic[ModelType]):
    async def get_by_id(self, id: UUID) -> Optional[ModelType]
    async def get_all(self, skip: int = 0, limit: int = 100) -> List[ModelType]
    async def create(self, obj: ModelType) -> ModelType
    async def update(self, obj: ModelType) -> ModelType
    async def delete(self, obj: ModelType) -> None
    async def delete_by_id(self, id: UUID) -> bool
```

### Usage Example

```python
from app.repositories import PlayerRepository

# Create repository instance
player_repo = PlayerRepository(db)

# Get by ID
player = await player_repo.get_by_id(player_id)

# Get all (with pagination)
players = await player_repo.get_all(skip=0, limit=10)

# Create
new_player = Player(name="John Doe")
created_player = await player_repo.create(new_player)

# Update
player.name = "Jane Doe"
updated_player = await player_repo.update(player)

# Delete
await player_repo.delete(player)
# or
success = await player_repo.delete_by_id(player_id)
```

## Available Repositories

### 1. PlayerRepository

**File**: `app/repositories/player.py`

**Custom Methods:**

```python
class PlayerRepository(BaseRepository[Player]):
    async def get_by_name(self, name: str) -> Optional[Player]
    async def get_active_players(
        self, skip: int = 0, limit: int = 100
    ) -> List[Player]
    async def get_players_with_season_rating(
        self, season_id: UUID, skip: int = 0, limit: int = 100
    ) -> List[tuple[Player, Optional[PlayerSeasonRating]]]
    async def search_by_name(
        self, name_query: str, skip: int = 0, limit: int = 100
    ) -> List[Player]
```

**Example Usage:**

```python
player_repo = PlayerRepository(db)

# Get active players
active_players = await player_repo.get_active_players()

# Search by name
results = await player_repo.search_by_name("john")

# Get players with ratings
players_with_ratings = await player_repo.get_players_with_season_rating(
    season_id
)
for player, rating in players_with_ratings:
    print(f"{player.name}: {rating.current_rating if rating else 'N/A'}")
```

---

### 2. SeasonRepository

**File**: `app/repositories/season.py`

**Custom Methods:**

```python
class SeasonRepository(BaseRepository[Season]):
    async def get_active_season(self) -> Optional[Season]
    async def get_by_year(self, year: int) -> List[Season]
    async def get_player_season_rating(
        self, player_id: UUID, season_id: UUID
    ) -> Optional[PlayerSeasonRating]
    async def get_season_ratings(
        self, season_id: UUID, skip: int = 0, limit: int = 100
    ) -> List[PlayerSeasonRating]
    async def create_player_season_rating(
        self, player_season_rating: PlayerSeasonRating
    ) -> PlayerSeasonRating
    async def update_player_season_rating(
        self, player_season_rating: PlayerSeasonRating
    ) -> PlayerSeasonRating
```

**Example Usage:**

```python
season_repo = SeasonRepository(db)

# Get active season
current_season = await season_repo.get_active_season()

# Get player's rating for season
rating = await season_repo.get_player_season_rating(player_id, season_id)

# Get all season ratings (for leaderboard)
all_ratings = await season_repo.get_season_ratings(season_id)
```

---

### 3. MatchRepository

**File**: `app/repositories/match.py`

**Custom Methods:**

```python
class MatchRepository(BaseRepository[Match]):
    async def get_by_season(
        self, season_id: UUID, skip: int = 0, limit: int = 100
    ) -> List[Match]
    async def get_upcoming_matches(
        self, season_id: UUID, skip: int = 0, limit: int = 100
    ) -> List[Match]
    async def get_completed_matches(
        self, season_id: UUID, skip: int = 0, limit: int = 100
    ) -> List[Match]
    async def get_match_with_details(self, match_id: UUID) -> Optional[Match]
    async def get_match_attendance(
        self, match_id: UUID, player_id: UUID
    ) -> Optional[MatchAttendance]
    async def get_match_attendances(self, match_id: UUID) -> List[MatchAttendance]
    async def get_confirmed_attendees(self, match_id: UUID) -> List[MatchAttendance]
    async def get_actual_attendees(self, match_id: UUID) -> List[MatchAttendance]
    async def create_attendance(
        self, attendance: MatchAttendance
    ) -> MatchAttendance
    async def update_attendance(
        self, attendance: MatchAttendance
    ) -> MatchAttendance
    async def get_third_time_attendance(
        self, match_id: UUID, player_id: UUID
    ) -> Optional[ThirdTimeAttendance]
    async def get_third_time_attendances(
        self, match_id: UUID
    ) -> List[ThirdTimeAttendance]
    async def create_third_time_attendance(
        self, attendance: ThirdTimeAttendance
    ) -> ThirdTimeAttendance
```

**Example Usage:**

```python
match_repo = MatchRepository(db)

# Get upcoming matches
upcoming = await match_repo.get_upcoming_matches(season_id)

# Get match with all relations loaded
match = await match_repo.get_match_with_details(match_id)
# match.attendances, match.teams, match.result all loaded

# Record attendance for match
attendance = MatchAttendance(
    match_id=match_id,
    player_id=player_id,
    attended=True
)
await match_repo.create_attendance(attendance)

# Get attendees
confirmed = await match_repo.get_confirmed_attendees(match_id)
```

---

### 4. TeamRepository

**File**: `app/repositories/team.py`

**Custom Methods:**

```python
class TeamRepository(BaseRepository[Team]):
    async def get_match_teams(self, match_id: UUID) -> List[Team]
    async def get_team_with_players(self, team_id: UUID) -> Optional[Team]
    async def get_team_players(self, team_id: UUID) -> List[TeamPlayer]
    async def add_player_to_team(self, team_player: TeamPlayer) -> TeamPlayer
    async def remove_player_from_team(
        self, team_id: UUID, player_id: UUID
    ) -> bool
    async def get_player_team_for_match(
        self, match_id: UUID, player_id: UUID
    ) -> Optional[Team]
```

**Example Usage:**

```python
team_repo = TeamRepository(db)

# Get both teams for a match
teams = await team_repo.get_match_teams(match_id)
team_a, team_b = teams[0], teams[1]

# Get team with players
team = await team_repo.get_team_with_players(team_id)
for team_player in team.players:
    print(team_player.player.name)

# Add player to team
assignment = TeamPlayer(team_id=team_id, player_id=player_id)
await team_repo.add_player_to_team(assignment)
```

---

### 5. ResultRepository

**File**: `app/repositories/result.py`

**Custom Methods:**

```python
class ResultRepository(BaseRepository[MatchResult]):
    async def get_by_match_id(self, match_id: UUID) -> Optional[MatchResult]
    async def get_result_with_teams(
        self, match_id: UUID
    ) -> Optional[MatchResult]
    async def get_season_results(
        self, season_id: UUID, skip: int = 0, limit: int = 100
    ) -> List[MatchResult]
    async def get_team_results(self, team_id: UUID) -> List[MatchResult]
```

**Example Usage:**

```python
result_repo = ResultRepository(db)

# Get match result
result = await result_repo.get_by_match_id(match_id)

# Get result with teams loaded
result = await result_repo.get_result_with_teams(match_id)
print(f"{result.team_a.name}: {result.team_a_score}")
print(f"{result.team_b.name}: {result.team_b_score}")

# Get all season results
all_results = await result_repo.get_season_results(season_id)
```

---

### 6. RatingRepository

**File**: `app/repositories/rating.py`

**Custom Methods:**

```python
class RatingRepository(BaseRepository[PlayerMatchRating]):
    async def get_player_match_rating(
        self, player_id: UUID, match_id: UUID
    ) -> Optional[PlayerMatchRating]
    async def get_player_season_ratings(
        self, player_id: UUID, season_id: UUID, skip: int = 0, limit: int = 100
    ) -> List[PlayerMatchRating]
    async def get_last_n_ratings(
        self, player_id: UUID, season_id: UUID, n: int = 3
    ) -> List[PlayerMatchRating]
    async def get_match_ratings(self, match_id: UUID) -> List[PlayerMatchRating]
    async def get_season_match_count(
        self, player_id: UUID, season_id: UUID
    ) -> int
    async def create_rating(
        self, rating: PlayerMatchRating
    ) -> PlayerMatchRating
    async def bulk_create_ratings(
        self, ratings: List[PlayerMatchRating]
    ) -> List[PlayerMatchRating]
```

**Example Usage:**

```python
rating_repo = RatingRepository(db)

# Get last 3 ratings for player
last_3 = await rating_repo.get_last_n_ratings(player_id, season_id, 3)

# Get all ratings for a match
match_ratings = await rating_repo.get_match_ratings(match_id)

# Bulk create ratings (efficient)
ratings = [PlayerMatchRating(...), PlayerMatchRating(...)]
created_ratings = await rating_repo.bulk_create_ratings(ratings)
```

---

## Using Repositories in Services

Services orchestrate multiple repositories:

```python
class RatingService:
    def __init__(
        self,
        db: AsyncSession,
        rating_repo: RatingRepository,
        season_repo: SeasonRepository,
        team_repo: TeamRepository,
    ):
        self.db = db
        self.rating_repo = rating_repo
        self.season_repo = season_repo
        self.team_repo = team_repo

    async def calculate_match_ratings(self, match, teams, players):
        # Use multiple repositories
        for player in players:
            season_rating = await self.season_repo.get_player_season_rating(
                player.id, match.season_id
            )

            last_ratings = await self.rating_repo.get_last_n_ratings(
                player.id, match.season_id, 3
            )

            # Business logic...

        # Bulk create all ratings
        await self.rating_repo.bulk_create_ratings(new_ratings)
```

## Using Repositories in API Endpoints

Inject repositories via dependency injection:

```python
from fastapi import Depends
from app.database import get_db

@router.get("/players/{player_id}")
async def get_player(
    player_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    player_repo = PlayerRepository(db)
    player = await player_repo.get_by_id(player_id)

    if not player:
        raise HTTPException(status_code=404, detail="Player not found")

    return player
```

## Best Practices

### 1. Always Use Repositories

```python
# Good ✅
player_repo = PlayerRepository(db)
player = await player_repo.get_by_id(player_id)

# Avoid ❌
player = await db.get(Player, player_id)
```

### 2. Leverage Custom Methods

```python
# Good ✅
active_players = await player_repo.get_active_players()

# Avoid ❌
result = await db.execute(select(Player).where(Player.is_active == True))
players = result.scalars().all()
```

### 3. Use Pagination

```python
# Good ✅
players = await player_repo.get_all(skip=0, limit=20)

# Avoid (could return thousands of records) ❌
all_players = await player_repo.get_all(limit=999999)
```

### 4. Eager Load Relationships

```python
# Use repository methods that eager load
match = await match_repo.get_match_with_details(match_id)
# match.teams already loaded, no additional queries

# Instead of causing N+1 queries
match = await match_repo.get_by_id(match_id)
for team in match.teams:  # Separate query for each team!
    print(team.name)
```

### 5. Batch Operations

```python
# Good ✅
await rating_repo.bulk_create_ratings(ratings)

# Less efficient ❌
for rating in ratings:
    await rating_repo.create(rating)
```

## Testing Repositories

### Unit Tests with Mock Database

```python
import pytest
from app.repositories import PlayerRepository
from app.models import Player

@pytest.mark.asyncio
async def test_get_active_players(async_session):
    # Setup
    player1 = Player(name="Active Player", is_active=True)
    player2 = Player(name="Inactive Player", is_active=False)
    async_session.add_all([player1, player2])
    await async_session.commit()

    # Test
    repo = PlayerRepository(async_session)
    active_players = await repo.get_active_players()

    # Assert
    assert len(active_players) == 1
    assert active_players[0].name == "Active Player"
```

### Mocking Repositories in Service Tests

```python
from unittest.mock import AsyncMock

async def test_rating_service():
    # Mock repositories
    mock_rating_repo = AsyncMock(spec=RatingRepository)
    mock_season_repo = AsyncMock(spec=SeasonRepository)

    # Setup mock returns
    mock_season_repo.get_player_season_rating.return_value = PlayerSeasonRating(...)

    # Test service
    service = RatingService(db, mock_rating_repo, mock_season_repo)
    result = await service.calculate_match_ratings(...)

    # Verify
    mock_rating_repo.bulk_create_ratings.assert_called_once()
```

## Performance Tips

### 1. Use Indexes

Repositories benefit from database indexes:

```python
# Fast (uses index on player_id, season_id)
await rating_repo.get_last_n_ratings(player_id, season_id, 3)
```

### 2. Limit Result Sets

```python
# Good - limited results
players = await player_repo.get_all(skip=0, limit=20)

# Bad - could be huge
all_players = await player_repo.get_all(limit=10000)
```

### 3. Batch Queries

```python
# Efficient - single query
players_with_ratings = await player_repo.get_players_with_season_rating(
    season_id
)

# Less efficient - N+1 queries
players = await player_repo.get_active_players()
for player in players:
    rating = await season_repo.get_player_season_rating(player.id, season_id)
```

## See Also

- [Database Schema](../database/schema.md) - Table structures
- [SQLAlchemy Models](../database/models.md) - Model definitions
- [System Overview](../architecture/overview.md) - Architecture context
- [Development Setup](../development/setup.md) - Local development guide

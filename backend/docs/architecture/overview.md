# System Architecture Overview

This document provides a high-level overview of the Futsal Friends backend architecture.

## Architecture Pattern

The application follows a **layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────┐
│          API Layer (FastAPI)                │
│  - REST endpoints                           │
│  - Request validation (Pydantic)            │
│  - Response serialization                   │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│         Service Layer (Business Logic)      │
│  - RatingService                            │
│  - TeamService                              │
│  - LeaderboardService                       │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│      Repository Layer (Data Access)         │
│  - PlayerRepository                         │
│  - SeasonRepository                         │
│  - MatchRepository                          │
│  - TeamRepository                           │
│  - ResultRepository                         │
│  - RatingRepository                         │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│      Model Layer (SQLAlchemy ORM)           │
│  - Player, Season, Match                    │
│  - Team, MatchResult                        │
│  - PlayerMatchRating, etc.                  │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│         Database (PostgreSQL)               │
└─────────────────────────────────────────────┘
```

## Layer Responsibilities

### 1. API Layer

**Location**: `app/api/v1/endpoints/`

**Responsibilities:**
- Define REST endpoints
- Validate incoming requests (Pydantic schemas)
- Handle HTTP concerns (status codes, headers)
- Serialize responses
- Error handling and formatting

**Example:**
```python
@router.post("/players", response_model=PlayerResponse)
async def create_player(
    player: PlayerCreate,
    db: AsyncSession = Depends(get_db)
):
    repo = PlayerRepository(db)
    # Use repository and services
    return response
```

### 2. Service Layer

**Location**: `app/services/`

**Responsibilities:**
- Implement business logic
- Coordinate between multiple repositories
- Enforce business rules
- Complex calculations (ratings, team balancing)
- Transaction management for multi-step operations

**Services:**
- **RatingService**: Rating calculations and updates
- **TeamService**: Team creation and balancing
- **LeaderboardService**: Statistics and leaderboard

**Example:**
```python
class RatingService:
    async def calculate_match_ratings(
        self, match, team_a, team_b, season_players
    ):
        # Complex business logic
        # Multiple repository interactions
        # Rating calculations
        return ratings
```

### 3. Repository Layer

**Location**: `app/repositories/`

**Responsibilities:**
- Database queries and operations
- CRUD operations
- Complex queries (joins, aggregations)
- Data access patterns
- Query optimization

**Repositories:**
- PlayerRepository
- SeasonRepository
- MatchRepository
- TeamRepository
- ResultRepository
- RatingRepository

**Example:**
```python
class PlayerRepository(BaseRepository[Player]):
    async def get_active_players(self):
        result = await self.db.execute(
            select(Player).where(Player.is_active == True)
        )
        return result.scalars().all()
```

### 4. Model Layer

**Location**: `app/models/`

**Responsibilities:**
- Define database schema
- Map Python objects to database tables
- Define relationships between entities
- Provide type hints and constraints

**Example:**
```python
class Player(Base):
    __tablename__ = "players"

    id: Mapped[uuid.UUID] = mapped_column(UUID, primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    # ... relationships
```

## Data Flow

### Example: Creating a Match Result

```
1. User Request
   POST /api/v1/matches/{id}/result
   Body: { "team_a_score": 5, "team_b_score": 3 }
   ↓

2. API Endpoint (api/endpoints/matches.py)
   - Validates request schema
   - Extracts match_id from path
   ↓

3. Service Layer (RatingService)
   - Creates MatchResult
   - Fetches match, teams, season players
   - Calculates ratings for ALL season players
   - Updates PlayerSeasonRating for each player
   ↓

4. Repository Layer
   - ResultRepository: Creates result
   - TeamRepository: Fetches teams
   - PlayerRepository: Fetches season players
   - RatingRepository: Creates PlayerMatchRating records
   - SeasonRepository: Updates PlayerSeasonRating records
   ↓

5. Model Layer
   - MatchResult model saved
   - PlayerMatchRating records saved
   - PlayerSeasonRating records updated
   ↓

6. Database
   - All changes committed in transaction
   ↓

7. Response
   - MatchResultResponse returned
   - HTTP 200 OK
```

## Key Design Patterns

### 1. Repository Pattern

Encapsulates data access logic:

```python
# Good: Using repository
player_repo = PlayerRepository(db)
player = await player_repo.get_by_id(player_id)

# Avoid: Direct database access in service/endpoint
player = await db.get(Player, player_id)
```

**Benefits:**
- Centralized query logic
- Easier testing (mock repositories)
- Consistent data access patterns
- Query optimization in one place

### 2. Dependency Injection

FastAPI's dependency injection for database sessions:

```python
from app.database import get_db

@router.get("/players")
async def get_players(db: AsyncSession = Depends(get_db)):
    # db is automatically injected
    # Automatically committed on success
    # Automatically rolled back on error
```

### 3. Service Orchestration

Services coordinate complex operations:

```python
class RatingService:
    def __init__(self, db, rating_repo, season_repo, team_repo):
        # Multiple repositories injected
        self.rating_repo = rating_repo
        self.season_repo = season_repo
        self.team_repo = team_repo

    async def calculate_match_ratings(self, ...):
        # Orchestrates multiple repository calls
        # Implements complex business logic
        # Returns calculated results
```

### 4. Schema Validation

Pydantic schemas for type safety:

```python
# Input validation
class PlayerCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)

# Output serialization
class PlayerResponse(BaseModel):
    id: UUID
    name: str
    created_at: datetime

    model_config = {"from_attributes": True}
```

## Async/Await Pattern

All I/O operations are async for better performance:

```python
# Database operations
result = await db.execute(query)

# Repository methods
player = await player_repo.get_by_id(player_id)

# Service methods
ratings = await rating_service.calculate_match_ratings(...)
```

**Benefits:**
- Non-blocking I/O
- Better concurrency
- Efficient resource usage
- Scales better under load

## Transaction Management

### Automatic Transaction

FastAPI dependency handles transactions:

```python
async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()  # Auto-commit on success
        except Exception:
            await session.rollback()  # Auto-rollback on error
            raise
```

### Manual Transaction

For complex operations:

```python
async with db.begin():
    # Create match
    match = await match_repo.create(match)

    # Create teams
    team_a = await team_repo.create(team_a)
    team_b = await team_repo.create(team_b)

    # If anything fails, all operations rollback
```

## Error Handling

### Repository Level

```python
async def get_by_id(self, id: UUID):
    result = await self.db.execute(...)
    player = result.scalar_one_or_none()

    if not player:
        return None  # Let caller handle missing data
    return player
```

### Service Level

```python
async def create_balanced_teams(self, ...):
    if len(player_ids) < 2:
        raise ValueError("Need at least 2 players")

    # Business logic validation
    # Raise domain-specific exceptions
```

### API Level

```python
@router.get("/players/{player_id}")
async def get_player(player_id: UUID, ...):
    player = await player_repo.get_by_id(player_id)

    if not player:
        raise HTTPException(
            status_code=404,
            detail="Player not found"
        )

    return player
```

## Configuration

### Environment Variables

```python
# app/config.py
class Settings(BaseSettings):
    DATABASE_URL: str
    ASYNC_DATABASE_URL: str
    DEBUG: bool = False

    model_config = SettingsConfigDict(env_file=".env")

settings = Settings()
```

### Constants

```python
# app/constants.py
class RatingConfig:
    INITIAL_RATING = 3.0
    MIN_RATING = 1.0
    MAX_RATING = 5.0
    ELO_K_FACTOR = 0.5
    # ...
```

## Testing Strategy

### Unit Tests

Test individual components in isolation:

```python
# Test service logic
def test_calculate_rating_change():
    service = RatingService(mock_db, ...)
    change = await service._calculate_rating_change(...)
    assert change == expected_value
```

### Integration Tests

Test layer interactions:

```python
# Test repository with real database
async def test_player_repository(test_db):
    repo = PlayerRepository(test_db)
    player = await repo.create(Player(name="Test"))
    assert player.id is not None
```

### API Tests

Test endpoints end-to-end:

```python
async def test_create_player_endpoint(client):
    response = await client.post(
        "/api/v1/players",
        json={"name": "Test Player"}
    )
    assert response.status_code == 200
```

## Performance Considerations

### 1. Query Optimization

```python
# Use indexes
select(Player).where(Player.name == "John")  # name is indexed

# Eager load relationships
select(Match).options(joinedload(Match.teams))
```

### 2. Batch Operations

```python
# Bulk insert for ratings
await rating_repo.bulk_create_ratings(ratings)
```

### 3. Connection Pooling

SQLAlchemy handles connection pooling automatically:

```python
async_engine = create_async_engine(
    url,
    pool_pre_ping=True,  # Verify connections
    echo=settings.DEBUG   # Log queries in debug
)
```

## Security Considerations

### 1. SQL Injection Prevention

SQLAlchemy ORM prevents SQL injection:

```python
# Safe (parameterized)
select(Player).where(Player.name == user_input)

# Avoid raw SQL with user input
```

### 2. Input Validation

Pydantic validates all inputs:

```python
class PlayerCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    # XSS prevention, length limits, etc.
```

### 3. UUID Primary Keys

UUIDs prevent ID enumeration attacks:

```python
id: Mapped[uuid.UUID] = mapped_column(UUID, primary_key=True)
```

## Scalability

### Horizontal Scaling

- Stateless API servers
- Database connection pooling
- Async operations for concurrency

### Vertical Scaling

- Efficient queries with indexes
- Batch operations
- Caching (future enhancement)

### Database Scaling

- PostgreSQL read replicas (future)
- Connection pooling
- Query optimization

## See Also

- [Rating System](rating-system.md) - ELO algorithm details
- [Team Balancing](team-balancing.md) - Team creation algorithm
- [Leaderboard](leaderboard.md) - Statistics calculation
- [Database Schema](../database/schema.md) - Data model
- [Repositories](../api/repositories.md) - Data access patterns

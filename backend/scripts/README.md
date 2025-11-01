# Management Scripts

This directory contains management scripts for database operations and data entry.

## Available Scripts

### 1. `seed_season.py` - Create New Season

Creates a new season and adds initial players.

**Usage:**
```bash
cd backend
python scripts/seed_season.py
```

**Interactive prompts:**
- Year (e.g., 2025)
- Season name (default: "YYYY Season")
- Start date (default: today)
- Player names (one at a time, press Enter to finish)

**Example:**
```bash
$ python scripts/seed_season.py

============================================================
  Create New Season
============================================================

Enter season details:
  Year (e.g., 2025): 2025
  Season name (default: '2025 Season'):
  Start date (YYYY-MM-DD, default: today):

Enter player names (press Enter with empty name to finish):
  Player 1: Alice
  Player 2: Bob
  Player 3: Charlie
  Player 4: Diana
  Player 5:

✓ Created season: 2025 Season (ID: ...)
✓ Initialized ratings for all players at 3.0
```

**What it does:**
- Creates a new season
- Adds players (creates new or reuses existing)
- Initializes PlayerSeasonRating for each player at 3.0
- Sets rating_locked = True (locked for first 3 matches)

---

### 2. `record_match.py` - Record Complete Match

Records a complete match with all details including attendance, teams, result, third time, and rating updates.

**Usage:**
```bash
cd backend
python scripts/record_match.py
```

**Interactive prompts:**
1. **Select attendees**: Choose which players attended
2. **Match details**: Date and location
3. **Teams**: Manually select players for each team
4. **Match result**: Scores for each team
5. **Third time**: Who attended post-match social
6. **Ratings**: Automatically calculated and updated

**Example:**
```bash
$ python scripts/record_match.py

============================================================
  Record Match
============================================================

Active season: 2025 Season (2025)
Season has 10 players

Select players who attended the match:
(Enter player numbers separated by spaces, e.g., '1 2 3 5')
  1. Alice (Rating: 3.00)
  2. Bob (Rating: 3.00)
  3. Charlie (Rating: 3.00)
  4. Diana (Rating: 3.00)
  5. Eve (Rating: 3.00)
  6. Frank (Rating: 3.00)
  7. Grace (Rating: 3.00)
  8. Henry (Rating: 3.00)

Attendees: 1 2 3 4 5 6 7 8

Match date (YYYY-MM-DD, default: today):
Location (optional): Sports Complex A

✓ Created match (ID: ...)
✓ Recorded attendance for 10 players
  Attended: 8
  Absent: 2

Select players for Team Black:
(Enter player numbers separated by spaces, e.g., '1 2 3 4')
  1. Alice (Rating: 3.00)
  2. Bob (Rating: 3.00)
  3. Charlie (Rating: 3.00)
  4. Diana (Rating: 3.00)
  5. Eve (Rating: 3.00)
  6. Frank (Rating: 3.00)
  7. Grace (Rating: 3.00)
  8. Henry (Rating: 3.00)

Team Black: 1 3 5 7

✓ Team Black (avg: 3.00):
    - Alice (3.00)
    - Charlie (3.00)
    - Eve (3.00)
    - Grace (3.00)

✓ Team Pink (avg: 3.00):
    - Bob (3.00)
    - Diana (3.00)
    - Frank (3.00)
    - Henry (3.00)

Enter match result:
  Team Black score: 5
  Team Pink score: 3

✓ Team Black won: 5-3

Who attended third time (post-match social)?
(Enter player numbers separated by spaces, or press Enter to skip)
  1. Alice
  2. Bob
  3. Charlie
  4. Diana
  5. Eve
  6. Frank
  7. Grace
  8. Henry

Third time attendees: 1 2 3 5 6 7

✓ Recorded third time attendance for 6 players

Calculating ratings for 10 players...
✓ Updated ratings for all players

Rating changes:
  Alice: 3.00 → 3.00 (+0.00)   [Match 1 - rating locked]
  Bob: 3.00 → 3.00 (+0.00)     [Match 1 - rating locked]
  ...

============================================================
  Current Leaderboard
============================================================

Rank   Player              Points   Rating   W/D/L      Attendance
----------------------------------------------------------------------
1      Alice               4        3.00     1/0/0      1/1
2      Eve                 4        3.00     1/0/0      1/1
3      Grace               4        3.00     1/0/0      1/1
...
```

**What it does:**
1. Creates a match record
2. Records attendance for ALL season players (attendees and non-attendees)
3. Allows manual selection of players for each team
4. Records match result
5. Records third time attendance (optional)
6. Calculates ratings for ALL season players using RatingService
7. Updates PlayerSeasonRating for everyone
8. Creates PlayerMatchRating records with full calculation details
9. Displays updated leaderboard

---

## Rating System Behavior

### First 3 Matches
- All players start at rating 3.0
- rating_locked = True
- Match results are recorded but rating stays at 3.0
- Data is still tracked in PlayerMatchRating

### Match 4 Onwards
- rating_locked = False
- Ratings calculated from last 3 matches only
- Includes attendance bonuses and penalties

**Example progression:**
```
Match 1: Rating = 3.0 (locked)
Match 2: Rating = 3.0 (locked)
Match 3: Rating = 3.0 (locked)
Match 4: Rating calculated from matches 1, 2, 3 → 3.25
Match 5: Rating calculated from matches 2, 3, 4 → 3.40
Match 6: Rating calculated from matches 3, 4, 5 → 3.35
```

### Non-Attendance Penalty
- Players who don't attend get -0.2 per match
- This is applied even during locked period (but rating stays 3.0)
- After match 4, penalties from last 3 matches affect rating

## Team Selection

Teams are created manually during match recording:
1. User selects players for Team Black from the attendees list
2. Remaining players are automatically assigned to Team Pink
3. Average ratings are calculated for both teams
4. Teams are stored in database

**Result:**
- Teams reflect actual match composition
- Average ratings displayed for reference
- Flexible team creation based on real-world needs

## Leaderboard Points

Points are calculated as:
```
Total Points = (Match Attendance × 1) +
               (Wins × 3) +
               (Draws × 1) +
               (Losses × 0) +
               (Third Time × 1)
```

**Sorted by:**
1. Total points (descending)
2. Current rating (tie-breaker)

## Prerequisites

Before running scripts:

1. **Database must be running:**
   ```bash
   docker-compose up -d
   ```

2. **Migrations must be applied:**
   ```bash
   alembic upgrade head
   ```

3. **Virtual environment must be activated:**
   ```bash
   source venv/bin/activate
   ```

## Workflow

### Initial Setup
```bash
# 1. Start database
docker-compose up -d

# 2. Apply migrations
alembic upgrade head

# 3. Create season and add players
python scripts/seed_season.py
```

### Recording Matches
```bash
# Record each match as it happens
python scripts/record_match.py
```

### Tips
- Run `record_match.py` after each real match
- Script saves ALL data: attendance, teams, result, third time, ratings
- Leaderboard updates automatically
- First 3 matches have locked ratings (3.0)
- After match 3, ratings start changing based on performance

## Troubleshooting

### "No active season found"
Run `seed_season.py` first to create a season.

### "Active season already exists"
Only one season can be active at a time. Either:
- Use the existing season
- Manually deactivate it in database
- Create season for a different year

### Database connection error
```bash
# Check database is running
docker ps

# Start database if not running
docker-compose up -d
```

### Import errors
```bash
# Make sure you're in backend directory
cd backend

# Ensure virtual environment is activated
source venv/bin/activate

# Check dependencies are installed
pip install -r requirements.txt
```

## Database Structure

Scripts use the full repository and service layer:

```
Scripts
  ↓
Repositories (data access)
  ↓
Models (SQLAlchemy)
  ↓
Database (PostgreSQL)
```

This ensures:
- ✅ Consistent data access patterns
- ✅ Business logic applied correctly
- ✅ All validations enforced
- ✅ Proper transaction handling

## See Also

- [Rating System](../docs/architecture/rating-system.md) - How ratings are calculated
- [Leaderboard](../docs/architecture/leaderboard.md) - Points calculation
- [Database Schema](../docs/database/schema.md) - Complete data model

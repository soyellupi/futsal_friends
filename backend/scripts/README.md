# Management Scripts

This directory contains management scripts for database operations and data entry.

## Available Scripts

| Script | Purpose |
|--------|---------|
| `seed_season.py` | Create a new season with initial players |
| `add_player_to_season.py` | Add a player to an existing season |
| `record_match.py` | Create a match (playable or unplayable) with teams |
| `record_match_result_and_update_leaderboard.py` | Record result, third time, and update ratings |
| `record_third_time_attendance.py` | Record third time attendance separately |
| `recalculate_match_ratings.py` | Recalculate ratings for a specific match |

---

## Workflow

### Normal Match Flow

```bash
# 1. Create the match and teams
python scripts/record_match.py
# Choose option 1 (match was played)
# Select players, create teams

# 2. After the match: record result and update leaderboard
python scripts/record_match_result_and_update_leaderboard.py
# Enter scores, third time attendance
# Ratings are calculated automatically
```

### Unplayable Match Flow

```bash
# 1. Record the unplayable match
python scripts/record_match.py
# Choose option 2 (match was NOT played)
# Enter date, location (optional), reason (optional)

# 2. (Optional) Record third time attendance
python scripts/record_third_time_attendance.py
```

---

## Script Details

### 1. `seed_season.py` - Create New Season

Creates a new season and adds initial players.

**Usage:**
```bash
python scripts/seed_season.py
```

**What it does:**
- Creates a new season
- Adds players (creates new or reuses existing)
- Initializes PlayerSeasonRating for each player at 3.0

---

### 2. `add_player_to_season.py` - Add Player to Season

Adds a new or existing player to the active season.

**Usage:**
```bash
python scripts/add_player_to_season.py
```

**Player Types:**
- **Regular**: Subject to attendance penalties (-0.2 for missing matches)
- **Invited**: No attendance penalties, no third time bonus

---

### 3. `record_match.py` - Create Match

Creates a match with teams. Supports both playable and unplayable matches.

**Usage:**
```bash
python scripts/record_match.py
```

**Flow:**
1. Ask if match was played (yes/no)
2. Enter match date
3. **If played**: Select players, goalkeepers, create teams
4. **If not played**: Enter location and reason (optional), done

---

### 4. `record_match_result_and_update_leaderboard.py` - Record Result

Records match result, third time attendance, and calculates ratings.

**Usage:**
```bash
python scripts/record_match_result_and_update_leaderboard.py
```

**Steps:**
1. Enter match week number
2. Enter scores (BLACK and PINK teams)
3. Enter third time attendees (comma-separated names)
4. Ratings calculated automatically
5. Leaderboard updated

**Notes:**
- Cannot be used for UNPLAYABLE matches
- Updates match status to COMPLETED
- Creates PlayerMatchRating for all season players

---

### 5. `record_third_time_attendance.py` - Record Third Time

Records third time attendance separately. Works for both playable and unplayable matches.

**Usage:**
```bash
python scripts/record_third_time_attendance.py
```

---

### 6. `recalculate_match_ratings.py` - Recalculate Ratings

Recalculates ratings for a specific match. Useful after corrections.

**Usage:**
```bash
python scripts/recalculate_match_ratings.py <match_week>
```

**Notes:**
- For normal matches: deletes existing ratings and recalculates
- For unplayable matches: resets season ratings (no player ratings created)

---

## Match Status Flow

```
                    ┌─────────────────────────────────────┐
                    │           record_match.py           │
                    └─────────────────────────────────────┘
                                     │
                    ┌────────────────┴────────────────┐
                    ▼                                 ▼
            Match Played?                     Match NOT Played?
                    │                                 │
                    ▼                                 ▼
            SCHEDULED                           UNPLAYABLE
            (with teams)                        (no teams)
                    │                                 │
                    ▼                                 ▼
    record_match_result_and_             record_third_time_
    update_leaderboard.py                attendance.py (optional)
                    │
                    ▼
              COMPLETED
         (ratings calculated)
```

---

## Unplayable Match Rules

| Aspect | Normal Match | Unplayable Match |
|--------|--------------|------------------|
| Teams created | Yes | No |
| Result recorded | Yes | No |
| Ratings calculated | Yes | No |
| Non-attendance penalty | -0.2 | None |
| Third time attendance | Yes | Yes |
| Third time points | +1 leaderboard | +1 leaderboard |

---

## Rating System

### First 3 Matches
- All players start at rating 3.0
- Rating is locked (stays at 3.0)
- Match results are tracked but don't affect rating

### Match 4 Onwards
- Rating calculated from last 3 matches
- Includes attendance bonuses and penalties

### Non-Attendance Penalty
- Regular players: -0.2 per missed match
- Invited players: no penalty
- Unplayable matches: no penalty for anyone

---

## Leaderboard Points

```
Total Points = (Match Attendance × 1) +
               (Wins × 3) +
               (Draws × 1) +
               (Third Time × 1)
```

Third time counts from both completed and unplayable matches.

---

## Prerequisites

```bash
# 1. Database running
docker-compose up -d

# 2. Migrations applied
alembic upgrade head

# 3. Virtual environment activated
source venv/bin/activate
```

---

## Troubleshooting

### "No active season found"
Run `seed_season.py` first.

### "Match is marked as UNPLAYABLE"
Use `record_third_time_attendance.py` for unplayable matches.

### Database connection error
```bash
docker-compose up -d
```

---

## See Also

- [Rating System](../docs/architecture/rating-system.md)
- [Leaderboard](../docs/architecture/leaderboard.md)
- [Database Schema](../docs/database/schema.md)

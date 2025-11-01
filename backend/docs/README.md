# Futsal Friends Backend Documentation

Welcome to the Futsal Friends backend documentation. This FastAPI-based application manages a futsal group with dynamic player ratings, team balancing, and comprehensive statistics tracking.

## 📚 Documentation Index

### Database
- [Database Schema](database/schema.md) - Complete database structure with ER diagrams
- [SQLAlchemy Models](database/models.md) - Model definitions and relationships
- [Database Migrations](database/migrations.md) - Migration management guide

### Architecture
- [System Overview](architecture/overview.md) - High-level architecture and design
- [Rating System](architecture/rating-system.md) - ELO-based rating algorithm (rolling 3-match window)
- [Team Balancing](architecture/team-balancing.md) - Automatic team creation algorithm
- [Leaderboard System](architecture/leaderboard.md) - Points calculation and statistics

### API & Data Access
- [Repositories](api/repositories.md) - Data access layer usage guide

### Development
- [Setup Guide](development/setup.md) - Local development setup
- [Contributing](development/contributing.md) - Contribution guidelines

## 🎯 Quick Start

### Key Features

1. **Dynamic Rating System (1-5 scale)**
   - Rolling 3-match window for current performance
   - ELO-based calculations with team balancing
   - Attendance and social participation bonuses
   - Non-attendance penalties

2. **RSVP & Attendance Tracking**
   - Pre-match RSVP system
   - Actual attendance recording
   - Post-match social ("third time") tracking

3. **Automatic Team Balancing**
   - Skill-based team creation
   - Minimizes rating differences between teams
   - Ensures competitive matches

4. **Comprehensive Statistics**
   - Season-based leaderboards
   - Win/draw/loss records
   - Attendance rates
   - Points system

## 🔑 Core Concepts

### Season
A yearly period where matches are organized. Each season:
- Has its own leaderboard
- Resets all player ratings to 3.0
- Tracks matches and statistics independently

### Match
A weekly futsal game where:
- Players RSVP beforehand
- Two teams are created from attendees
- Results are recorded after the match
- Ratings are calculated for ALL season players

### Rating
A dynamic 1-5 score representing player skill:
- Locked at 3.0 for first 3 matches
- Calculated from last 3 matches only
- Updates after every match (even for non-attendees)
- Used for team balancing

### Third Time
Post-match social gathering:
- Separate from match attendance
- Provides bonus points
- Contributes to leaderboard

## 📊 Technology Stack

- **Framework**: FastAPI
- **Database**: PostgreSQL
- **ORM**: SQLAlchemy 2.0 (async)
- **Migrations**: Alembic
- **Validation**: Pydantic v2
- **Authentication**: JWT (planned)

## 🏗️ Project Structure

```
backend/
├── app/
│   ├── models/           # SQLAlchemy models
│   ├── schemas/          # Pydantic schemas
│   ├── repositories/     # Data access layer
│   ├── services/         # Business logic
│   ├── api/              # FastAPI endpoints
│   ├── database.py       # DB configuration
│   ├── config.py         # App configuration
│   └── constants.py      # System constants
├── alembic/              # Database migrations
├── docs/                 # Documentation (you are here!)
└── tests/                # Test suite
```

## 📖 Getting Started

1. Read the [System Overview](architecture/overview.md) to understand the architecture
2. Review the [Database Schema](database/schema.md) to see the data model
3. Understand the [Rating System](architecture/rating-system.md) algorithm
4. Check [Setup Guide](development/setup.md) for local development

## 🤝 Contributing

See [Contributing Guidelines](development/contributing.md) for information on how to contribute to this project.

## 📝 License

This project is part of the Futsal Friends platform.

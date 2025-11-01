# Development Setup Guide

This guide will help you set up the Futsal Friends backend for local development.

## Prerequisites

### Required Software

- **Python 3.9+** ([Download](https://www.python.org/downloads/))
- **PostgreSQL 14+** ([Download](https://www.postgresql.org/download/))
- **Docker** (optional, for containerized PostgreSQL) ([Download](https://www.docker.com/))
- **Git** ([Download](https://git-scm.com/downloads))

### Optional Tools

- **PgAdmin** - PostgreSQL GUI ([Download](https://www.pgadmin.org/))
- **Postman** or **Insomnia** - API testing
- **VS Code** with Python extension

## Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd futsal_friends/backend
```

### 2. Run Setup Script

The quickest way to get started:

```bash
./setup.sh
```

This script will:
- Create Python virtual environment
- Install dependencies
- Set up environment variables
- Start PostgreSQL (Docker)
- Run database migrations

### 3. Start Development Server

```bash
./start-dev.sh
```

The API will be available at:
- **API**: http://localhost:8000
- **API Docs**: http://localhost:8000/api/docs
- **ReDoc**: http://localhost:8000/api/redoc

## Manual Setup

If you prefer manual setup or the scripts don't work:

### Step 1: Create Virtual Environment

```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
# On macOS/Linux:
source venv/bin/activate

# On Windows:
venv\Scripts\activate
```

### Step 2: Install Dependencies

```bash
pip install -r requirements.txt
```

### Step 3: Set Up PostgreSQL

#### Option A: Using Docker (Recommended)

```bash
docker-compose up -d
```

This starts:
- PostgreSQL on port 5432
- PgAdmin on port 5050 (http://localhost:5050)

#### Option B: Local PostgreSQL

```bash
# Create database
createdb futsal_friends_db

# Create user (if needed)
psql postgres
CREATE USER futsal_user WITH PASSWORD 'password';
GRANT ALL PRIVILEGES ON DATABASE futsal_friends_db TO futsal_user;
```

### Step 4: Configure Environment

Copy the example environment file:

```bash
cp .env.example .env
```

Edit `.env` with your settings:

```env
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/futsal_friends_db
ASYNC_DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/futsal_friends_db

# Application
DEBUG=True
APP_NAME=Futsal Friends API
API_V1_PREFIX=/api/v1

# Security (generate with: openssl rand -hex 32)
SECRET_KEY=your-secret-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# CORS
ALLOWED_ORIGINS=http://localhost:5173,http://localhost:3000
```

### Step 5: Run Migrations

```bash
# Apply database migrations
alembic upgrade head
```

### Step 6: Start Development Server

```bash
# Run with auto-reload
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Project Structure

```
backend/
├── alembic/                 # Database migrations
│   ├── versions/            # Migration files
│   └── env.py               # Alembic config
├── app/
│   ├── api/                 # API endpoints
│   │   └── v1/
│   │       ├── endpoints/   # Route handlers
│   │       └── router.py    # API router
│   ├── models/              # SQLAlchemy models
│   ├── schemas/             # Pydantic schemas
│   ├── repositories/        # Data access layer
│   ├── services/            # Business logic
│   ├── utils/               # Utility functions
│   ├── config.py            # Configuration
│   ├── constants.py         # Constants
│   ├── database.py          # Database setup
│   └── main.py              # FastAPI application
├── docs/                    # Documentation
├── tests/                   # Test suite
├── .env                     # Environment variables (not in git)
├── .env.example             # Example environment file
├── docker-compose.yml       # Docker services
├── alembic.ini              # Alembic configuration
├── requirements.txt         # Python dependencies
├── setup.sh                 # Setup script
├── start-dev.sh             # Start development server
└── stop-dev.sh              # Stop services
```

## Development Workflow

### Making Code Changes

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make changes to code**

3. **Format code**:
   ```bash
   black app/
   ```

4. **Run linter**:
   ```bash
   flake8 app/
   ```

5. **Type check**:
   ```bash
   mypy app/
   ```

6. **Run tests**:
   ```bash
   pytest
   ```

### Database Changes

1. **Modify models** in `app/models/`

2. **Generate migration**:
   ```bash
   alembic revision --autogenerate -m "Description of changes"
   ```

3. **Review migration** in `alembic/versions/`

4. **Apply migration**:
   ```bash
   alembic upgrade head
   ```

5. **Test rollback**:
   ```bash
   alembic downgrade -1
   alembic upgrade head
   ```

### API Testing

#### Using Interactive Docs

Visit http://localhost:8000/api/docs

- Swagger UI with "Try it out" feature
- Test all endpoints interactively
- See request/response schemas

#### Using curl

```bash
# Health check
curl http://localhost:8000/health

# Create player
curl -X POST http://localhost:8000/api/v1/players \
  -H "Content-Type: application/json" \
  -d '{"name": "John Doe"}'

# Get players
curl http://localhost:8000/api/v1/players
```

#### Using Python Requests

```python
import requests

response = requests.post(
    "http://localhost:8000/api/v1/players",
    json={"name": "John Doe"}
)
print(response.json())
```

## Running Tests

### All Tests

```bash
pytest
```

### Specific Test File

```bash
pytest tests/test_players.py
```

### With Coverage

```bash
pytest --cov=app --cov-report=html
open htmlcov/index.html
```

### Verbose Output

```bash
pytest -v
```

### Stop on First Failure

```bash
pytest -x
```

## Database Management

### Access PostgreSQL

```bash
# Via Docker
docker exec -it futsal_postgres psql -U user -d futsal_friends_db

# Local installation
psql -U user -d futsal_friends_db
```

### Common SQL Commands

```sql
-- List tables
\dt

-- Describe table
\d players

-- Query data
SELECT * FROM players;

-- Check migrations
SELECT * FROM alembic_version;
```

### Reset Database

```bash
# Drop and recreate
dropdb futsal_friends_db
createdb futsal_friends_db

# Run migrations
alembic upgrade head
```

### Backup Database

```bash
pg_dump futsal_friends_db > backup_$(date +%Y%m%d).sql
```

### Restore Database

```bash
psql futsal_friends_db < backup_20251101.sql
```

## Debugging

### Enable Debug Mode

In `.env`:
```env
DEBUG=True
```

This enables:
- SQL query logging
- Detailed error messages
- Auto-reload on code changes

### VS Code Debug Configuration

Create `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "FastAPI",
      "type": "python",
      "request": "launch",
      "module": "uvicorn",
      "args": [
        "app.main:app",
        "--reload",
        "--host", "0.0.0.0",
        "--port", "8000"
      ],
      "jinja": true,
      "justMyCode": false
    }
  ]
}
```

### Print Debugging

```python
# In your code
print(f"Debug: player_id={player_id}")

# Or use logging
import logging
logger = logging.getLogger(__name__)
logger.debug(f"Processing player: {player_id}")
```

### Interactive Debugging

```python
# Add breakpoint
import pdb; pdb.set_trace()

# Or in modern Python
breakpoint()
```

## Common Issues

### Port Already in Use

```bash
# Find process using port 8000
lsof -i :8000

# Kill process
kill -9 <PID>
```

### Database Connection Failed

1. Check PostgreSQL is running:
   ```bash
   docker ps  # If using Docker
   # or
   pg_isready
   ```

2. Verify connection string in `.env`

3. Check firewall settings

### Migration Conflicts

```bash
# Check current version
alembic current

# Check for multiple heads
alembic heads

# If multiple heads, merge them
alembic merge <head1> <head2> -m "Merge migrations"
```

### Import Errors

```bash
# Ensure virtual environment is activated
source venv/bin/activate

# Reinstall dependencies
pip install -r requirements.txt
```

## Code Quality Tools

### Formatter (Black)

```bash
# Format all code
black app/

# Check without modifying
black --check app/

# Format specific file
black app/models/player.py
```

### Linter (Flake8)

```bash
# Lint all code
flake8 app/

# Specific file
flake8 app/models/player.py

# With config
flake8 --max-line-length=88 app/
```

### Type Checker (MyPy)

```bash
# Type check
mypy app/

# Strict mode
mypy --strict app/

# Specific file
mypy app/models/player.py
```

### Pre-commit Hooks (Optional)

Install pre-commit:

```bash
pip install pre-commit
pre-commit install
```

Create `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/psf/black
    rev: 23.1.0
    hooks:
      - id: black
  - repo: https://github.com/pycqa/flake8
    rev: 6.0.0
    hooks:
      - id: flake8
```

## Environment Variables

### Required Variables

```env
DATABASE_URL=postgresql://user:password@localhost:5432/futsal_friends_db
ASYNC_DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/futsal_friends_db
SECRET_KEY=your-secret-key-here
```

### Optional Variables

```env
DEBUG=True
APP_NAME=Futsal Friends API
API_V1_PREFIX=/api/v1
ALLOWED_ORIGINS=http://localhost:5173
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

## Helper Scripts

### Setup Script (`setup.sh`)

Sets up entire development environment:
```bash
./setup.sh
```

### Start Development (`start-dev.sh`)

Starts all services:
```bash
./start-dev.sh
```

### Stop Services (`stop-dev.sh`)

Stops all services:
```bash
./stop-dev.sh
```

## Next Steps

Once setup is complete:

1. **Read the documentation**:
   - [Architecture Overview](../architecture/overview.md)
   - [Database Schema](../database/schema.md)
   - [Rating System](../architecture/rating-system.md)

2. **Explore the API**:
   - Visit http://localhost:8000/api/docs
   - Try the interactive examples

3. **Run tests**:
   ```bash
   pytest
   ```

4. **Start coding**:
   - See [Contributing Guide](contributing.md)

## Getting Help

- **Documentation**: `/docs` directory
- **Issues**: GitHub Issues
- **API Reference**: http://localhost:8000/api/docs

## See Also

- [Contributing Guidelines](contributing.md)
- [Database Migrations](../database/migrations.md)
- [Repository Usage](../api/repositories.md)
- [System Overview](../architecture/overview.md)

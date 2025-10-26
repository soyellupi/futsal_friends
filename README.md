# Futsal Friends

A social platform for organizing and managing futsal games with friends.

## Tech Stack

### Backend
- **FastAPI** - Modern, fast web framework for building APIs
- **PostgreSQL** - Relational database
- **SQLAlchemy** - SQL toolkit and ORM
- **Alembic** - Database migration tool
- **Pydantic** - Data validation using Python type hints

### Frontend
- **React 18** - UI library
- **TypeScript** - Type-safe JavaScript
- **Vite** - Fast build tool and dev server
- **TailwindCSS** - Utility-first CSS framework
- **Headless UI** - Unstyled, accessible UI components
- **TanStack Query** - Data fetching and caching
- **React Router v6** - Client-side routing
- **React Hook Form** - Form handling
- **Zod** - Schema validation

## Project Structure

```
futsal_friends/
├── backend/                 # FastAPI backend
│   ├── app/
│   │   ├── api/            # API routes
│   │   │   └── v1/
│   │   │       ├── endpoints/
│   │   │       └── router.py
│   │   ├── models/         # SQLAlchemy models
│   │   ├── schemas/        # Pydantic schemas
│   │   ├── services/       # Business logic
│   │   ├── repositories/   # Database operations
│   │   ├── utils/          # Utilities
│   │   ├── config.py       # Configuration
│   │   ├── database.py     # Database setup
│   │   ├── dependencies.py # Dependency injection
│   │   └── main.py         # FastAPI app
│   ├── alembic/            # Database migrations
│   ├── tests/              # Backend tests
│   ├── requirements.txt    # Python dependencies
│   └── .env.example        # Environment variables template
│
├── frontend/                # React frontend
│   ├── src/
│   │   ├── components/     # React components
│   │   │   ├── common/    # Reusable components
│   │   │   ├── layout/    # Layout components
│   │   │   └── features/  # Feature-specific components
│   │   ├── pages/         # Page components
│   │   ├── hooks/         # Custom React hooks
│   │   ├── contexts/      # React contexts
│   │   ├── services/      # API services
│   │   ├── types/         # TypeScript types
│   │   ├── utils/         # Utility functions
│   │   ├── constants/     # Constants
│   │   ├── config/        # Configuration
│   │   ├── App.tsx        # Root component
│   │   └── main.tsx       # Entry point
│   ├── public/            # Static assets
│   ├── package.json       # Node dependencies
│   └── .env.example       # Environment variables template
│
├── .claude/
│   └── agents/            # Claude Code agents
│       ├── backend-agent.md
│       ├── frontend-agent.md
│       └── ui-agent.md
│
├── .mise.toml             # mise configuration (Python 3.11, Node 20)
├── .envrc                 # direnv configuration (optional)
├── docker-compose.yml     # Docker services (PostgreSQL, PgAdmin)
├── setup.sh               # Automated setup script
└── README.md
```

## Getting Started

### Prerequisites

**Using mise (Recommended):**
- [mise](https://mise.jdx.dev/) - Manages Python, Node.js versions automatically
- Docker & Docker Compose

**Manual installation:**
- Python 3.11+
- Node.js 20+
- Docker & Docker Compose

**Note:** PostgreSQL runs in Docker, so you don't need to install it locally!

### Installing mise (Recommended)

mise automatically manages the correct versions of Python and Node.js:

```bash
# macOS/Linux
curl https://mise.run | sh

# Or with Homebrew
brew install mise

# Add to your shell (choose one):
echo 'eval "$(mise activate bash)"' >> ~/.bashrc
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
echo 'mise activate fish | source' >> ~/.config/fish/config.fish

# Reload your shell or run:
source ~/.bashrc  # or ~/.zshrc
```

### Quick Setup (Automated)

The easiest way to set up the project is using the automated setup script:

```bash
./setup.sh
```

This script will:
- Check for mise or fallback to system Python/Node.js
- Install correct tool versions via mise (if available)
- Start PostgreSQL in a Docker container
- Create and configure Python virtual environment
- Install all backend dependencies
- Run database migrations
- Install all frontend dependencies
- Create environment configuration files
- Generate helper scripts (`start-dev.sh`, `stop-dev.sh`, `docker-helpers.sh`)

**With mise:** Tool versions are automatically managed from `.mise.toml`

**Without mise:** The script falls back to using system Python and Node.js

After setup completes, start the development environment:

```bash
./start-dev.sh
```

This will start both backend (port 8000) and frontend (port 5173) servers.

To stop all services:

```bash
./stop-dev.sh              # Stops backend and frontend only
./docker-helpers.sh stop   # Stops Docker containers
```

### mise Tasks (Recommended Workflow)

If you're using mise, you can use built-in tasks for common operations:

```bash
mise tasks                  # List all available tasks

# Development
mise run dev                # Start both backend and frontend
mise run backend:dev        # Start backend only
mise run frontend:dev       # Start frontend only
mise run stop               # Stop all services

# Database
mise run db:migrate         # Run database migrations
mise run db:migration "msg" # Create new migration
mise run db:shell           # Open PostgreSQL shell
mise run db:reset           # Reset database (WARNING: deletes data)

# Testing
mise run backend:test       # Run backend tests
mise run frontend:test      # Run frontend tests

# Code quality
mise run backend:format     # Format backend code with black
mise run backend:lint       # Lint backend code

# Docker
mise run docker:start       # Start Docker containers
mise run docker:stop        # Stop Docker containers
mise run docker:logs        # View PostgreSQL logs
mise run docker:pgadmin     # Start PgAdmin UI
```

### Docker Helper Commands

The project includes a `docker-helpers.sh` script with useful Docker commands:

```bash
./docker-helpers.sh         # Show all available commands
./docker-helpers.sh start   # Start Docker containers
./docker-helpers.sh stop    # Stop Docker containers
./docker-helpers.sh logs    # View PostgreSQL logs
./docker-helpers.sh shell   # Open PostgreSQL shell
./docker-helpers.sh reset   # Reset database (deletes all data)
./docker-helpers.sh pgadmin # Start PgAdmin web UI (http://localhost:5050)
```

### Manual Setup

If you prefer to set up the project manually or need more control:

#### Backend Setup

1. Navigate to the backend directory:
```bash
cd backend
```

2. Create and activate a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Create a `.env` file from the example:
```bash
cp .env.example .env
```

5. Update the `.env` file with your database credentials and other settings.

6. Start PostgreSQL with Docker:
```bash
docker-compose up -d db
```

7. Run database migrations:
```bash
alembic upgrade head
```

8. Start the development server:
```bash
uvicorn app.main:app --reload
```

The API will be available at `http://localhost:8000`
- API Documentation: `http://localhost:8000/api/docs`
- Alternative Documentation: `http://localhost:8000/api/redoc`

#### Frontend Setup

1. Navigate to the frontend directory:
```bash
cd frontend
```

2. Install dependencies:
```bash
npm install
```

3. Create a `.env` file from the example:
```bash
cp .env.example .env
```

4. Update the `.env` file with your API URL (default: `http://localhost:8000`)

5. Start the development server:
```bash
npm run dev
```

The application will be available at `http://localhost:5173`

## Development

### Backend Development

The backend follows a clean architecture pattern:

- **Routes** (`app/api/v1/endpoints/`): Handle HTTP requests and responses
- **Services** (`app/services/`): Contain business logic
- **Repositories** (`app/repositories/`): Handle database operations
- **Models** (`app/models/`): SQLAlchemy ORM models
- **Schemas** (`app/schemas/`): Pydantic models for validation

For backend development, consult the **backend-agent** (`.claude/agents/backend-agent.md`)

### Frontend Development

The frontend is organized by feature and type:

- **Components**: Reusable UI components
- **Pages**: Top-level route components
- **Hooks**: Custom React hooks for reusable logic
- **Contexts**: React Context providers for global state
- **Services**: API integration layer

For frontend development:
- Use **frontend-agent** (`.claude/agents/frontend-agent.md`) for logic and state
- Use **ui-agent** (`.claude/agents/ui-agent.md`) for styling and UI components

### Running Tests

Backend tests:
```bash
cd backend
pytest
```

Frontend tests:
```bash
cd frontend
npm test
```

## Code Style

### Backend
- Follow PEP 8 style guide
- Use type hints for all functions
- Maximum line length: 88 characters (Black formatter)
- Run `black .` to format code
- Run `flake8` for linting

### Frontend
- Use TypeScript strict mode
- Follow ESLint rules
- Use Prettier for formatting
- Maximum line length: 100 characters
- Group imports: React, third-party, local

## Environment Variables

### Backend (.env)
```
DATABASE_URL=postgresql://user:password@localhost:5432/futsal_friends_db
ASYNC_DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/futsal_friends_db
SECRET_KEY=your-secret-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
ALLOWED_ORIGINS=http://localhost:5173
```

### Frontend (.env)
```
VITE_API_URL=http://localhost:8000
```

## Claude Code Agents

This project includes specialized AI agents for development:

- **backend-agent.md**: Python, FastAPI, PostgreSQL expert
- **frontend-agent.md**: React, TypeScript, state management expert
- **ui-agent.md**: TailwindCSS, Headless UI, design expert

Use these agents with Claude Code for context-aware assistance.

## License

MIT

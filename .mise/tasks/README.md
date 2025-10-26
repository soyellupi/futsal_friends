# mise Tasks Reference

This document lists all available mise tasks for the Futsal Friends project.

## Usage

```bash
mise tasks           # List all tasks
mise run <task>      # Run a task
```

## Available Tasks

### Development

| Task | Description |
|------|-------------|
| `mise run dev` | Start both backend and frontend development servers |
| `mise run backend:dev` | Start only the backend server |
| `mise run frontend:dev` | Start only the frontend server |
| `mise run stop` | Stop all development services |

### Installation

| Task | Description |
|------|-------------|
| `mise run install` | Install all dependencies (backend + frontend) |
| `mise run setup` | Run the full setup script |

### Database

| Task | Description |
|------|-------------|
| `mise run db:migrate` | Apply database migrations |
| `mise run db:migration "message"` | Create a new migration |
| `mise run db:shell` | Open PostgreSQL interactive shell |
| `mise run db:reset` | Reset database (⚠️ deletes all data) |

### Testing

| Task | Description |
|------|-------------|
| `mise run backend:test` | Run backend tests with pytest |
| `mise run frontend:test` | Run frontend tests |

### Code Quality

| Task | Description |
|------|-------------|
| `mise run backend:format` | Format backend code with black |
| `mise run backend:lint` | Lint backend code with flake8 |

### Docker

| Task | Description |
|------|-------------|
| `mise run docker:start` | Start Docker containers |
| `mise run docker:stop` | Stop Docker containers |
| `mise run docker:logs` | Show PostgreSQL container logs |
| `mise run docker:pgadmin` | Start PgAdmin web interface |

## Examples

```bash
# Start development environment
mise run dev

# Create a new database migration
mise run db:migration "add users table"

# Run tests
mise run backend:test

# Format code
mise run backend:format

# Access database shell
mise run db:shell
```

## Environment Variables

mise automatically loads environment variables from:
- `.mise.toml` - Project configuration
- `.env` files in backend/frontend directories

To see active environment variables:
```bash
mise env
```

## Custom Tasks

You can add custom tasks to `.mise.toml`:

```toml
[tasks.my-task]
description = "My custom task"
run = "echo 'Hello from my task'"
```

Then run with:
```bash
mise run my-task
```

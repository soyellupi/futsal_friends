#!/bin/bash

# Futsal Friends - Development Environment Setup Script
# This script sets up the entire project for local development using Docker

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project configuration
DB_NAME="futsal_friends_db"
DB_USER="futsal_user"
DB_PASSWORD="futsal_password"
DB_HOST="localhost"
DB_PORT="5432"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Futsal Friends Setup Script${NC}"
echo -e "${BLUE}================================${NC}\n"

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "${BLUE}[1/7] Checking prerequisites...${NC}\n"

# Check mise
if command_exists mise; then
    MISE_VERSION=$(mise --version | head -1)
    print_success "mise is installed ($MISE_VERSION)"

    # Install/verify tools defined in .mise.toml
    print_info "Installing required tools with mise..."
    mise install

    # Activate mise environment
    eval "$(mise activate bash)"

    # Verify tools are available
    if command_exists python3; then
        PYTHON_VERSION=$(python3 --version | cut -d ' ' -f 2)
        print_success "Python is ready (version $PYTHON_VERSION)"
    else
        print_error "Python installation failed"
        exit 1
    fi

    if command_exists node; then
        NODE_VERSION=$(node --version)
        print_success "Node.js is ready (version $NODE_VERSION)"
    else
        print_error "Node.js installation failed"
        exit 1
    fi

    if command_exists npm; then
        NPM_VERSION=$(npm --version)
        print_success "npm is ready (version $NPM_VERSION)"
    fi
else
    print_error "mise is not installed."
    print_info "Install mise: https://mise.jdx.dev/getting-started.html"
    print_info "  macOS/Linux: curl https://mise.run | sh"
    print_info "  Or use homebrew: brew install mise"
    echo ""
    print_warning "Falling back to system Python and Node.js..."

    # Fallback: Check system Python
    if command_exists python3; then
        PYTHON_VERSION=$(python3 --version | cut -d ' ' -f 2)
        print_success "Python 3 is installed (version $PYTHON_VERSION)"
    else
        print_error "Python 3 is not installed. Please install Python 3.11 or higher."
        exit 1
    fi

    # Fallback: Check system Node.js
    if command_exists node; then
        NODE_VERSION=$(node --version)
        print_success "Node.js is installed (version $NODE_VERSION)"
    else
        print_error "Node.js is not installed. Please install Node.js 20 or higher."
        exit 1
    fi

    # Fallback: Check npm
    if command_exists npm; then
        NPM_VERSION=$(npm --version)
        print_success "npm is installed (version $NPM_VERSION)"
    else
        print_error "npm is not installed. Please install npm."
        exit 1
    fi
fi

# Check Docker
if command_exists docker; then
    DOCKER_VERSION=$(docker --version | cut -d ' ' -f 3 | tr -d ',')
    print_success "Docker is installed (version $DOCKER_VERSION)"
else
    print_error "Docker is not installed. Please install Docker Desktop."
    print_info "  macOS: https://docs.docker.com/desktop/install/mac-install/"
    print_info "  Linux: https://docs.docker.com/desktop/install/linux-install/"
    exit 1
fi

# Check if Docker daemon is running
if docker info >/dev/null 2>&1; then
    print_success "Docker daemon is running"
else
    print_error "Docker daemon is not running. Please start Docker Desktop."
    exit 1
fi

# Check Docker Compose
if command_exists docker-compose || docker compose version >/dev/null 2>&1; then
    if command_exists docker-compose; then
        COMPOSE_CMD="docker-compose"
        COMPOSE_VERSION=$(docker-compose --version | cut -d ' ' -f 4 | tr -d ',')
    else
        COMPOSE_CMD="docker compose"
        COMPOSE_VERSION=$(docker compose version --short)
    fi
    print_success "Docker Compose is available (version $COMPOSE_VERSION)"
else
    print_error "Docker Compose is not available."
    exit 1
fi

echo ""

# Start Docker containers
echo -e "${BLUE}[2/7] Starting Docker containers...${NC}\n"

print_info "Starting PostgreSQL container..."
$COMPOSE_CMD up -d db

# Wait for PostgreSQL to be ready
print_info "Waiting for PostgreSQL to be ready..."
RETRIES=30
until docker exec futsal_friends_db pg_isready -U $DB_USER -d $DB_NAME >/dev/null 2>&1 || [ $RETRIES -eq 0 ]; do
    echo -n "."
    sleep 1
    RETRIES=$((RETRIES - 1))
done
echo ""

if [ $RETRIES -eq 0 ]; then
    print_error "PostgreSQL failed to start. Check logs with: docker logs futsal_friends_db"
    exit 1
fi

print_success "PostgreSQL is ready and accepting connections"

echo ""

# Setup Backend
echo -e "${BLUE}[3/7] Setting up Backend...${NC}\n"

cd backend

# Create virtual environment
if [ ! -d "venv" ]; then
    print_info "Creating Python virtual environment..."
    python3 -m venv venv
    print_success "Virtual environment created"
else
    print_info "Virtual environment already exists"
fi

# Activate virtual environment
print_info "Activating virtual environment..."
source venv/bin/activate

# Install Python dependencies
print_info "Installing Python dependencies..."
pip install --upgrade pip >/dev/null 2>&1
pip install -r requirements.txt >/dev/null 2>&1
print_success "Python dependencies installed"

# Setup .env file
if [ ! -f ".env" ]; then
    print_info "Creating .env file from template..."
    cp .env.example .env

    # Update database connection strings
    sed -i.bak "s|postgresql://.*@localhost.*/futsal_friends_db|postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME|g" .env
    sed -i.bak "s|postgresql+asyncpg://.*@localhost.*/futsal_friends_db|postgresql+asyncpg://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME|g" .env
    rm -f .env.bak

    # Generate a random secret key
    SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
    sed -i.bak "s|your-secret-key-here-change-in-production|$SECRET_KEY|g" .env
    rm -f .env.bak

    print_success ".env file created and configured"
else
    print_info ".env file already exists"
fi

cd ..

echo ""

# Setup Database migrations
echo -e "${BLUE}[4/7] Running database migrations...${NC}\n"

cd backend
source venv/bin/activate
print_info "Running Alembic migrations..."
alembic upgrade head
print_success "Database migrations completed"
cd ..

echo ""

# Setup Frontend
echo -e "${BLUE}[5/7] Setting up Frontend...${NC}\n"

cd frontend

# Install npm dependencies
print_info "Installing npm dependencies..."
npm install --silent
print_success "npm dependencies installed"

# Setup .env file
if [ ! -f ".env" ]; then
    print_info "Creating .env file from template..."
    cp .env.example .env
    print_success ".env file created"
else
    print_info ".env file already exists"
fi

cd ..

echo ""

# Create helper scripts
echo -e "${BLUE}[6/7] Creating helper scripts...${NC}\n"

# Create start-dev.sh script
cat > start-dev.sh << 'EOF'
#!/bin/bash

# Start both backend and frontend in development mode

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Starting Futsal Friends Development Environment...${NC}\n"

# Check if Docker Compose is available
if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
else
    COMPOSE_CMD="docker compose"
fi

# Start Docker containers if not running
if ! docker ps | grep -q futsal_friends_db; then
    echo -e "${YELLOW}Starting Docker containers...${NC}"
    $COMPOSE_CMD up -d db
    echo -e "${GREEN}✓ Docker containers started${NC}\n"
fi

# Function to cleanup on exit
cleanup() {
    echo -e "\n${BLUE}Shutting down services...${NC}"
    kill $(jobs -p) 2>/dev/null
    exit
}

trap cleanup SIGINT SIGTERM

# Start Backend
echo -e "${GREEN}Starting Backend (http://localhost:8000)...${NC}"
cd backend
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 > ../backend.log 2>&1 &
BACKEND_PID=$!
cd ..

# Wait for backend to start
sleep 3

# Start Frontend
echo -e "${GREEN}Starting Frontend (http://localhost:5173)...${NC}"
cd frontend
npm run dev > ../frontend.log 2>&1 &
FRONTEND_PID=$!
cd ..

sleep 2

echo -e "\n${GREEN}✓ Development environment is running!${NC}\n"
echo -e "  ${BLUE}Backend API:${NC}      http://localhost:8000"
echo -e "  ${BLUE}API Docs:${NC}         http://localhost:8000/api/docs"
echo -e "  ${BLUE}Frontend:${NC}         http://localhost:5173"
echo -e "  ${BLUE}PostgreSQL:${NC}       localhost:5432"
echo -e "\n  ${BLUE}Logs:${NC}"
echo -e "    Backend:  tail -f backend.log"
echo -e "    Frontend: tail -f frontend.log"
echo -e "    Docker:   docker logs futsal_friends_db"
echo -e "\nPress Ctrl+C to stop all services\n"

# Wait for processes
wait
EOF

chmod +x start-dev.sh
print_success "Created start-dev.sh script"

# Create stop-dev.sh script
cat > stop-dev.sh << 'EOF'
#!/bin/bash

# Stop all development services

echo "Stopping development services..."

# Kill processes on ports 8000 and 5173
lsof -ti:8000 | xargs kill -9 2>/dev/null || true
lsof -ti:5173 | xargs kill -9 2>/dev/null || true

echo "✓ Development services stopped"
echo ""
echo "Note: Docker containers are still running."
echo "To stop Docker containers: docker-compose down"
echo "To stop and remove volumes: docker-compose down -v"
EOF

chmod +x stop-dev.sh
print_success "Created stop-dev.sh script"

# Create docker-helpers.sh script
cat > docker-helpers.sh << 'EOF'
#!/bin/bash

# Docker helper commands for Futsal Friends

# Detect compose command
if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
else
    COMPOSE_CMD="docker compose"
fi

case "$1" in
    start)
        echo "Starting Docker containers..."
        $COMPOSE_CMD up -d
        ;;
    stop)
        echo "Stopping Docker containers..."
        $COMPOSE_CMD down
        ;;
    restart)
        echo "Restarting Docker containers..."
        $COMPOSE_CMD restart
        ;;
    logs)
        echo "Showing Docker logs (Ctrl+C to exit)..."
        $COMPOSE_CMD logs -f db
        ;;
    shell)
        echo "Opening PostgreSQL shell..."
        docker exec -it futsal_friends_db psql -U futsal_user -d futsal_friends_db
        ;;
    reset)
        echo "⚠️  WARNING: This will delete all database data!"
        read -p "Are you sure? (yes/no): " confirm
        if [ "$confirm" == "yes" ]; then
            echo "Stopping containers and removing volumes..."
            $COMPOSE_CMD down -v
            echo "Starting fresh containers..."
            $COMPOSE_CMD up -d
            echo "✓ Database reset complete"
        else
            echo "Cancelled"
        fi
        ;;
    pgadmin)
        echo "Starting PgAdmin..."
        $COMPOSE_CMD --profile tools up -d pgadmin
        echo "✓ PgAdmin available at http://localhost:5050"
        echo "  Email: admin@futsalfriends.local"
        echo "  Password: admin"
        ;;
    *)
        echo "Futsal Friends - Docker Helper Commands"
        echo ""
        echo "Usage: ./docker-helpers.sh [command]"
        echo ""
        echo "Commands:"
        echo "  start     - Start Docker containers"
        echo "  stop      - Stop Docker containers"
        echo "  restart   - Restart Docker containers"
        echo "  logs      - Show PostgreSQL logs"
        echo "  shell     - Open PostgreSQL shell"
        echo "  reset     - Reset database (deletes all data)"
        echo "  pgadmin   - Start PgAdmin web interface"
        ;;
esac
EOF

chmod +x docker-helpers.sh
print_success "Created docker-helpers.sh script"

echo ""

# Verify setup
echo -e "${BLUE}[7/7] Verifying setup...${NC}\n"

# Check backend
if [ -f "backend/venv/bin/python" ]; then
    print_success "Backend virtual environment is ready"
else
    print_error "Backend virtual environment not found"
fi

# Check frontend node_modules
if [ -d "frontend/node_modules" ]; then
    print_success "Frontend dependencies are installed"
else
    print_error "Frontend dependencies not found"
fi

# Check Docker container
if docker ps | grep -q futsal_friends_db; then
    print_success "PostgreSQL container is running"
else
    print_warning "PostgreSQL container is not running"
fi

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Setup completed successfully!${NC}"
echo -e "${GREEN}================================${NC}\n"

echo -e "${BLUE}To start the development environment:${NC}"
echo -e "  ${YELLOW}./start-dev.sh${NC}\n"

echo -e "${BLUE}Or start services individually:${NC}"
echo -e "  ${YELLOW}Backend:${NC}   cd backend && source venv/bin/activate && uvicorn app.main:app --reload"
echo -e "  ${YELLOW}Frontend:${NC}  cd frontend && npm run dev\n"

echo -e "${BLUE}To stop services:${NC}"
echo -e "  ${YELLOW}./stop-dev.sh${NC}        - Stop backend and frontend only"
echo -e "  ${YELLOW}./docker-helpers.sh stop${NC}  - Stop Docker containers\n"

echo -e "${BLUE}Docker commands:${NC}"
echo -e "  ${YELLOW}./docker-helpers.sh${NC}         - Show all Docker helper commands"
echo -e "  ${YELLOW}docker-compose logs -f db${NC}   - View PostgreSQL logs"
echo -e "  ${YELLOW}docker-compose down -v${NC}      - Stop and remove all data\n"

echo -e "${BLUE}Database credentials:${NC}"
echo -e "  Host:     $DB_HOST:$DB_PORT"
echo -e "  Database: $DB_NAME"
echo -e "  User:     $DB_USER"
echo -e "  Password: $DB_PASSWORD\n"

echo -e "${BLUE}Useful commands:${NC}"
echo -e "  ${YELLOW}Backend tests:${NC}     cd backend && source venv/bin/activate && pytest"
echo -e "  ${YELLOW}Frontend tests:${NC}    cd frontend && npm test"
echo -e "  ${YELLOW}Code formatting:${NC}   cd backend && source venv/bin/activate && black ."
echo -e "  ${YELLOW}New migration:${NC}     cd backend && source venv/bin/activate && alembic revision --autogenerate -m \"description\""
echo -e "  ${YELLOW}Database shell:${NC}    ./docker-helpers.sh shell"
echo -e "  ${YELLOW}PgAdmin UI:${NC}        ./docker-helpers.sh pgadmin\n"

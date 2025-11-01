#!/bin/bash

# Database restore script using Docker
# Restores a PostgreSQL database from a dump file

# Configuration
DB_USER="futsal_user"

# Check if backup file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <backup_file.sql>"
    echo ""
    echo "Available backups:"
    ls -lht ./db_backups/*.sql 2>/dev/null | head -n 10 || echo "No backups found in ./db_backups/"
    exit 1
fi

BACKUP_FILE="$1"

# Check if file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "============================================================"
echo "  Database Restore (Docker)"
echo "============================================================"
echo ""
echo "⚠️  WARNING: This will DROP and recreate the database!"
echo "Backup file: $BACKUP_FILE"
echo ""

# Confirm with user
read -p "Are you sure you want to continue? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled."
    exit 0
fi

# Find the PostgreSQL container
CONTAINER_ID=$(docker ps --filter "name=futsal_friends_db" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    # Try to find by ancestor
    CONTAINER_ID=$(docker ps --filter "ancestor=postgres" --format "{{.ID}}" | head -1)
fi

if [ -z "$CONTAINER_ID" ]; then
    # Try to find by generic postgres name
    CONTAINER_ID=$(docker ps --filter "name=postgres" --format "{{.ID}}" | head -1)
fi

if [ -z "$CONTAINER_ID" ]; then
    echo "✗ No running PostgreSQL container found!"
    echo ""
    echo "Please make sure your PostgreSQL container is running:"
    echo "  docker ps"
    exit 1
fi

echo "Using container: $CONTAINER_ID"
echo ""
echo "Starting restore..."

# Restore backup using docker exec
docker exec -i "$CONTAINER_ID" psql -U "$DB_USER" -d postgres < "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Restore completed successfully!"
else
    echo ""
    echo "✗ Restore failed!"
    exit 1
fi

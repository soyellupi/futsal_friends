#!/bin/bash

# Database backup script using Docker
# Creates a dump of the PostgreSQL database with structure and data

# Configuration
DB_NAME="futsal_friends_db"
DB_USER="futsal_user"
CONTAINER_NAME="futsal_postgres"  # Change this if your container has a different name

# Timestamp for backup file
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Backup directory
BACKUP_DIR="/Users/francisco/dev/ai-apps/futsal_friends/backend/db_backups"
mkdir -p "$BACKUP_DIR"

# Backup filename
BACKUP_FILE="futsal_friends_${TIMESTAMP}.sql"

echo "============================================================"
echo "  Database Backup (Docker)"
echo "============================================================"
echo ""
echo "Database: $DB_NAME"
echo "Container: $CONTAINER_NAME"
echo "Backup file: $BACKUP_DIR/$BACKUP_FILE"
echo ""

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

# Create backup using docker exec
docker exec -t "$CONTAINER_ID" pg_dump -U "$DB_USER" -d "$DB_NAME" --clean --if-exists --create > "$BACKUP_DIR/$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Backup completed successfully!"
    echo "✓ File: $BACKUP_DIR/$BACKUP_FILE"
    echo "✓ Size: $(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)"
    echo ""

    # Create a compressed version
    echo "Creating compressed backup..."
    gzip -k "$BACKUP_DIR/$BACKUP_FILE"
    echo "✓ Compressed backup: $BACKUP_DIR/${BACKUP_FILE}.gz"
    echo "✓ Size: $(du -h "$BACKUP_DIR/${BACKUP_FILE}.gz" | cut -f1)"
    echo ""

    echo "To restore this backup, run:"
    echo "  docker exec -i $CONTAINER_ID psql -U $DB_USER -d postgres < $BACKUP_DIR/$BACKUP_FILE"
    echo ""

    # List recent backups
    echo "Recent backups:"
    ls -lht "$BACKUP_DIR"/*.sql 2>/dev/null | head -n 5
else
    echo ""
    echo "✗ Backup failed!"
    exit 1
fi

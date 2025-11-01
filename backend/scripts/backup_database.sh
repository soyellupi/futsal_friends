#!/bin/bash

# Database backup script
# Creates a dump of the PostgreSQL database with structure and data

# Configuration
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="futsal_friends_db"
DB_USER="futsal_user"
DB_PASSWORD="futsal_password"

# Timestamp for backup file
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Backup directory
BACKUP_DIR="/Users/francisco/dev/ai-apps/futsal_friends/backend/db_backups"
mkdir -p "$BACKUP_DIR"

# Backup filename
BACKUP_FILE="$BACKUP_DIR/futsal_friends_${TIMESTAMP}.sql"

echo "============================================================"
echo "  Database Backup"
echo "============================================================"
echo ""
echo "Database: $DB_NAME"
echo "Host: $DB_HOST:$DB_PORT"
echo "Backup file: $BACKUP_FILE"
echo ""

# Create backup using pg_dump
export PGPASSWORD="$DB_PASSWORD"

pg_dump -h "$DB_HOST" \
        -p "$DB_PORT" \
        -U "$DB_USER" \
        -d "$DB_NAME" \
        --clean \
        --if-exists \
        --create \
        --format=plain \
        --encoding=UTF8 \
        --verbose \
        --file="$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Backup completed successfully!"
    echo "✓ File: $BACKUP_FILE"
    echo "✓ Size: $(du -h "$BACKUP_FILE" | cut -f1)"
    echo ""
    echo "To restore this backup, run:"
    echo "  psql postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/postgres -f $BACKUP_FILE"
else
    echo ""
    echo "✗ Backup failed!"
    exit 1
fi

# Create a compressed version
echo "Creating compressed backup..."
gzip -k "$BACKUP_FILE"
echo "✓ Compressed backup: ${BACKUP_FILE}.gz"
echo "✓ Size: $(du -h "${BACKUP_FILE}.gz" | cut -f1)"
echo ""

# List recent backups
echo "Recent backups:"
ls -lh "$BACKUP_DIR" | tail -n 5

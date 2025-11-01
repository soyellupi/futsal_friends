#!/bin/bash

# Database restore script
# Restores a PostgreSQL database from a dump file

# Configuration
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="futsal_friends_db"
DB_USER="futsal_user"
DB_PASSWORD="futsal_password"

# Check if backup file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <backup_file.sql>"
    echo ""
    echo "Available backups:"
    ls -lh ./backups/*.sql 2>/dev/null || echo "No backups found in ./backups/"
    exit 1
fi

BACKUP_FILE="$1"

# Check if file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "============================================================"
echo "  Database Restore"
echo "============================================================"
echo ""
echo "⚠️  WARNING: This will DROP and recreate the database!"
echo "Database: $DB_NAME"
echo "Host: $DB_HOST:$DB_PORT"
echo "Backup file: $BACKUP_FILE"
echo ""

# Confirm with user
read -p "Are you sure you want to continue? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled."
    exit 0
fi

echo ""
echo "Starting restore..."

# Set password
export PGPASSWORD="$DB_PASSWORD"

# Restore backup
psql -h "$DB_HOST" \
     -p "$DB_PORT" \
     -U "$DB_USER" \
     -d postgres \
     -f "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Restore completed successfully!"
else
    echo ""
    echo "✗ Restore failed!"
    exit 1
fi

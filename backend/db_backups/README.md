# Database Backups

This directory contains backups of the Futsal Friends PostgreSQL database.

## Backup Files

Backups are created with timestamps in the format: `futsal_friends_YYYYMMDD_HHMMSS.sql`

Both plain SQL files and compressed `.gz` versions are created.

## Create a Backup

To create a new backup, run:

```bash
cd /Users/francisco/dev/ai-apps/futsal_friends/backend
./scripts/backup_database_docker.sh
```

This will create two files:
- `futsal_friends_YYYYMMDD_HHMMSS.sql` - Plain SQL dump (larger)
- `futsal_friends_YYYYMMDD_HHMMSS.sql.gz` - Compressed version (smaller, for archiving)

## Restore a Backup

To restore a backup, run:

```bash
cd /Users/francisco/dev/ai-apps/futsal_friends/backend
./scripts/restore_database_docker.sh db_backups/futsal_friends_YYYYMMDD_HHMMSS.sql
```

⚠️ **WARNING**: Restoring will **DROP** the existing database and recreate it from the backup!

## What's Included in Backups

Each backup contains:
- ✅ Database schema (all tables, indexes, constraints)
- ✅ All data from all tables
- ✅ Sequences and their current values
- ✅ Enum types
- ✅ Foreign key relationships

## Backup Schedule Recommendations

- **Before major changes**: Always backup before significant data operations
- **Daily**: Run `./scripts/backup_database_docker.sh` daily
- **After matches**: Backup after recording important matches
- **Before migrations**: Backup before running `alembic upgrade`

## Storage

- Keep at least the last 7 daily backups
- Archive monthly backups for historical records
- Compressed backups (.gz) are ~80% smaller than plain SQL files
- Consider storing backups in cloud storage (Google Drive, Dropbox, etc.)

## Example Workflow

### Daily Backup
```bash
./scripts/backup_database_docker.sh
```

### Restore Specific Backup
```bash
# List available backups
ls -lht db_backups/*.sql

# Restore a specific backup
./scripts/restore_database_docker.sh db_backups/futsal_friends_20251101_230025.sql
```

### Extract Compressed Backup
```bash
gunzip db_backups/futsal_friends_YYYYMMDD_HHMMSS.sql.gz
```

## Troubleshooting

### "No running PostgreSQL container found"
Make sure your database container is running:
```bash
docker ps | grep futsal_friends_db
```

If not running, start it:
```bash
docker start futsal_friends_db
```

### "Permission denied"
Make sure the scripts are executable:
```bash
chmod +x scripts/backup_database_docker.sh
chmod +x scripts/restore_database_docker.sh
```

### Backup file too large
Use the compressed `.gz` version for storage and sharing.

## Current Backups

The latest backup was created on: 2025-11-01 23:00:25

-- Initial database setup script
-- This runs automatically when the PostgreSQL container is first created

-- Create extensions if needed
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Grant all privileges to futsal_user
GRANT ALL PRIVILEGES ON DATABASE futsal_friends_db TO futsal_user;

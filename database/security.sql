
-- SECURITY.SQL — implements a basic Role-Based Access Control (RBAC) model


SET search_path TO olist;


-- ----------1. CREATE ROLES-------------

-- Read-only analyst role
CREATE ROLE analyst NOINHERIT;

-- Read/write application user role
CREATE ROLE app_user_rw NOINHERIT LOGIN PASSWORD 'app_user_rw123';


-- ---------2. GRANT PRIVILEGES------------

-- ANALYST (READ-ONLY)

-- Allow read-only connections
GRANT CONNECT ON DATABASE olist_db TO analyst;

-- Allow usage of the schema
GRANT USAGE ON SCHEMA olist TO analyst;

-- Allow select on all existing tables
GRANT SELECT ON ALL TABLES IN SCHEMA olist TO analyst;

-- Allow rules for future tables 
ALTER DEFAULT PRIVILEGES IN SCHEMA olist
    GRANT SELECT ON TABLES TO analyst;



-- APPLICATION USER (READ-WRITE)

-- Allow connecting to the DB
GRANT CONNECT ON DATABASE olist_db TO app_user_rw;

-- Allow usage of schema
GRANT USAGE ON SCHEMA olist TO app_user_rw;

-- Allow complete access
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA olist TO app_user_rw;

-- Allow app_user_rw to create tables if needed (Optional)
-- GRANT CREATE ON SCHEMA olist TO app_user_rw;

-- Ensure read/write applies to FUTURE tables
ALTER DEFAULT PRIVILEGES IN SCHEMA olist
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user_rw;



-- 3. Create a read-only login user

CREATE USER analyst_user WITH PASSWORD 'readonly123';
GRANT analyst TO analyst_user;


CREATE USER app_user WITH PASSWORD 'rw123';
GRANT app_user_rw TO app_user;

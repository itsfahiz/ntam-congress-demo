import pg from 'pg';

let pool;

/**
 * PostgreSQL pool for later persistence.
 * Phase 1 catalog routes do not call this. No queries are issued on startup.
 */
export function getPool() {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    const error = new Error('DATABASE_URL is not configured.');
    error.status = 503;
    throw error;
  }
  if (!pool) {
    pool = new pg.Pool({
      connectionString,
      max: 5,
    });
  }
  return pool;
}

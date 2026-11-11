import { Pool } from 'pg';
import type { AppError } from '../types/http.js';

let pool: Pool | undefined;

/**
 * PostgreSQL pool for later persistence.
 * Phase 1 catalog routes do not call this. No queries are issued on startup.
 */
export function getPool() {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    const error = new Error('DATABASE_URL is not configured.') as AppError;
    error.status = 503;
    throw error;
  }
  if (!pool) {
    pool = new Pool({
      connectionString,
      max: 5,
    });
  }
  return pool;
}

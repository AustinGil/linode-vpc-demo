import { DB_USER, DB_PASS, DB_HOST, DB_PORT, DB_NAME } from './src/config.js'

/** @type { import("drizzle-kit").Config } */
export default {
  schema: "./src/services/db/schema-*.mjs",
  out: "./drizzle",

  // SQLite
  // driver: 'better-sqlite', // 'pg' | 'mysql2' | 'better-sqlite' | 'libsql' | 'turso'
  // dbCredentials: {
  //   url: './dev.db'
  // }

  // Postgres
  driver: 'pg',
  dbCredentials: {
    user: DB_USER,
    password: DB_PASS,
    host: DB_HOST,
    port: DB_PORT,
    database: DB_NAME,
  },
};
const DB_USER = "mydbuser"
const DB_PASS = "mydbpass"
const DB_HOST = "172.232.190.75"
const DB_PORT = 5432
const DB_NAME = "mydbname"
// const DB_NAME = "postgres"
// psql -h lin-74460-45521-pgsql-primary.servers.linodedb.net -p 5432 -U linpostgres postgres

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
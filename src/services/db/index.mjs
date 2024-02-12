// SQLite
// import { drizzle } from 'drizzle-orm/better-sqlite3';
// import Database from 'better-sqlite3';
// import { migrate } from "drizzle-orm/better-sqlite3/migrator";

// const sqlite = new Database('dev.db');
// const sqlite = new Database(":memory:");

// const db = drizzle(sqlite);
// migrate(db);

// Postgres
import { drizzle } from 'drizzle-orm/postgres-js';
// import { migrate } from 'drizzle-orm/postgres-js/migrator';
import postgres from 'postgres';
import { DB_USER, DB_PASS, DB_HOST, DB_PORT, DB_NAME } from '../../config.mjs'

// const client = postgres(`postgres://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}`);
const client = postgres({
  user: DB_USER,
  pass: DB_PASS,
  host: DB_HOST,
  port: Number(DB_PORT),
  database: DB_NAME,
});
const db = drizzle(client);

export default db

export { default as schemaPokemon } from './schema-pokemon.mjs'
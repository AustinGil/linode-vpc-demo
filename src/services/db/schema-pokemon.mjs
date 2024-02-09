// import { sql } from "drizzle-orm";

// SQLite
// import { sqliteTable, text, integer } from "drizzle-orm/sqlite-core";
// const pokemon = sqliteTable('pokemon', {
//   ...
// })

// Postgres
import { pgTable, integer, text } from "drizzle-orm/pg-core";

// export const pokemonTypes = /** @type {const} */ (["normal", "fire", "water", "electric", "grass", "ice", "fighting", "poison", "ground", "flying", "psychic", "bug", "rock", "ghost", "dragon", "dark", "steel", "fairy",])

const pokemon = pgTable('pokemon', {
  id: integer('id').primaryKey(),
  name: text('name'),
  // textModifiers: text('text_modifiers').notNull().default(sql`CURRENT_TIMESTAMP`),
  // intModifiers: integer('int_modifiers', { mode: 'boolean' }).notNull().default(false),
  type: text('type'),
  // type: text('type', { enum: pokemonTypes }),
  hp: integer('hp'),
  attack: integer('attack'),
  defense: integer('defense'),
  spAttack: integer('sp_attack'),
  spDefense: integer('sp_defense'),
  speed: integer('speed'),
});

export default pokemon
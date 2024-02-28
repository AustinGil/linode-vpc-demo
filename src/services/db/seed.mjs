import db, { schemaPokemon }from "./index.mjs";

const pokemon = [
  {
    "id": 1,
    "name": "Allilord",
    "type": [
      "grass",
      "poison"
    ],
    "hp": 45,
    "attack": 49,
    "defense": 49,
    "spAttack": 65,
    "spDefense": 65,
    "speed": 45
  },
  {
    "id": 2,
    "name": "Gazelax",
    "type": [
      "grass",
      "poison"
    ],
    "hp": 60,
    "attack": 62,
    "defense": 63,
    "spAttack": 80,
    "spDefense": 80,
    "speed": 60
  },
  {
    "id": 3,
    "name": "Dragius",
    "type": [
      "grass",
      "poison"
    ],
    "hp": 80,
    "attack": 82,
    "defense": 83,
    "spAttack": 100,
    "spDefense": 100,
    "speed": 80
  },
  {
    "id": 4,
    "name": "Jagevoir",
    "type": [
      "fire"
    ],
    "hp": 39,
    "attack": 52,
    "defense": 43,
    "spAttack": 60,
    "spDefense": 50,
    "speed": 65
  },
  {
    "id": 5,
    "name": "Hippomish",
    "type": [
      "fire"
    ],
    "hp": 58,
    "attack": 64,
    "defense": 58,
    "spAttack": 80,
    "spDefense": 65,
    "speed": 80
  },
  {
    "id": 6,
    "name": "Dinobite",
    "type": [
      "fire",
      "flying"
    ],
    "hp": 78,
    "attack": 84,
    "defense": 78,
    "spAttack": 109,
    "spDefense": 85,
    "speed": 100
  },
  {
    "id": 7,
    "name": "Komodix",
    "type": [
      "water"
    ],
    "hp": 44,
    "attack": 48,
    "defense": 65,
    "spAttack": 50,
    "spDefense": 64,
    "speed": 43
  },
  {
    "id": 8,
    "name": "Chimpola",
    "type": [
      "water"
    ],
    "hp": 59,
    "attack": 63,
    "defense": 80,
    "spAttack": 65,
    "spDefense": 80,
    "speed": 58
  },
  {
    "id": 9,
    "name": "Magirilla",
    "type": [
      "water"
    ],
    "hp": 79,
    "attack": 83,
    "defense": 100,
    "spAttack": 85,
    "spDefense": 105,
    "speed": 78
  }
]

const main = async () => {
  console.log("Seed start");
  const pokes = pokemon.map(p => {
    return {
      ...p,
      type: p.type.join(',')
    }
  })
  await db
    .insert(schemaPokemon)
    .values(pokes)
    .onConflictDoNothing({ target: schemaPokemon.id }); 
  console.log("Seed done");
};

main().then(() => {
  process.exit()
})
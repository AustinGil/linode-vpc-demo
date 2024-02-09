import { component$ } from "@builder.io/qwik";
import { routeLoader$ } from '@builder.io/qwik-city';
import db, { schemaPokemon } from '../services/db/index.mjs'
import { Pill } from "~/components";

export const usePokemonData = routeLoader$(async () => {
  const res = await db.select().from(schemaPokemon);
  return res
});

export default component$(() => {
  const result = usePokemonData();

  const tableDataMapper = {
    id: "ID",
    name: "Name",
    type: "Type",
    hp: "HP",
    attack: "Attack",
    defense: "Defense",
    spAttack: "Sp. Attack",
    spDefense: "Sp. Defense",
    speed: "Speed"
  } as const

  return (
    <>
      <main class="h-screen bg-gray-200">
        <div class="container p-8 mx-auto">
          <h1 class="text-3xl font-medium text-gray-700">Dashboard</h1>

          <div class="overflow-x-auto mt-8 sm:rounded-lg border-b border-gray-200 shadow">
            <table class="min-w-full">
              <thead>
                  <tr class="text-xs font-medium leading-4 tracking-wider text-left text-gray-500 uppercase border-b border-gray-200 bg-gray-50">
                    {Object.values(tableDataMapper).map((text) => <th key={text} class="px-6 py-3">{text}</th> )}
                  </tr>
              </thead>

              <tbody class="bg-white">
                {!result.value.length && (
                  <tr><td class="px-6 py-4 text-center" colSpan={Object.values(tableDataMapper).length}>No Entries</td></tr>
                )}
                {result.value.map(p => {
                  return <tr key={p.id} class="whitespace-no-wrap border-b border-gray-200 text-sm leading-5 text-gray-900">
                    {Object.keys(tableDataMapper).map((key) => (
                      <td
                        key={key}
                        class={{
                          "px-6 py-4": true,
                          "font-medium": key === 'id',
                        }}
                      >
                        {'type' === key && (
                          <div class="flex gap-1">
                            {p.type?.split(',').map(type => (
                              <Pill 
                                key={type}
                                color={
                                  type === 'grass' ? 'green' :
                                  type === 'fire' ? 'red' :
                                  type === 'water' ? 'blue' :
                                  type === 'poison' ? 'purple' :
                                  type === 'flying' ? 'cyan' : ''
                                }
                              >
                                {type}
                              </Pill>
                            ))}
                          </div>
                        )}
                        {'id' === key && p.id.toString().padStart(4, '0')}
                        {!['id', 'type'].includes(key) && p[key as keyof typeof tableDataMapper]}
                      </td>
                    ))}
                  </tr>
                })}
              </tbody>
            </table>
          </div>
        </div>
      </main>
    </>
  );
});


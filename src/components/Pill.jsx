import { component$, Slot } from "@builder.io/qwik";

/**
 * @typedef {import('@builder.io/qwik').QwikIntrinsicElements['span']} SpanAttributes
 */

/**
 * @type {Component<SpanAttributes  & {
 * color: 'red'|'green'|'blue'|'cyan'|'purple'|'',
 * class?: string
 * }>}
 */

const component = component$(({ color, class: className, ...attrs }) => {
  return (
    <span
      class={{
        [String(className)]: !!className,
        'rounded-xl px-2 py-1': true,
        "text-red-800 bg-red-100": color === 'red',
        "text-green-800 bg-green-100": color === 'green',
        "text-blue-800 bg-blue-100": color === 'blue',
        "text-cyan-800 bg-cyan-100": color === 'cyan',
        "text-purple-800 bg-purple-100": color === 'purple',
      }}
      {...attrs}
    >
      <Slot />
    </span>
  );
});

export default component
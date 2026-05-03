# React

Reads on top of [`10-javascript-node.md`](10-javascript-node.md). Everything there applies; this adds React-specific rules.

## Components

- **Function components only.** No class components in new code.
- **One component per file**, file named `PascalCase.tsx`. Co-locate `PascalCase.test.tsx` and `PascalCase.module.css` (or equivalent).
- Components render UI; they don't fetch in render. Use a hook for fetching.
- Component props are typed (`interface Props { ... }` or `type Props = { ... }`). No untyped props.
- Don't return more than one element from a render without a Fragment (`<>...</>`).
- Components stay small — if a component file passes ~150 lines, extract subcomponents or a hook.

## Hooks

- Follow the rules of hooks. ESLint plugin `react-hooks` is required.
- Custom hooks live in `useXxx.ts` and start with `use`.
- `useEffect` dependency arrays must be exhaustive. If you need to lie, document why on the same line.
- Don't put fetching logic in `useEffect` for new code — use TanStack Query, RTK Query, or SWR.
- `useMemo` / `useCallback` only when there is a measured perf reason. They are not free.
- Side effects belong in `useEffect`, not in render or event handlers' setState chains.

## State

- Default: local component state via `useState` / `useReducer`.
- Lift state only as far as necessary. Don't push everything into a global store.
- For complex local state with many transitions, prefer `useReducer` over many `useState` calls.
- Server state (data from APIs) goes in TanStack Query / RTK Query — not in Redux/Zustand alongside client state.
- Global client state (auth, theme) uses one of: React Context (small), Zustand (medium), Redux Toolkit (large legacy). Pick one per project.
- Forms: React Hook Form. Don't roll your own.

## Styling

Pick **one** styling approach per project and document it in the README. Acceptable:

- Tailwind CSS
- CSS Modules
- Styled-components / Emotion
- Vanilla CSS in a strict folder structure

Forbidden:

- Inline `style={{...}}` for anything beyond dynamic, computed values
- Global stylesheets that leak across components (use modules / scoping)
- Mixing two of the above approaches in the same project

## Routing & data

- Routing: React Router (SPA) or the framework's router (Next.js, Remix).
- Code-split by route. `React.lazy` + `Suspense` for SPAs.
- Loading and error states are mandatory — `if (isLoading) return ...; if (error) return ...;` is not optional.
- Don't `catch` errors and render `null`. Show a real error UI.

## Accessibility

Non-negotiable minimums:

- Semantic HTML. `<button>` for clickables; never `<div onClick>`.
- All form inputs have an associated `<label>` or `aria-label`.
- All images have `alt` text (`alt=""` for purely decorative images).
- Focus is visible and logical. Don't disable focus outlines without a replacement.
- Color is not the only carrier of meaning (errors get an icon and text, not just red).
- Run `eslint-plugin-jsx-a11y`. Fix violations, don't disable them.

## Performance

- Don't optimize what you haven't measured (React DevTools profiler).
- The biggest wins: not rendering at all (virtualize long lists with TanStack Virtual / react-window), avoiding waterfall fetches (parallelize on mount), and code-splitting routes.
- Memoization (`React.memo`, `useMemo`) is a last resort, not a default.

## Project layout

```
src/
  features/
    users/
      UserList.tsx
      UserList.test.tsx
      useUsers.ts
      users.api.ts
      users.types.ts
  components/         # cross-feature presentational components
  hooks/              # cross-feature hooks
  lib/                # cross-feature utilities (no React)
  routes/             # route definitions / pages (or app/ for Next.js)
```

## Don't do

- `dangerouslySetInnerHTML` without a sanitizer (DOMPurify) — and document why
- Index as a key in a `.map` over reorderable lists — use a stable id
- Calling a setter unconditionally inside `useEffect` without a guard — infinite loop
- Passing entire objects through props when the child only needs two fields
- Wrapping every component in `React.memo` "just in case"

# CLAUDE.md — Frontend Engineering Standards
> This file is automatically loaded by **Claude Code** and **OpenAI Codex**.
> It defines the rules, patterns, and guardrails every developer and AI agent MUST follow.
> Treat this file like code: review it, version it, and update it when practices change.

---

## ⚡ GOLDEN RULE — When In Doubt, Ask

**NEVER assume. NEVER guess. NEVER hallucinate a library, API, config key, or design token.**

If any of the following are unclear, stop and ask the developer before writing a single line:
- The target framework version (React 18 vs 19, Next.js 14 vs 15, etc.)
- Whether a library is already installed or approved
- The existing design system / token structure
- The auth strategy, API base URL, or data-fetching pattern in use
- Any business logic that is not explicitly described

---

## 1. Project Layout — Consistent Structure Across the Entire Site

Every project MUST follow this directory convention. Do not deviate without team agreement.

```
project-root/
├── public/                  # Static assets (favicon, robots.txt, sitemap.xml)
├── src/
│   ├── app/                 # Route files (Next.js App Router) OR pages/
│   ├── components/
│   │   ├── ui/              # Primitive, reusable atoms (Button, Input, Modal…)
│   │   ├── layout/          # Shell components (Header, Footer, Sidebar, PageWrapper)
│   │   └── features/        # Domain-scoped composites (UserCard, ProductGrid…)
│   ├── hooks/               # All custom React hooks (useAuth, useForm, useFetch…)
│   ├── lib/                 # Pure utilities, helpers, formatters
│   ├── services/            # API call functions (no UI logic here)
│   ├── store/               # Global state (Zustand / Redux slices)
│   ├── styles/              # Global CSS, design tokens, CSS variables
│   │   ├── globals.css
│   │   └── tokens.css       # All CSS custom properties live here
│   ├── types/               # Shared TypeScript interfaces and enums
│   └── constants/           # App-wide constants (routes, config keys, enums)
├── .env.local               # Local secrets — NEVER commit
├── .env.example             # Template with all keys, empty values — ALWAYS commit
├── .env.development
├── .env.production
└── CLAUDE.md                # This file
```

**Rules:**
- Page-level components live in `app/` or `pages/` only — never import them into other components.
- A component file that grows beyond **500 lines** MUST be split. No exceptions.
- One component per file. File name = component name (PascalCase).

---

## 2. Environment Variables — Always Use `.env`

### MUST DO
- All environment-dependent values (API URLs, keys, flags, timeouts) go in `.env.*` files.
- Use the framework's env prefix (`NEXT_PUBLIC_` for Next.js, `VITE_` for Vite) for client-exposed vars.
- Commit `.env.example` with every key present but values empty or clearly fake.
- Never hardcode URLs, tokens, credentials, or feature flags inline in source code.

### MUST NOT DO
- Never commit `.env.local`, `.env.development`, or `.env.production` with real secrets.
- Never `console.log` an env variable — not even in development.
- Never access `process.env.SOME_KEY` directly in components — wrap it in `src/lib/env.ts`.

```ts
// src/lib/env.ts — single source of truth for env access
export const env = {
  apiBaseUrl: process.env.NEXT_PUBLIC_API_BASE_URL ?? '',
  appEnv: process.env.NEXT_PUBLIC_APP_ENV ?? 'development',
} as const;
```

---

## 3. Component Rules — Modular, Derived, Under 500 Lines

### Size Limit
- **Hard limit: 500 lines per component file.**
- At ~300 lines, start planning the split.
- Extract sub-sections into named sub-components in the same `features/` folder.

### Composition Pattern
```tsx
// ✅ CORRECT — derived, composable
// features/UserProfile/index.tsx          (orchestrator, < 80 lines)
// features/UserProfile/UserAvatar.tsx     (pure display)
// features/UserProfile/UserStats.tsx      (pure display)
// features/UserProfile/useUserProfile.ts  (all state + side-effects)

// ❌ WRONG — monolith
// features/UserProfile.tsx  (600 lines mixing UI + logic + API calls)
```

### Component Checklist
- [ ] Props are typed with a named TypeScript interface, not inline `{}` literals.
- [ ] Default prop values are declared at the parameter level, not with `defaultProps`.
- [ ] No raw `fetch` / `axios` calls inside components — use a hook or service function.
- [ ] No magic strings — use constants from `src/constants/`.
- [ ] Components are pure where possible; side effects are isolated in hooks.
- [ ] Every interactive element is keyboard-accessible and has an `aria-label` where needed.

---

## 4. Design System — Common Classes, Tokens, and Palette

**Never hardcode a hex color, pixel size, font name, or z-index number in a component.**
All design values are defined once in `src/styles/tokens.css` and consumed via CSS variables.

### Token Structure (example — adapt to project)
```css
/* src/styles/tokens.css */
:root {
  /* Colors */
  --color-primary:        #1D4ED8;
  --color-primary-hover:  #1E40AF;
  --color-secondary:      #7C3AED;
  --color-surface:        #FFFFFF;
  --color-surface-muted:  #F9FAFB;
  --color-border:         #E5E7EB;
  --color-text:           #111827;
  --color-text-muted:     #6B7280;
  --color-error:          #DC2626;
  --color-success:        #16A34A;
  --color-warning:        #D97706;

  /* Spacing */
  --space-1: 4px;   --space-2: 8px;   --space-3: 12px;
  --space-4: 16px;  --space-6: 24px;  --space-8: 32px;
  --space-12: 48px; --space-16: 64px;

  /* Typography */
  --font-sans:    'Inter Variable', system-ui, sans-serif;
  --font-mono:    'JetBrains Mono', monospace;
  --text-xs: 12px; --text-sm: 14px; --text-base: 16px;
  --text-lg: 18px; --text-xl: 20px; --text-2xl: 24px;
  --text-3xl: 30px; --text-4xl: 36px;
  --leading-tight: 1.25; --leading-normal: 1.5;
  --font-normal: 400; --font-medium: 500;
  --font-semibold: 600; --font-bold: 700;

  /* Radius */
  --radius-sm: 4px; --radius-md: 8px;
  --radius-lg: 12px; --radius-full: 9999px;

  /* Shadows */
  --shadow-sm: 0 1px 2px rgba(0,0,0,0.05);
  --shadow-md: 0 4px 6px rgba(0,0,0,0.07);
  --shadow-lg: 0 10px 15px rgba(0,0,0,0.10);

  /* Z-index scale */
  --z-base: 0; --z-dropdown: 100; --z-sticky: 200;
  --z-overlay: 300; --z-modal: 400; --z-toast: 500;

  /* Transitions */
  --transition-fast: 150ms ease;
  --transition-base: 250ms ease;
  --transition-slow: 400ms ease;
}
```

> If the project uses Tailwind, extend `tailwind.config.ts` to map these tokens — do NOT inline arbitrary values with `text-[#1D4ED8]`.

---

## 5. Common Input Components — Build Once, Reuse Everywhere

All form inputs MUST come from `src/components/ui/`. Never build a one-off input inside a feature.

### Required UI Primitives
Create these before building any form in the project:

| Component | Props to support |
|-----------|-----------------|
| `<Input>` | `label`, `name`, `type`, `value`, `onChange`, `error`, `hint`, `disabled`, `required`, `placeholder`, `prefix`, `suffix` |
| `<Textarea>` | Same as Input + `rows`, `maxLength`, `showCount` |
| `<Select>` | `label`, `name`, `options`, `value`, `onChange`, `error`, `disabled`, `placeholder` |
| `<Checkbox>` | `label`, `name`, `checked`, `onChange`, `disabled`, `error` |
| `<RadioGroup>` | `label`, `name`, `options`, `value`, `onChange`, `disabled` |
| `<Switch>` | `label`, `name`, `checked`, `onChange`, `disabled` |
| `<DatePicker>` | `label`, `name`, `value`, `onChange`, `min`, `max`, `error` |
| `<FileUpload>` | `label`, `name`, `accept`, `multiple`, `maxSize`, `onChange`, `error` |
| `<Button>` | `variant` (primary/secondary/ghost/danger), `size`, `loading`, `disabled`, `type`, `icon` |
| `<FormField>` | Wrapper: renders label + input + error message in consistent layout |

### Input Contract Rules
- Every input MUST display its `error` prop below the field in `--color-error`.
- Every input MUST have an associated `<label>` — never a placeholder-only field.
- Controlled inputs only — no uncontrolled inputs without explicit justification.
- Use `react-hook-form` or `formik` for form state — never manage field state manually in a page.

---

## 6. Build Checks — Run on Every Commit and Feature Branch

### Pre-commit (run automatically via Husky + lint-staged)
```bash
npm run lint          # ESLint — zero warnings, zero errors
npm run type-check    # tsc --noEmit
npm run format:check  # Prettier
```

### Pre-push / CI
```bash
npm run build         # Must succeed with zero errors
npm run test          # Unit + integration tests
npm run test:e2e      # Playwright / Cypress smoke suite (at minimum)
```

### AI Agent Rule
After making ANY code change — new feature, refactor, bug fix, dependency update — run:
```bash
npm run build && npm run lint && npm run type-check
```
Do not present the work as complete until all three pass.

---

## 7. SEO — Required on Every Page

### `<head>` Tag Minimum Requirements
Every page MUST include:

```html
<!-- Identity -->
<html lang="en">         <!-- Set correct locale per page/region -->
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">

<!-- SEO essentials -->
<title>Page Title — Under 60 chars — Brand Name</title>
<meta name="description" content="150–160 chars. Clear, keyword-rich, unique per page.">
<link rel="canonical" href="https://yourdomain.com/current-page">

<!-- Open Graph (social sharing) -->
<meta property="og:title" content="Page Title">
<meta property="og:description" content="Page description">
<meta property="og:image" content="https://yourdomain.com/og-image.png">  <!-- 1200×630px -->
<meta property="og:url" content="https://yourdomain.com/current-page">
<meta property="og:type" content="website">
<meta property="og:site_name" content="Brand Name">

<!-- Twitter / X Card -->
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="Page Title">
<meta name="twitter:description" content="Page description">
<meta name="twitter:image" content="https://yourdomain.com/og-image.png">

<!-- Favicon -->
<link rel="icon" href="/favicon.ico" sizes="any">
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
<link rel="manifest" href="/site.webmanifest">
```

### Heading Hierarchy Rules
- One `<h1>` per page — contains the primary keyword.
- Logical order: `h1 → h2 → h3`. Never skip levels.
- Headings describe content structure, not styling. Never use a heading just to make text big.

### Semantic HTML Rules
```html
<!-- ❌ WRONG -->
<div class="header">  <div class="nav">  <div class="main">  <div class="footer">

<!-- ✅ CORRECT -->
<header>  <nav>  <main>  <footer>  <article>  <section>  <aside>
```

### URL Structure
- Use clean, descriptive slugs: `/blog/seo-checklist` not `/blog?id=123`
- Maximum 3 URL depth levels for important content
- Use hyphens, not underscores: `/about-us` not `/about_us`

### Structured Data
Add `application/ld+json` schema where relevant (Article, Product, FAQ, BreadcrumbList, Organization).

---

## 8. Image Optimization — No Raw `<img>` Tags in Production

### Rules
- Use the framework image component — `<Image>` in Next.js, `<img>` with explicit `width` + `height` + `loading` otherwise.
- Always provide descriptive `alt` text. Decorative images use `alt=""` (not missing).
- Use **WebP** or **AVIF** as the primary format. Fall back to JPEG/PNG only when necessary.
- Serve responsive images with `srcset` and `sizes` attributes.
- Images **above the fold**: use `priority` / `loading="eager"`.
- Images **below the fold**: use `loading="lazy"`.
- Never embed a >100KB image without compression. Run through `squoosh`, `sharp`, or CI pipeline.
- Store images in a CDN, not in the Git repo.

```tsx
// ✅ Next.js
<Image
  src="/hero.webp"
  alt="Team collaborating on a project dashboard"
  width={1200}
  height={600}
  priority          // above-the-fold hero image
  sizes="(max-width: 768px) 100vw, 1200px"
/>

// ✅ Vanilla HTML
<img
  src="card.webp"
  srcset="card-400.webp 400w, card-800.webp 800w"
  sizes="(max-width: 480px) 100vw, 50vw"
  alt="Product packaging in matte black"
  width="800" height="600"
  loading="lazy"
  decoding="async"
/>
```

---

## 9. Performance — Lighthouse Score Targets

| Metric | Target | Hard Minimum |
|--------|--------|-------------|
| Performance | 90+ | 80 |
| Accessibility | 100 | 95 |
| Best Practices | 100 | 95 |
| SEO | 100 | 95 |
| LCP (Largest Contentful Paint) | < 2.5s | < 4.0s |
| CLS (Cumulative Layout Shift) | < 0.1 | < 0.25 |
| INP (Interaction to Next Paint) | < 200ms | < 500ms |

### Performance Rules
- Enable **code splitting** — `React.lazy()` + `Suspense` for every route and heavy component.
- Enable **tree shaking** — import named exports, never `import * as Lib from 'big-lib'`.
- Use **dynamic imports** for third-party widgets (maps, rich text editors, charts).
- Avoid **layout shifts**: always specify `width` and `height` on images and video embeds.
- Preload critical fonts with `<link rel="preload" as="font">`.
- Use `font-display: swap` for all web fonts.
- Remove unused CSS — audit with PurgeCSS or the framework's built-in tree shaking.
- Enable **gzip / Brotli** compression at the server or CDN level.

### What to Check Before Merging
1. Run `npx lighthouse <URL> --output=json` or open Chrome DevTools → Lighthouse.
2. Check bundle size with `npm run build` and inspect output. Warn if a chunk exceeds 250KB gzipped.
3. Check for render-blocking resources in the Lighthouse report.

---

## 10. Accessibility (a11y) — Non-Negotiable

- All interactive elements (`button`, `a`, `input`) are reachable by keyboard (`Tab`/`Enter`/`Space`).
- Color contrast ratio: **4.5:1** for normal text, **3:1** for large text (WCAG AA).
- All images have `alt`. All form fields have `<label>`. All icons used as buttons have `aria-label`.
- ARIA roles are used only where native HTML semantics are insufficient.
- Modals trap focus while open and restore focus on close.
- Avoid `outline: none` or `outline: 0` without a custom focus style replacement.
- Test with keyboard-only navigation before shipping any new interactive component.

---

## 11. Dependency Management — Approved Libraries Only

### Before Adding Any Package, Ask:
1. Is there already a utility in the project that does this?
2. Is there a native browser/framework API that covers this?
3. When was this package last published? Is it actively maintained?
4. What is its bundle size? (Check bundlephobia.com)
5. Does it have a permissive license (MIT, Apache 2.0)?

### NEVER Install
- Packages with no updates in >2 years (unless deliberately stable)
- Multiple packages that do the same thing (e.g., both `moment` and `date-fns`)
- Packages flagged for security issues in `npm audit`
- Packages that require polyfills for >10% of your target browsers

### Prefer
| Category | Preferred Choice |
|----------|-----------------|
| Date handling | `date-fns` or `dayjs` (not moment) |
| HTTP client | `fetch` (native) or `axios` if interceptors needed |
| State management | `zustand` (light) or `redux-toolkit` (complex) |
| Forms | `react-hook-form` |
| Validation | `zod` |
| Animations | CSS transitions first; `framer-motion` if complex |
| Icons | Single icon library per project (lucide-react, heroicons) |
| Tables | `tanstack-table` |
| Charts | `recharts` or `chart.js` |

---

## 12. TypeScript Rules

- `strict: true` in `tsconfig.json`. No exceptions.
- No `any` — use `unknown` and narrow it. If you must escape, use `// eslint-disable-next-line @typescript-eslint/no-explicit-any` with a comment explaining why.
- Prefer `interface` for object shapes, `type` for unions/intersections.
- All API response shapes must be typed. Use `zod` to validate and infer types from real responses.
- No `as SomeType` casts unless the value has been validated.
- Export types from a central `src/types/` barrel file.

---

## 14. Security Baseline

- Use **HTTPS only**. Redirect all HTTP traffic.
- Set security headers: `Content-Security-Policy`, `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy`.
- Sanitize all user-generated content before rendering. Use `DOMPurify` if rendering HTML.
- Never trust client-side data for authorization — validate on the server.
- Use `rel="noopener noreferrer"` on every `target="_blank"` link.
- `npm audit --audit-level=high` must pass in CI.
- Store auth tokens in `httpOnly` cookies, not `localStorage`.

---

## 15. Responsive Design Rules

- **Mobile-first** CSS. Base styles target mobile; `@media (min-width: ...)` scales up.
- Test at these breakpoints minimum: 375px, 768px, 1024px, 1440px.
- Never use fixed-width containers without a `max-width` cap.
- Touch targets (buttons, links) must be at least **44×44px**.
- Text must remain readable at default browser zoom (100%) and 200% zoom.
- No horizontal scroll on any breakpoint below 1440px.

---

## 16. Error Handling — Every Layer

```
UI Layer:      React Error Boundaries around every route and major feature area
Async Layer:   Every fetch / mutation has loading, error, and empty states
Form Layer:    Every field shows inline validation errors (not just toast alerts)
Network Layer: Retry logic for transient failures; graceful fallback for total failures
404/500:       Custom error pages with helpful navigation back to safe ground
```

- Never show raw error messages or stack traces to end users.
- Log errors to a monitoring service (Sentry, Datadog) — not just `console.error`.

---

## 17. Testing Standards

| Layer | Tool | When Required |
|-------|------|--------------|
| Unit | Vitest / Jest | All utility functions, hooks, services |
| Component | React Testing Library | All `ui/` primitives |
| Integration | React Testing Library | Feature flows (form submit, auth state) |
| E2E | Playwright | Critical user journeys (login, checkout, signup) |

- Tests live next to source: `Button.tsx` + `Button.test.tsx`
- Coverage target: **70% minimum** on `src/` (excluding generated files and `*.d.ts`)
- No snapshot tests for interactive components — test behavior, not markup.

# CreatorVerse AI

Premium AI education platform — built and owned by **Cletus Tech**.

> Learn AI. Create Without Limits. Build Your Future.

---

## Tech Stack

- **Next.js 14** (App Router) + **React 18** + **TypeScript**
- **Tailwind CSS** for styling
- **Framer Motion** patterns (CSS keyframe equivalents are pre-wired in `tailwind.config.js`; swap in `<motion.div>` where you want JS-driven animation)
- **Lucide React** icons

## Getting Started

```bash
npm install
npm run dev
```

Open http://localhost:3000.

> **Note:** `package-lock.json` is not included because this project was generated in a sandboxed environment without npm registry access. Running `npm install` will generate it on your machine — commit it afterward for reproducible installs.

## Project Structure

```
src/
  app/                 → Next.js App Router pages (one folder per route)
    (auth)/            → login, register, forgot-password, reset-password, verify-email
    courses/[slug]/    → dynamic course detail page
    dashboard/         → student dashboard
    admin/             → admin dashboard
    settings/          → account settings
    layout.tsx         → root layout (fonts, Navbar, Footer)
    page.tsx           → landing page
    not-found.tsx       → 404 page
  components/
    layout/            → Navbar, Footer
    ui/                → Button, GlassCard, Badge, Accordion, PageHero, Eyebrow
    home/               → Hero, HeroBackground, FounderCard, SkillsGrid, SocialIcons
    auth/               → AuthShell, PasswordInput, PasswordStrength, GoogleButton
    dashboard/          → DashboardShell, StatCard
  lib/                 → constants, utils, auth.ts (stub), sample data
  hooks/               → useScrolled, useCountdown
  types/               → shared TypeScript interfaces
  middleware.ts        → route protection (prepared, currently inert)
```

## Pages

Landing, About, Courses, Course Details, Community, Showcase, Prompt Library,
AI Tools, Resources, Contact, FAQ, Student Dashboard, Admin Dashboard,
Settings, Login, Register, Forgot Password, Reset Password, Email
Verification, and a custom 404.

## Authentication — Development Mode

Authentication is **architected but intentionally disabled** so the whole
site can be reviewed without logging in:

- All pages render with mock/sample data.
- `src/lib/auth.ts` defines the full interface (`signInWithEmail`,
  `signInWithGoogle`, `registerWithEmail`, `requestPasswordReset`,
  `resetPassword`, `resendVerificationEmail`, `signOut`, `getSession`) as
  typed placeholders — wire each one up to your real backend/provider when
  ready.
- `src/middleware.ts` already contains route-protection logic for
  `/dashboard`, `/admin`, and `/settings`. It's a no-op while
  `AUTH_ENABLED` (in `src/lib/constants.ts`) is `false`.

**To go live with auth:** implement the functions in `lib/auth.ts`, set
`AUTH_ENABLED = true`, and replace the cookie check in `middleware.ts` with
your real session check.

## Brand & Contact

All brand, social, and contact details live in one place:
`src/lib/constants.ts`. Update them there and they propagate across the
Navbar, Footer, Contact page, and auth screens.

- Email: cletustech25@gmail.com
- Phone: +2349021344162
- WhatsApp: +2349066528682
- TikTok / Facebook / YouTube: Cletus Tech
- Instagram: Cletus_tech

## Deployment

### Vercel (recommended)

1. Push this repo to GitHub.
2. Import it in Vercel — it auto-detects Next.js via `vercel.json`.
3. Deploy. No environment variables are required in development mode.

### GitHub

```bash
git init
git add .
git commit -m "Initial commit — CreatorVerse AI"
git branch -M main
git remote add origin <your-repo-url>
git push -u origin main
```

## Scripts

| Command           | Description                  |
| ------------------ | ----------------------------- |
| `npm run dev`       | Start local dev server        |
| `npm run build`     | Production build              |
| `npm run start`     | Start production server       |
| `npm run lint`      | Run ESLint                    |
| `npm run typecheck` | Run TypeScript without emitting |

---

© CreatorVerse AI — a Cletus Tech product.

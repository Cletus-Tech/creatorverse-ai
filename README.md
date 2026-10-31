# CreatorVerse AI

Static site in `public/`. No build step.

## Structure
- `public/` — the website (this folder is what gets published)
- `reference/` — original untouched landing page (design reference, do not edit)
- `.github/workflows/deploy-pages.yml` — deploys `public/` to GitHub Pages on push to `main`
- `MASTER_PROJECT_PLAN.md` — replace the placeholder with your original
- `PROJECT_CHANGELOG.md` — progress, decisions, status

## Deploy (GitHub Pages)
1. Push to the `main` branch.
2. Repo → Settings → Pages → Source: **GitHub Actions**.
3. Repo → Actions tab → the "Deploy site to GitHub Pages" run → open the site link.

## Deploy (Cloudflare Pages instead)
Connect the repo, build command: none, output directory: `public`.

## Phone tips
- A `.zip` uploaded to GitHub is NOT unpacked. Unzip first (`unzip file.zip`), then push the files.
- Hidden folders (`.github`) can be missed by Android file pickers. If the workflow is missing in the repo,
  create `.github/workflows/deploy-pages.yml` via GitHub → Add file → Create new file, and paste the contents
  of `github-workflow-copy/deploy-pages.yml.txt`.
- Termux: `git init -b main && git add -A && git commit -m "Phase 0" && git remote add origin <url> && git push -u origin main`

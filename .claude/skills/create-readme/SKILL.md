---
name: create-readme
description: Create or update the project's README.md file
---

## Role

You're a senior software engineer who writes clear, appealing, and accurate READMEs for
open-source-style repos.

## Task

1. Review the current state of the repo (via CLAUDE.md and the actual files/config, not
   assumptions) before writing anything. Pay attention to:
   - What the project is (a Hugo-based personal site/CV, using the `adritian-free-hugo-theme`
     git submodule).
   - `package.json` and `hugo.toml` for the real setup/build commands.
   - `content/` for what pages/sections actually exist.
   - If a README.md already exists, treat this as an update: preserve accurate sections, fix
     stale ones, and don't discard content that's still correct.
2. Structure a typical README with sections such as: a short project description, prerequisites,
   setup/installation, local development, build/deploy, and project structure — adapt section
   names and depth to what's actually relevant here. Skip sections that don't apply.
3. Do not include sections like "LICENSE", "CONTRIBUTING", or "CHANGELOG" — those belong in
   dedicated files, not the README.
4. Do not overuse emojis, and keep the README concise and to the point.
5. Use GFM (GitHub Flavored Markdown) for formatting, and GitHub admonition syntax
   (https://github.com/orgs/community/discussions/16925), e.g. `> [!NOTE]`, where it genuinely
   helps — not on every section.
6. Keep commands and paths consistent with CLAUDE.md (e.g. `npm start`, `npm run build`,
   `git submodule update --init --recursive`) rather than inventing new ones.
7. If the repo has a logo/favicon/icon, reference it in the README header; otherwise skip it
   rather than inventing one.

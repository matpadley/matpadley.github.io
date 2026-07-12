# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal site/CV for Mathew Padley (matpadley.github.io), built with Hugo using the
`adritian-free-hugo-theme` (a git submodule at `themes/adritian-free-hugo-theme`). The repo holds
content, config, a handful of site-specific layout overrides, and the theme submodule — `data/` and
`static/` are currently empty; `assets/` has one file (`assets/css/custom.css`).

## Commands

```bash
npm install          # install JS deps (bootstrap, bootstrap-print-css) needed by the theme's asset pipeline
npm start            # hugo server — local dev server with drafts/live reload
npm run build        # hugo --gc --minify — production build into ./public
```

Useful ad-hoc commands (no test suite exists in this repo):

```bash
hugo server -D                     # serve including draft content
hugo new experience/some-role.md   # scaffold new content from archetypes/
```

Requires Hugo (extended edition) — match the version pinned in `.github/workflows/hugo.yml`
(`0.157.0`) when testing locally. The theme is a submodule — after cloning or switching branches,
run `git submodule update --init --recursive` if `themes/adritian-free-hugo-theme` is empty.

CI (`.github/workflows/hugo.yml`) builds with `hugo --gc --minify --baseURL <pages-url>` and deploys
to GitHub Pages on every push to `main`. It checks out submodules recursively and runs `npm ci` before
building — match that when testing locally (`npm ci` + `hugo --gc --minify`) if verifying a CI-equivalent build.

## Content architecture

Content lives in `content/`, organized by Hugo content type (each maps to a theme layout/shortcode):

- `content/home/home.md` — homepage, built from theme shortcodes (`showcase-section`, `about-section`,
  `experience-section`, `platform-links`) rather than free-form prose.
- `content/cv.md` — the `/cv` page. Free-form markdown plus `{{< experience-list >}}` and
  `{{< education-list >}}` shortcodes that pull structured data from `content/experience/*.md` and
  `content/education/*.md`.
- `content/experience/*.md` — one file per job, with front matter (`date`, `title`, `jobTitle`,
  `company`, `location`, `duration`) rendered by the theme's experience layout/shortcode. `_index.md`
  holds the section intro text.
- `content/education/*.md` — same pattern (`university`, `year`, `degree` front matter), plus `_index.md`.
- `content/articles/` — blog-style posts; `_index.md` is the section page. Rendered with the
  site-specific layouts in `layouts/articles/` (see below), not the theme's default blog templates.
- `content/news/` — a second, separate blog-style section (AI-coding-tools news commentary), with
  its own `_index.md`. Uses the theme's default list/single templates (no overrides), unlike `articles/`.
- `content/footer/footer.md` — footer content, built with the `contact-section` shortcode (Formspree-backed
  contact form).

**Multi-language content**: the site is served in English (default), French, and Spanish
(`hugo.toml` `[languages]`). Translated content uses Hugo's language-suffix convention:
`cv.md` (en) / `cv.fr.md` / `cv.es.md`, `_index.md` / `_index.fr.md` / `_index.es.md`, etc. When
editing any content file, check for and update its `.fr.md` / `.es.md` siblings so translations don't
drift. UI string translations (not page content) live in `i18n/en.yaml`, `i18n/fr.yaml`, `i18n/es.yaml`.
Not every `content/news/*.md` post has `.fr.md`/`.es.md` siblings yet — check before assuming parity.

## Site-specific layout overrides

`layouts/` contains a small number of site-specific templates that override the theme's defaults
(Hugo resolves site `layouts/` before the theme's). Do not confuse these with theme files — they're
the one place in this repo where template logic (not just content/config) lives:

- `layouts/experience/single.html` — single-job page; renders the sidebar job list plus a `job-card`
  header (title/company/location/dates) above the job's markdown body.
- `layouts/shortcodes/experience-list.html` — override of the theme's `experience-list` shortcode used
  on `/cv`. Renders a compact sidebar-style list of links (title/company/date) instead of the theme's
  default of inlining every job's full description — matches the theme demo's `/experience/job-2/`
  drill-down behaviour. Each entry still carries its full description in `d-none d-print-block` markup
  so printing `/cv` produces a complete one-page resume even though the on-screen view only shows links.
- `layouts/articles/list.html`, `summary.html`, `li.html` — override the theme's blog listing for
  `content/articles/` only (`content/news/` is unaffected). Groups posts into Bootstrap pill tabs by
  month, rendering each `content/articles/` page as either a `summary` partial (full teaser card, used
  when `params.blog.listStyle = "summary"` in `hugo.toml`) or an `li` partial (title + date only).

## Configuration

`hugo.toml` is the single site config: languages/menus, theme params (color scheme, SEO, blog layout),
plugin CSS/JS/SCSS includes, and module mounts. Notably it mounts `node_modules/bootstrap/...` into
`assets/` so the theme can build Bootstrap from the npm dependency — if Bootstrap versions or paths
change, update both `package.json` and the `[[module.mounts]]` entries here.

Menu items, per-language, are defined inline in `hugo.toml` under `[languages.<lang>.menus]` — there's
no separate data file for navigation.

## Theme

Do not edit files under `themes/adritian-free-hugo-theme/` directly — it's a separate upstream repo
(https://github.com/zetxek/adritian-free-hugo-theme) pulled in as a submodule. Site-specific
customization happens via `hugo.toml` params and the `content/` front matter/shortcodes the theme
already supports; if a needed shortcode/layout doesn't exist, that's an upstream theme change, not a
change to make in this repo.

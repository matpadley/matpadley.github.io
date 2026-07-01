# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal site/CV for Mathew Padley (matpadley.github.io), built with Hugo using the
`adritian-free-hugo-theme` (a git submodule at `themes/adritian-free-hugo-theme`). The repo was
recently migrated from Jekyll to Hugo — there is no legacy Jekyll content left to worry about.
This repo contains only content, config, and the theme submodule; there are no custom layouts or
assets of its own (`data/`, `assets/`, `static/` are currently empty; `layouts/` doesn't exist at
the top level — all templates come from the theme).

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

The theme is a submodule — after cloning or switching branches, run `git submodule update --init --recursive`
if `themes/adritian-free-hugo-theme` is empty.

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
- `content/articles/` — blog-style posts (`welcome.md` is the first one); `_index.md` is the section page.
- `content/footer/footer.md` — footer content, built with the `contact-section` shortcode (Formspree-backed
  contact form).

**Multi-language content**: the site is served in English (default), French, and Spanish
(`hugo.toml` `[languages]`). Translated content uses Hugo's language-suffix convention:
`cv.md` (en) / `cv.fr.md` / `cv.es.md`, `_index.md` / `_index.fr.md` / `_index.es.md`, etc. When
editing any content file, check for and update its `.fr.md` / `.es.md` siblings so translations don't
drift. UI string translations (not page content) live in `i18n/en.yaml`, `i18n/fr.yaml`, `i18n/es.yaml`.

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

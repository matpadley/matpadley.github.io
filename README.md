# matpadley.github.io

Personal site and CV for Mathew Padley, built with [Hugo](https://gohugo.io) using the
[adritian-free-hugo-theme](https://github.com/zetxek/adritian-free-hugo-theme). Served at
[matpadley.github.io](https://matpadley.github.io/) via GitHub Pages.

The repo holds only content, configuration, and a couple of theme overrides — the theme itself is
pulled in as a git submodule.

## Prerequisites

- [Hugo](https://gohugo.io/installation/) (extended edition) — matches the version pinned in
  `.github/workflows/hugo.yml` (`0.157.0`)
- [Node.js](https://nodejs.org/) — used to install Bootstrap for the theme's asset pipeline

## Setup

```bash
git clone --recurse-submodules https://github.com/matpadley/matpadley.github.io.git
npm install
```

> [!NOTE]
> If you've already cloned without `--recurse-submodules`, or the theme folder
> (`themes/adritian-free-hugo-theme`) is empty after switching branches, run:
> `git submodule update --init --recursive`

## Local development

```bash
npm start   # hugo server — local dev server with drafts and live reload
```

Other useful commands:

```bash
hugo server -D                     # serve including draft content
hugo new experience/some-role.md   # scaffold new content from archetypes/
```

## Build

```bash
npm run build   # hugo --gc --minify — production build into ./public
```

CI builds the same way (`hugo --gc --minify --baseURL <pages-url>`) and deploys `./public` to
GitHub Pages on every push to `main` (see `.github/workflows/hugo.yml`).

## Project structure

```
content/            Site content, organized by Hugo content type
  home/              Homepage (built from theme shortcodes)
  cv.md              /cv page — free-form markdown + experience/education shortcodes
  experience/         One file per job, rendered by the experience layout/shortcode
  education/          One file per qualification
  articles/           Blog-style posts
  footer/             Footer content (contact form)
layouts/             Small theme overrides (articles list/summary, experience single, a shortcode)
i18n/                UI string translations (en, fr, es)
data/                Site data files
assets/              Site-specific CSS
hugo.toml            Site config: languages, menus, theme params, module mounts
themes/               adritian-free-hugo-theme (git submodule, do not edit directly)
```

### Multi-language content

The site is served in English (default), French, and Spanish. Translated content uses Hugo's
language-suffix convention, e.g. `cv.md` / `cv.fr.md` / `cv.es.md`. When editing a content file,
check for and update its `.fr.md` / `.es.md` siblings so translations don't drift.

## Theme

Do not edit files under `themes/adritian-free-hugo-theme/` directly — it's a separate upstream
repo pulled in as a submodule. Site-specific customization happens via `hugo.toml` params and
`content/` front matter/shortcodes; anything a shortcode/layout doesn't already support is an
upstream theme change, not a change to make here.

# matpadley.github.io

Personal site and CV for Mathew Padley, built with [Hugo](https://gohugo.io) using the
[adritian-free-hugo-theme](https://github.com/zetxek/adritian-free-hugo-theme). Served at
[matpadley.github.io](https://matpadley.github.io/) via GitHub Pages.

The repo holds content, configuration, and a couple of theme overrides for the site itself — the
theme is pulled in as a git submodule — plus the Azure Function backend and infrastructure for the
`/contact` form (see [Contact form backend](#contact-form-backend)).

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
assets/js/           contact-form.js — client-side honeypot/timing logic for the /contact form
i18n/                UI string translations (en, fr, es)
data/                Site data files
hugo.toml            Site config: languages, menus, theme params, module mounts
themes/              adritian-free-hugo-theme (git submodule, do not edit directly)
api/ContactFunction/ Azure Function backend for the /contact form (see below)
infra/               Bicep templates provisioning that function's Azure resources
```

### Multi-language content

The site is served in English (default), French, and Spanish. Translated content uses Hugo's
language-suffix convention, e.g. `cv.md` / `cv.fr.md` / `cv.es.md`. When editing a content file,
check for and update its `.fr.md` / `.es.md` siblings so translations don't drift.

## Contact form backend

The `/contact` form posts to an Azure Function rather than a third-party form service:

- `api/ContactFunction/` — .NET 10 isolated-worker Azure Function (`ContactFunction.cs`) that
  validates the submission, applies a honeypot + submission-timing anti-bot check shared with
  `assets/js/contact-form.js`, and sends the message via Azure Communication Services Email.
- `infra/main.bicep` / `infra/rbac.bicep` — provisions the Function App (Flex Consumption), storage,
  Application Insights, and the ACS email domain the function sends through.
- `.github/workflows/deploy-contact-function.yml` — manual-only (`workflow_dispatch`) deploy that
  applies the Bicep and publishes the function code. It never runs on a push, since it touches
  billed Azure resources.

This is separate from the main Hugo build/deploy in `.github/workflows/hugo.yml`. One-time Azure/GitHub
setup (resource group, OIDC federated identity, GitHub environment secrets) is required before the
deploy workflow can run — see the local, git-ignored `local_docs/AZURE_SETUP_TODO.md` if present, or
recreate those steps from `infra/main.bicep`'s parameters and the workflow's required secrets.

To develop the function locally, copy `api/ContactFunction/local.settings.json.example` to
`local.settings.json` and fill in an ACS connection string.

## Theme

Do not edit files under `themes/adritian-free-hugo-theme/` directly — it's a separate upstream
repo pulled in as a submodule. Site-specific customization happens via `hugo.toml` params and
`content/` front matter/shortcodes; anything a shortcode/layout doesn't already support is an
upstream theme change, not a change to make here.

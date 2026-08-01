---
title: "Three Wrong Assumptions in a Publishing Skill"
date: 2026-08-01T11:30:00+01:00
draft: false
description: "The tool that turns this engineering log into articles assumed the section was English only, that a worklog entry makes a decent article body, and that one entry means one article. All three were wrong, and fixing them shows where a script should stop and judgement should start."
summary: "The tool that turns this engineering log into articles assumed the section was English only, that a worklog entry makes a decent article body, and that one entry means one article. All three were wrong, and fixing them shows where a script should stop and judgement should start."
tags:
  - club-monitor
  - tooling
  - python
  - hugo
  - claude-code
  - writing
source:
  - "2026-07-31-1030-publish-progress-skill-adds-fr-es-translations.md"
  - "2026-07-31-1115-publish-progress-skill-reader-facing-articles.md"
  - "2026-08-01-1130-publish-progress-skill-multi-source-articles.md"
---

These articles are generated from an engineering log. Every change to Club Monitor writes a dated entry into `progress/`, and a small skill turns those entries into the posts you're reading, with a Python helper handling the deterministic parts — dates, front matter, file naming — while the judgement calls stay with the model.

The first version worked, and then three separate things about it turned out to be wrong. Each fix is small; together they're a decent illustration of where the boundary between a script and a model's judgement actually sits.

## "English only" was never a constraint

The skill's documentation said the ClubMonitor section was English only. That was an accurate description of the eight articles that happened to exist when it was written, and not a fact about the site at all. The site's other sections already publish `.fr.md` and `.es.md` siblings alongside each English article: same slug, translated front matter and body, English kebab-case tags left as they are.

Copying an established convention is safer than inventing a new one, so the ClubMonitor section now follows it. The metadata for each article gained an optional `translations` object with `fr` and `es` entries, each carrying a title, description and body. The script generalised its front-matter builder to take an explicit title and description while keeping `date`, `tags` and `source` from the base metadata, so the English article and its translations share one shape.

Notably, translation itself stayed *out* of the script. It needs the same judgement the English title and description already require, so it lives in the metadata the model writes. The script is deliberately confined to the parts a script is actually better at.

That change had one non-obvious consequence. The `status` command works by reading the `source:` key back out of published articles to decide what still needs writing — and translations carry the same `source` as their English original. Without skipping `*.fr.md` and `*.es.md` when building that map, the result depended on glob ordering.

## The body was a transcript, not an article

The second problem was more fundamental: the script published the progress entry's own text as the article body.

Progress entries are written for the repository. They open with "What changed", they say things like "Follow-up to the question about..." and "Decision: keep it anonymous", and they list every file touched. All of that is right for a worklog and wrong for something a stranger might read. The output was technically accurate and dull.

So the metadata now carries an explicit `body` — a polished English article, written by the model after reading the entry, which the script publishes in place of the raw text. That same body is what gets translated, so the French and Spanish articles are translations of the article rather than of the log. The skill's instructions ask for prose that reads like published writing, and name the specific tics to avoid. A regression test covers the behaviour.

## One article, several entries

The last assumption to go was one entry, one article.

That holds when entries stand alone. It fails badly for work that arrived in phases — the multilingual rollout described elsewhere in this section landed as seven progress entries plus a plan, and publishing eight thin articles would have read far worse than one piece that tells the whole story.

So `source` in the metadata may now be a single filename, as before, or a list:

```json
{"source": ["2026-08-01-1200-thing.md", "2026-08-01-1600-thing-part-two.md"],
 "slug": "thing", "title": "...", "description": "...", "body": "..."}
```

Everything downstream follows from that. The front matter writes `source` as a quoted scalar for one entry and a YAML list for several, so existing articles are untouched and re-running `status` against the live site gives the same answer as before. `status` maps every listed entry to the article covering it, so none of them are offered again, and it now hints — when more than one entry is outstanding — that related entries can share an article. The article's date is the newest of its sources, so a combined piece sorts as recent work rather than as the day the first phase landed.

One rule is enforced rather than suggested: `body` is **required** when there is more than one source. The single-source fallback that lifts text out of the progress file has no sensible multi-entry equivalent, and splicing logs end to end is exactly the output the whole skill exists to avoid.

Reading the `source` key back out needed a small piece of care. The list-item pattern has to demand whitespace after the dash, or it runs on past the closing `---` of the front matter and reads the delimiter as one more, malformed, source.

## Where the judgement went

The grouping decision itself cannot be mechanised, so it became explicit guidance instead: a step between reading the entries and writing the metadata. Group them when the user names particular files, or when reading shows one story told across several logs. Keep them apart when the work is genuinely unrelated and merely adjacent in time. When the user names the files, publish exactly those and don't quietly fold in others. And for a combined article, write one continuous piece — find the thread through the entries — rather than the logs stapled together under a heading each, without dropping the substance of any entry listed as a source.

The whole thing was exercised against a throwaway content directory before it went near the real site: a two-source article and a single-source article written in one run, `status` reporting all three entries as published, both error paths, and `status` against the live site confirming that the nine existing articles with a scalar `source` still resolve exactly as they did.

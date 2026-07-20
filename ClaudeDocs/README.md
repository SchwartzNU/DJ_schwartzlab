# Schwartz Lab Database — new-member docs

A small static website that explains the `DJ_schwartzlab` DataJoint pipeline to
someone with no SQL background. Five pages:

- **index.html** — overview + the data-levels ladder (start here)
- **levels.html** — every level (Animal → Eye → Cell → Dataset → Epoch → Spike train) explained, plus how it maps onto the raw Symphony file
- **tables.html** — a searchable browser of every table in every `sln_*` schema, with plain-language fields, links, and DataJoint tier colors
- **analysis.html** — step-by-step guide to writing a new analysis + its `result_table_template`, following the real `SMS_CA` example
- **glossary.html** — SQL-free definitions of the recurring terms

## Viewing it

It's plain HTML/CSS/JS — no build step or server needed. Open `index.html`
in a browser, or serve the folder (e.g. `python3 -m http.server`) and drop it on
GitHub Pages / any static host. Fonts load from Google Fonts, so a first view
needs internet; everything else works offline.

## Regenerating after the schema changes

The table pages are generated straight from the repo's schema definitions, so
they stay accurate. From the repo root (`DJ_schwartzlab/`):

```bash
python3 parse_schemas.py          # reads schemas/+*/*.m  ->  schema_data.json
python3 build_site.py             # schema_data.json      ->  the .html pages
```

`parse_schemas.py` expects to run from the repo root (it reads the `schemas/`
folder). `build_site.py` writes the pages to the output directory set at the top
of the file — change `OUT` to wherever you keep the site. Hand-written prose
(levels, analysis, glossary) lives inside `build_site.py`; the table cards are
derived automatically from each table's DataJoint definition block.

Schemas shown are the current `sln_*` set. The legacy `sl_*` schemas and the
test schemas are intentionally left out to keep it approachable; add them to
`SCHEMA_META` in `build_site.py` if you want them.

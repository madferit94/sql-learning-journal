# Editorial and validation notes

[한국어](editorial.ko.md) · [Home](../README.md)

## Current scope

The manual Notion snapshot on 2026-10-27 covers 21 sessions and 110 final recorded queries. Days18–21 are added in Korean and English, and Days11–20 reflect the latest note cleanup. Coaching dialogue, paste-correction narration and unsupported proficiency evaluations are excluded; useful SQL mistakes, fixes, actual outputs and metric caveats remain.

Korean follows the detailed source. English is a condensed translation with the same exercises, exact final queries and recorded numeric outputs. Repetition may be condensed. Finance customer IDs are pseudonymized; private exports, original identifier maps, raw datasets, dumps, credentials and machine-specific paths are excluded.

## Evidence and checks

Recorded result tables are historical executions. This publication checks file structure, both language editions, SQL hashes, result-table correspondence, links, Markdown fences and privacy exclusions. It does not rerun the exercise SQL. Day19 Exercise 1 includes the later supplied result and its recorded read-only DB cross-check. F1 ingestion validation is a separate data-preparation check described in the data notes.

query-manifest.json maps day/exercise numbers to final query hashes. Earlier attempts are not runnable solutions. Day11 Exercise 3 retains ERROR 1064 and the successful follow-up; a suspected whitespace cause is not independently reproduced by this publication.

## Interpretation

- Verify output grain, composite keys, missing rows, duplicate joins, date scope and denominators.
- Repeat-purchase percentages are not cohort retention or causal loyalty measures.
- Intermediate rounding can change averages of averages or ranks; keep precision when the question requires it.
- SQL name resolution and functional dependencies depend on the database; a successful example is not a portable guarantee.
- The 40-lap threshold and time cutoffs are instructional. Main-race points and RANK ties are not the official championship.

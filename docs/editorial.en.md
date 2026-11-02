# Editorial and validation notes

[한국어](editorial.ko.md) · [Home](../README.md)

## Current scope

The manual snapshot on 2026-11-02 contains 22 sessions and 115 final queries. Korean follows the detailed Notion source; English is an edited translation with the same exercises, final SQL and recorded outputs. Coaching assessments and paste-correction narration are excluded; useful SQL errors, fixes and interpretation remain.

## Historical runs and current audit

Existing result tables/timings remain historical. This update separately reran all 115 final queries using explicit snapshot and schema adaptations. See the [audit](audit.en.md) and [per-query evidence](audit-results.json). A successful current run does not independently reproduce the byte-level cause of an old error. Day11 Exercise 3 is resolved, retaining its historical ERROR 1064 and later successful result.

query-manifest.json records final SQL hashes; the validation script checks both languages, query files, recorded table alignment, links, fences, counts and exclusions. Earlier attempts may be invalid and are not final runnable solutions. Document validation does not itself execute SQL; execution evidence is in the separate audit report.

## Publication and interpretation

Retain existing finance pseudonyms. Do not publish private Notion exports, raw datasets, dumps, original ID maps, credentials or machine-specific paths. Keep row grain, keys, NULL behavior, denominators, date/snapshot scope and precision explicit. Repeat-purchase percentages are not cohort retention. Lap cutoffs are instructional; main-race points and RANK do not implement official championship countback.

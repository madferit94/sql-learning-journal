# Editorial and validation notes

[한국어](editorial.ko.md) · [Home](../README.md)

## Publication method

- The Korean Notion journal was read on 2026-10-08. Eleven days and sixty exercises were included.
- Korean prose and historical attempts were preserved with Markdown formatting cleanup. Broken Notion-only tags and unavailable internal file citations were removed; HTML tables were converted to Markdown.
- English is an edited translation covering every exercise, not a line-by-line translation of repeated coaching dialogue. It adds clearly useful interpretation cautions; the Korean journal remains the detailed source.
- Final recorded SQL was extracted into `sql/`, including the unresolved Day11 Exercise 3. “Final recorded” means last in the journal, not independently validated or necessarily correct.
- Customer identifiers in Day06 were pseudonymized consistently. No raw datasets, account credentials or unrelated private workspace files are included.
- `query-manifest.json` maps the extracted queries to day, exercise, source code-block position and SHA-256. It supports publication consistency checks, not database correctness claims.

## Interpretation cautions

1. Grouping by state and customer creates **state/customer pairs**. Summing those counts across states need not equal globally unique customers if a customer appears in several states. Repeat status is evaluated within each state and time window.
2. Repeat-customer percentage here is the share with at least two observed orders, not cohort retention, a causal effect or future loyalty.
3. Equal row counts before and after a JOIN are insufficient on their own: unmatched rows and multiplying keys can offset one another.
4. MySQL's `ONLY_FULL_GROUP_BY` behavior depends on grouping and functional dependencies. Selecting a team name while grouping by only its ID requires appropriate uniqueness constraints; the repository does not include those constraints.
5. Historical errors and malformed attempt snippets remain as learning evidence. Do not copy an “earlier attempt” as a working answer. `SUM(x)/COUNT(*)` matches `AVG(x)` only when the relevant null treatment and denominator agree.
6. Day11 Exercise 3 records ERROR 1064 after the final query. The notes suggest unusual whitespace; the cause and a successful repair have not been independently reproduced.

## What was checked

Publication checks cover bilingual day/exercise counts, local links, extracted-query hashes, exclusion of local source exports and Day06 identifier replacement. No database was available to rerun the queries. Existing result tables remain historical evidence, with some source outputs only partially displayed.

# AI development log

I built this project while taking the dbt Fundamentals course, using **Claude Code** (Anthropic) as a
pair programmer. This log records what I asked for, what the AI did, what I decided or did myself,
and how each step was verified. The rule I followed: the AI can propose and edit, but nothing goes
to `main` without a passing `dbt build` and a pull request that I review and merge.

---

### 1. Moving off the dbt Cloud managed repository — 2026-10-03
- **Goal:** let the AI read my models. The project lived in a dbt Cloud *managed* repo, which is not
  accessible from outside dbt Cloud.
- **AI:** explained the limitation, recreated the project locally from the files I exported,
  initialised git and prepared the commands to push to my own GitHub repo.
- **Me:** created the GitHub repo, pushed, reconnected the dbt Cloud project to it and added the
  deploy key with write access.
- **Verified:** I committed a test branch from the dbt Cloud IDE and the AI fetched it locally —
  round trip working in both directions.

### 2. First bug: broken `ref()` calls
- **AI:** spotted that `customers.sql` referenced `ref('stg_jaffle_shop_customers.sql')` (file
  extension + single underscore). Fixed it on a branch.
- **Me:** ran `dbt build` in dbt Cloud, opened my first PR and merged it.
- **Learned:** `ref()` uses the model name, not the file path; the dbt Cloud IDE can keep a stale
  parse after a fix (solved with *Restart IDE*).

### 3. Course exercises: staging/marts, sources, `fct_orders`
- **Me:** did the restructuring (staging/marts folders, project rename, materializations by folder,
  sources) myself in the IDE, asking the AI to review.
- **AI:** caught mismatched project names between `name:` and the `models:` config key, a double
  `LIMIT` caused by dbt Cloud's preview, the cents-to-dollars conversion, and missing
  `group by`/join syntax in my SQL.
- **Verified:** `sum(lifetime_value) = 1672`, the expected value from the course.

### 4. YAML debugging and partial parsing
- **Problem:** source tests kept failing with `SELECT list must not be empty` even after fixing the
  indentation.
- **AI:** read the committed file, confirmed it was correct, and identified dbt's **partial parsing
  cache** as the cause.
- **Fix:** `--no-partial-parse` / `dbt clean`. **Learned:** a test name ending in `_` means it was
  parsed at table level, not column level.

### 5. Letting the AI run dbt (dbt Cloud CLI)
- **Decision:** I wanted the AI to run tests itself. Options were dbt Core + a BigQuery service
  account, or the dbt Cloud CLI. I chose the **Cloud CLI**: no warehouse keys on my machine.
- **AI:** downloaded the official release, **verified its SHA-256 checksum** against dbt Labs'
  published checksums, added it to PATH and added the `project-id` to `dbt_project.yml`.
- **Me:** downloaded `dbt_cloud.yml` (contains my token — the AI never read it) and renamed a test
  file whose name contained `:`, which is invalid on Windows. The AI declined to disable git's NTFS
  path protection to work around it.

### 6. Tests based on data profiling
- **Ask:** "add the tests you think are needed before running `dbt build`".
- **AI:** profiled the data first (distinct statuses, payment methods, null and orphan counts) and
  only then wrote tests, so `accepted_values` reflect real values. Added 21 tests: `unique` +
  `not_null` on every primary key, `relationships` on foreign keys (source and model level).
- **Judgement calls it explained:** no `not_null` on `fct_orders.amount` (a left join can
  legitimately produce null); no `unique` on payments staging because the model has no payment key.
- **Verified:** `dbt build` → 37/37 pass.

### 7. Documentation — and a caught regression
- **AI:** added descriptions for every source, model and column, reusing my `order_status` doc block.
- **Caught:** my own descriptions commit had overwritten two tests the AI had added earlier (I edited
  an outdated copy). The AI noticed and restored them.
- **Learned:** pull before editing; doc blocks are the way to share one description across columns.

### 8. Connecting Lightdash
- **Me:** created the Lightdash project and a Google Cloud service account (key never shared with
  the AI).
- **AI:** debugged from my screenshots: the dbt connection type was set to **CLI** instead of GitHub
  (so no models appeared), and the dataset had been typed into **Execution project**.
- **Verified:** models visible in Lightdash, queries returning data.

### 9. Metrics and semantic layer
- **AI:** added `order_date`/`order_status` to `fct_orders` and Lightdash metrics under
  `config: meta:` (dbt ≥ 1.10). Later added a `fct_orders → dim_customers` join, a SQL-defined
  `customer_segment` dimension and ratio metrics (`return_rate`, `repeat_customer_rate`). It checked
  the Lightdash docs for the exact syntax before writing them.
- **Me:** asked for each step to be explained so I could learn it; reviewed and merged the PRs.
- **Verified:** totals cross-checked with `dbt show` against expected values (revenue 1672, 99
  orders, AOV 16.89).

### 10. Dashboard
- **Me:** built the dashboard myself in the Lightdash UI, following a chart-by-chart plan, to
  practise the tool hands-on.

---

## Where AI helped / where I stayed in control

**Helped most:** spotting small but blocking errors fast (YAML indentation, `ref()` names, Lightdash
config fields), profiling data before writing tests, writing documentation, and explaining *why*
something works the way it does.

**Stayed with me:** every merge to `main`, all credentials (dbt token, GCP key, GitHub auth), the
choice of tools (Cloud CLI over storing warehouse keys), the course exercises themselves, and
building the dashboard.

**What I would watch for:** AI output was always checked by running `dbt build` and comparing totals
against known values — the AI itself flagged that some issues (like integer division on Redshift,
see README) would not be caught by generic tests.

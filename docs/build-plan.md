# Support Triage SLM — Master Build Plan v1.0

Oct 15, 2026 · @Nugen IT Services

## 0. How to use this document

This is the single source of truth for building the **Enterprise Support Ticket Triage SLM** (Antern mentor brief v4, Parts A–D). Export it as Markdown, attach or paste it into a fresh chat, and send the kickoff prompt in section 16. Everything decided in earlier sessions is carried forward in section 3 so nothing has to be re-argued.

**Operating rules for whoever (human or AI) executes this plan:**

1. Phases are gated. No phase starts until the previous phase's exit gate is checked off and committed. Skipping a gate invalidates the experiment, not just the paperwork.
2. The test set is frozen once and hashed. After `08-freeze-test-set`, nobody reads, edits, or tunes against `test.jsonl` until the final evaluation run.
3. Success criteria are written before training and never moved afterward. A miss is reported as a miss and investigated.
4. The LLM generates and proposes; the policy decides; a human approves. No synthetic example enters the reviewed dataset without human sign-off.
5. One controlled change per iteration. Train → evaluate → failure analysis → one change → retrain. Never "generate more data and retrain" without a diagnosed cause.
6. Every number in a report traces to a committed file (dataset version + config + run ID). If it cannot be traced, it does not go in the paper.
7. Scope is fixed: one behavior, six classes, single-label. No agent, no RAG, no UI, no API, no vector DB, no multi-label.
8. The pipeline is policy-parameterized. The mentor experiment runs on the generic enterprise policy; the same code must be able to run later on a Nugenova/Nexora-specific policy and ticket schema by swapping `policy.md` and a scenario matrix, not by rewriting scripts.

## 1. Mission, scope and non-goals

**The one behavior:** given an enterprise support ticket and its context, classify it into the single operational action support should take next, according to a fixed generic enterprise policy.

**The experiment:** a small Qwen model fine-tuned with LoRA on Tinker, using \~140 reviewed examples, will classify unseen tickets according to the policy more consistently than the same model prompted, and we measure how far it sits from a frontier model under identical conditions.

**Hypothesis (H1):** LoRA-Qwen beats prompted base-Qwen on the frozen test set by ≥ 10 percentage points of decision accuracy and reaches macro-F1 ≥ 0.85.

**Null (H0):** fine-tuning gives no meaningful improvement over prompting. H0 is an acceptable outcome if it is measured honestly.

**In scope**

- Policy design, annotation SOP, reviewed dataset (≥ 100 examples, target 200)
- Frozen test set, base and frontier baselines, one or two LoRA runs on Tinker
- Per-class and per-scenario evaluation, failure analysis, reproducible public repo
- Part A white paper (Qwen / Llama / Mistral), Part B Manim LoRA video, Part D 150–200 build-in-public posts

**Out of scope (hard no)**

- Agents, RAG, vector databases, web UI, production API, multi-agent workflows
- Multi-label routing, auto-resolution, generated customer replies as a primary objective
- Datasets above \~250 candidates in v1; scaling comes only after a diagnosed failure needs it
- Any Nexora integration work in this repo. The pipeline is built so a Nugenova policy can be dropped in later; the integration itself is a separate project.

## 2. Decisions already frozen (carry-forward)

These were settled in prior sessions and are not reopened in the new chat. Policy version: `support-triage-policy-v1.1`.

**Current repo state (as of 2026-10-15):** only `docs/behavior-spec.md` v1.0 and `docs/review-sop.md` exist as files. Policy v1.1, the 30-example pilot, and the dataset-generation spec were worked out in chat but are **not yet committed**. The phase plan in section 8 therefore starts by turning those into files before any code is written. No scripts, data, or Tinker work exist yet.

| Decision | Value |
| --- | --- |
| Project behavior | Enterprise Support Ticket Triage |
| Label set (6, mutually exclusive) | `ROUTE_TO_SECURITY`, `ROUTE_TO_ENGINEERING`, `ROUTE_TO_BILLING`, `REQUEST_MORE_INFORMATION`, `SELF_SERVICE`, `HUMAN_REVIEW` |
| Primary objective | `decision` (exact match). `priority` and `reason` are secondary, scored separately, never used to pick the decision |
| Policy flavor | Generic enterprise policy, not a named company |
| Classification | Single label per ticket |
| Precedence (only when the higher signal is genuine) | SECURITY → ENGINEERING → BILLING → SELF\_SERVICE → REQUEST\_MORE\_INFORMATION → HUMAN\_REVIEW |
| Pilot | 30 examples reviewed; three policy gaps found and fixed in v1.1 |

**Policy v1.1 rules that came out of the pilot**

1. **Payment boundary.** Confirmed account/financial cause (declined card, wrong invoice, duplicate charge, unpaid balance) → BILLING. Confirmed technical cause (checkout returns HTTP 500, payment service timing out) → ENGINEERING. Cause not stated ("payment isn't working") → REQUEST\_MORE\_INFORMATION.
2. **Multi-issue tickets.** Classify the highest-priority *actionable* issue. Secondary issues change nothing unless they alter risk, ownership or urgency of the primary one. Dashboard 500s + contract exception → ENGINEERING.
3. **HUMAN\_REVIEW semantics.** Means "facts are sufficient, but policy requires a human/business decision" (contract exception, discretionary refund, approval). It never means "hard example" or "annotator unsure". Missing facts → REQUEST\_MORE\_INFORMATION.
4. **Security override.** Credible unauthorized access or compromise → SECURITY even with billing, refund or technical issues attached. Security vocabulary alone ("forgot my password") is not a security incident.
5. **Evidence rule.** The model never converts an assumption into a fact. "I can't log in" alone → REQUEST\_MORE\_INFORMATION.
6. **SELF\_SERVICE** requires an identifiable issue mapped to an established documented procedure; "looks easy" is not enough.
7. **Leakage rule.** No label names, routing instructions or policy language inside ticket text.
8. **Generation rule.** The LLM generates *scenarios*, then tickets; the policy and a human assign the label. The generator never owns ground truth.

**Pre-registered success criteria (do not move after results)**

| Metric | Target | Model |
| --- | --- | --- |
| Decision accuracy (test) | ≥ 85% | LoRA |
| Macro-F1 (test) | ≥ 0.85 | LoRA |
| Base → LoRA accuracy delta | ≥ +10 pp | LoRA vs base |
| Invalid / unparseable output | < 2% | LoRA |
| Adversarial-slice accuracy | materially above base (report delta + CI) | LoRA vs base |
| Per-class recall | reported for all 6 | all three |
| Failure analysis | ≥ 5 documented | LoRA |

Thresholds may be re-tuned once, after the base baseline reveals task difficulty and before any LoRA run; that revision is committed with a rationale.

## 3. Mentor-brief deliverables → artifacts

Every brief requirement maps to a committed file. If a requirement has no file, it is not done.

| Part | Brief requirement | Artifact in repo | Phase |
| --- | --- | --- | --- |
| C | One specific behavior + why prompting is insufficient | `docs/behavior-spec.md` | 0 |
| C | Labeling / review SOP | `docs/review-sop.md`, `docs/policy.md` | 1 |
| C | ≥ 100 reviewed examples, label + reviewer + kept flag | `data/reviewed/*.jsonl` | 2 |
| C | Contradiction + balance analysis, random-20 manual audit | `evaluation/dataset-audit.md` | 2 |
| C | PII removed | `scripts/validate_data.py` (PII check) + audit log | 2 |
| C | Train / val / test split, test frozen | `data/{train,validation,test}.jsonl` + `data/MANIFEST.json` (sha256) | 2 |
| C | Success criteria before training | `docs/evaluation.md` (pre-registration section) | 0, locked at 3 |
| C | Base Qwen vs frontier vs LoRA, one scorecard, per-decision scores | `evaluation/scorecard.json`, `evaluation/scorecard.md` | 4–6 |
| C | LoRA on Tinker, Qwen from Tinker model list; rank/alpha/targets/LR/epochs/cost explained | `training/config.yaml`, `docs/lora-report.md`, `training/runs/<id>/` | 5 |
| C | ≥ 5 failure examples | `evaluation/failures.md` | 6 |
| C | README, diagrams (Mermaid), incremental commit history | `README.md`, `diagrams/*.mmd`, git log | all |
| A | Qwen / Llama / Mistral comparison through a common abstraction lens, ≥ 5 reverse-engineered design changes | `paper/main.tex`, `research/*.md`, `research/reading-log.md` | A1–A3 |
| A | White paper 10–15 pages with required structure + reading-log appendix | `paper/main.pdf` | A3 |
| B | Manim LoRA video (Beamer fallback) walking a WQ 32×64, r=4 example to the real config | `lora-video/` (scenes, render), `lora-video/script.md` | B1–B2 |
| D | 150–200 build-in-public pieces incl. mistakes, costs, scorecards | `content/backlog.md`, `content/posts/` | D, continuous |

## 4. System architecture

The project is a miniature ML engineering system with three trust boundaries: the **policy** (authority), the **LLM** (assistant, never authority), and the **frozen test set** (sealed after one write).

```text
 policy.md (v1.1)                      ┐
   │                                    │ AUTHORITY LAYER — humans own these
   ▼                                    │
 scenario_matrix.yaml ──────────────────┘
   │
   ▼
 generate_data.py  ── LLM ──▶  data/raw/candidates.jsonl     (scenario → ticket, label NOT written)
   │
   ▼
 annotate_data.py  ── LLM ──▶  data/raw/annotated.jsonl      (proposed label + evidence, no gold shown)
   │
   ▼
 review (human, CLI tool) ──▶  data/reviewed/reviewed.jsonl  (approve / correct / reject + reviewer_id)
   │
   ▼
 validate_data.py + audit_dataset.py ──▶ evaluation/dataset-audit.md   (schema, dupes, PII, contradictions, balance)
   │
   ▼
 split_data.py (scenario-family aware) ──▶ train.jsonl / validation.jsonl / test.jsonl + MANIFEST.json (sha256)
                                                                                   │
          ┌────────────────────────────────────────────────────────────────────────┘
          ▼
  ┌───────────────────┐   ┌───────────────────┐   ┌───────────────────┐
  │ run_baseline.py   │   │ run_frontier.py   │   │ train.py (Tinker) │
  │ Qwen base + fixed │   │ Claude/GPT + same │   │ LoRA → sample on  │
  │ prompt, temp 0    │   │ prompt, temp 0    │   │ val, then test    │
  └─────────┬─────────┘   └─────────┬─────────┘   └─────────┬─────────┘
            └──────────────┬────────┴──────────────┬─────────┘
                           ▼                       ▼
                   evaluate.py  ──▶  predictions/<run_id>.jsonl
                           │
                           ▼
                   metrics.py  ──▶  evaluation/scorecard.json + scorecard.md
                           │
                           ▼
                   analyze_failures.py ──▶ evaluation/failures.md
                           │
                           ▼
                   one controlled change ──▶ policy / data / config (versioned) ──▶ loop
```

**Component responsibilities**

| Component | Owns | Must never |
| --- | --- | --- |
| `policy.md` + `scenario_matrix.yaml` | Label definitions, precedence, which scenarios exist and how many | Be edited mid-experiment without a version bump |
| Generator | Realistic ticket text from a scenario spec | See or emit the target label in the ticket |
| First-pass annotator | Proposed label + evidence + alternatives | See the intended gold label |
| Human reviewer | Final label, kept flag, rationale, disagreement category | Approve on the LLM's say-so |
| Validator / auditor | Schema, dupes (exact, normalized, semantic), PII, contradictions, balance, boundary coverage | Pass silently; every check writes to the audit file |
| Splitter | Family-aware split, MANIFEST hashes | Random-shuffle paraphrase families across splits |
| Eval harness | One prompt, one parser, one metrics module for all three models | Differ per model |
| Trainer | Tinker LoRA run from `config.yaml`, logs, checkpoint IDs, cost | Touch `test.jsonl` |
| Failure analyzer | Per-example diff across base / LoRA / frontier with root-cause tags | Modify the test set |

## 5. Repository layout

Public GitHub repo `slm-support-triage`. Everything below exists by the end; the phase plan says when each part is created.

```text
slm-support-triage/
├── README.md                      # story in one page: behavior → data → baselines → LoRA → scorecard → failures
├── pyproject.toml                 # uv-managed; pinned deps
├── uv.lock
├── .env.example                   # TINKER_API_KEY, ANTHROPIC_API_KEY / OPENAI_API_KEY, MAX_COST_USD
├── .gitignore                     # .env, data/raw/_scratch/, training/runs/*/checkpoints/
├── .pre-commit-config.yaml        # ruff, schema validation on data/*.jsonl, MANIFEST hash check
├── Makefile                       # make generate | annotate | review | audit | split | freeze | baseline | frontier | train | eval | failures | paper | video
│
├── docs/
│   ├── behavior-spec.md           # Phase 0 contract (v1.x)
│   ├── policy.md                  # support-triage-policy-v1.1
│   ├── review-sop.md              # annotation SOP, decision tree, anti-patterns
│   ├── dataset-generation.md      # generation + review spec v1.0
│   ├── evaluation.md              # pre-registered metrics, prompt, parser rules
│   ├── lora-report.md             # Part C LoRA write-up: base model, r/α/targets/LR/epochs/cost + rationale
│   └── decisions.md               # ADR log: dated decisions and why
│
├── policy/
│   ├── generic-enterprise/        # the mentor experiment
│   │   ├── policy.md -> ../../docs/policy.md
│   │   ├── scenario_matrix.yaml
│   │   └── prompt_system.txt
│   └── _template/                 # placeholder for a later Nugenova/Nexora policy (not built in v1)
│
├── data/
│   ├── raw/
│   │   ├── candidates.jsonl       # generator output, no labels
│   │   └── annotated.jsonl        # LLM first-pass proposals
│   ├── reviewed/
│   │   ├── reviewed.jsonl         # human-approved canonical records
│   │   └── disagreements.jsonl    # every human–LLM or human–human disagreement, categorized
│   ├── train.jsonl
│   ├── validation.jsonl
│   ├── test.jsonl                 # FROZEN — hash in MANIFEST.json
│   ├── MANIFEST.json              # dataset_version, policy_version, counts, sha256 per split, split_seed
│   └── CHANGELOG.md               # dataset-v0.1 → v0.2 → v1.0
│
├── src/triage/
│   ├── schema.py                  # Pydantic: TicketInput, Label, Annotation, CanonicalRecord, Prediction
│   ├── policy.py                  # label enum, precedence, evidence rules as code constants
│   ├── prompts.py                 # ONE system prompt builder shared by all three models
│   ├── formatter.py               # canonical → Qwen chat/instruction format (train) and inference prompt (eval)
│   ├── parser.py                  # strict JSON extraction, invalid-output classification
│   ├── metrics.py                 # accuracy, per-class P/R/F1, macro-F1, confusion, slices, bootstrap CI
│   ├── dedupe.py                  # exact, normalized, embedding-similarity dupes
│   └── pii.py                     # regex + NER PII scan
│
├── scripts/
│   ├── generate_data.py           # scenario → ticket (LLM)
│   ├── annotate_data.py           # ticket → proposed label (LLM, blind)
│   ├── review_cli.py              # human review loop, writes reviewed.jsonl + disagreements.jsonl
│   ├── validate_data.py           # schema, labels, dupes, PII, leakage strings
│   ├── audit_dataset.py           # balance, difficulty, boundary coverage, contradictions → dataset-audit.md
│   ├── split_data.py              # family-aware split + MANIFEST
│   ├── freeze_test.py             # hashes test.jsonl, writes MANIFEST, makes file read-only
│   ├── run_baseline.py            # Qwen base via Tinker sampling, temp 0
│   ├── run_frontier.py            # Claude or GPT, same prompt, temp 0
│   ├── evaluate.py                # predictions → scorecard
│   └── analyze_failures.py        # cross-model diff → failures.md
│
├── training/
│   ├── config.yaml                # the LoRA hypothesis (see §10)
│   ├── train.py                   # Tinker LoRA run; logs loss per step; saves sampler/checkpoint IDs
│   ├── dry_run.py                 # 5-example, 2-step smoke test + cost estimate
│   └── runs/
│       └── <run_id>/              # config snapshot, train_log.jsonl, val predictions, cost.json
│
├── evaluation/
│   ├── dataset-audit.md
│   ├── scorecard.json             # all three models, all metrics, all slices, CIs
│   ├── scorecard.md
│   ├── confusion_<model>.png
│   ├── failures.md
│   └── experiments.csv            # one row per run
│
├── predictions/
│   └── <run_id>.jsonl             # raw model outputs, never edited
│
├── tests/                         # pytest: schema round-trip, parser edge cases, metrics vs sklearn, split leakage guard
│
├── diagrams/
│   ├── data-pipeline.mmd
│   ├── training-flow.mmd
│   └── evaluation-flow.mmd
│
├── research/                      # Part A
│   ├── lens.md                    # the common abstraction lens (block list)
│   ├── qwen.md · llama.md · mistral.md
│   ├── design-changes.md          # ≥ 5 problem→idea→change→result→cost entries
│   └── reading-log.md
│
├── paper/                         # Part A
│   ├── main.tex · references.bib · figures/
│
├── lora-video/                    # Part B
│   ├── script.md · scenes/ · assets/ · render/
│
└── content/                       # Part D
    ├── backlog.md                 # 150–200 post ideas, tagged by track
    └── posts/
```

## 6. Toolchain, environment, secrets, cost controls

Keep the stack small. Every dependency below has one job; nothing is added "in case".

| Purpose | Tool | Note |
| --- | --- | --- |
| Language / env | Python 3.12, `uv` | `uv sync` reproduces the env from `uv.lock` |
| Data contracts | Pydantic v2 | Every JSONL line validated on read and write |
| Tests | pytest | Run in pre-commit and CI |
| Metrics | scikit-learn, numpy, pandas | `metrics.py` cross-checked against `sklearn.metrics` in tests |
| Dedup | rapidfuzz (normalized), sentence-transformers `all-MiniLM-L6-v2` (semantic, cosine ≥ 0.90 flagged) | Flags go to human, never auto-dropped |
| PII | regex (email, phone, card, IP) + `presidio` or spaCy NER for names | Any hit blocks the record until edited |
| Fine-tuning | Tinker SDK (training client + sampling client), Qwen from the Tinker model list | Exact model string recorded in `config.yaml`; candidates Qwen3-4B-Instruct / Qwen3-8B-Instruct — confirm against the live model list at kickoff |
| Base baseline | Same Qwen via Tinker sampling, temperature 0, fixed max tokens | Same prompt object as LoRA eval |
| Frontier baseline | Claude (Anthropic API) or GPT (OpenAI API), temperature 0, seed where supported | Same prompt, same parser, same test file |
| Generation / annotation LLM | Claude or GPT, run through `scripts/` only | Prompts committed; raw responses logged to `data/raw/_logs/` |
| Diagrams | Mermaid (`.mmd` rendered by `mmdc`) | Committed source + PNG |
| Video | Manim Community; Beamer + LaTeX as fallback | Scenes committed; render not |
| Paper | LaTeX (Overleaf or local), BibTeX via Zotero | `main.tex` committed |
| Notes | Obsidian vault mirrored into `research/` | Reading log is the appendix |
| Lint / format | ruff | Pre-commit |
| CI | GitHub Actions: `uv sync`, pytest, `validate_data.py`, MANIFEST hash check | Fails if `test.jsonl` hash changes after freeze tag |

**Secrets**

- `.env` only; `.env.example` lists keys with empty values. Keys: `TINKER_API_KEY`, `ANTHROPIC_API_KEY` or `OPENAI_API_KEY`, `MAX_COST_USD`.
- Pre-commit secret scan (`gitleaks`) before the repo goes public.

**Cost controls**

- `MAX_COST_USD` read by every script that calls a paid API; scripts refuse to start if the running total in `evaluation/cost_ledger.json` plus the estimate would exceed it.
- Budget split (adjust at kickoff): generation + annotation ≤ 25%, frontier baseline ≤ 15%, Tinker training + sampling ≤ 50%, reserve 10%.
- `dry_run.py` must print an estimated cost for the full run before `train.py` is allowed to launch.
- Every run writes `cost.json` (tokens in/out, steps, USD) — this is the cost figure the brief asks for.

**Determinism**

- Global `SEED=42` for splits, sampling order, bootstrap; the seed is written into MANIFEST and each run's config snapshot.
- All inference at temperature 0; frontier calls pass `seed` where the API supports it and record the `system_fingerprint` / model snapshot ID.

## 7. Data contracts

Five schemas, all Pydantic models in `src/triage/schema.py`. Nothing is read or written without passing through them.

**7.1 Canonical record** (`data/reviewed/reviewed.jsonl`, and every split file)

```json
{
  "id": "triage_0001",
  "policy_version": "support-triage-policy-v1.1",
  "dataset_version": "dataset-v1.0",
  "family_id": "fam_0317",
  "input": {
    "customer_tier": "enterprise",
    "product": "analytics",
    "ticket_title": "Dashboard returning server errors",
    "ticket_description": "All users began receiving HTTP 500 errors after today's deployment.",
    "conversation_history": [],
    "metadata": {"users_affected": 120, "environment": "production"}
  },
  "label": {
    "decision": "ROUTE_TO_ENGINEERING",
    "priority": "P1",
    "reason": "A confirmed production technical failure is affecting multiple users."
  },
  "annotation": {
    "difficulty": "medium",
    "information_completeness": "complete",
    "scenario_type": "deployment_regression",
    "signal_type": "engineering",
    "conflict_type": "none",
    "source_type": "synthetic"
  },
  "review": {
    "llm_proposed_decision": "ROUTE_TO_ENGINEERING",
    "reviewer_id": "reviewer_01",
    "review_status": "approved",
    "kept": true,
    "disagreement_category": null,
    "review_notes": "",
    "reviewed_at": "2026-10-20"
  },
  "split": "train"
}
```

Rules: `family_id` groups paraphrases of one underlying scenario and is the unit of splitting. `review_status` ∈ {approved, corrected, rejected}; rejected records stay in `reviewed.jsonl` with `kept=false` for the audit trail but never enter a split. `disagreement_category` ∈ {LLM\_ERROR, HUMAN\_ERROR, POLICY\_AMBIGUITY, INSUFFICIENT\_INFORMATION, GENERATION\_ERROR, OTHER}.

**7.2 Training serialization** (produced by `formatter.py`, never hand-edited)

```json
{"messages": [
  {"role": "system", "content": "<policy/prompt_system.txt, byte-identical to eval>"},
  {"role": "user", "content": "<input rendered as fixed template>"},
  {"role": "assistant", "content": "{\"decision\":\"ROUTE_TO_ENGINEERING\",\"priority\":\"P1\",\"reason\":\"...\"}"}
]}
```

Loss is computed on assistant tokens only. The same system prompt and user template are used for base, frontier and LoRA inference, so the only variable between base and LoRA is the adapter.

**7.3 Prediction record** (`predictions/<run_id>.jsonl`)

```json
{"id": "triage_0183", "run_id": "lora_r8_a16_e3_s42", "model": "lora", "raw_output": "...",
 "parsed": {"decision": "ROUTE_TO_BILLING", "priority": "P2", "reason": "..."},
 "parse_status": "ok", "latency_ms": 412, "tokens_in": 318, "tokens_out": 41}
```

`parse_status` ∈ {ok, invalid\_json, invalid\_label, missing\_field, truncated}. Anything other than `ok` scores as wrong **and** counts toward the invalid-output rate. No regex rescue of near-JSON; strictness is identical for all three models.

**7.4 Scorecard** (`evaluation/scorecard.json`)

```json
{"dataset_version": "dataset-v1.0", "test_sha256": "...", "n_test": 30,
 "models": {"base": {...}, "frontier": {...}, "lora": {...}},
 "per_model_schema": {
   "accuracy": 0.0, "accuracy_ci95": [0.0, 0.0], "macro_f1": 0.0, "macro_f1_ci95": [0.0, 0.0],
   "invalid_rate": 0.0,
   "per_class": {"ROUTE_TO_SECURITY": {"precision": 0, "recall": 0, "f1": 0, "support": 0}, "...": {}},
   "slices": {"difficulty": {}, "information_completeness": {}, "conflict_type": {}, "signal_type": {}},
   "confusion": [[...]],
   "priority_accuracy": 0.0, "reason_rubric_mean": 0.0}}
```

**7.5 Experiments log** (`evaluation/experiments.csv`) — one row per run: `run_id, date, phase, model, base_model, dataset_version, policy_version, rank, alpha, target_modules, learning_rate, epochs, batch_size, seed, steps, final_train_loss, val_accuracy, val_macro_f1, test_accuracy, test_macro_f1, invalid_rate, cost_usd, checkpoint_id, notes`. Test columns stay empty until the final evaluation phase; validation columns drive all tuning.

## 8. Phase plan with gates

Starting point: `behavior-spec.md` v1.0 and `review-sop.md` exist; nothing else. Each phase lists what goes in, what comes out, the gate that must pass, and the commit tag. Effort is for one person working part-time (\~3–4 h/day).

### Phase 0 — Repo bootstrap and spec reconciliation (0.5 day) → tag `01-init-project`

- Create the repo skeleton from section 5 (empty dirs with `.gitkeep`, `pyproject.toml`, `uv.lock`, `.env.example`, `.gitignore`, pre-commit, Makefile, CI stub).
- Move the two existing docs in; bump `behavior-spec.md` to **v1.1** so it references policy v1.1 and the three pilot corrections. Record the change in `docs/decisions.md` (ADR-001: behavior, ADR-002: six labels, ADR-003: single-label, ADR-004: generic policy).
- Write `docs/evaluation.md` with the pre-registered metrics from section 2 and the exact prompt-freeze rule.
- Gate: `uv sync` works, `pytest` runs (even with zero tests), CI green, README has the one-paragraph story.

### Phase 1 — Policy v1.1 and pilot as files (1 day) → tags `02-policy-v1.1`, `03-pilot-dataset-v0.1`

- Write `docs/policy.md` = policy v1.1 verbatim (six definitions, precedence, payment boundary, multi-issue rule, HUMAN\_REVIEW semantics, evidence rule, security override, classification procedure, contradiction rule, versioning).
- Update `review-sop.md` to cite `support-triage-policy-v1.1` and add the three anti-patterns the pilot exposed.
- Commit the 30 pilot examples as `data/reviewed/pilot-v0.1.jsonl` in the canonical schema, each with `review_status`, `reviewer_id`, `kept`, `family_id`.
- Write `docs/dataset-generation.md` (the generation and review spec v1.0: scenario matrix, boundary matrix, multi-issue matrix, adversarial patterns, paraphrase families, generator prompt, annotator prompt, review workflow, dedup, leakage, acceptance criteria).
- Gate (Phase 1 exit checklist from the SOP): all 12 items ticked; no unresolved labeling ambiguity in the 30 pilot examples; `policy.md` and `review-sop.md` agree on every rule.

### Phase 2 — Code foundations (2 days) → tag `04-schema-and-validation`

- `schema.py`, `policy.py`, `prompts.py`, `formatter.py`, `parser.py` with tests: schema round-trip on the 30 pilot records, parser on 20 adversarial outputs (markdown fences, trailing text, wrong enum, truncated JSON), formatter produces byte-identical system prompt for train and eval.
- `validate_data.py`, `dedupe.py`, `pii.py` run clean on the pilot.
- Gate: pytest ≥ 25 tests green; `make validate` on pilot passes; a deliberately broken record is rejected.

### Phase 3 — Dataset construction (5 days) → tags `05-scenario-matrix`, `06-generate-candidates`, `07-review-complete`

- `scenario_matrix.yaml`: per label × scenario\_type × difficulty × information\_completeness × conflict\_type, with target counts summing to \~250 candidates (allocation from the spec: SEC 32, ENG 40, BIL 32, RMI 40, SS 28, HR 28 after review ≈ 200).
- `generate_data.py`: scenario-first; the prompt receives policy, scenario spec, forbidden shortcuts; the label is attached from the matrix, never written into the ticket. Log raw responses.
- `annotate_data.py`: blind first pass; outputs decision, confidence, evidence, missing\_information, alternatives. Never sees the matrix label.
- `review_cli.py`: shows ticket first, asks for the human label, then reveals LLM proposal, then asks approve / correct / reject + category. For the first 40 records the human labels before seeing any proposal (independence measurement); compute raw agreement and Cohen's κ between human and LLM, and between human and matrix intent.
- If human–matrix agreement < 85% or any boundary pair shows a consistent disagreement, stop, patch policy (bump to v1.2), re-review affected records, log in `decisions.md`.
- Gate: ≥ 200 records with `kept=true`; every record has reviewer\_id and rationale; `disagreements.jsonl` populated; zero records with `review_status` missing.

### Phase 4 — Dataset audit, split, freeze (1.5 days) → tag `08-freeze-test-set`

- `audit_dataset.py` → `evaluation/dataset-audit.md`: label balance, difficulty mix, completeness mix, boundary-pair coverage (six pairs, each ≥ 8 examples), multi-issue count (≥ 20), adversarial count (≥ 30), contradiction report (semantic-near-duplicates with different labels, each classified), PII scan = 0 hits, leakage-string scan = 0 hits, random-20 manual audit table.
- `split_data.py`: split by `family_id`, stratified by label and difficulty; test set over-weights hard + adversarial (target ≥ 40% of test); 140 / 30 / 30.
- `freeze_test.py`: sha256 of `test.jsonl` into `MANIFEST.json`; `chmod 444`; CI job fails if the hash ever changes under that tag.
- Gate: all acceptance criteria in `dataset-generation.md` §28 pass; MANIFEST committed; `dataset-v1.0` recorded in CHANGELOG.

### Phase 5 — Evaluation harness and baselines (2 days) → tags `09-eval-harness`, `10-base-baseline`, `11-frontier-baseline`

- `metrics.py` + tests vs sklearn; bootstrap CI (1000 resamples, seed 42).
- Prompt engineering is allowed **only on the validation set** and only before the first baseline run on test. Freeze `prompt_system.txt` with a hash in MANIFEST. The same frozen prompt is used for base, frontier and LoRA.
- `run_baseline.py` on validation then test; `run_frontier.py` same. Write both to `predictions/` and `experiments.csv`.
- Review the pre-registered thresholds once against base difficulty; if revised, commit the revision with rationale before any LoRA work.
- Gate: scorecard rows for base and frontier exist with CIs; invalid rate reported; per-class and per-slice tables rendered; failure examples from base recorded (they seed the LoRA hypothesis).

### Phase 6 — LoRA on Tinker (2 days) → tags `12-lora-config`, `13-dry-run`, `14-first-training-run`

- `config.yaml` written as a hypothesis (section 10) with written rationale per field in `docs/lora-report.md` draft.
- `dry_run.py`: 5 examples, 2 steps, prints cost estimate and verifies checkpoint save + sampling round-trip.
- `train.py`: full run; log loss every step; evaluate on validation at each epoch end; save checkpoint IDs; write `cost.json`.
- Select the checkpoint by validation macro-F1 only. Run test **once**.
- Gate: `experiments.csv` row complete; `training/runs/<id>/` contains config snapshot, log, val predictions, cost; test predictions written and never re-run for this config.

### Phase 7 — Evaluation and failure analysis (1.5 days) → tags `15-evaluate-lora`, `16-analyze-failures`

- `evaluate.py` → full three-model `scorecard.json/.md`, confusion matrices, slice tables, deltas with CIs.
- `analyze_failures.py` → `failures.md`: every LoRA error with base and frontier outputs, expected label, root-cause tag {policy\_gap, data\_gap, data\_contradiction, format, capacity, label\_error}, and a proposed training example (added to a *candidate* file, not to the dataset).
- Verdict against the pre-registered criteria, written as PASS/FAIL per metric.
- Gate: ≥ 5 failures fully documented; verdict committed; no dataset or test change made in this phase.

### Phase 8 — One controlled iteration (2 days, optional but expected) → tags `17-dataset-v1.1`, `18-second-run`, `19-final-evaluation`

- Pick exactly one change from `failures.md` root-cause counts: either (a) add contrastive training examples for the dominant data\_gap (new reviewed records → `dataset-v1.1`, test untouched), or (b) one hyperparameter change (rank, epochs, or LR), or (c) a policy clarification (bump v1.2, re-review affected train/val records only).
- Retrain, validate, test once. Both runs stay in `experiments.csv`; the paper reports both.
- Gate: the change is one line in `decisions.md`; test hash unchanged; final scorecard shows run 1 and run 2 side by side.

### Phase 9 — Reproducibility audit and public repo (1 day) → tag `20-reproducibility-audit`

- Fresh clone on a clean machine: `uv sync && make validate && make eval` reproduces the scorecard from committed predictions; `make train` reproduces the config (not the exact weights).
- README: story, how to reproduce, cost, limitations, what would come next (incl. the policy-swap path for a company-specific policy).
- Mermaid diagrams rendered; secrets scan clean; license added.
- Gate: a second person (or a fresh AI session given only the README) can answer the five engineering questions in the brief: which dataset, which config, which checkpoint, how much it cost, how to rerun.

## 9. Evaluation protocol

One harness, three models, zero per-model exceptions. All of this is written into `docs/evaluation.md` before the first baseline run.

**Inference conditions (identical for base, frontier, LoRA)**

- System prompt: `policy/generic-enterprise/prompt_system.txt` (frozen, hashed). Contains the six label definitions, precedence, the three boundary rules, and the output schema. No few-shot examples from any split.
- User template: fixed rendering of the input object (title, description, tier, product, environment, users\_affected, history).
- Temperature 0, max 160 output tokens, single sample. No retries on invalid output; the invalid output is the output.
- Frontier: one named model snapshot, recorded; `seed` passed where supported.

**Metrics (all computed by `metrics.py`, cross-checked against sklearn in tests)**

| Metric | Definition | Why |
| --- | --- | --- |
| Decision accuracy | exact match on `decision`; invalid output = wrong | Primary, matches the brief |
| Macro-F1 | unweighted mean of per-class F1 over six classes | Catches majority-class gaming |
| Per-class P / R / F1 / support | standard | Brief requires per-decision scores |
| Invalid-output rate | share with `parse_status ≠ ok` | Format compliance is part of the behavior |
| Slice accuracy | by difficulty, information\_completeness, conflict\_type, signal\_type, multi-issue flag | Shows whether precedence was learned or keywords memorized |
| Base → LoRA delta, LoRA → frontier gap | difference with bootstrap 95% CI | The actual claims of the paper |
| Priority accuracy | exact match, secondary | Reported, not optimized |
| Reason rubric | 0–2 scale: cites the deciding evidence (1), consistent with label (1); scored by frontier LLM with the rubric, 20-sample human spot check | Secondary; never influences decision scoring |

**Statistical honesty with n = 30**

- A 30-example test set has a 95% CI of roughly ±15 pp on accuracy. Report CIs everywhere; a delta whose CI crosses zero is reported as "not significant", not hidden.
- If budget allows, grow the test set to 50 at the freeze step (before any baseline) to tighten CIs; never afterward.
- Validation set (30) is for checkpoint selection and prompt tuning only; its numbers never appear as results.

**Hard rules**

1. Test file is read by exactly one function (`load_split("test")`) which refuses to run unless `MANIFEST.json` hash matches.
2. Test is evaluated once per (model, config). A second test run for the same config is a protocol violation and is logged as such.
3. No metric, threshold, prompt, or parser rule changes after the first test evaluation. Changes require a new dataset or protocol version and a fresh freeze.
4. Majority-class and random baselines are reported in the scorecard as sanity rows.

## 10. LoRA experiment design

The config is a hypothesis with a written reason per field. Numbers below are the starting proposal; they are confirmed or revised in Phase 6 after the base baseline, and the final values plus rationale go into `docs/lora-report.md`.

```yaml
# training/config.yaml  — run_id is derived: lora_r{rank}_a{alpha}_e{epochs}_s{seed}
base_model: "<exact Qwen string from the Tinker model list>"   # record at kickoff
adapter:
  rank: 8            # ~140 train examples, one narrow behavior: small capacity, less memorization
  alpha: 16          # alpha/rank = 2 keeps update scale conventional; vary only in a later run
  target_modules: [q_proj, k_proj, v_proj, o_proj]   # attention only for run 1; MLP added only if run 1 under-fits
  dropout: 0.05
optim:
  learning_rate: 1.0e-4   # start of the conventional LoRA range; halve if val loss oscillates
  epochs: 3                # 140 ex × 3 ≈ 420 example-passes; checkpoint each epoch, pick by val macro-F1
  batch_size: 8
  warmup_steps: 5
  weight_decay: 0.0
  max_seq_len: 1024
  loss_on: assistant_only
seed: 42
data:
  dataset_version: dataset-v1.0
  train: data/train.jsonl
  validation: data/validation.jsonl
  manifest: data/MANIFEST.json
budget:
  max_cost_usd: <from .env>
  stop_if_val_f1_drops_for_epochs: 2
```

**Rationale skeleton for `lora-report.md` (the brief's required explanations)**

| Field | Reason to write down |
| --- | --- |
| Base model | Why this Qwen size: fits the "small model" premise, instruction-tuned so JSON output is reachable before fine-tuning, on Tinker's list, cost per step |
| Rank / alpha | Capacity vs dataset size; the ΔW = B·A parameter count for the chosen layers (compute and state it: e.g. for a d×d projection, 2·d·r params per module) |
| Target modules | Attention projections carry the "which evidence matters" signal; MLP left frozen in run 1 to keep the ablation clean |
| LR / epochs | Small dataset → few epochs; selection by validation, not by test |
| Cost | From `cost.json`: tokens, steps, USD; compare to the frontier baseline's inference cost per 1,000 tickets |

**What a successful LoRA run must show**

- Train loss decreases monotonically-ish; val macro-F1 improves over the prompted base by epoch 2; no epoch where val F1 rises while train loss collapses to \~0 (memorization signal).
- Slice analysis: the gain must appear on `conflict_type ≠ none` and `difficulty ∈ {hard, adversarial}` slices, not only on `easy`. Gain only on easy = keyword learning, reported as such.
- Invalid-output rate drops below base.

**Iteration rule (one change per run)**

| If failure analysis shows | Change | Not allowed |
| --- | --- | --- |
| Dominant `data_gap` on one boundary pair | Add ≥ 10 contrastive reviewed examples for that pair → dataset-v1.1 | Touching test |
| Dominant `capacity` (under-fit, val F1 flat) | rank 8 → 16 or add MLP modules | Also changing LR in the same run |
| Over-fit (train loss → 0, val F1 drops) | epochs 3 → 2 or dropout 0.1 | Adding data at the same time |
| Dominant `policy_gap` | policy v1.2 + re-review affected train/val only | Re-labeling test |
| Dominant `format` | Fix formatter/prompt → new prompt hash → new baselines too | Changing parser leniency |

**Not in v1:** full fine-tuning, QLoRA comparisons, multiple seeds (report as a limitation), merging the adapter for deployment.

## 11. Risk register

| # | Risk | Likelihood | Impact | Mitigation (built into the plan) | Detection |
| --- | --- | --- | --- | --- | --- |
| 1 | Test-set contamination (paraphrase of a test ticket in train) | High | Fatal | Family-aware split; semantic-dup scan across splits at freeze; CI hash check | `audit_dataset.py` cross-split similarity > 0.90 = fail |
| 2 | Model learns keywords, not policy | High | High | Adversarial slice ≥ 30 examples; keyword-bait, negation, historical-mention patterns; slice reporting mandatory | Gain only on `easy` slice |
| 3 | Label noise from synthetic data | High | High | Blind LLM annotation + human review; κ measured on first 40; rejected records kept with reason | κ < 0.7 or human–matrix agreement < 85% halts Phase 3 |
| 4 | HUMAN\_REVIEW / REQUEST\_MORE\_INFORMATION become dump classes | Medium | High | Explicit semantics in policy v1.1; negative examples ("contract" words → SELF\_SERVICE); contradiction audit question 5–6 | Class recall high but precision low |
| 5 | Single reviewer (Varun) = no true inter-annotator agreement | High | Medium | Time-separated self-review (re-label 40 records ≥ 48 h later, blind) + LLM as second annotator; declare this limitation in the paper; recruit one Nugen engineer for the random-20 audit if possible | — |
| 6 | 30-example test set too small to show significance | High | Medium | Report CIs; grow test to 50 at freeze if budget allows; frame results honestly | CI crosses zero |
| 7 | Invalid JSON from base model inflates LoRA's apparent gain | Medium | Medium | Report accuracy both with invalid=wrong and on the valid-only subset; invalid rate is its own metric | Base invalid rate > 10% |
| 8 | Prompt tuned on test by accident | Medium | Fatal | Prompt frozen and hashed before any test run; validation-only tuning rule in `evaluation.md` | Prompt hash change after tag 10 |
| 9 | Tinker API or model list changes mid-project | Medium | Medium | Pin SDK version in `uv.lock`; record exact model string; `dry_run.py` as early smoke test in Phase 6 day 1 | Dry run fails |
| 10 | Cost overrun | Medium | Medium | `MAX_COST_USD` gate in every script; cost ledger; dry-run estimate before full train | Ledger ≥ 80% budget |
| 11 | Over-fitting on 140 examples | Medium | Medium | Rank 8, 3 epochs, checkpoint by val F1, early stop on val drop; memorization check (train loss → 0) | Train loss < 0.05 with val F1 falling |
| 12 | Scope creep (agent, UI, RAG, Nexora integration) | Medium | High | Section 1 non-goals; ADR required for any new component; Nexora adaptation is a separate project | Any PR touching `src/` outside the listed modules |
| 13 | Frontier model non-determinism | Low | Low | Temperature 0, seed, snapshot ID; run once; note residual variance | — |
| 14 | Part A / B / D starve the core experiment of time | High | Medium | Parallel tracks (section 13) with fixed weekly slots; Part C gates come first | Weekly review of the timeline |
| 15 | PII slips into a public dataset | Low | High | PII scan blocks records; synthetic-only tickets; secrets scan before going public | 0 hits required at freeze |

## 12. Reproducibility and governance

The standard: a stranger with the repo and an API key reproduces every number in the scorecard from committed predictions, and every training run from a committed config.

**Versioned things and where the version lives**

| Thing | Version scheme | Recorded in |
| --- | --- | --- |
| Policy | `support-triage-policy-vX.Y` | `docs/policy.md` header; every canonical record |
| Dataset | `dataset-v0.1` (pilot) → `v0.2` (reviewed, unsplit) → `v1.0` (frozen) → `v1.1` (iteration) | `data/MANIFEST.json`, `data/CHANGELOG.md` |
| Prompt | sha256 of `prompt_system.txt` | MANIFEST, every prediction file header |
| Run | `lora_r8_a16_e3_s42` + Tinker checkpoint ID | `experiments.csv`, `training/runs/<id>/config.yaml` (snapshot) |
| Protocol | `eval-protocol-v1` | `docs/evaluation.md` header; scorecard |
| Decisions | ADR-001… dated | `docs/decisions.md` |

**Git discipline**

- Commits follow the numbered tag sequence (`01-init-project` … `20-reproducibility-audit`); each tag is a reviewable checkpoint. Small commits inside each phase are fine; the tag marks the gate.
- Branch per phase, squash-free merge to `main` so the research trail stays readable.
- `predictions/`, `evaluation/`, `data/` are committed (small, text); checkpoints and raw LLM logs are not.

**CI (GitHub Actions on every push)**

1. `uv sync --frozen`
2. `ruff check`
3. `pytest`
4. `python scripts/validate_data.py data/reviewed data/*.jsonl`
5. `python scripts/freeze_test.py --verify` (fails if `test.jsonl` hash ≠ MANIFEST after tag 08)
6. `gitleaks detect`

**Paper-grade traceability**

- Every table in the paper is generated by `make tables` from `scorecard.json` and `experiments.csv`; no hand-typed numbers.
- Figures (confusion matrices, slice bars, loss curves) are generated by `make figures` into `paper/figures/` with the run ID in the filename.
- The README lists: dataset version, policy version, prompt hash, run IDs, checkpoint IDs, total cost, and the exact commands to reproduce.

**Decision log format (`docs/decisions.md`)**

```markdown
## ADR-007 — 2026-10-24 — Test set grown to 50 before freeze
Context: 30-example CI too wide (±15 pp).
Decision: allocate 20 more reviewed hard/adversarial examples to test before freeze.
Consequence: train stays 140; validation 30; test 50; budget +$X.
Status: accepted
```

## 13. Parallel tracks — Part A, Part B, Part D

These run alongside Part C in fixed weekly slots so they do not stall the experiment. Part C gates always win a scheduling conflict.

### Part A — Architecture white paper (Qwen vs Llama vs Mistral)

| Step | Output | Done when |
| --- | --- | --- |
| A1 Lens | `research/lens.md`: the block list every model is described through — tokenizer, vocab, embedding, norm (pre/post, RMSNorm), position (RoPE variants), attention (MHA/GQA/MQA, KV heads, sliding window), FFN (width, SwiGLU/GeGLU), depth, width, tied output head, context length, training data scale | 14 rows, each with a one-line "what it controls" |
| A2 Per-model notes | `research/qwen.md`, `llama.md`, `mistral.md`: filled lens table + 3 ablations/trade-offs each, from the official papers/tech reports only; each drawn from memory once, then checked | Master comparison table complete with citations |
| A3 Design changes | `research/design-changes.md`: ≥ 5 entries in the form Problem → Idea → Architecture change → Result → Cost (e.g. KV-cache memory → GQA; long context → RoPE scaling; inference cost → sliding-window attention; FFN quality → SwiGLU; vocab coverage vs embedding size) | Each entry cites the paper and states the trade-off numerically where available |
| A4 Paper | `paper/main.tex` in the brief's 11-section structure + reading-log appendix; 10–15 pages; figures from `research/` | Compiles; every claim has a reference; reading log ≥ 15 entries |

Self-test before submitting: answer the architecture questions in the original plan (why GQA, why RoPE, why SwiGLU, width vs parameter count, vocabulary trade-off) without notes.

### Part B — LoRA explainer video (Manim; Beamer fallback)

- `lora-video/script.md` first: 15 scenes, one tensor through the whole video — WQ 32×64, r=4 → A 4×64, B 32×4, B·A 32×64; parameter count 2,048 vs 512; B initialized to zero so W' = W at step 0; alpha as a scale on B·A; rank 1 → 4 → 8 visual; merge W + B·A; final scene shows the real `config.yaml` numbers and the real parameter count for the chosen Qwen layers.
- Build order: script → storyboard (one sketch per scene) → Manim scenes 1–5 (static tensors) → scenes 6–12 (animations) → 13–15 (training, merge, our config) → voice/caption → render.
- Fallback trigger: if Manim scenes 1–5 are not working by the end of week 5, switch to Beamer with the same storyboard.
- Done when: a viewer can answer "why two matrices, why B starts at zero, what rank controls, what alpha does" from the video alone.

### Part D — Build-in-public (150–200 pieces)

- `content/backlog.md`: the knowledge tree from the original plan (Architecture ≈ 40 nodes, LoRA ≈ 30, SLM/dataset/eval ≈ 60, failures/costs/scorecards ≈ 30, meta/lessons ≈ 20). Each node = one post idea with a tag and the phase that produces its evidence.
- Cadence: 1 post per working day from Phase 1 onward, written in the last 20 minutes of the day from that day's commit; batch-write 3 on Fridays from the week's `decisions.md` and `failures.md`.
- Mandatory content types (brief asks for them): every policy correction, every κ number, every disagreement category count, the base scorecard before LoRA, the dry-run cost, the first LoRA result even if it fails, every failure example, the final cost.
- Format: short text + one image (Mermaid render, confusion matrix, table screenshot); long-form weekly recap on LinkedIn; threads elsewhere. Nothing from `test.jsonl` is ever posted.

## 14. Timeline and effort

Eight weeks from the kickoff chat, assuming \~3–4 focused hours per working day. Dependency order is what matters; the calendar can slip, the gates cannot be skipped.

| Week | Part C (core, gated) | Part A | Part B | Part D |
| --- | --- | --- | --- | --- |
| 1 | Phase 0 + Phase 1: repo, policy v1.1 as file, pilot committed, dataset spec | A1 lens | Script outline | Backlog written; posts start |
| 2 | Phase 2: schemas, parser, validator, tests | A2 Qwen notes | Storyboard | daily |
| 3 | Phase 3: scenario matrix, generate \~250, blind annotate, start review (first 40 blind + κ) | A2 Llama notes | — | daily |
| 4 | Phase 3 finish review; Phase 4 audit, split, **freeze test** | A2 Mistral notes | Scenes 1–5 | daily |
| 5 | Phase 5: eval harness, prompt freeze, base + frontier baselines, threshold confirmation | A3 design changes | Scenes 6–12 (fallback decision end of week) | daily |
| 6 | Phase 6 + 7: dry run, LoRA run 1, test once, scorecard, failure analysis | A4 paper draft | Scenes 13–15 | daily + first scorecard post |
| 7 | Phase 8: one controlled change, run 2, final evaluation; `lora-report.md` | A4 paper final | Render + captions | daily |
| 8 | Phase 9: reproducibility audit, README, diagrams, public release | Proof-read | Publish | Final recap series; hit 150–200 |

**Effort by phase (Part C only):** P0 0.5 d · P1 1 d · P2 2 d · P3 5 d · P4 1.5 d · P5 2 d · P6 2 d · P7 1.5 d · P8 2 d · P9 1 d ≈ 18.5 working days. Human review in Phase 3 is the long pole (≈ 250 records × 2–3 min ≈ 10 h); it cannot be delegated to the LLM.

**Kill / pause criteria**

- Human–matrix agreement < 85% after two policy revisions → stop and redesign the label set (likely merge or redefine a class) before generating more data.
- Base model invalid-output rate > 25% with the frozen prompt → the chosen Qwen size cannot follow the format; move one size up before training.
- Cost ledger reaches 80% of budget before Phase 6 → cut Phase 8, report run 1 only.

## 15. Kickoff prompt for the new chat

Attach this document (exported as Markdown) plus the Antern brief, `behavior-spec.md` v1.0 and `review-sop.md`, then send:

```markdown
You are my AI/ML engineering lead for the attached project: "Support Triage SLM — Master Build Plan v1.0".

Context
- Mentor brief: antern-brief-v4 (attached). Parts A–D all required.
- Repo state: only docs/behavior-spec.md v1.0 and docs/review-sop.md exist. Policy v1.1, the 30-example pilot, and the dataset-generation spec exist only as chat transcripts (attached) and must be turned into files first.
- Operating rules: section 0 of the plan. Phases and gates: section 8. Do not skip a gate. Do not reopen decisions in section 2.

Your job in this chat
1. Confirm you have read the plan by listing the Phase 0 and Phase 1 outputs and their commit tags — nothing else.
2. Execute Phase 0: produce the repo skeleton (every file in section 5 that is Phase 0), pyproject.toml, Makefile, CI stub, .env.example, and docs/decisions.md with ADR-001..004. Give me the files, not a description.
3. Execute Phase 1: write docs/policy.md (v1.1 verbatim from the transcript, no silent edits), bump behavior-spec.md to v1.1 with a change-history entry, write docs/dataset-generation.md, and convert the 30 pilot examples into data/reviewed/pilot-v0.1.jsonl in the canonical schema from section 7.1.
4. Stop at the Phase 1 gate and present the exit checklist from review-sop.md §27 with each item marked done/not done and the evidence.

Rules for this chat
- Ask before inventing: if a value is missing (Tinker model string, budget, reviewer id), ask me in one message with the options.
- Never write code before Phase 1's gate passes.
- Every artifact you produce must be a complete file with its path. Partial snippets are not acceptable.
- When you disagree with the plan, say so with a reason and a proposed ADR; do not silently deviate.
- Keep responses to the deliverable; no recap of the plan.

Start with step 1.
```

Subsequent chats follow the same pattern: attach the plan + the repo state, name the phase, demand files, stop at the gate.

## 16. Open questions to resolve at kickoff

Answer these in the first message of the new chat; each becomes an ADR.

- [ ] **Tinker base model string** — which Qwen size is on the Tinker model list today, and which one fits the budget? (Default: the smallest instruction-tuned Qwen3 that passes the format test in the base baseline.)
- [ ] **Budget** — `MAX_COST_USD` for the whole project and the 25 / 15 / 50 / 10 split from section 6. (Default: set it before Phase 3 starts; generation is the first paid step.)
- [ ] **Frontier model** — Claude or GPT for the frontier baseline, and which one for generation/annotation. Using the same vendor for both is acceptable but must be stated as a limitation.
- [ ] **Second reviewer** — is there a Nugen engineer who can do the blind 40-record pass and the random-20 audit? If not, the time-separated self-review in risk #5 applies and the paper says so.
- [ ] **Test-set size** — stay at 30 (plan) or grow to 50 at freeze for tighter CIs? Decide before Phase 4; never after.
- [ ] **Priority field** — keep `priority` in the output for run 1 (adds a secondary metric, slightly harder format) or drop it to `decision` + `reason` only? (Default: keep; it is in the frozen behavior spec.)
- [ ] **Public repo timing** — public from day one (build-in-public) or private until Phase 9? (Default: public from Phase 1 with `data/raw/_logs/` ignored.)
- [ ] **Nugenova follow-on** — confirm it stays out of this repo; the only accommodation is the `policy/_template/` directory and the policy-parameterized scripts, so a Nexora-specific policy and ticket schema can be dropped in as a second experiment later.
- [ ] **Manim environment** — local install works, or fall back to Beamer immediately to protect the schedule?
- [ ] **Timeline** — are 8 weeks at 3–4 h/day realistic alongside Nugen work, or should Part B and the Part D cadence be reduced from the start?

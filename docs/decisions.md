# Architecture Decision Records

Dated decisions and why they were made. One entry per decision; entries are never edited after acceptance — a reversal is a new ADR that supersedes the old one.

Format: Context → Decision → Consequence → Status.

---

## ADR-001 — 2026-10-15 — One behavior: enterprise support-ticket triage

**Context:** The mentor brief (Antern v4, Part C) requires fine-tuning a small model on *one specific behavior* and explaining why prompting alone is insufficient. A broad "support assistant" would mix several behaviors (classification, reply drafting, retrieval) and make any improvement impossible to attribute.

**Decision:** The model does exactly one thing: given a ticket and its context, output the single operational action support should take next, according to a fixed policy. Output is `{decision, priority, reason}`; `decision` is the only primary objective.

**Consequence:** Agents, RAG, vector DBs, UI, API, auto-resolution and reply generation are out of scope (build plan §1). `priority` and `reason` are scored as secondary metrics and never used to choose the decision. Specified in `docs/behavior-spec.md`.

**Status:** accepted

---

## ADR-002 — 2026-10-15 — Six mutually exclusive decision labels

**Context:** The label set has to cover the realistic next actions of an enterprise support desk, while staying small enough that ~140 training examples give every class meaningful support.

**Decision:** `ROUTE_TO_SECURITY`, `ROUTE_TO_ENGINEERING`, `ROUTE_TO_BILLING`, `REQUEST_MORE_INFORMATION`, `SELF_SERVICE`, `HUMAN_REVIEW`. Conflicts are resolved by the precedence SECURITY → ENGINEERING → BILLING → SELF_SERVICE → REQUEST_MORE_INFORMATION → HUMAN_REVIEW, applied only when the higher signal is genuine.

**Consequence:** Adding, merging or renaming a label requires a policy version bump and re-review of the whole dataset. `HUMAN_REVIEW` and `REQUEST_MORE_INFORMATION` have tight semantics (policy v1.1) so they cannot become dump classes. If human–matrix agreement stays below 85% after two policy revisions, the label set is redesigned (build plan §14 kill criteria).

**Status:** accepted

---

## ADR-003 — 2026-10-15 — Single-label classification

**Context:** Real tickets often contain several issues (e.g. a dashboard outage plus a contract question). Multi-label output would need a different loss, a different metric set and far more data per label combination.

**Decision:** Every ticket gets exactly one label: the highest-priority *actionable* issue under the precedence rules. Secondary issues change nothing unless they alter the risk, ownership or urgency of the primary one (policy v1.1, multi-issue rule).

**Consequence:** Multi-issue tickets are part of the dataset (target ≥ 20) and form their own evaluation slice. Multi-label routing is an explicit non-goal.

**Status:** accepted

---

## ADR-004 — 2026-10-15 — Generic enterprise policy, not a named company

**Context:** A named company's policy would bring proprietary rules, real customer data and PII risk into a public repo, and would tie the experiment to one organisation.

**Decision:** The experiment runs on a generic enterprise support policy (`support-triage-policy-v1.1`) with synthetic tickets only. The pipeline is policy-parameterized: a company-specific policy (e.g. Nugenova/Nexora) is supported later by swapping `policy.md` and the scenario matrix under `policy/<name>/`, not by rewriting scripts.

**Consequence:** No real tickets enter the repo. `policy/_template/` is reserved for a later company-specific policy; building it is a separate project.

**Status:** accepted

---

## ADR-005 — 2026-10-15 — Master Build Plan v1.0 adopted; earlier scaffold discarded

**Context:** The repo had 35 empty placeholder files whose layout (e.g. `evaluation/metrics.py`, `scripts/detect_duplicates.py`, `research/architecture/`) didn't match the Master Build Plan's repository layout (§5). Only `docs/behavior-spec.md`, `docs/review-sop.md` and a week-by-week outline held content.

**Decision:** Restart from the plan. All empty placeholders were deleted. `docs/build-plan.md` is the copy of the plan in the repo and the source of truth for phases, gates and layout. The week outline and self-test questions are kept in `docs/execution-sequence.md`; the plan's §14 timeline supersedes the week outline. Script names in `review-sop.md` §28 are superseded by build plan §5 and get updated in Phase 1.

**Consequence:** Directories are created with `.gitkeep`; a file appears only in the phase that gives it content, so an empty file never passes for a finished artifact.

**Status:** accepted

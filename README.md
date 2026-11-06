# slm-support-triage

Can a small Qwen model, fine-tuned with LoRA on ~140 human-reviewed examples, apply a fixed enterprise support-triage policy more consistently than the same model prompted, and how far does it sit from a frontier model under identical conditions? Each ticket is classified into one of six operational actions (`ROUTE_TO_SECURITY`, `ROUTE_TO_ENGINEERING`, `ROUTE_TO_BILLING`, `REQUEST_MORE_INFORMATION`, `SELF_SERVICE`, `HUMAN_REVIEW`) according to a written policy. Synthetic tickets are generated from a scenario matrix, labelled by policy plus a human reviewer (never by the generator), split by scenario family, and scored on a test set that is frozen and hashed before any model sees it. Success criteria are pre-registered in [docs/evaluation.md](docs/evaluation.md) and a miss is reported as a miss.

> **Status:** Phase 0, repo bootstrap. No data, no scripts and no results yet.

## Where things are

| | |
|---|---|
| Build plan (source of truth) | [docs/build-plan.md](docs/build-plan.md) |
| Behavior contract | [docs/behavior-spec.md](docs/behavior-spec.md) |
| Annotation SOP | [docs/review-sop.md](docs/review-sop.md) |
| Evaluation protocol + pre-registration | [docs/evaluation.md](docs/evaluation.md) |
| Decision log | [docs/decisions.md](docs/decisions.md) |

## Setup

Requires [uv](https://docs.astral.sh/uv/).

```bash
uv sync
make check
```

Copy `.env.example` to `.env` before any phase that calls a paid API.

## Scope

One behavior, six classes, single label. No agent, RAG, vector DB, UI or API. See build plan §1.

# Evaluation Protocol

**Document:** `docs/evaluation.md`
**Protocol version:** `eval-protocol-v1`
**Policy:** `support-triage-policy-v1.1`
**Status:** Draft — Phase 0. The pre-registration section is **locked at tag `10-base-baseline`** (after the one permitted threshold review; see §2.3).

One harness, three models, no per-model exceptions. This file is written before any data exists, so that no metric, threshold or rule can be fitted to results.

---

## 1. Systems under comparison

| ID | System | Notes |
|---|---|---|
| `base` | Qwen base model (exact Tinker model string recorded in `training/config.yaml`) + frozen system prompt | The prompted baseline the brief requires |
| `lora` | Same Qwen + LoRA adapter trained on Tinker + the same frozen prompt | The only difference from `base` is the adapter |
| `frontier` | One named frontier model snapshot (Claude or GPT; decided at kickoff, ADR pending) + the same frozen prompt | Upper reference point |
| `majority` / `random` | Sanity rows | Reported in the scorecard; never a claim |

---

## 2. Pre-registered success criteria

### 2.1 Hypotheses

- **H1:** LoRA-Qwen beats prompted base-Qwen on the frozen test set by ≥ 10 percentage points of decision accuracy and reaches macro-F1 ≥ 0.85.
- **H0:** Fine-tuning gives no meaningful improvement over prompting. H0 is an acceptable outcome if it is measured honestly.

### 2.2 Criteria

| # | Metric | Target | Applies to |
|---|---|---|---|
| C1 | Decision accuracy (test) | ≥ 85% | `lora` |
| C2 | Macro-F1 over six classes (test) | ≥ 0.85 | `lora` |
| C3 | Base → LoRA accuracy delta | ≥ +10 pp | `lora` vs `base` |
| C4 | Invalid / unparseable output rate | < 2% | `lora` |
| C5 | Adversarial-slice accuracy | Materially above base; reported as delta + 95% CI | `lora` vs `base` |
| C6 | Per-class precision / recall / F1 / support | Reported for all 6 classes | all three |
| C7 | Documented failure examples | ≥ 5 | `lora` |

Each criterion is reported as **PASS / FAIL** at Phase 7. A miss is reported as a miss and investigated; it's never re-framed.

### 2.3 The one permitted revision

Thresholds C1–C5 may be revised **once**, after the base baseline reveals how hard the task is and **before any LoRA run**. The revision is committed to this section with a dated rationale and an ADR in `docs/decisions.md`. After that, the section is locked.

| Date | Change | Rationale | ADR |
|---|---|---|---|
| — | none yet | — | — |

---

## 3. Inference conditions (identical for all models)

- **System prompt:** `policy/generic-enterprise/prompt_system.txt`. It contains the six label definitions, the precedence, the boundary rules and the output schema. No few-shot examples from any split.
- **User message:** fixed rendering of the input object (title, description, tier, product, environment, users_affected, history), produced by `src/triage/formatter.py`.
- **Decoding:** temperature 0, max 160 output tokens, a single sample.
- **No retries.** An invalid output stands as the output.
- **Frontier:** one named model snapshot, recorded; `seed` passed where the API supports it; `system_fingerprint` / snapshot ID logged.
- **LoRA training serialization** uses the byte-identical system prompt and user template (build plan §7.2), so the adapter is the only variable between `base` and `lora`.

---

## 4. Prompt-freeze rule

1. Prompt engineering is allowed **only against the validation split**, and only **before the first baseline run on test**.
2. Once frozen, the sha256 of `prompt_system.txt` (and of the user template) is written into `data/MANIFEST.json` and into the header of every prediction file.
3. The same frozen prompt is used for `base`, `frontier` and `lora`. A model never gets its own prompt variant.
4. Any change to the prompt after freezing means a new prompt hash, **new baselines for all models**, and a protocol version bump. A run evaluated under an old hash is never compared directly with one under a new hash.

---

## 5. Output parsing

Expected output: a single JSON object `{"decision": ..., "priority": ..., "reason": ...}`.

| `parse_status` | Meaning |
|---|---|
| `ok` | Valid JSON object, all three fields present, `decision` in the six-label set, `priority` in {P1..P4} |
| `invalid_json` | Not parseable as one JSON object |
| `invalid_label` | `decision` (or `priority`) outside the allowed vocabulary |
| `missing_field` | One or more required fields absent |
| `truncated` | Output hit the token limit before the object closed |

Rules:

- Anything other than `ok` scores as **wrong** on decision accuracy **and** counts toward the invalid-output rate.
- No regex rescue of near-JSON and no lenient repair. Strictness is identical for all three models.
- Accuracy is also reported on the valid-only subset, so a base model's format failures can't silently inflate the LoRA gain (risk #7).

---

## 6. Metrics

All computed by `src/triage/metrics.py` and cross-checked against `sklearn.metrics` in tests.

| Metric | Definition | Role |
|---|---|---|
| Decision accuracy | Exact match on `decision`; invalid = wrong | Primary |
| Macro-F1 | Unweighted mean of per-class F1 over the six classes | Primary (catches majority-class gaming) |
| Per-class P / R / F1 / support | Standard | Required by the brief |
| Invalid-output rate | Share of `parse_status ≠ ok` | Format compliance is part of the behavior |
| Slice accuracy | By `difficulty`, `information_completeness`, `conflict_type`, `signal_type`, multi-issue flag | Shows whether the model learned precedence or memorized keywords |
| Base → LoRA delta; LoRA → frontier gap | Difference with paired bootstrap 95% CI | The paper's actual claims |
| Priority accuracy | Exact match on `priority` | Secondary; reported, never optimized |
| Reason rubric | 0–2: cites the deciding evidence (1) + consistent with the label (1); scored by the frontier LLM with a 20-sample human spot check | Secondary; never affects decision scoring |

A correct priority never compensates for a wrong decision.

---

## 7. Statistical honesty

- With n = 30 the 95% CI on accuracy is roughly ±15 pp. CIs are reported everywhere; a delta whose CI crosses zero is reported as **not significant**, not hidden.
- Bootstrap: 1,000 resamples, seed 42.
- The test set may grow to 50 **at the freeze step only**, before any baseline (open question at kickoff). Never afterward.
- Validation numbers are used for checkpoint selection and prompt tuning only. They never appear as results.

---

## 8. Hard rules

1. `test.jsonl` is read by exactly one function, `load_split("test")`, which refuses to run unless the file's sha256 matches `data/MANIFEST.json`.
2. Test is evaluated **once per (model, config)**. A second test run for the same config is a protocol violation and is logged as such in `docs/decisions.md`.
3. No metric, threshold, prompt or parser rule changes after the first test evaluation. A change requires a new dataset or protocol version and a fresh freeze.
4. Majority-class and random baselines appear in every scorecard as sanity rows.
5. Every number in a report traces to a committed file: dataset version + prompt hash + config + run ID.

# Enterprise Support Ticket Triage SLM

**Document:** `docs/behavior-spec.md`  
**Version:** 1.0  
**Status:** Draft — Phase 0  
**Primary behavior:** Enterprise support ticket triage  
**Model family:** Small Qwen model + LoRA  
**Policy scope:** Generic enterprise support environment

---

## 1. Problem Statement

Enterprise support teams receive tickets covering technical failures, security incidents, billing problems, known issues, and incomplete requests.

The objective of this project is to build a small language model that can consistently classify an incoming support ticket into the correct operational action according to a predefined enterprise support policy.

The model is not intended to solve the customer's problem.

Its primary responsibility is:

> **Given a support ticket and its available context, determine the correct operational action according to the defined support-triage policy.**

The project will investigate whether LoRA fine-tuning can make a small Qwen model more consistently aligned with this organization-specific decision policy than the prompted base model.

---

## 2. Specific Model Behavior

### Input

The model receives:

- customer information
- product information
- ticket title
- ticket description
- optional conversation history
- optional operational metadata

### Output

The model produces:

1. `decision` — primary prediction
2. `priority` — secondary prediction
3. `reason` — concise explanation

Example:

```json
{
  "decision": "ROUTE_TO_ENGINEERING",
  "priority": "P1",
  "reason": "A production issue is affecting multiple users."
}
```

### Primary objective

The most important output is:

```text
decision
```

The experiment therefore prioritizes **decision accuracy and per-class performance** over explanation quality.

---

## 3. Scope

The model covers six operational decisions:

```text
ROUTE_TO_SECURITY
ROUTE_TO_ENGINEERING
ROUTE_TO_BILLING
REQUEST_MORE_INFORMATION
SELF_SERVICE
HUMAN_REVIEW
```

The policy is intentionally generic rather than representing one real company.

The objective is to demonstrate the mechanics of organization-specific SLM behavior without introducing real customer data or proprietary information.

---

## 4. Non-Goals

This project does not attempt to build:

- a customer-facing chatbot
- an autonomous support agent
- an agentic workflow
- a RAG system
- a ticket-management application
- an automated ticket-resolution system
- a production support API
- a general-purpose support model
- a model optimized primarily for inference speed
- a guardrail or safety framework

These may be valid future projects, but including them here would weaken the experiment by introducing variables unrelated to the core fine-tuning question.

---

# 5. Input Schema

The conceptual input format is:

```json
{
  "customer_tier": "enterprise",
  "product": "analytics",
  "ticket_title": "Users cannot access dashboard",
  "ticket_description": "All users started receiving 500 errors after today's deployment.",
  "conversation_history": [],
  "metadata": {
    "users_affected": 120,
    "environment": "production"
  }
}
```

## 5.1 Field definitions

### `customer_tier`

Examples:

```text
free
standard
business
enterprise
```

This field may affect priority but should not automatically determine the operational decision.

### `product`

The product or service involved in the ticket.

Examples:

```text
analytics
payments
identity
messaging
storage
```

### `ticket_title`

Short summary provided by the customer or support system.

### `ticket_description`

Primary natural-language description of the issue.

### `conversation_history`

Optional previous interaction between the customer and support team.

An empty history is valid.

### `metadata`

Optional structured operational context.

Examples:

```text
users_affected
environment
region
timestamp
deployment_status
```

Metadata must not be treated as universally available.

The dataset must contain examples where important information is absent.

---

# 6. Output Schema

The canonical output format is:

```json
{
  "decision": "ROUTE_TO_ENGINEERING",
  "priority": "P1",
  "reason": "A production issue is affecting multiple users."
}
```

## 6.1 Decision

Must be exactly one of:

```text
ROUTE_TO_SECURITY
ROUTE_TO_ENGINEERING
ROUTE_TO_BILLING
REQUEST_MORE_INFORMATION
SELF_SERVICE
HUMAN_REVIEW
```

## 6.2 Priority

Initial priority vocabulary:

```text
P1
P2
P3
P4
```

Priority is secondary to the project objective.

The evaluation must not allow a correct priority to compensate for an incorrect decision.

Example:

```text
Correct:
decision = ROUTE_TO_ENGINEERING
priority = P2

Incorrect:
decision = ROUTE_TO_BILLING
priority = P1
```

The second prediction is a failure.

## 6.3 Reason

A short explanation of why the decision was selected.

The reason should reference evidence from the ticket rather than inventing facts.

---

# 7. Decision Taxonomy

## 7.1 ROUTE_TO_SECURITY

Use when the ticket indicates:

- suspected account compromise
- unauthorized access
- suspicious authentication activity
- credential compromise
- data exposure
- security vulnerability
- privacy/security incident
- suspicious transactions where security compromise is indicated

### Example

> "We noticed an unknown login from another country and the account settings were changed."

Decision:

```text
ROUTE_TO_SECURITY
```

---

## 7.2 ROUTE_TO_ENGINEERING

Use when the ticket indicates:

- software defects
- service failures
- production outages
- repeated technical errors
- integration failures
- API failures
- system degradation
- technical problems requiring engineering investigation

### Example

> "Every user in our organization receives a 500 error when opening the analytics dashboard after today's deployment."

Decision:

```text
ROUTE_TO_ENGINEERING
```

---

## 7.3 ROUTE_TO_BILLING

Use when the primary issue concerns:

- incorrect invoices
- duplicate charges
- subscription charges
- payment failures
- refunds
- billing configuration
- plan charges
- account billing

### Example

> "We were charged twice for this month's subscription."

Decision:

```text
ROUTE_TO_BILLING
```

---

## 7.4 REQUEST_MORE_INFORMATION

Use when the available information is genuinely insufficient to determine the appropriate operational action.

This class must **not** become a generic fallback for difficult tickets.

### Example

> "The system isn't working. Please help."

There is insufficient information to determine whether the issue is billing, engineering, security, or something else.

Decision:

```text
REQUEST_MORE_INFORMATION
```

---

## 7.5 SELF_SERVICE

Use when:

- the problem is a known/common issue
- the required resolution is documented
- no specialist intervention is necessary
- the ticket contains enough information to identify the known procedure

### Example

> "I forgot my password. How can I reset it?"

Decision:

```text
SELF_SERVICE
```

The model should recognize the known procedure rather than route every authentication-related issue to security.

---

## 7.6 HUMAN_REVIEW

Use when the policy explicitly requires human judgment because the case is:

- exceptional
- materially ambiguous despite sufficient information
- legally/commercially sensitive
- outside established policy
- dependent on a business decision that cannot be safely automated

`HUMAN_REVIEW` is **not** synonymous with:

> "The model finds this example difficult."

A difficult but policy-resolvable ticket must still receive its correct operational decision.

---

# 8. Decision Policy

The model must follow the policy rather than relying solely on superficial keywords.

## 8.1 Security takes priority when genuine security risk is present

Example:

> "Someone accessed our account without authorization. We also noticed a duplicate invoice."

Correct:

```text
ROUTE_TO_SECURITY
```

The presence of billing information does not override the security concern.

---

## 8.2 Engineering takes priority for genuine technical incidents

Example:

> "The API returns 500 errors for every request after deployment."

Correct:

```text
ROUTE_TO_ENGINEERING
```

---

## 8.3 Billing issues go to billing when no higher-risk issue exists

Example:

> "Our invoice contains an unexpected charge."

Correct:

```text
ROUTE_TO_BILLING
```

---

## 8.4 Known procedures should use self-service

Example:

> "I forgot my password. Where can I reset it?"

Correct:

```text
SELF_SERVICE
```

But:

> "Someone changed my password without my permission."

Correct:

```text
ROUTE_TO_SECURITY
```

The word "password" alone does not determine the class.

---

## 8.5 Missing information should trigger information gathering

Example:

> "My account isn't working."

Correct:

```text
REQUEST_MORE_INFORMATION
```

The model should not invent the missing context.

---

## 8.6 Human review is an explicit business outcome

Example:

> "Our contract requires a custom refund arrangement outside the standard refund policy."

Correct:

```text
HUMAN_REVIEW
```

This is not simply a case where the model "doesn't know."

The policy itself requires a human decision.

---

# 9. Initial Policy Precedence

When multiple valid signals occur, the initial policy precedence is:

```text
1. ROUTE_TO_SECURITY
2. ROUTE_TO_ENGINEERING
3. ROUTE_TO_BILLING
4. SELF_SERVICE
5. REQUEST_MORE_INFORMATION
6. HUMAN_REVIEW
```

This precedence is a **project design decision**, not a requirement from the mentor brief.

It must be validated against the dataset and explicitly documented before training.

### Important rule

Precedence does not mean:

```text
keyword detected → highest class
```

The signal must be genuine.

For example:

> "I cannot log in because I forgot my password."

must not become:

```text
ROUTE_TO_SECURITY
```

merely because authentication is involved.

---

# 10. Edge Cases

The dataset must deliberately include cases that expose shallow classification strategies.

## 10.1 Security vs billing

> "We found an unauthorized login and also see a duplicate payment."

Expected:

```text
ROUTE_TO_SECURITY
```

---

## 10.2 Password reset vs account compromise

> "I forgot my password."

Expected:

```text
SELF_SERVICE
```

versus:

> "Someone changed my password without permission."

Expected:

```text
ROUTE_TO_SECURITY
```

---

## 10.3 One user vs production outage

> "One user receives a 500 error."

Potentially:

```text
ROUTE_TO_ENGINEERING
```

but the final decision depends on the available context.

The model must not assume:

```text
production = P1
```

or:

```text
500 = engineering
```

without considering the complete ticket.

---

## 10.4 Billing vs technical failure

> "My payment failed because the checkout API returns an error."

The dataset must establish whether the operational owner is:

```text
ROUTE_TO_BILLING
```

or:

```text
ROUTE_TO_ENGINEERING
```

based on the defined policy.

This is precisely the type of ambiguity that must be resolved **before dataset generation**, not after the model is trained.

---

## 10.5 Insufficient information

> "Something is wrong with my account."

Expected:

```text
REQUEST_MORE_INFORMATION
```

---

## 10.6 Difficult but classifiable

A complex ticket should not automatically become:

```text
HUMAN_REVIEW
```

If the policy clearly determines the correct route, the expected label must reflect that route.

---

# 11. Initial Examples

| # | Ticket | Expected Decision |
|---:|---|---|
| 1 | "We were charged twice this month." | `ROUTE_TO_BILLING` |
| 2 | "The analytics API returns 500 errors for all users." | `ROUTE_TO_ENGINEERING` |
| 3 | "I forgot my password." | `SELF_SERVICE` |
| 4 | "Someone accessed our account without authorization." | `ROUTE_TO_SECURITY` |
| 5 | "My account isn't working." | `REQUEST_MORE_INFORMATION` |
| 6 | "We need a refund outside the standard refund policy." | `HUMAN_REVIEW` |
| 7 | "Unknown login detected and our invoice is also incorrect." | `ROUTE_TO_SECURITY` |
| 8 | "The dashboard stopped working immediately after deployment." | `ROUTE_TO_ENGINEERING` |
| 9 | "Where can I download my invoice?" | `SELF_SERVICE` |
| 10 | "Our subscription payment failed." | `ROUTE_TO_BILLING` |
| 11 | "Someone changed my password without permission." | `ROUTE_TO_SECURITY` |
| 12 | "The application is broken." | `REQUEST_MORE_INFORMATION` |
| 13 | "Our API integration consistently returns invalid responses." | `ROUTE_TO_ENGINEERING` |
| 14 | "We need a contract exception approved." | `HUMAN_REVIEW` |
| 15 | "How do I update my billing address?" | `SELF_SERVICE` |

These examples are **seed examples only**.

They are not yet the training dataset.

---

# 12. Adversarial Dataset Strategy

The test set must contain examples designed to defeat shallow pattern matching.

Categories should include:

### Keyword traps

```text
"password"
"payment"
"production"
"invoice"
"login"
"security"
```

appearing in contexts where they do not determine the correct decision.

### Conflicting signals

```text
security + billing
engineering + billing
security + self-service
```

### Paraphrases

The same underlying scenario expressed in substantially different language.

### Information removal

Take a classifiable ticket and progressively remove information.

Example:

```text
Full:
"All 120 users receive 500 errors after today's deployment."

Reduced:
"Users receive 500 errors."

Minimal:
"The system is broken."
```

The expected decision may change as information disappears.

### Distractor information

Include irrelevant details that should not change the decision.

### Long tickets

The decisive evidence may appear near the middle or end.

### Short tickets

Very little context but still enough to make a decision.

### Boundary cases

Examples where two classes appear plausible but the policy defines one correct answer.

---

# 13. Why Prompting Alone May Be Insufficient

A base model may already understand generic support-ticket classification.

However, generic model knowledge does not guarantee consistent adherence to a custom operational policy.

Potential limitations include:

- inconsistent handling of conflicting signals
- inconsistent application of precedence
- different interpretations of ambiguous tickets
- sensitivity to wording
- inconsistent structured output
- overuse of fallback categories
- insufficient alignment with organization-specific definitions
- inconsistent distinction between self-service and specialist routing

Therefore the experiment tests whether LoRA can improve consistency on the defined behavior.

The claim will **not** be:

> "Fine-tuning always beats prompting."

The claim will be empirical:

> "For this defined support-triage behavior and evaluation set, does LoRA fine-tuning produce a measurable improvement over the prompted base model?"

---

# 14. Experimental Hypothesis

### Primary hypothesis

> A small Qwen model fine-tuned with LoRA on reviewed enterprise support-triage examples will classify unseen tickets according to the defined policy more consistently than the prompted base Qwen model.

### Secondary hypothesis

Fine-tuning may provide the greatest improvement on:

- conflicting cases
- policy-specific boundaries
- paraphrased cases
- repeated operational patterns
- structured output consistency

It may provide little or no improvement on obvious examples that the base model already handles correctly.

This distinction will be investigated rather than assumed.

---

# 15. Evaluation Metrics

The primary evaluation is decision classification.

## Required metrics

### Overall accuracy

```text
correct decisions / total decisions
```

### Per-class precision

Measure how often predictions for each class are correct.

### Per-class recall

Measure how often examples belonging to each class are correctly identified.

### Macro F1

Important because overall accuracy can hide poor performance on minority classes.

### Invalid-output rate

Percentage of responses that fail the required output format.

### Adversarial accuracy

Accuracy specifically on deliberately difficult cases.

---

# 16. Initial Success Criteria

These are project targets and will be frozen before the training experiment.

| Criterion | Target |
|---|---:|
| Decision accuracy | ≥ 85% |
| Macro F1 | ≥ 0.85 |
| Invalid output | < 2% |
| Base → LoRA accuracy improvement | ≥ 10 percentage points |
| Adversarial performance | Measurable improvement over base |
| Per-class evaluation | Required |
| Failure analysis | At least 5 failures |
| Frontier comparison | Required |

If the model fails these targets, the result is not hidden.

We document the failure and investigate it.

---

# 17. Evaluation Models

The final experiment will compare three systems.

## Model A — Base Qwen

```text
Base Qwen
+
Best prompt
```

This establishes the baseline.

## Model B — LoRA Qwen

```text
Base Qwen
+
LoRA adapter
+
Same evaluation prompt
```

This measures the effect of fine-tuning.

## Model C — Frontier model

A frontier model such as Claude or GPT will be evaluated using the same task definition and prompt.

The mentor brief explicitly requires comparison against the base Qwen with the best prompt and one frontier model.

---

# 18. Experimental Fairness

The comparison must control for:

- same test examples
- same expected labels
- same task definition
- same output requirements
- same evaluation rubric
- deterministic or controlled generation where possible
- no access to the test labels

The test set must remain frozen after evaluation begins.

---

# 19. Dataset Quality Requirements

Before training, every dataset version must pass:

### Schema validation

Every record contains the required fields.

### Label validation

Every decision belongs to the six allowed classes.

### Duplicate detection

Near-identical examples should not leak across train and test.

### PII check

No real customer PII.

The mentor brief explicitly requires PII removal.

### Contradiction check

The same scenario should not receive different labels unless the contextual difference explains the difference.

### Class-balance analysis

We must know the distribution of all six classes.

### Manual random sample

At least 20 examples will be manually reviewed.

### Adversarial review

Hard examples receive explicit human review.

---

# 20. Dataset Split

The initial target is at least 100 reviewed examples, as required by the mentor brief.

A stronger initial target is approximately:

```text
Train       140
Validation   30
Test         30
----------------
Total       200
```

However, the final split will depend on the actual generated/reviewed dataset.

The critical rule is:

> **The test set must represent decision boundaries, not merely random examples.**

The test set should deliberately contain:

- all six classes
- easy examples
- medium examples
- adversarial examples
- conflicting signals
- insufficient-information cases
- paraphrases
- boundary cases

---

# 21. Test Set Integrity

Once finalized:

```text
test.jsonl
```

is frozen.

No training example may be copied from the test set.

No model-development decision should be based on repeatedly inspecting the test-set labels.

If we iterate on the dataset after seeing test failures, those examples should move into a new development/evaluation cycle rather than silently remaining a "secret test."

---

# 22. Failure Analysis

The final report must include at least five meaningful failures.

For each failure:

```text
Example
Expected decision
Base Qwen prediction
LoRA prediction
Frontier prediction
What went wrong
Likely cause
Potential dataset change
Potential policy change
```

Example:

```text
Failure #1

Ticket:
"Someone changed my password without authorization."

Expected:
ROUTE_TO_SECURITY

Base:
SELF_SERVICE

LoRA:
ROUTE_TO_SECURITY

Frontier:
ROUTE_TO_SECURITY

Analysis:
The base model over-weighted the password-reset pattern and ignored
the unauthorized-access signal.

Potential improvement:
Add more contrastive examples separating legitimate password-reset
requests from compromised-account cases.
```

This type of analysis is more valuable than simply reporting:

```text
Accuracy = 87%
```

---

# 23. Experiment Tracking

Every training run should record:

```text
experiment_id
date
base_model
dataset_version
dataset_size
LoRA rank
LoRA alpha
target modules
learning rate
epochs
training loss
validation loss
decision accuracy
macro F1
per-class metrics
adversarial accuracy
invalid output rate
training cost
notes
```

This allows us to answer:

> Why did experiment 7 perform better than experiment 4?

rather than guessing.

---

# 24. Versioning

The project should version:

```text
Policy
Dataset
Prompt
Training configuration
Evaluation script
Model adapter
Results
```

Example:

```text
policy-v1
dataset-v1
prompt-v1
experiment-001
```

If the policy changes, the dataset version must change.

If the evaluation rubric changes, the results must not be directly compared without qualification.

---

# 25. Project Invariants

These rules should remain true throughout the project:

### Invariant 1

The model has one primary behavior:

```text
support-ticket → operational decision
```

### Invariant 2

Decision classification is the primary metric.

### Invariant 3

The test set remains frozen during an experiment cycle.

### Invariant 4

We do not hide failed experiments.

### Invariant 5

We distinguish model failures from policy/dataset failures.

### Invariant 6

Synthetic data is acceptable, but synthetic data is not automatically good data.

### Invariant 7

A larger dataset is not automatically better.

### Invariant 8

Fine-tuning is justified only if evaluation demonstrates a measurable benefit.

---

# 26. Current Experimental Question

Everything in this project ultimately supports one question:

> **Can a small Qwen model, fine-tuned with LoRA on a carefully reviewed organization-specific dataset, learn a deterministic enterprise support-triage policy more consistently than the prompted base model?**

If the answer is **yes**, we document the evidence.

If the answer is **no**, that is also a valid result.

The objective is not to make LoRA look successful.

The objective is to understand **when and why a small model benefits from task-specific fine-tuning.**

---

# 27. Phase 0 Exit Criteria

Phase 0 is complete when:

- [x] Project behavior defined
- [x] Six decisions defined
- [x] Primary objective defined
- [x] Generic policy selected
- [x] Input contract defined
- [x] Output contract defined
- [x] Initial precedence defined
- [x] Edge-case strategy defined
- [x] Evaluation metrics defined
- [x] Initial success criteria defined
- [x] Baseline models defined
- [x] Dataset quality gates defined
- [x] Failure-analysis approach defined

### Next phase

**Phase 1 — Policy Engineering & Dataset Design**

We will now turn this behavior contract into a **formal labeling policy + dataset schema + annotation SOP**.

That is the next critical step.

Do **not** generate 200 examples yet.

First we need to define exactly how a human annotator decides between:

```text
SECURITY
ENGINEERING
BILLING
SELF_SERVICE
REQUEST_MORE_INFORMATION
HUMAN_REVIEW
```

If the labeling policy is ambiguous, the model will simply learn our ambiguity.
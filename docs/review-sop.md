# Policy & Annotation SOP v1

**Project:** Enterprise Support Ticket Triage SLM  
**Document:** `docs/review-sop.md`  
**Version:** 1.0  
**Status:** Phase 1  
**Policy:** Generic enterprise support

---

# 1. Purpose

This document defines how support-ticket examples are labeled for training and evaluation of the Enterprise Support Ticket Triage SLM.

The purpose of the annotation process is to produce a dataset in which:

1. Each example has one defensible operational decision.
2. Labels are determined by explicit policy rather than annotator intuition.
3. Ambiguous cases are handled consistently.
4. Conflicting signals are resolved using defined precedence rules.
5. Reviewers can explain why a label was assigned.
6. Dataset quality can be audited before training.

The annotator must classify the **operational action**, not merely identify the topic of the ticket.

---

# 2. Core Annotation Principle

The fundamental question is:

> **"What should the enterprise support organization do next with this ticket?"**

Not:

> "What topic is this ticket about?"

For example:

> "Someone changed my password without permission."

The topic is authentication.

The operational action is:

```text
ROUTE_TO_SECURITY
```

Likewise:

> "I forgot my password."

The topic is also authentication.

The operational action is:

```text
SELF_SERVICE
```

Therefore, **topic ≠ decision**.

---

# 3. Label Set

Exactly one of the following labels must be assigned.

```text
ROUTE_TO_SECURITY
ROUTE_TO_ENGINEERING
ROUTE_TO_BILLING
REQUEST_MORE_INFORMATION
SELF_SERVICE
HUMAN_REVIEW
```

No additional labels are permitted without changing the policy version.

---

# 4. Decision Tree

Annotators should use the following decision sequence.

```text
START
  │
  ▼
Is there a genuine security/privacy
or unauthorized-access concern?
  │
  ├── YES ──→ ROUTE_TO_SECURITY
  │
  └── NO
        │
        ▼
Is there a technical defect, outage,
integration failure, or system problem
requiring engineering investigation?
        │
        ├── YES ──→ ROUTE_TO_ENGINEERING
        │
        └── NO
              │
              ▼
Is the primary operational issue
billing/payment/subscription/invoice related?
              │
              ├── YES ──→ ROUTE_TO_BILLING
              │
              └── NO
                    │
                    ▼
Can the issue be resolved through
an established self-service procedure?
                    │
                    ├── YES ──→ SELF_SERVICE
                    │
                    └── NO
                          │
                          ▼
Is sufficient information available
to determine the operational action?
                          │
                          ├── NO ──→ REQUEST_MORE_INFORMATION
                          │
                          └── YES
                                │
                                ▼
Does the case require an explicit
human/business judgment outside
standard policy?
                                │
                                ├── YES ──→ HUMAN_REVIEW
                                │
                                └── NO ──→ Re-evaluate
                                            policy/application
```

The final "re-evaluate" branch is intentional.

An annotator must not use `HUMAN_REVIEW` simply because they personally find the example difficult.

---

# 5. Label Definitions

## 5.1 ROUTE_TO_SECURITY

### Definition

Use when the ticket indicates a credible security, privacy, unauthorized-access, credential-compromise, or suspicious-activity concern requiring security investigation.

### Positive indicators

Examples include:

- unauthorized access
- suspicious login
- compromised credentials
- account takeover
- unauthorized password change
- suspected data exposure
- security vulnerability
- suspicious activity

### Positive example

> "We noticed a login from an unknown location and nobody on our team recognizes it."

```text
ROUTE_TO_SECURITY
```

### Negative example

> "I forgot my password and need to reset it."

```text
SELF_SERVICE
```

### Critical distinction

Do not classify based on security-related vocabulary alone.

The actual operational risk must be present.

---

# 6. ROUTE_TO_ENGINEERING

### Definition

Use when the ticket describes a technical defect or system behavior requiring engineering investigation.

### Positive indicators

- production outage
- application failure
- API errors
- software defect
- broken integration
- system degradation
- deployment-related failure
- repeated technical errors

### Positive example

> "After today's deployment, every request to the reporting API returns HTTP 500."

```text
ROUTE_TO_ENGINEERING
```

### Negative example

> "How do I configure the API integration?"

If documentation already provides the answer:

```text
SELF_SERVICE
```

---

# 7. ROUTE_TO_BILLING

### Definition

Use when the primary operational issue concerns money, invoices, subscriptions, charges, refunds, or payment processing.

### Positive indicators

- duplicate charge
- incorrect invoice
- subscription charge
- payment failure
- refund
- billing address
- plan charge
- invoice discrepancy

### Positive example

> "Our company was charged twice for the same subscription period."

```text
ROUTE_TO_BILLING
```

### Negative example

> "Someone accessed our account and used the account to make an unauthorized payment."

```text
ROUTE_TO_SECURITY
```

The security concern takes precedence.

---

# 8. SELF_SERVICE

### Definition

Use when:

1. The request is a known/common problem or procedure.
2. A documented self-service path exists.
3. No specialist intervention is required.
4. The available information is sufficient to identify the procedure.

### Positive examples

> "I forgot my password. How do I reset it?"

```text
SELF_SERVICE
```

> "Where can I download my invoice?"

```text
SELF_SERVICE
```

> "How do I update my billing address?"

```text
SELF_SERVICE
```

### Important rule

A ticket is not `SELF_SERVICE` merely because a solution might exist somewhere.

The annotator must have sufficient evidence that the issue maps to an established self-service procedure under the project policy.

---

# 9. REQUEST_MORE_INFORMATION

### Definition

Use when the ticket does not contain enough information to determine the appropriate operational action.

### Positive example

> "My account is not working. Please fix it."

```text
REQUEST_MORE_INFORMATION
```

There is no reliable way to determine whether the problem is:

- technical
- billing
- security
- configuration
- access-related

### Critical rule

Do not use `REQUEST_MORE_INFORMATION` simply because the ticket is difficult.

Ask:

> **Would additional information genuinely change the operational decision?**

If yes, this label may be appropriate.

---

# 10. HUMAN_REVIEW

### Definition

Use when sufficient information exists, but the standard policy does not safely determine the final business action and an authorized human must make the decision.

Examples:

- exceptional commercial requests
- contract exceptions
- non-standard refund decisions
- policy exceptions
- cases requiring business authorization
- legally sensitive cases outside the standard workflow

### Positive example

> "Our contract contains a custom refund clause and we are requesting an exception to the standard refund policy."

```text
HUMAN_REVIEW
```

### Critical distinction

`HUMAN_REVIEW` means:

> **The business process requires a human decision.**

It does not mean:

> "The annotator is unsure."

If an annotator is unsure, they must review the policy or escalate the annotation for adjudication.

---

# 11. Conflict Resolution Policy

Tickets can contain multiple signals.

The following precedence applies:

```text
1. ROUTE_TO_SECURITY
2. ROUTE_TO_ENGINEERING
3. ROUTE_TO_BILLING
4. SELF_SERVICE
5. REQUEST_MORE_INFORMATION
6. HUMAN_REVIEW
```

However, precedence applies only when the higher-priority signal is **genuine and operationally relevant**.

---

# 12. Conflict Examples

## Security + Billing

> "Someone accessed our account without authorization. We also noticed a duplicate charge."

Label:

```text
ROUTE_TO_SECURITY
```

Reason:

The unauthorized-access issue creates a security investigation that takes precedence over the billing issue.

---

## Security vocabulary without security incident

> "I need to change my password because I forgot it."

Label:

```text
SELF_SERVICE
```

The presence of "password" does not create a security incident.

---

## Engineering + Billing

> "Our payment failed because the payment API is returning 500 errors."

This requires a policy distinction.

If the evidence indicates a platform/API defect is causing the payment failure:

```text
ROUTE_TO_ENGINEERING
```

If the payment itself is rejected for a billing/account reason and no engineering defect is indicated:

```text
ROUTE_TO_BILLING
```

This boundary must be represented explicitly in the dataset.

---

## Engineering + Self-Service

> "The dashboard displays an error because the user has not enabled the required setting. The documented procedure explains how to enable it."

Label:

```text
SELF_SERVICE
```

A technical-looking symptom does not automatically imply engineering ownership.

---

# 13. Information Sufficiency

Annotators must distinguish:

### Case A — insufficient information

> "The application doesn't work."

```text
REQUEST_MORE_INFORMATION
```

### Case B — sufficient information

> "The application returns HTTP 500 for every user immediately after the latest deployment."

```text
ROUTE_TO_ENGINEERING
```

The difference is not ticket length.

The difference is whether the evidence supports an operational decision.

---

# 14. Annotation Procedure

Every annotator follows these steps.

## Step 1 — Read the complete ticket

Read:

- title
- description
- conversation history
- metadata

Do not label from the title alone.

---

## Step 2 — Identify operational signals

Record relevant signals.

Example:

```text
Security signal: unauthorized login
Billing signal: duplicate invoice
```

---

## Step 3 — Determine information sufficiency

Ask:

> Do I have enough information to make a policy-based decision?

If no:

```text
REQUEST_MORE_INFORMATION
```

unless a higher-priority explicit risk already determines the route.

---

## Step 4 — Apply policy precedence

Evaluate genuine operational signals according to the precedence rules.

---

## Step 5 — Check for self-service

Before assigning a specialist route, determine whether the issue clearly maps to an established self-service procedure.

---

## Step 6 — Check for legitimate human review

Only assign:

```text
HUMAN_REVIEW
```

when the business process itself requires human judgment.

---

## Step 7 — Record rationale

Every reviewed training example should have a concise rationale.

Example:

```text
decision: ROUTE_TO_SECURITY

rationale:
Unauthorized access is explicitly reported, making security
investigation the highest-priority operational action.
```

---

# 15. Annotation Schema

The canonical dataset record should contain:

```json
{
  "id": "ticket_000001",
  "input": {
    "customer_tier": "enterprise",
    "product": "analytics",
    "ticket_title": "Unknown login detected",
    "ticket_description": "We noticed a login from an unknown location.",
    "conversation_history": [],
    "metadata": {}
  },
  "label": {
    "decision": "ROUTE_TO_SECURITY",
    "priority": "P1",
    "reason": "The ticket reports potentially unauthorized account access."
  },
  "annotation": {
    "difficulty": "easy",
    "information_completeness": "complete",
    "signal_type": "security",
    "conflict_type": "none",
    "annotator_id": "annotator_01",
    "review_status": "reviewed"
  }
}
```

---

# 16. Annotation Metadata

Each example should capture dimensions useful for later analysis.

## Difficulty

```text
easy
medium
hard
adversarial
```

## Information completeness

```text
complete
partial
insufficient
```

## Signal type

```text
security
engineering
billing
self_service
human_review
mixed
none
```

## Conflict type

```text
none
security_vs_billing
security_vs_self_service
engineering_vs_billing
engineering_vs_self_service
other
```

These metadata fields are for dataset analysis and do not necessarily become model inputs.

---

# 17. Reviewer Independence

The strongest dataset process is:

```text
Generated example
       ↓
Annotator A
       ↓
Annotator B
       ↓
Compare labels
       ↓
Agreement?
   ┌───┴───┐
  YES      NO
   │        │
   ▼        ▼
Accept   Adjudication
```

The reviewer should not see the other annotator's label before submitting their own decision.

This prevents agreement from becoming social conformity.

---

# 18. Disagreement Handling

If two reviewers disagree:

### Step 1

Do not immediately change either label.

### Step 2

Compare the evidence each reviewer used.

### Step 3

Identify the policy rule causing the disagreement.

### Step 4

Determine whether:

- the policy is ambiguous
- the example is ambiguous
- one reviewer misapplied the policy
- the policy needs an explicit boundary rule

### Step 5

An adjudicator determines the final label.

### Step 6

If the disagreement reveals a policy gap, update the policy **before continuing large-scale annotation**.

This is critical.

We should not solve repeated disagreements by telling annotators:

> "Use your best judgment."

That simply hides a broken policy.

---

# 19. Inter-Annotator Agreement

For the first annotation batch, we will measure agreement between reviewers.

At minimum:

```text
raw agreement %
```

A stronger analysis can additionally use:

```text
Cohen's kappa
```

for two independent annotators.

The purpose is not to chase an arbitrary statistical threshold.

The purpose is to identify whether the policy produces reproducible labels.

If agreement is poor, we stop dataset expansion and fix the policy.

---

# 20. Contradiction Detection

Before training, search for examples where the same underlying scenario receives different labels.

Example:

```text
Example A:
"I forgot my password."
→ SELF_SERVICE

Example B:
"I forgot my password."
→ ROUTE_TO_SECURITY
```

This is an obvious contradiction unless meaningful context differs.

More subtle contradictions are more dangerous.

For example:

```text
"The payment API returns an error."
→ ENGINEERING

"The payment API returns an error."
→ BILLING
```

If the contextual evidence does not explain the difference, the dataset is defective.

---

# 21. Synthetic Data Policy

Synthetic data is permitted for this project.

However:

> **Synthetic does not mean automatically correct.**

The generation process may introduce:

- repetitive phrasing
- unrealistic tickets
- label leakage
- artificial correlations
- overly obvious examples
- class imbalance
- contradictory examples

Therefore generated examples are treated as **unreviewed candidates** until they pass the annotation process.

The mentor brief allows synthetic data but requires reviewed examples and a documented SOP.

---

# 22. Dataset Generation Rules

When generating candidate examples:

### Do

- vary wording
- vary ticket length
- create paraphrases
- create conflicting cases
- create incomplete cases
- create realistic operational context
- deliberately challenge policy boundaries
- include negative examples

### Do not

- generate 200 nearly identical tickets
- put the label name in the ticket text
- use obvious keywords as the only signal
- make every class equally easy
- generate synthetic tickets and immediately call them "ground truth"
- allow the generator to decide the final label without review

---

# 23. Leakage Prevention

Avoid examples such as:

> "Please route this to engineering because the API is broken."

The desired label is literally stated.

Also avoid:

> "This is clearly a security incident."

Such examples teach the model to copy explicit labels rather than infer the operational decision.

The dataset should require classification from evidence.

---

# 24. Quality Gates

A dataset version cannot proceed to training until it passes:

```text
[ ] Schema validation
[ ] Allowed-label validation
[ ] No obvious duplicates
[ ] No PII
[ ] Contradiction audit
[ ] Class-distribution analysis
[ ] Reviewer agreement analysis
[ ] At least 20 manually reviewed samples
[ ] Adversarial examples reviewed
[ ] Test set separated
[ ] Test set frozen
```

These gates are part of the engineering process, not optional documentation.

---

# 25. Annotation Example Set

## Example 1 — Billing

**Ticket**

> "We were charged twice for our monthly subscription."

**Decision**

```text
ROUTE_TO_BILLING
```

**Reason**

Duplicate subscription charge requires billing investigation.

---

## Example 2 — Engineering

**Ticket**

> "Every user gets a 500 error when opening the dashboard after today's deployment."

**Decision**

```text
ROUTE_TO_ENGINEERING
```

**Reason**

A widespread production technical failure requires engineering investigation.

---

## Example 3 — Self-service

**Ticket**

> "I forgot my password. How do I reset it?"

**Decision**

```text
SELF_SERVICE
```

**Reason**

The request maps to a standard password-reset procedure.

---

## Example 4 — Security

**Ticket**

> "Someone changed my password without my permission."

**Decision**

```text
ROUTE_TO_SECURITY
```

**Reason**

Unauthorized credential modification indicates potential account compromise.

---

## Example 5 — More information

**Ticket**

> "The application is broken."

**Decision**

```text
REQUEST_MORE_INFORMATION
```

**Reason**

There is insufficient information to identify the operational owner.

---

## Example 6 — Human review

**Ticket**

> "We want a refund outside the terms of our contract and need an exception approved."

**Decision**

```text
HUMAN_REVIEW
```

**Reason**

The request requires a business exception rather than standard automated routing.

---

## Example 7 — Security/Billing conflict

**Ticket**

> "We discovered an unauthorized login and also noticed an unexpected charge."

**Decision**

```text
ROUTE_TO_SECURITY
```

**Reason**

The unauthorized-access concern takes precedence over the billing issue.

---

## Example 8 — Security keyword trap

**Ticket**

> "I need to change my password because I forgot it."

**Decision**

```text
SELF_SERVICE
```

**Reason**

There is no evidence of unauthorized access or compromise.

---

## Example 9 — Engineering/Billing boundary

**Ticket**

> "Our payment failed because the checkout service is returning HTTP 500."

**Decision**

```text
ROUTE_TO_ENGINEERING
```

**Reason**

The available evidence identifies a technical service failure as the operational cause.

---

## Example 10 — Insufficient information

**Ticket**

> "My payment isn't working."

**Decision**

```text
REQUEST_MORE_INFORMATION
```

**Reason**

There is insufficient information to distinguish a billing issue from a technical payment-service failure.

---

## Example 11 — Self-service billing

**Ticket**

> "Where can I download my monthly invoice?"

**Decision**

```text
SELF_SERVICE
```

---

## Example 12 — Security

**Ticket**

> "We found an unknown device logged into our administrator account."

**Decision**

```text
ROUTE_TO_SECURITY
```

---

## Example 13 — Engineering

**Ticket**

> "Our webhook integration stopped receiving events after the latest API release."

**Decision**

```text
ROUTE_TO_ENGINEERING
```

---

## Example 14 — Human review

**Ticket**

> "We need an exception to our contracted service terms and require approval from your business team."

**Decision**

```text
HUMAN_REVIEW
```

---

## Example 15 — Self-service

**Ticket**

> "How can I update the billing address on our account?"

**Decision**

```text
SELF_SERVICE
```

---

# 26. Annotation Anti-Patterns

Annotators must not do the following.

### Anti-pattern 1 — Keyword classification

```text
"password" → SECURITY
```

Wrong.

---

### Anti-pattern 2 — Complexity equals human review

```text
long ticket → HUMAN_REVIEW
```

Wrong.

---

### Anti-pattern 3 — Missing information equals human review

```text
unclear ticket → HUMAN_REVIEW
```

Wrong.

The correct label is normally:

```text
REQUEST_MORE_INFORMATION
```

when more information is required to determine the route.

---

### Anti-pattern 4 — Technical word equals engineering

```text
"API" → ENGINEERING
```

Wrong.

A request for API documentation may be:

```text
SELF_SERVICE
```

---

### Anti-pattern 5 — Payment word equals billing

```text
"payment" → BILLING
```

Wrong.

A payment failure caused by a confirmed platform outage may be:

```text
ROUTE_TO_ENGINEERING
```

---

# 27. Phase 1 Exit Criteria

Policy engineering is complete only when:

```text
[ ] Six labels have precise definitions
[ ] Decision precedence is documented
[ ] Boundary cases are explicitly defined
[ ] Human-review semantics are defined
[ ] Information-sufficiency rule is defined
[ ] Annotation schema is defined
[ ] Review SOP is defined
[ ] Disagreement process is defined
[ ] Contradiction process is defined
[ ] Synthetic-data rules are defined
[ ] Dataset quality gates are defined
[ ] Initial examples exist
```

---

# 28. Next Phase

The next step is **Dataset Engineering**.

We will build:

```text
data/
├── raw/
│   └── generated_candidates.jsonl
│
├── reviewed/
│   └── reviewed_examples.jsonl
│
├── train.jsonl
├── validation.jsonl
└── test.jsonl
```

And scripts:

```text
scripts/
├── generate_data.py
├── validate_data.py
├── detect_duplicates.py
├── audit_labels.py
├── split_data.py
└── inspect_dataset.py
```

But before generating 200 examples, we will first create a **small pilot batch of ~30 examples**.

The pilot is deliberately small.

We will use it to discover:

- policy contradictions
- ambiguous boundaries
- bad synthetic patterns
- class imbalance
- annotation disagreements
- missing decision rules

Only after the policy survives that pilot should we scale toward the 100+ reviewed examples required by the mentor brief.

**Do not optimize for dataset size yet. Optimize for label quality first.**
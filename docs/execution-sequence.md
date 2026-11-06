WEEK 1
│
├── Understand brief
├── Choose behavior
├── Define policy
├── Define schema
└── Define success metrics

WEEK 2
│
├── Study Qwen
├── Study Llama
├── Study Mistral
├── Build abstraction table
└── Start white paper

WEEK 3
│
├── Generate dataset
├── Write review SOP
├── Human review
├── Audit contradictions
├── Balance labels
└── Freeze test

WEEK 4
│
├── Base baseline
├── Frontier baseline
├── Analyze baseline failures
└── Finalize LoRA hypothesis

WEEK 5
│
├── Tinker dry run
├── LoRA training
├── Validation
├── Test
└── Scorecard

WEEK 6
│
├── Failure analysis
├── Dataset improvement
├── Optional second run
├── Final evaluation
└── Reproducibility audit

WEEK 7
│
├── Manim video
├── LoRA report
├── White paper
├── README
└── Diagrams

WEEK 8+
│
└── Build-in-public content


Questions for the last to judge the understanding

Architecture:
1. Why does GQA exist?
2. Why RoPE?
3. Why SwiGLU?
4. Why does increasing width affect parameter count?
5. What is the trade-off of vocabulary size?

LoRA:
1. Why two matrices?
2. Why does B start at zero?
3. What does rank actually control?
4. What does alpha actually do?
5. Why choose these target modules?

SLM:
1. Why this base model?
2. Why not a larger model?
3. Why is prompting insufficient?
4. Why this dataset size?
5. How do you know the model learned the behavior rather than memorized examples?

Evaluation:
1. Why is accuracy insufficient?
2. What does macro F1 tell you?
3. Why freeze the test set?
4. Why compare against a frontier model?
5. Where does your model fail?

Engineering:
1. Can another person reproduce your experiment?
2. Can they identify exactly which dataset produced your result?
3. Can they identify which config produced the checkpoint?
4. Can they understand how much the experiment cost?
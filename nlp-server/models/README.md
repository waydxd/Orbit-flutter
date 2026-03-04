# Model Directory

This directory stores your fine-tuned T5 models for event and task parsing.

## Required Structure

```
models/
├── event-parser/
│   ├── config.json
│   ├── tokenizer_config.json
│   ├── tokenizer.json
│   ├── special_tokens_map.json
│   ├── spiece.model
│   └── pytorch_model.bin
│
└── task-parser/
    ├── config.json
    ├── tokenizer_config.json
    ├── tokenizer.json
    ├── special_tokens_map.json
    ├── spiece.model
    └── pytorch_model.bin
```

## How to Get Models

Models are **not included in the repository** because they're too large (~245 MB each).

**You need to:**
1. Train models in Google Colab using `train_event_parser.ipynb` or `train_task_parser.py`
2. Download the trained models
3. Place them in this directory

**See:** `../MODEL_DEPLOYMENT_GUIDE.md` for complete instructions.

## Quick Start

```bash
# After training in Colab, download and extract here:
cd nlp-server
unzip ~/Downloads/event-parser.zip -d models/

# Verify structure:
ls -R models/

# Start server:
python3 server.py
```

## Status

- [ ] Event parser model (`event-parser/`)
- [ ] Task parser model (`task-parser/`)

Once both models are deployed, the NLP server will be fully functional!

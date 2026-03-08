# Model Directory

This directory stores the fine-tuned FLAN-T5-small model for event parsing.

> **Note:** The task parser is rule-based and does not require a model file.

## Required Structure

```
models/
└── event-parser/
    ├── config.json
    ├── tokenizer_config.json
    ├── tokenizer.json
    ├── spiece.model
    └── model.safetensors   (or pytorch_model.bin)
```

## How to Get the Model

Model files are **not included** in the repository (~293 MB).

1. Train in Google Colab using `train_event_parser_v2.ipynb`
2. Download the resulting zip from Colab
3. Extract here:

```bash
cd nlp-server
unzip ~/Downloads/event-parser.zip -d models/
```

## Quick Start

```bash
# Verify structure
ls models/event-parser/

# Start server locally
python3 server.py

# Or with Docker
docker compose up --build
```

## Status

- [x] Event parser model (`event-parser/`)
- [x] Task parser (rule-based, no model needed)

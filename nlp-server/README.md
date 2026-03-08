# Orbit NLP Server

FastAPI server that parses natural language descriptions of events and tasks into structured JSON for the Orbit Flutter app.

## Architecture

```
User Input: "Meeting with John tomorrow at 3pm"
                    |
                    v
        facebook/bart-large-mnli
         (zero-shot: task vs event)
                    |
        +-----------+-----------+
        |                       |
        v                       v
Fine-tuned FLAN-T5-small   Rule-based parser
   (event-parser)           (task-parser)
        |                       |
        v                       v
{                           {
  "title": "Meeting",         "title": "...",
  "start_time": "...",        "due_date": "...",
  "end_time": "...",          "priority": "...",
  "location": "...",          "description": ""
  "recurrence": "..."       }
}
```

The **task parser** uses regex and date resolution (no model required). The **event parser** uses a fine-tuned FLAN-T5-small model.

## API Endpoints

| Endpoint       | Method | Description                    |
|----------------|--------|--------------------------------|
| `/`            | GET    | Service info                   |
| `/health`      | GET    | Health check                   |
| `/parse/event` | POST   | Parse event text → JSON        |
| `/parse/task`  | POST   | Parse task text → JSON         |

## Running with Docker (Recommended)

```bash
cd nlp-server

# Build and start
docker compose up --build

# Run in background
docker compose up -d --build
```

The server starts at `http://localhost:5001`. The `./models` directory is mounted into the container at runtime, so the model files are never baked into the image.

## Running Locally

```bash
cd nlp-server
pip install -r requirements.txt
python3 server.py
```

## Model Setup

The event parser model is **not included** in the repository (~293 MB). Place it at:

```
models/
└── event-parser/
    ├── config.json
    ├── tokenizer_config.json
    ├── tokenizer.json
    ├── spiece.model
    └── model.safetensors   (or pytorch_model.bin)
```

To train a new model, open `train_event_parser_v2.ipynb` in Google Colab, run all cells, and download the resulting zip. Then:

```bash
unzip ~/Downloads/event-parser.zip -d nlp-server/models/
```

## Testing the Server

```bash
# Event parsing
curl -X POST http://localhost:5001/parse/event \
  -H "Content-Type: application/json" \
  -d '{"text": "Team meeting next Monday at 10am for 1 hour"}'

# Task parsing (no model required)
curl -X POST http://localhost:5001/parse/task \
  -H "Content-Type: application/json" \
  -d '{"text": "Submit report by Friday 5pm high priority"}'

# Tricky task cases
curl -X POST http://localhost:5001/parse/task \
  -H "Content-Type: application/json" \
  -d '{"text": "Buy clothes before Monday"}'

curl -X POST http://localhost:5001/parse/task \
  -H "Content-Type: application/json" \
  -d '{"text": "by next Friday morning"}'

curl -X POST http://localhost:5001/parse/task \
  -H "Content-Type: application/json" \
  -d '{"text": "in 2 days"}'
```

## Flutter Integration

The Flutter app points to the server via `lib/config/app_config.dart`:

```dart
static const String nlpServerBaseUrl = 'http://localhost:5001';
```

- iOS Simulator: `http://localhost:5001`
- Android Emulator: `http://10.0.2.2:5001`

## Troubleshooting

**Event model not found:**
- Verify `./models/event-parser/` exists and contains model files
- Check: `ls models/event-parser/`

**Port already in use:**
- Check: `lsof -i :5001`
- Kill existing process: `kill <PID>`

**Out of memory:**
- The model requires ~1 GB RAM to load
- Reduce batch size if retraining: set `BATCH_SIZE = 4` or `2`

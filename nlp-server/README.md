# NLP Event/Task Parser Server

Fine-tuned T5-small models for parsing natural language descriptions into structured JSON.

## Architecture

```
User Input: "Meeting with John tomorrow at 3pm"
                    |
                    v
        facebook/bart-large-mnli
           (classification: task vs event)
                    |
        +-----------+-----------+
        |                       |
        v                       v
T5-small (event-parser)   T5-small (task-parser)
        |                       |
        v                       v
{                           {
  "title": "Meeting",         "title": "...",
  "start_time": "...",        "due_date": "...",
  "end_time": "...",          "priority": "...",
  "location": "",             "description": "..."
  "description": "With: John" }
}
```

## Quick Start

### 1. Prepare Data

```bash
# Event data (already done if you have augmented.jsonl)
python utils/data_preprocessing.py

# Task data (when you have task_augmented.jsonl)
python utils/data_preprocessing.py task
```

### 2. Train the Model

**Option A: Local Training (CPU - slower)**
```bash
pip install -r requirements.txt
python train_event_parser.py
```
*Time: ~10-20 minutes*

**Option B: Google Colab (GPU - faster, recommended)**

1. Upload these files to Colab:
   - `train_event_parser.py`
   - `data/event_training_data.jsonl`

2. In Colab, run:
   ```python
   !pip install transformers datasets torch accelerate sentencepiece
   !python train_event_parser.py
   ```

3. Download the model:
   ```python
   !zip -r event-parser-model.zip ./models/event-parser
   from google.colab import files
   files.download('event-parser-model.zip')
   ```

4. On your Mac:
   ```bash
   unzip event-parser-model.zip -d nlp-server/models/
   ```

### 3. Test the Model

```bash
python test_one-shot_classification.py
```

### 4. Start the Server

```bash
python server.py
```

Server runs on `http://localhost:5000`

### 5. Test the Server

```bash
# Test event parsing
curl -X POST http://localhost:5000/parse/event \
  -H "Content-Type: application/json" \
  -d '{"text": "Meeting with John tomorrow at 3pm for 1 hour"}'

# Test task parsing (when task model is trained)
curl -X POST http://localhost:5000/parse/task \
  -H "Content-Type: application/json" \
  -d '{"text": "Submit report by Friday 5pm high priority"}'
```

## Model Details

- **Base Model**: T5-small (60M parameters)
- **Task**: Sequence-to-sequence (text to JSON)
- **Training Data**: 2,584 event examples
- **Input Format**: `"parse event: <natural language>"` or `"parse task: <natural language>"`
- **Output Format**: JSON string

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Service info |
| `/health` | GET | Health check |
| `/parse/event` | POST | Parse event text → JSON |
| `/parse/task` | POST | Parse task text → JSON |

## Flutter Integration

Once the server is running:

1. Update Flutter `lib/config/app_config.dart`:
   ```dart
   static const String nlpServerBaseUrl = 'http://localhost:5000';
   static const bool useLocalNlpServer = true;
   ```

2. For iOS simulator: use `http://localhost:5000`
3. For Android emulator: use `http://10.0.2.2:5000`

## Training Your Own Task Parser

1. Create `data/task_augmented.jsonl` with format:
   ```json
   {"task_text": "Submit report by Friday", "output": {"action": "Submit report", "date": "31/01/2026", "time": "5:00 PM", "priority": "high", "notes": null}}
   ```

2. Generate training data:
   ```bash
   python utils/data_preprocessing.py task
   ```

3. Train:
   ```bash
   python train_task_parser.py
   ```

## Troubleshooting

**Model not found error:**
- Make sure you've trained the model first
- Check that `./models/event-parser/` exists and contains model files

**Out of memory during training:**
- Reduce `BATCH_SIZE` in training script (try 4 or 2)
- Or use Colab with GPU

**Server won't start:**
- Check if port 5000 is available: `lsof -i :5000`
- Try a different port in `server.py`

**Invalid JSON output:**
- The model may need more training epochs
- Try increasing `num_beams` in generation for better quality

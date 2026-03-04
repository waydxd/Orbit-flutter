# Quick Start Guide

## For Google Colab Training (Recommended - Free GPU)

### Step 1: Upload to Colab

Create a new Colab notebook and upload these files:
1. `train_event_parser.py`
2. `data/event_training_data.jsonl`

Or create a folder structure in your Google Drive and access it from Colab.

### Step 2: Install Dependencies

```python
!pip install transformers datasets torch accelerate sentencepiece
```

### Step 3: Run Training

```python
!python train_event_parser.py
```

**Expected time:** 3-5 minutes with GPU

### Step 4: Download the Model

```python
!zip -r event-parser-model.zip ./models/event-parser

from google.colab import files
files.download('event-parser-model.zip')
```

### Step 5: On Your Mac

```bash
cd ~/Downloads
unzip event-parser-model.zip
mv event-parser /Users/claudia_wzj/AndroidStudioProjects/Orbit-flutter/nlp-server/models/
```

---

## For Local Training (Your Mac - No GPU)

### Step 1: Create Virtual Environment

```bash
cd /Users/claudia_wzj/AndroidStudioProjects/Orbit-flutter/nlp-server
python3 -m venv venv
source venv/bin/activate
```

### Step 2: Install Dependencies

```bash
pip install -r requirements.txt
```

### Step 3: Train (CPU - will be slower)

```bash
python train_event_parser.py
```

**Expected time:** 10-20 minutes on CPU

---

## Test the Model

```bash
python test_one-shot_classification.py
```

You should see parsed JSON outputs for test examples like:
```
Input: Meeting with John tomorrow at 3pm for 1 hour
Parsed JSON:
  title: Meeting
  start_time: 2026-01-30T15:00:00
  end_time: 2026-01-30T16:00:00
  location: 
  description: With: John
```

---

## Start the Server

```bash
python server.py
```

Server runs on `http://localhost:5000`

**Test it:**
```bash
curl -X POST http://localhost:5000/parse/event \
  -H "Content-Type: application/json" \
  -d '{"text": "Meeting with John tomorrow at 3pm for 1 hour"}'
```

Expected response:
```json
{
  "title": "Meeting",
  "start_time": "2026-01-30T15:00:00",
  "end_time": "2026-01-30T16:00:00",
  "location": "",
  "description": "With: John"
}
```

---

## Next Steps

Once the server is running and working:
1. Keep the server running in a terminal
2. Update Flutter app configuration
3. Test the integration from the Flutter app

---

## Training Task Parser (When Ready)

1. Create task dataset `data/task_augmented.jsonl`
2. Generate training data: `python utils/data_preprocessing.py task`
3. Train: `python train_task_parser.py`
4. Test: `python test_model.py task`

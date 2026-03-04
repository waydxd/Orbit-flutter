# Model Deployment Guide

This guide explains how to train, download, and deploy your fine-tuned event/task parsing models.

---

## Directory Structure

Your trained models should be placed in the following structure:

```
nlp-server/
├── models/
│   ├── event-parser/          ← Event parsing model goes here
│   │   ├── config.json
│   │   ├── tokenizer_config.json
│   │   ├── tokenizer.json
│   │   ├── special_tokens_map.json
│   │   ├── spiece.model
│   │   └── pytorch_model.bin (or model.safetensors)
│   │
│   └── task-parser/           ← Task parsing model goes here
│       ├── config.json
│       ├── tokenizer_config.json
│       ├── tokenizer.json
│       ├── special_tokens_map.json
│       ├── spiece.model
│       └── pytorch_model.bin (or model.safetensors)
│
└── server.py
```

**Server expects:**
- Event model at: `./models/event-parser`
- Task model at: `./models/task-parser`

---

## Step-by-Step Deployment

### 1. Train Model in Google Colab

**Open the training notebook:**
- Upload `train_event_parser.ipynb` to Google Colab
- Or use `train_task_parser.py` for task model

**Run training:**
```python
# The notebook is already configured to save at the correct path
OUTPUT_DIR = "./models/event-parser"

# After training completes, the model will be saved automatically:
model.save_pretrained(OUTPUT_DIR)
tokenizer.save_pretrained(OUTPUT_DIR)
```

**Training takes approximately:**
- 15 epochs × 2502 examples ÷ batch size 8 = ~4700 steps
- On Colab T4 GPU: ~30-45 minutes

### 2. Verify Model in Colab

Before downloading, test the model in Colab:

```python
# Quick test
test_text = "Meeting tomorrow at 3pm for 1 hour"
input_text = f"parse event: {test_text}"

inputs = tokenizer(input_text, return_tensors="pt", max_length=128, truncation=True)
outputs = model.generate(**inputs, max_length=150, num_beams=4)
result = tokenizer.decode(outputs[0], skip_special_tokens=True)

print(f"Input: {test_text}")
print(f"Output: {result}")
```

**Expected output format:**
```
action: Meeting | date: 30/01/2026 | time: 03:00 PM | attendees: none | location: none | duration: 1 hour | recurrence: none | notes: none
```

### 3. Download Model from Colab

**Option A: Download as ZIP**

In Colab, run:
```python
# Create a ZIP file
!zip -r event-parser.zip ./models/event-parser
```

Then download:
1. Click the folder icon (Files) in left sidebar
2. Navigate to `event-parser.zip`
3. Right-click → Download

**Option B: Download to Google Drive**

```python
from google.colab import drive
drive.mount('/content/drive')

# Copy model to Drive
!cp -r ./models/event-parser /content/drive/MyDrive/orbit-models/
```

Then download from Google Drive.

**Option C: Download Files Individually**

In Colab Files sidebar:
1. Navigate to `models/event-parser/`
2. Download each file:
   - `config.json`
   - `tokenizer_config.json`
   - `tokenizer.json`
   - `special_tokens_map.json`
   - `spiece.model`
   - `pytorch_model.bin` (largest file, ~242 MB for FLAN-T5-small)

### 4. Place Model in Your Project

**On your local machine:**

```bash
cd /Users/claudia_wzj/AndroidStudioProjects/Orbit-flutter/nlp-server

# If you downloaded a ZIP:
unzip ~/Downloads/event-parser.zip -d ./models/

# Or if you downloaded individual files:
# Create the directory
mkdir -p ./models/event-parser

# Move downloaded files
mv ~/Downloads/config.json ./models/event-parser/
mv ~/Downloads/tokenizer_config.json ./models/event-parser/
mv ~/Downloads/tokenizer.json ./models/event-parser/
mv ~/Downloads/special_tokens_map.json ./models/event-parser/
mv ~/Downloads/spiece.model ./models/event-parser/
mv ~/Downloads/pytorch_model.bin ./models/event-parser/
```

### 5. Verify Directory Structure

```bash
cd nlp-server
ls -R models/
```

**Expected output:**
```
models/:
event-parser

models/event-parser:
config.json
pytorch_model.bin
special_tokens_map.json
spiece.model
tokenizer.json
tokenizer_config.json
```

### 6. Test Model Locally

**Start the server:**
```bash
cd nlp-server
python3 server.py
```

**Expected startup output:**
```
Loading event parser from ./models/event-parser...
Event parser loaded!
WARNING: Task model not found at ./models/task-parser

========================================
Orbit NLP Parser Server (T5)
========================================
Starting server on http://localhost:5000
```

**Test with curl:**
```bash
curl -X POST http://localhost:5000/parse/event \
  -H "Content-Type: application/json" \
  -d '{"text": "Meeting tomorrow at 3pm for 1 hour"}'
```

**Expected response:**
```json
{
  "title": "Meeting",
  "start_time": "2026-03-02T15:00:00",
  "end_time": "2026-03-02T16:00:00",
  "location": "",
  "description": ""
}
```

---

## For Task Model

Repeat the same process for the task parser:

1. **Train:** Upload and run `train_task_parser.py` in Colab
2. **Download:** Model saves to `./models/task-parser`
3. **Place:** Extract/move to `nlp-server/models/task-parser/`
4. **Test:** `curl -X POST http://localhost:5000/parse/task ...`

---

## Troubleshooting

### Model Not Found (503 Error)

**Error:**
```
Event model not loaded. Please train the model first.
```

**Solution:**
1. Verify files exist: `ls nlp-server/models/event-parser/`
2. Check server logs for path issues
3. Ensure all 6 files are present

### Wrong Directory Structure

**Common mistake:**
```
models/
└── event-parser/
    └── models/
        └── event-parser/     ← Too nested!
            └── config.json
```

**Correct structure:**
```
models/
└── event-parser/
    └── config.json           ← Direct files here
```

### Missing Files

If you're missing `pytorch_model.bin`, the model might have saved as `model.safetensors` instead. Both work fine!

### Large File Size

`pytorch_model.bin` for FLAN-T5-small is ~242 MB. This is normal. Make sure you have enough disk space.

---

## File Sizes Reference

For **FLAN-T5-small** model:

| File | Size |
|------|------|
| `pytorch_model.bin` | ~242 MB |
| `spiece.model` | ~792 KB |
| `tokenizer.json` | ~2.4 MB |
| `config.json` | ~1 KB |
| `tokenizer_config.json` | ~1 KB |
| `special_tokens_map.json` | ~1 KB |

**Total:** ~245 MB per model

---

## Quick Commands Cheat Sheet

```bash
# Check current directory
cd nlp-server && ls models/

# Create directories if needed
mkdir -p models/event-parser
mkdir -p models/task-parser

# Unzip downloaded model
unzip ~/Downloads/event-parser.zip -d models/

# Verify model files
ls -lh models/event-parser/

# Test server
python3 server.py

# Test event parsing
curl -X POST http://localhost:5000/parse/event \
  -H "Content-Type: application/json" \
  -d '{"text": "Meeting today at 3pm"}'

# Check if model loaded
curl http://localhost:5000/health
```

---

## Next Steps

After deploying the event model:

1. ✅ Test with various inputs
2. ⏭️ Train and deploy the task model
3. ⏭️ Integrate with Flutter app
4. ⏭️ (Optional) Set up Docker deployment

---

## Notes

- Models are **not included in git** (too large)
- Each developer needs to train and download their own models
- Or share via Google Drive / cloud storage
- Consider using model versioning (e.g., `event-parser-v1`, `event-parser-v2`)

---

**Need help?** Check `COLAB_TRAINING.md` for training issues or `NLP_INTEGRATION_SUMMARY.md` for integration issues.

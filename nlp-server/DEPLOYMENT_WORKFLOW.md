# Model Deployment Workflow

## Visual Guide

```
┌─────────────────────────────────────────────────────────────────┐
│                    STEP 1: TRAIN IN COLAB                       │
└─────────────────────────────────────────────────────────────────┘
                             │
                             ▼
    ┌────────────────────────────────────────────────┐
    │  Upload train_event_parser.ipynb to Colab     │
    │                                                 │
    │  Run all cells:                                │
    │  • Load data from event_text_mapping.jsonl    │
    │  • Fine-tune FLAN-T5-small model              │
    │  • Train for 15 epochs (~30-45 mins)          │
    │  • Save to ./models/event-parser              │
    └────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   STEP 2: VERIFY IN COLAB                       │
└─────────────────────────────────────────────────────────────────┘
                             │
                             ▼
    ┌────────────────────────────────────────────────┐
    │  Test the trained model:                       │
    │                                                 │
    │  Input:  "Meeting tomorrow at 3pm"            │
    │  Output: "action: Meeting | date: ... "       │
    │                                                 │
    │  ✓ Verify pipe-delimited format               │
    │  ✓ Check all fields present                   │
    └────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                  STEP 3: DOWNLOAD MODEL                         │
└─────────────────────────────────────────────────────────────────┘
                             │
                             ▼
    ┌────────────────────────────────────────────────┐
    │  Option A: ZIP and Download                    │
    │  !zip -r event-parser.zip ./models/event-parser│
    │  → Right-click → Download                      │
    │                                                 │
    │  Option B: Save to Google Drive                │
    │  !cp -r ./models/event-parser ~/Drive/         │
    │  → Download from Drive                         │
    └────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              STEP 4: PLACE IN LOCAL PROJECT                     │
└─────────────────────────────────────────────────────────────────┘
                             │
                             ▼
    ┌────────────────────────────────────────────────┐
    │  On your Mac:                                  │
    │                                                 │
    │  cd Orbit-flutter/nlp-server                   │
    │  unzip ~/Downloads/event-parser.zip -d models/ │
    │                                                 │
    │  Result:                                       │
    │  models/                                       │
    │  └── event-parser/                            │
    │      ├── config.json                          │
    │      ├── pytorch_model.bin (~242 MB)          │
    │      ├── tokenizer files...                   │
    │      └── spiece.model                         │
    └────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                  STEP 5: START SERVER                           │
└─────────────────────────────────────────────────────────────────┘
                             │
                             ▼
    ┌────────────────────────────────────────────────┐
    │  python3 server.py                             │
    │                                                 │
    │  Console output:                               │
    │  ✓ Loading event parser from ./models/...     │
    │  ✓ Event parser loaded!                       │
    │  ✓ Starting server on http://localhost:5000   │
    └────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   STEP 6: TEST SERVER                           │
└─────────────────────────────────────────────────────────────────┘
                             │
                             ▼
    ┌────────────────────────────────────────────────┐
    │  curl -X POST http://localhost:5000/parse/event│
    │    -H "Content-Type: application/json" \       │
    │    -d '{"text": "Meeting today at 3pm"}'       │
    │                                                 │
    │  Response:                                     │
    │  {                                             │
    │    "title": "Meeting",                         │
    │    "start_time": "2026-03-01T15:00:00",       │
    │    "end_time": "2026-03-01T16:00:00",         │
    │    "location": "",                            │
    │    "description": ""                          │
    │  }                                             │
    └────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   STEP 7: USE IN FLUTTER                        │
└─────────────────────────────────────────────────────────────────┘
                             │
                             ▼
    ┌────────────────────────────────────────────────┐
    │  1. Ensure server is running                   │
    │  2. Launch Flutter app                         │
    │  3. Go to NLP input page                       │
    │  4. Type: "Meeting tomorrow at 3pm"            │
    │  5. Tap "Create"                               │
    │                                                 │
    │  ✓ Auto-fills event form with parsed data     │
    └────────────────────────────────────────────────┘
```

---

## File Size Overview

### What You're Downloading

```
event-parser/
├── pytorch_model.bin      ████████████████████  242 MB  (90%)
├── tokenizer.json         █                       2.4 MB  (1%)
├── spiece.model           █                       792 KB  (<1%)
├── config.json            ▏                       1 KB    (<1%)
├── tokenizer_config.json  ▏                       1 KB    (<1%)
└── special_tokens_map.json▏                       1 KB    (<1%)
                           
TOTAL: ~245 MB per model
```

**Important:** The model files are binary and cannot be edited manually. They must be generated through training.

---

## Common Paths Reference

| Environment | Path |
|------------|------|
| **Google Colab** | `/content/models/event-parser/` |
| **Your Mac** | `/Users/claudia_wzj/AndroidStudioProjects/Orbit-flutter/nlp-server/models/event-parser/` |
| **Server expects** | `./models/event-parser/` (relative to server.py) |
| **Downloads** | `~/Downloads/event-parser.zip` |

---

## Quick Verification Commands

After deployment, run these to verify everything:

```bash
# 1. Check directory structure
cd nlp-server && tree models/ -L 2

# Or without tree:
ls -R models/

# 2. Check file sizes
du -sh models/event-parser/*

# 3. Verify model can load
python3 -c "
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
tokenizer = AutoTokenizer.from_pretrained('./models/event-parser')
model = AutoModelForSeq2SeqLM.from_pretrained('./models/event-parser')
print('✓ Model loaded successfully!')
"

# 4. Start server and check
python3 server.py &
sleep 3
curl http://localhost:5000/health
```

Expected output:
```json
{
  "status": "healthy",
  "event_model_loaded": true,
  "task_model_loaded": false
}
```

---

## Troubleshooting Quick Fixes

### "Model not found"
```bash
# Check if files exist
ls models/event-parser/

# Check if directory is nested incorrectly
find models -name "config.json"
```

### "Cannot load model"
```bash
# Check file permissions
chmod -R 755 models/event-parser/

# Check file sizes (pytorch_model.bin should be ~242 MB)
ls -lh models/event-parser/
```

### "Out of memory"
```bash
# The model requires ~1 GB RAM to load
# Check available memory
free -h  # Linux
vm_stat  # Mac
```

---

## Next Model: Task Parser

Repeat the entire process for the task parser:

1. Upload `train_task_parser.py` to Colab
2. Train and save to `./models/task-parser`
3. Download and place in `nlp-server/models/task-parser/`
4. Restart server

Both models can coexist and the server will load both automatically.

---

**Ready to deploy?** 
1. Read `MODEL_DEPLOYMENT_GUIDE.md` for detailed instructions
2. Open `train_event_parser.ipynb` in Google Colab
3. Click "Run all" and wait ~30-45 minutes
4. Follow the download steps above

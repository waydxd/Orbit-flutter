# Model Deployment Checklist

Quick reference checklist for deploying your NLP models.

---

## 📋 Event Parser Model

### Training Phase (Google Colab)

- [ ] Upload `train_event_parser.ipynb` to Colab
- [ ] Upload `event_text_mapping_expanded.jsonl` to Colab (if not using from Drive)
- [ ] Run all cells
- [ ] Wait for training to complete (~30-45 minutes)
- [ ] Verify training loss decreased (should be < 1.0)
- [ ] Test model output in Colab
- [ ] Verify output is in pipe-delimited format

### Download Phase

- [ ] In Colab, run: `!zip -r event-parser.zip ./models/event-parser`
- [ ] Download `event-parser.zip` from Colab Files
- [ ] Verify ZIP file is ~245 MB
- [ ] Extract ZIP and check 6 files are present

### Deployment Phase

- [ ] Navigate to: `Orbit-flutter/nlp-server/`
- [ ] Extract model: `unzip ~/Downloads/event-parser.zip -d models/`
- [ ] Verify structure: `ls models/event-parser/`
- [ ] Check files:
  - [ ] `config.json` (~1 KB)
  - [ ] `tokenizer_config.json` (~1 KB)
  - [ ] `tokenizer.json` (~2.4 MB)
  - [ ] `special_tokens_map.json` (~1 KB)
  - [ ] `spiece.model` (~792 KB)
  - [ ] `pytorch_model.bin` (~242 MB) OR `model.safetensors`

### Testing Phase

- [ ] Start server: `python3 server.py`
- [ ] Check console: "✓ Event parser loaded!"
- [ ] Test health endpoint: `curl http://localhost:5000/health`
- [ ] Test parsing: 
  ```bash
  curl -X POST http://localhost:5000/parse/event \
    -H "Content-Type: application/json" \
    -d '{"text": "Meeting today at 3pm"}'
  ```
- [ ] Verify JSON response with title, start_time, end_time, etc.
- [ ] Test with relative dates: "Meeting tomorrow at noon"
- [ ] Verify dates are resolved correctly

---

## 📋 Task Parser Model (Optional)

- [ ] Upload `train_task_parser.py` to Colab
- [ ] Train model (saves to `./models/task-parser`)
- [ ] Download and extract to `nlp-server/models/task-parser/`
- [ ] Restart server
- [ ] Test: `curl http://localhost:5000/parse/task ...`

---

## 📋 Flutter Integration

### Server Setup

- [ ] NLP server is running on `localhost:5000`
- [ ] Event model is loaded
- [ ] Health check returns `event_model_loaded: true`
- [ ] Date resolver is working (test with "tomorrow at noon")

### App Configuration

- [ ] `AppConfig.nlpServerBaseUrl` is set correctly:
  - [ ] Mac/iOS Simulator: `http://localhost:5000`
  - [ ] Android Emulator: `http://10.0.2.2:5000`
  - [ ] Physical Device: `http://YOUR_IP:5000`

### Testing in App

- [ ] Launch Flutter app
- [ ] Navigate to NLP input page
- [ ] Enter: "Meeting tomorrow at 3pm for 1 hour"
- [ ] Tap "Create"
- [ ] Verify:
  - [ ] Classification shows "event"
  - [ ] Navigate to CreateItemPage
  - [ ] Title = "Meeting"
  - [ ] Start date = tomorrow
  - [ ] Start time = 3:00 PM
  - [ ] End time = 4:00 PM (1 hour later)

---

## 🎯 Success Criteria

### Minimum Working System

✅ **Event model deployed and working**
- Server starts without errors
- Health check shows model loaded
- curl tests return valid JSON
- Dates are preprocessed correctly

### Full System

✅ **All of the above, plus:**
- Task model deployed (optional)
- Flutter app connects to server
- Form auto-fills from parsed data
- No console errors in Flutter

---

## 🐛 Quick Debug

### Server Won't Start

```bash
# Check Python version (needs 3.8+)
python3 --version

# Check dependencies
pip3 list | grep transformers

# Check model files
ls -lh models/event-parser/

# Try loading model manually
python3 -c "from transformers import AutoModelForSeq2SeqLM; AutoModelForSeq2SeqLM.from_pretrained('./models/event-parser')"
```

### Model Not Loading

```bash
# Check directory structure
tree models/  # or: ls -R models/

# Verify config.json is valid
cat models/event-parser/config.json | python3 -m json.tool

# Check permissions
chmod -R 755 models/
```

### Flutter Can't Connect

```bash
# Check server is running
curl http://localhost:5000/health

# For Android emulator, verify correct IP:
# Should be 10.0.2.2:5000, not localhost:5000

# Check firewall (Mac)
# System Preferences → Security & Privacy → Firewall
# Allow Python to accept incoming connections
```

---

## 📝 Notes

- Model files are ~245 MB each (normal size for FLAN-T5-small)
- Training takes ~30-45 minutes on Colab T4 GPU
- Models are NOT committed to git (too large)
- Each developer must train/download their own models
- Or share via Google Drive within the team

---

## ✅ Done!

Once all checkboxes are complete, your NLP feature is fully deployed and ready to use!

**Next steps:**
- Test with various natural language inputs
- Fine-tune the model if needed (retrain with more examples)
- Deploy task parser using the same process
- (Optional) Set up Docker deployment for production

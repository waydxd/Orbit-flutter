# Training FLAN-T5 Event Parser in Google Colab

## 🚀 Complete Colab Workflow

### Step 1: Setup in Colab

```python
# Mount Google Drive
from google.colab import drive, files
drive.mount('/content/drive')

# Navigate to your project folder
%cd /content/drive/MyDrive/nlp-server

# OR: Upload files directly (slower for large datasets)
# files.upload()  # Upload train_event_parser.py and data/event_training_data.jsonl
```

### Step 2: Install Dependencies

```python
!pip install transformers datasets torch accelerate sentencepiece
```

### Step 3: Train Model

```python
# Train - model saves to ./models/event-parser/
!python train_event_parser.py
```

**Expected Output:**
- Loss should start around 3-5 and **decrease** (NOT stay at 0!)
- Gradients should be numbers like 0.5-2.0 (NOT NaN!)
- Eval loss should decrease over epochs (NOT stay NaN!)

✅ **Good training example:**
```
{'loss': 3.245, 'grad_norm': 1.234, 'learning_rate': 2.883e-05, 'epoch': 0.2}
{'loss': 2.891, 'grad_norm': 0.987, 'learning_rate': 2.763e-05, 'epoch': 0.4}
{'loss': 2.456, 'grad_norm': 0.765, 'learning_rate': 2.644e-05, 'epoch': 0.6}
...
{'eval_loss': 2.123, 'eval_runtime': 1.5, ...}
```

❌ **Bad training (bug):**
```
{'loss': 0, 'grad_norm': nan, ...}  # THIS MEANS NO LEARNING!
```

### Step 4: Download Model (Only After Successful Training!)

```python
# Create minimal zip with only inference files
!mkdir -p event-parser-minimal

# Copy core model files
!cp models/event-parser/config.json event-parser-minimal/
!cp models/event-parser/model.safetensors event-parser-minimal/
!cp models/event-parser/generation_config.json event-parser-minimal/

# Copy tokenizer files (use wildcards to handle variations)
!cp models/event-parser/tokenizer*.json event-parser-minimal/ 2>/dev/null || true
!cp models/event-parser/special*.json event-parser-minimal/ 2>/dev/null || true
!cp models/event-parser/*.model event-parser-minimal/ 2>/dev/null || true

# Verify files before zipping
!ls -lh event-parser-minimal/

# Create zip
!zip -r event-parser-minimal.zip event-parser-minimal/

# Download
files.download('event-parser-minimal.zip')
```

### Step 5: Test Model in Colab (Before Downloading)

```python
# Quick test in Colab
!python << 'EOF'
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM

model_path = "./models/event-parser"
tokenizer = AutoTokenizer.from_pretrained(model_path)
model = AutoModelForSeq2SeqLM.from_pretrained(model_path)

test_input = "parse event: Meeting with John tomorrow at 3pm for 1 hour"
inputs = tokenizer(test_input, return_tensors="pt", max_length=128, truncation=True)
outputs = model.generate(**inputs, max_length=256)
result = tokenizer.decode(outputs[0], skip_special_tokens=True)

print("Input:", test_input)
print("Output:", result)
print("\nIf output is valid JSON, training succeeded! ✓")
EOF
```

## 📦 What's in the Minimal Zip?

Required files (~250-300 MB):
- `config.json` - Model configuration
- `model.safetensors` - Trained weights (largest file)
- `generation_config.json` - Generation settings
- `tokenizer_config.json` - Tokenizer config
- `tokenizer.json` - Tokenizer vocabulary
- `special_tokens_map.json` - Special tokens
- `spiece.model` - SentencePiece tokenizer model (for T5)

**NOT included** (saves ~2-5 GB):
- `checkpoint-*` folders - Training checkpoints
- `optimizer.pt` - Optimizer state
- `trainer_state.json` - Training logs
- `training_args.bin` - Training arguments

## 🐛 Troubleshooting

### Problem: Loss = 0, grad_norm = NaN

**Cause:** Padding tokens not masked in labels (training script bug)

**Solution:** The updated `train_event_parser.py` now includes the fix. Re-upload and retrain.

### Problem: "FileNotFoundError: data/event_training_data.jsonl"

**Cause:** Dataset not uploaded to Colab

**Solutions:**
1. Upload `event_training_data.jsonl` to `data/` folder in Google Drive
2. OR: Upload `event_text_mapping_expanded.jsonl` + run preprocessing:
   ```python
   !python utils/data_preprocessing.py
   ```

### Problem: "CUDA out of memory"

**Cause:** Batch size too large for Colab GPU

**Solution:** In `train_event_parser.py`, change:
```python
BATCH_SIZE = 8  # Change to 4 or 2
```

### Problem: Missing tokenizer files during copy

**Cause:** Files have different names or weren't saved

**Solution:** Use the updated download commands with wildcards (see Step 4)

## 📊 Training Time Estimates

- **Colab Free (T4 GPU):** ~4-6 minutes for 5 epochs on 2,502 examples
- **Colab Free (CPU only):** ~30-45 minutes
- **Colab Pro (A100):** ~2-3 minutes

## 🎯 After Download

1. Unzip on your local machine:
   ```bash
   unzip event-parser-minimal.zip
   ```

2. Move to your project:
   ```bash
   mv event-parser-minimal /path/to/nlp-server/models/event-parser
   ```

3. Test locally:
   ```bash
   cd /path/to/nlp-server
   python test_model.py
   ```

4. If tests pass, start the server:
   ```bash
   python server.py
   ```

---

**Updated:** 2026-01-29  
**Bug fixed:** Padding tokens now properly masked with -100 in labels

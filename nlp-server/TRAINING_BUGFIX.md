# Training Bug Fix: Loss=0, grad_norm=NaN

## 🐛 The Bug

When training FLAN-T5 for event/task parsing, you saw:
- `loss: 0` throughout training (should decrease from ~3-5)
- `grad_norm: nan` (should be ~0.5-2.0)
- `eval_loss: nan` (should decrease over epochs)

**This means the model was NOT learning!**

## 🔍 Root Cause

In the `preprocess_function`, padding tokens in the labels were not replaced with `-100`.

### Broken Code (Before):
```python
def preprocess_function(examples, tokenizer, max_input_length=128, max_output_length=256):
    model_inputs = tokenizer(
        examples['input'],
        max_length=max_input_length,
        truncation=True,
        padding='max_length'
    )
    
    labels = tokenizer(
        examples['output'],
        max_length=max_output_length,
        truncation=True,
        padding='max_length'
    )
    
    # BUG: Padding tokens (ID=0) are included in labels
    model_inputs['labels'] = labels['input_ids']  # ❌ Wrong!
    return model_inputs
```

**Problem:** The model tried to predict padding tokens (ID=0), which:
1. Confuses the loss function
2. Causes gradient instability (NaN)
3. Prevents actual learning

## ✅ The Fix

Replace padding token IDs with `-100`, which PyTorch ignores in loss computation:

```python
def preprocess_function(examples, tokenizer, max_input_length=128, max_output_length=256):
    model_inputs = tokenizer(
        examples['input'],
        max_length=max_input_length,
        truncation=True,
        padding='max_length'
    )
    
    labels = tokenizer(
        examples['output'],
        max_length=max_output_length,
        truncation=True,
        padding='max_length'
    )
    
    # FIX: Replace padding token IDs with -100
    labels_ids = labels['input_ids']
    labels_ids = [
        [(label if label != tokenizer.pad_token_id else -100) for label in label_seq]
        for label_seq in labels_ids
    ]
    
    model_inputs['labels'] = labels_ids  # ✅ Correct!
    return model_inputs
```

## 📁 Fixed Files

1. ✅ `train_event_parser.py` - Updated
2. ✅ `train_task_parser.py` - Updated
3. ✅ `train_event_parser.ipynb` - Updated

## 🚀 How to Retrain (Colab)

1. **Delete old model** (it didn't learn anything):
   ```python
   !rm -rf models/event-parser/
   ```

2. **Re-upload fixed script**:
   - Upload the updated `train_event_parser.py` to Google Drive
   - Or copy-paste the fixed `preprocess_function` into your Colab notebook

3. **Train again**:
   ```python
   !python train_event_parser.py
   ```

4. **Verify training is working**:
   ```
   # GOOD (learning is happening):
   {'loss': 3.245, 'grad_norm': 1.234, ...}  # Loss starts high
   {'loss': 2.891, 'grad_norm': 0.987, ...}  # Loss decreases
   {'loss': 2.456, 'grad_norm': 0.765, ...}  # Loss continues to drop
   ...
   {'eval_loss': 2.123, ...}  # Eval loss is a number, not NaN
   
   # BAD (bug still present):
   {'loss': 0, 'grad_norm': nan, ...}  # ❌ Stop and check code!
   ```

## 📊 Expected Training Metrics

### First Epoch
- **Initial loss:** 3.0-5.0
- **Grad norm:** 0.5-3.0
- **Eval loss:** 2.0-4.0

### Later Epochs
- **Loss trend:** Should steadily decrease
- **Final loss:** 0.5-1.5 (lower is better)
- **Eval loss:** 0.8-2.0 (should not be much higher than train loss)

## 🎯 Testing the Fixed Model

After successful training (loss decreased normally), test:

```python
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
import json

model_path = "./models/event-parser"
tokenizer = AutoTokenizer.from_pretrained(model_path)
model = AutoModelForSeq2SeqLM.from_pretrained(model_path)

test_input = "parse event: Meeting with John tomorrow at 3pm for 1 hour"
inputs = tokenizer(test_input, return_tensors="pt", max_length=128, truncation=True)
outputs = model.generate(**inputs, max_length=256)
result = tokenizer.decode(outputs[0], skip_special_tokens=True)

print("Input:", test_input)
print("Output:", result)

# Try to parse as JSON
try:
    parsed = json.loads(result)
    print("\n✓ Valid JSON output!")
    print("Parsed fields:", list(parsed.keys()))
except:
    print("\n❌ Output is not valid JSON - model needs more training")
```

**Expected output** (after successful training):
```json
{
  "action": "Meeting",
  "date": "30/01/2026",
  "time": "03:00 PM",
  "attendees": ["John"],
  "location": null,
  "duration": "1 hour",
  "recurrence": null,
  "notes": null
}
```

## 📚 Technical Details

### Why -100?

In PyTorch, `-100` is a special value used by `CrossEntropyLoss` (and other loss functions):
- Tokens with label `-100` are **ignored** in loss computation
- This is the standard way to mask padding tokens in sequence-to-sequence models

From PyTorch docs:
> If a target index is -100, the corresponding loss is ignored (the gradient is not computed)

### Why did this cause NaN?

1. Padding tokens (ID=0) were treated as valid targets
2. Model tried to predict token 0 for most output positions
3. This created numerical instability in the loss function
4. Gradients became undefined (NaN)
5. Weight updates failed, so loss stayed at 0

## ✅ Verification Checklist

Before downloading your model, check:
- [ ] Loss decreases over time (not stuck at 0)
- [ ] Grad norm is a number, not NaN
- [ ] Eval loss is a number, not NaN
- [ ] Test inference produces valid JSON
- [ ] Model file size is ~250-300 MB (safetensors format)

---

**Fixed:** 2026-01-29  
**Applies to:** Both event and task parser training

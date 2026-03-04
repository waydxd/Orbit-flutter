"""
Fine-tune FLAN-T5-small for event parsing (text -> JSON)

For Google Colab:
  !pip install transformers datasets torch accelerate sentencepiece
  !python train_event_parser.py
"""

import json
from datasets import Dataset
from transformers import (
    AutoTokenizer,
    AutoModelForSeq2SeqLM,
    Seq2SeqTrainer,
    Seq2SeqTrainingArguments,
    default_data_collator,
)
import torch


# ─── Configuration ──────────────────────────────────────────
MODEL_NAME = "google/flan-t5-small"
OUTPUT_DIR = "./models/event-parser"
DATA_FILE = "data/event_training_data.jsonl"
MAX_INPUT_LENGTH = 128
MAX_OUTPUT_LENGTH = 200
BATCH_SIZE = 8
EPOCHS = 15
LEARNING_RATE = 5e-4   # Higher LR for small model to learn JSON structure
WARMUP_RATIO = 0.06


def main():
    print("=" * 60)
    print("Event Parser Training (FLAN-T5-small)")
    print("=" * 60)

    # ─── 1. Load tokenizer & model ─────────────────────────
    print("\n[1] Loading tokenizer and model...")
    tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
    model = AutoModelForSeq2SeqLM.from_pretrained(MODEL_NAME)
    pad_id = tokenizer.pad_token_id
    print(f"    Pad token id: {pad_id}")

    # ─── 2. Load data ──────────────────────────────────────
    print("[2] Loading data...")
    inputs, outputs = [], []
    with open(DATA_FILE, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            ex = json.loads(line)
            inputs.append(ex["input"])
            outputs.append(ex["output"])
    print(f"    Loaded {len(inputs)} examples")

    # ─── 3. Verify data ────────────────────────────────────
    print("[3] Verifying data...")
    print(f"    Input[0]:  {inputs[0][:90]}...")
    print(f"    Output[0]: {outputs[0][:90]}...")

    # Check that outputs are valid JSON and start with '{'
    # Verify pipe-delimited format: "action: ... | date: ... | time: ... | ..."
    bad = 0
    for i, o in enumerate(outputs):
        if "action:" not in o or "|" not in o:
            bad += 1
            if bad <= 3:
                print(f"    WARNING line {i}: not pipe format: {o[:60]}")
    if bad == 0:
        print("    All outputs are valid pipe format (action: ... | date: ... | ...)")
    else:
        print(f"    {bad} problematic outputs found!")

    # ─── 4. Tokenize ───────────────────────────────────────
    print("[4] Tokenizing...")

    # Tokenize all at once
    model_inputs = tokenizer(
        inputs,
        max_length=MAX_INPUT_LENGTH,
        truncation=True,
        padding="max_length",
    )

    # Tokenize targets the SIMPLE way - just call tokenizer directly
    target_encodings = tokenizer(
        outputs,
        max_length=MAX_OUTPUT_LENGTH,
        truncation=True,
        padding="max_length",
    )

    # Replace pad tokens with -100 in labels (so loss ignores padding)
    labels = []
    for label_ids in target_encodings["input_ids"]:
        labels.append(
            [tok if tok != pad_id else -100 for tok in label_ids]
        )

    # VERIFICATION: decode first label back to text to make sure it's correct
    first_label_tokens = [t for t in labels[0] if t != -100]
    decoded = tokenizer.decode(first_label_tokens, skip_special_tokens=True)
    print(f"    Decoded label[0]: {decoded[:90]}...")
    
    # Check for UNK tokens (id=2 in T5 = unknown, means data has chars not in vocab)
    unk_count = sum(1 for label_seq in labels for t in label_seq if t == 2)
    print(f"    UNK tokens in labels: {unk_count} (should be 0!)")
    if unk_count > 0:
        print("    WARNING: UNK tokens found! The model cannot learn these characters.")
    
    if "action:" in decoded and "|" in decoded:
        print("    Pipe format detected - GOOD")
    else:
        print("    WARNING: Expected pipe format (action: ... | date: ... | ...)")

    # Build dataset
    dataset = Dataset.from_dict({
        "input_ids": model_inputs["input_ids"],
        "attention_mask": model_inputs["attention_mask"],
        "labels": labels,
    })
    dataset.set_format("torch")

    # ─── 5. Split ───────────────────────────────────────────
    print("[5] Splitting dataset...")
    split = dataset.train_test_split(test_size=0.1, seed=42)
    train_ds = split["train"]
    val_ds = split["test"]
    print(f"    Train: {len(train_ds)}, Val: {len(val_ds)}")

    # ─── 6. Training setup ──────────────────────────────────
    print("[6] Setting up training...")

    # NEVER use fp16 with T5 - causes NaN
    use_bf16 = torch.cuda.is_available() and torch.cuda.is_bf16_supported()
    device_name = "GPU" if torch.cuda.is_available() else "CPU"
    print(f"    Device: {device_name}, bf16={use_bf16}")

    training_args = Seq2SeqTrainingArguments(
        output_dir=OUTPUT_DIR,
        num_train_epochs=EPOCHS,
        per_device_train_batch_size=BATCH_SIZE,
        per_device_eval_batch_size=BATCH_SIZE,
        learning_rate=LEARNING_RATE,
        warmup_ratio=WARMUP_RATIO,
        weight_decay=0.01,
        eval_strategy="epoch",
        save_strategy="epoch",
        save_total_limit=2,
        load_best_model_at_end=True,
        metric_for_best_model="eval_loss",
        greater_is_better=False,
        logging_steps=20,
        fp16=False,
        bf16=use_bf16,
        predict_with_generate=False,   # Faster training without generation during eval
        report_to="none",
    )

    trainer = Seq2SeqTrainer(
        model=model,
        args=training_args,
        train_dataset=train_ds,
        eval_dataset=val_ds,
        data_collator=default_data_collator,   # Data is already padded
    )

    # ─── 7. Train ───────────────────────────────────────────
    print("[7] Starting training...")
    steps_per_epoch = len(train_ds) // BATCH_SIZE
    print(f"    Steps/epoch: ~{steps_per_epoch}, Total: ~{steps_per_epoch * EPOCHS}")
    print(f"    Epochs: {EPOCHS}, LR: {LEARNING_RATE}")
    print()
    print("    >>> WATCH: loss should START around 2-5 and DECREASE <<<")
    print("    >>> If loss=0 and grad_norm=nan, something is STILL wrong <<<")
    print()

    trainer.train()

    # ─── 8. Save ────────────────────────────────────────────
    print("\n" + "=" * 60)
    print("Saving model...")
    model.save_pretrained(OUTPUT_DIR)
    tokenizer.save_pretrained(OUTPUT_DIR)
    print(f"Saved to: {OUTPUT_DIR}")

    # ─── 9. Quick test ──────────────────────────────────────
    print("\n--- Quick Inference Test ---")
    test_texts = [
        "parse event: Meeting with John on 12th, Mar 2026 at 3pm for 1 hour",
        "parse event: Dentist appointment on 5th, Feb 2026 at 10am",
        "parse event: Yoga every Wednesday at 6pm at HKUST gym for 1 hour",
    ]
    device = next(model.parameters()).device
    for t in test_texts:
        enc = tokenizer(t, return_tensors="pt", max_length=128, truncation=True)
        enc = {k: v.to(device) for k, v in enc.items()}
        out = model.generate(
            **enc,
            max_new_tokens=150,
            num_beams=4,
            no_repeat_ngram_size=3,
            repetition_penalty=2.5,
            early_stopping=True,
        )
        result = tokenizer.decode(out[0], skip_special_tokens=True)
        print(f"  In:  {t}")
        print(f"  Out: {result}")
        if "action:" in result and "|" in result:
            print(f"  >>> Pipe format output - GOOD <<<")
        else:
            print(f"  >>> Unexpected format <<<")
        print()

    print("=" * 60)
    print("Done!")
    print("=" * 60)


if __name__ == "__main__":
    main()

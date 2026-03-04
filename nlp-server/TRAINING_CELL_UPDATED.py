# === Updated Training Configuration for Colab ===
# Copy this into your notebook

# Cell 6: Training Configuration with Early Stopping
from transformers import Seq2SeqTrainingArguments, Seq2SeqTrainer, EarlyStoppingCallback

training_args = Seq2SeqTrainingArguments(
    output_dir=OUTPUT_DIR,
    eval_strategy="epoch",  # Changed from evaluation_strategy
    save_strategy="epoch",
    learning_rate=LEARNING_RATE,
    per_device_train_batch_size=BATCH_SIZE,
    per_device_eval_batch_size=BATCH_SIZE,
    num_train_epochs=EPOCHS,
    weight_decay=WEIGHT_DECAY,
    save_total_limit=2,
    predict_with_generate=False,
    warmup_ratio=WARMUP_RATIO,
    logging_steps=20,
    load_best_model_at_end=True,  # Load best checkpoint at end
    metric_for_best_model="eval_loss",  # Use validation loss
    greater_is_better=False,  # Lower loss is better
    report_to="none",
    fp16=False,  # Not available on all GPUs
    bf16=True,   # Better for training
)

print("Training Configuration:")
print(f"  Max Epochs: {EPOCHS}")
print(f"  Early Stopping: Enabled (patience=3)")
print(f"  Load Best Model: True")
print(f"  Save Strategy: epoch")
print(f"  Metric: eval_loss")

# Cell 7: Initialize Trainer with Early Stopping
trainer = Seq2SeqTrainer(
    model=model,
    args=training_args,
    train_dataset=tokenized_train,
    eval_dataset=tokenized_val,
    callbacks=[
        EarlyStoppingCallback(early_stopping_patience=3)
    ]
)

print("\n✅ Trainer initialized with early stopping")
print("   Training will stop if validation loss doesn't improve for 3 epochs")

# Cell 8: Train
print("Starting training...")
print("=" * 70)

trainer.train()

print("\n" + "=" * 70)
print("✅ Training completed!")
print("   Best model automatically loaded")
print("=" * 70)

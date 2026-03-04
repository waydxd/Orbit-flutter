"""
Fine-tune FLAN-T5-small for task parsing (text to JSON)
Converts natural language task descriptions to structured JSON

Usage:
1. Copy task_augmented.jsonl to nlp-server/data/
2. Run: python utils/data_preprocessing.py task (to create task_training_data.jsonl)
3. Run: python train_task_parser.py

For Google Colab:
1. Upload this script and data/ folder to Colab
2. Install dependencies: !pip install transformers datasets torch accelerate sentencepiece
3. Run the script
4. Download the model: files.download('task-parser-model.zip')
"""

import json
from datasets import Dataset
from transformers import (
    AutoTokenizer,
    AutoModelForSeq2SeqLM,
    Seq2SeqTrainer,
    Seq2SeqTrainingArguments,
    DataCollatorForSeq2Seq,
)
import torch


def load_data(file_path='data/task_training_data.jsonl'):
    """Load training data from JSONL file."""
    data = {'input': [], 'output': []}
    
    with open(file_path, 'r') as f:
        for line in f:
            example = json.loads(line)
            data['input'].append(example['input'])
            data['output'].append(example['output'])
    
    return Dataset.from_dict(data)


def main():
    print("=" * 60)
    print("Task Parser Fine-tuning Script (FLAN-T5-small)")
    print("=" * 60)
    
    # Configuration
    MODEL_NAME = "google/flan-t5-small"
    OUTPUT_DIR = "./models/task-parser"
    MAX_INPUT_LENGTH = 128
    MAX_OUTPUT_LENGTH = 256
    BATCH_SIZE = 8
    EPOCHS = 5
    LEARNING_RATE = 3e-5
    
    print(f"\nConfiguration:")
    print(f"  Base Model: {MODEL_NAME}")
    print(f"  Output Dir: {OUTPUT_DIR}")
    print(f"  Epochs: {EPOCHS}")
    print(f"  Batch Size: {BATCH_SIZE}")
    print(f"  Learning Rate: {LEARNING_RATE}")
    print(f"  Max Input Length: {MAX_INPUT_LENGTH}")
    print(f"  Max Output Length: {MAX_OUTPUT_LENGTH}")
    
    # Load tokenizer and model
    print("\n[1/6] Loading tokenizer and model...")
    tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
    model = AutoModelForSeq2SeqLM.from_pretrained(MODEL_NAME)
    
    # Load dataset
    print("[2/6] Loading dataset...")
    try:
        dataset = load_data('data/task_training_data.jsonl')
        print(f"  Loaded {len(dataset)} examples")
    except FileNotFoundError:
        print("  ERROR: data/task_training_data.jsonl not found!")
        print("  Run: python utils/data_preprocessing.py task first")
        return
    
    # Split dataset
    print("[3/6] Splitting dataset (80% train, 10% val, 10% test)...")
    train_test = dataset.train_test_split(test_size=0.2, seed=42)
    val_test = train_test['test'].train_test_split(test_size=0.5, seed=42)
    
    train_dataset = train_test['train']
    val_dataset = val_test['train']
    test_dataset = val_test['test']
    
    print(f"  Train: {len(train_dataset)} examples")
    print(f"  Validation: {len(val_dataset)} examples")
    print(f"  Test: {len(test_dataset)} examples")
    
    # Tokenize datasets
    # NOTE: Do NOT pad here. Let DataCollatorForSeq2Seq handle dynamic padding.
    print("[4/6] Tokenizing datasets...")
    
    def preprocess_function(examples):
        """Tokenize inputs and outputs for T5."""
        model_inputs = tokenizer(
            examples['input'],
            max_length=MAX_INPUT_LENGTH,
            truncation=True,
            padding=False,
        )
        
        labels = tokenizer(
            text_target=examples['output'],
            max_length=MAX_OUTPUT_LENGTH,
            truncation=True,
            padding=False,
        )
        
        model_inputs['labels'] = labels['input_ids']
        return model_inputs
    
    tokenized_train = train_dataset.map(
        preprocess_function,
        batched=True,
        remove_columns=train_dataset.column_names
    )
    tokenized_val = val_dataset.map(
        preprocess_function,
        batched=True,
        remove_columns=val_dataset.column_names
    )
    
    # Data collator - handles dynamic padding and sets padding labels to -100
    data_collator = DataCollatorForSeq2Seq(
        tokenizer=tokenizer,
        model=model,
        label_pad_token_id=-100,
        padding=True,
    )
    
    # Training arguments
    print("[5/6] Setting up training...")
    
    # IMPORTANT: T5/FLAN-T5 is unstable with fp16! Use bf16 if available, else fp32.
    use_bf16 = torch.cuda.is_available() and torch.cuda.is_bf16_supported()
    use_fp16 = False  # NEVER use fp16 with T5 - causes NaN gradients
    
    print(f"  fp16: {use_fp16}, bf16: {use_bf16}")
    
    training_args = Seq2SeqTrainingArguments(
        output_dir=OUTPUT_DIR,
        num_train_epochs=EPOCHS,
        per_device_train_batch_size=BATCH_SIZE,
        per_device_eval_batch_size=BATCH_SIZE,
        learning_rate=LEARNING_RATE,
        weight_decay=0.01,
        eval_strategy="epoch",
        save_strategy="epoch",
        save_total_limit=2,
        load_best_model_at_end=True,
        push_to_hub=False,
        logging_steps=50,
        fp16=use_fp16,
        bf16=use_bf16,
        predict_with_generate=True,
    )
    
    # Initialize trainer
    trainer = Seq2SeqTrainer(
        model=model,
        args=training_args,
        train_dataset=tokenized_train,
        eval_dataset=tokenized_val,
        data_collator=data_collator,
    )
    
    # Train
    print("[6/6] Starting training...")
    print(f"  Device: {'GPU' if torch.cuda.is_available() else 'CPU'}")
    print(f"  This may take 10-20 minutes on CPU, 3-5 minutes on GPU\n")
    
    trainer.train()
    
    # Save final model
    print("\n" + "=" * 60)
    print("Training complete! Saving model...")
    model.save_pretrained(OUTPUT_DIR)
    tokenizer.save_pretrained(OUTPUT_DIR)
    
    print(f"\nModel saved to: {OUTPUT_DIR}")
    print("\nNext steps:")
    print("  1. Test the model: python test_one-shot_classification.py task")
    print("  2. Start the server: python server.py")
    print("  3. Or if in Colab, download the model:")
    print("     !zip -r task-parser-model.zip ./models/task-parser")
    print("     from google.colab import files")
    print("     files.download('task-parser-model.zip')")
    print("=" * 60)


if __name__ == '__main__':
    main()

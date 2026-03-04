"""
Test the current deployed model to see what it learned
"""

from transformers import AutoTokenizer, AutoModelForSeq2SeqLM

MODEL_PATH = "./models/event-parser"

print("Loading model...")
tokenizer = AutoTokenizer.from_pretrained(MODEL_PATH, use_fast=False)
model = AutoModelForSeq2SeqLM.from_pretrained(MODEL_PATH)
print("Model loaded!\n")

# Test cases that should work if model was trained on correct data
test_cases = [
    # Basic events (should work even with old model)
    ("Meeting with John tomorrow at 3pm", "Should extract: action, date, time"),
    ("Team meeting next Monday at 10am for 1 hour", "Should extract: action, date, time, duration"),
    
    # Time ranges (needs NEW training data)
    ("Meeting 10am-11:20am tomorrow", "Should extract: duration '1 hour 20 minutes'"),
    ("Workshop 3pm-5pm today", "Should extract: duration '2 hours'"),
    
    # Recurrence (needs improved dataset)
    ("Yoga every Wednesday at 6pm", "Should extract: recurrence 'Weekly'"),
    ("Daily standup at 9am", "Should extract: recurrence 'Daily'"),
]

print("="*70)
print("MODEL OUTPUT TEST")
print("="*70)

for i, (text, expected) in enumerate(test_cases, 1):
    print(f"\n{i}. Input: {text}")
    print(f"   {expected}")
    print(f"   {'-'*66}")
    
    input_text = f"parse event: {text}"
    inputs = tokenizer(input_text, return_tensors="pt", max_length=128, truncation=True)
    
    outputs = model.generate(
        **inputs,
        max_length=200,
        num_beams=4,
        early_stopping=True
    )
    
    generated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)
    
    if len(generated_text) == 0:
        print(f"   ❌ Model output: EMPTY")
    elif len(generated_text) < 20 or '|' not in generated_text:
        print(f"   ❌ Model output: INVALID")
        print(f"      Raw: {generated_text[:100]}")
    else:
        print(f"   ✅ Model output: {generated_text}")

print("\n" + "="*70)
print("DIAGNOSIS")
print("="*70)

# Check which tests passed
print("\nIf most tests show EMPTY or INVALID:")
print("  → Model was likely trained on wrong/corrupted data")
print("  → OR model training didn't converge properly")
print("  → Solution: Retrain with the correct event_training_data.jsonl")
print("\nIf tests 1-2 work but 3-6 fail:")
print("  → Model was trained on OLD dataset (before time range fix)")
print("  → Solution: Retrain with NEW dataset (3,702 examples)")

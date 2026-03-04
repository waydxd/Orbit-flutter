"""
Direct test of the event parser model to see raw output
"""

from transformers import AutoTokenizer, AutoModelForSeq2SeqLM

MODEL_PATH = "./models/event-parser"

print("Loading model...")
tokenizer = AutoTokenizer.from_pretrained(MODEL_PATH, use_fast=False)
model = AutoModelForSeq2SeqLM.from_pretrained(MODEL_PATH)
print("Model loaded!")

# Test cases
test_cases = [
    "Meeting tomorrow at 3pm for 2 hours",
    "Meeting 10am-11:20am tomorrow",
    "Yoga every Wednesday at 6pm",
]

for text in test_cases:
    print(f"\n{'='*60}")
    print(f"Input: {text}")
    print(f"{'='*60}")
    
    # Prepare input
    input_text = f"parse event: {text}"
    inputs = tokenizer(input_text, return_tensors="pt", max_length=128, truncation=True)
    
    # Generate
    outputs = model.generate(
        **inputs,
        max_length=200,
        num_beams=4,
        early_stopping=True
    )
    
    # Decode
    generated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)
    
    print(f"Raw Output: '{generated_text}'")
    print(f"Output Length: {len(generated_text)}")
    print(f"Output Type: {type(generated_text)}")

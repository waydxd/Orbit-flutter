"""
Test the fine-tuned T5 event/task parser models

Usage:
  python test_one-shot_classification.py         # Test event parser
  python test_one-shot_classification.py task    # Test task parser
"""

from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
import json
import sys


def pipe_to_dict(pipe_str: str) -> dict:
    """Convert pipe-delimited model output to dict."""
    result = {}
    list_fields = {"attendees"}
    
    parts = pipe_str.split(" | ")
    for part in parts:
        part = part.strip()
        if ": " not in part:
            continue
        key, value = part.split(": ", 1)
        key = key.strip()
        value = value.strip()
        
        if value.lower() in ("none", "null", ""):
            result[key] = None
        elif key in list_fields:
            items = [v.strip() for v in value.split(",")]
            result[key] = items if items != ["none"] else None
        else:
            result[key] = value
    
    return result


EVENT_MODEL_PATH = "../models/event-parser"
TASK_MODEL_PATH = "./models/task-parser"

EVENT_TEST_EXAMPLES = [
    "Meeting with John tomorrow at 3pm for 1 hour",
    "Dentist appointment next Monday at 10am",
    "Team standup every Tuesday at 9am for 15 minutes",
    "COMP 2012 lecture every Monday at 10am-11:20am at HKUST Room 4504",
    "Coffee chat with Sarah at Starbucks tomorrow 10am for 30 minutes",
    "Dinner at Causeway Bay on 5th, Feb 2026 at 7pm with Emma",
    "Yoga every Wednesday at 6pm at HKUST gym for 1 hour",
]

TASK_TEST_EXAMPLES = [
    "Submit report by Friday 5pm high priority",
    "Buy groceries tomorrow",
    "Call mom this weekend",
    "Finish presentation by next Monday urgent",
    "Review code changes low priority",
]


def test_model(model_path, test_examples, prefix, model_type):
    print("=" * 80)
    print(f"Testing {model_type} Parser")
    print("=" * 80)
    
    print(f"\nLoading model from {model_path}...")
    try:
        tokenizer = AutoTokenizer.from_pretrained(model_path)
        model = AutoModelForSeq2SeqLM.from_pretrained(model_path)
        print("Model loaded!\n")
    except Exception as e:
        print(f"Failed: {e}")
        return
    
    valid_count = 0
    
    for test_text in test_examples:
        print(f"Input:  {test_text}")
        
        input_text = f"{prefix}: {test_text}"
        inputs = tokenizer(input_text, return_tensors="pt", max_length=128, truncation=True)
        
        outputs = model.generate(
            **inputs,
            max_new_tokens=150,
            num_beams=4,
            early_stopping=True,
            no_repeat_ngram_size=3,
            repetition_penalty=2.5,
        )
        raw = tokenizer.decode(outputs[0], skip_special_tokens=True)
        print(f"Raw:    {raw}")
        
        # Parse pipe format to dict
        parsed = pipe_to_dict(raw)
        if parsed:
            print(f"Parsed: {json.dumps(parsed, ensure_ascii=False)}")
            valid_count += 1
        else:
            print("  Could not parse output")
        
        print("-" * 80)
    
    print(f"\nResults: {valid_count}/{len(test_examples)} successfully parsed")
    print("=" * 80)


def main():
    if len(sys.argv) > 1 and sys.argv[1].lower() == 'task':
        test_model(TASK_MODEL_PATH, TASK_TEST_EXAMPLES, "parse task", "Task")
    else:
        test_model(EVENT_MODEL_PATH, EVENT_TEST_EXAMPLES, "parse event", "Event")


if __name__ == '__main__':
    main()

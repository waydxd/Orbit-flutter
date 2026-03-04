"""
Evaluate the trained event parser model.
Shows accuracy metrics and common errors.
"""

import json
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
from datasets import Dataset


def evaluate_model(model_path, test_data_file, num_samples=100):
    """Evaluate model on test data."""
    print("Loading model...")
    tokenizer = AutoTokenizer.from_pretrained(model_path)
    model = AutoModelForSeq2SeqLM.from_pretrained(model_path)
    
    print(f"Loading test data from {test_data_file}...")
    test_examples = []
    with open(test_data_file, 'r', encoding='utf-8') as f:
        for i, line in enumerate(f):
            if i >= num_samples:
                break
            test_examples.append(json.loads(line.strip()))
    
    print(f"\nEvaluating on {len(test_examples)} examples...\n")
    
    # Metrics
    total = len(test_examples)
    valid_json_count = 0
    exact_match_count = 0
    field_accuracy = {}
    
    errors = []
    
    for i, example in enumerate(test_examples):
        input_text = example['input']
        expected_output = example['output']
        expected_json = json.loads(expected_output)
        
        # Generate prediction
        inputs = tokenizer(input_text, return_tensors="pt", max_length=128, truncation=True)
        outputs = model.generate(**inputs, max_length=256, num_beams=4)
        predicted_text = tokenizer.decode(outputs[0], skip_special_tokens=True)
        
        # Check if valid JSON
        try:
            predicted_json = json.loads(predicted_text)
            valid_json_count += 1
            
            # Check exact match
            if predicted_json == expected_json:
                exact_match_count += 1
            else:
                errors.append({
                    'input': input_text.replace('parse event: ', ''),
                    'expected': expected_json,
                    'predicted': predicted_json
                })
            
            # Check field-level accuracy
            for field in expected_json.keys():
                if field not in field_accuracy:
                    field_accuracy[field] = {'correct': 0, 'total': 0}
                
                field_accuracy[field]['total'] += 1
                if field in predicted_json and predicted_json[field] == expected_json[field]:
                    field_accuracy[field]['correct'] += 1
        
        except json.JSONDecodeError:
            errors.append({
                'input': input_text.replace('parse event: ', ''),
                'expected': expected_json,
                'predicted': f"INVALID JSON: {predicted_text}"
            })
    
    # Print results
    print("="*70)
    print("EVALUATION RESULTS")
    print("="*70)
    print(f"\nTotal examples: {total}")
    print(f"Valid JSON outputs: {valid_json_count}/{total} ({valid_json_count/total*100:.1f}%)")
    print(f"Exact matches: {exact_match_count}/{total} ({exact_match_count/total*100:.1f}%)")
    
    print(f"\nField-level Accuracy:")
    for field, stats in sorted(field_accuracy.items()):
        accuracy = stats['correct'] / stats['total'] * 100
        print(f"  {field:15s}: {stats['correct']:3d}/{stats['total']:3d} ({accuracy:5.1f}%)")
    
    # Show sample errors
    if errors:
        print(f"\n{'='*70}")
        print(f"SAMPLE ERRORS (showing first 5):")
        print(f"{'='*70}")
        for i, error in enumerate(errors[:5]):
            print(f"\n[Error {i+1}]")
            print(f"Input:     {error['input'][:80]}...")
            print(f"Expected:  {json.dumps(error['expected'], ensure_ascii=False)[:80]}...")
            print(f"Predicted: {str(error['predicted'])[:80]}...")
    
    # Recommendations
    print(f"\n{'='*70}")
    print("RECOMMENDATIONS:")
    print(f"{'='*70}")
    
    json_rate = valid_json_count / total * 100
    exact_rate = exact_match_count / total * 100
    
    if json_rate < 95:
        print("⚠ Low JSON validity rate (<95%):")
        print("  → Train for more epochs (10-15)")
        print("  → Check training data quality")
    
    if exact_rate < 70:
        print("⚠ Low exact match rate (<70%):")
        print("  → Add more training examples")
        print("  → Train with t5-base instead of t5-small")
        print("  → Increase max_output_length to 512")
    elif exact_rate < 85:
        print("✓ Good performance! To improve further:")
        print("  → Train for 15-20 epochs")
        print("  → Fine-tune with more diverse examples")
    else:
        print("✅ Excellent performance!")
        print("  → Model is production-ready")
    
    print()


if __name__ == "__main__":
    import sys
    
    model_path = sys.argv[1] if len(sys.argv) > 1 else "./models/event-parser"
    test_file = sys.argv[2] if len(sys.argv) > 2 else "data/event_training_data.jsonl"
    num_samples = int(sys.argv[3]) if len(sys.argv) > 3 else 100
    
    print(f"Model: {model_path}")
    print(f"Test file: {test_file}")
    print(f"Samples: {num_samples}\n")
    
    evaluate_model(model_path, test_file, num_samples)

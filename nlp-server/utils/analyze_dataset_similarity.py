"""
Analyze similarity between two event datasets.
"""

import json
from collections import Counter


def analyze_dataset(file_path, name):
    """Analyze a single dataset."""
    print(f"\n{'='*60}")
    print(f"Dataset: {name}")
    print(f"{'='*60}")
    
    examples = []
    output_fields = set()
    input_texts = []
    
    with open(file_path, 'r', encoding='utf-8') as f:
        for line in f:
            example = json.loads(line.strip())
            examples.append(example)
            input_texts.append(example['input'].replace('parse event: ', ''))
            
            # Parse output JSON to get field names
            output_data = json.loads(example['output'])
            output_fields.update(output_data.keys())
    
    print(f"Total examples: {len(examples)}")
    print(f"\nOutput fields: {sorted(output_fields)}")
    
    # Check for null/non-null patterns
    print(f"\nField usage analysis (non-null values):")
    field_counts = Counter()
    for example in examples:
        output_data = json.loads(example['output'])
        for field, value in output_data.items():
            if value is not None and value != [] and value != "":
                field_counts[field] += 1
    
    for field, count in sorted(field_counts.items()):
        percentage = (count / len(examples)) * 100
        print(f"  {field:20s}: {count:5d} ({percentage:5.1f}%)")
    
    # Show sample
    print(f"\nSample examples:")
    for i in range(min(3, len(examples))):
        print(f"\n  [{i+1}] Input: {input_texts[i][:80]}...")
        output = json.loads(examples[i]['output'])
        print(f"      Output fields: {list(output.keys())}")
    
    return input_texts, output_fields


def check_overlap(texts1, texts2, name1, name2):
    """Check for overlapping texts between datasets."""
    print(f"\n{'='*60}")
    print(f"Overlap Analysis: {name1} vs {name2}")
    print(f"{'='*60}")
    
    set1 = set(texts1)
    set2 = set(texts2)
    
    overlap = set1.intersection(set2)
    
    print(f"{name1} unique texts: {len(set1)}")
    print(f"{name2} unique texts: {len(set2)}")
    print(f"Overlapping texts: {len(overlap)}")
    
    if overlap:
        print(f"\nOverlap percentage:")
        print(f"  {name1}: {(len(overlap) / len(set1) * 100):.1f}%")
        print(f"  {name2}: {(len(overlap) / len(set2) * 100):.1f}%")
        print(f"\nSample overlapping texts:")
        for text in list(overlap)[:3]:
            print(f"  - {text[:100]}...")
    else:
        print("\n✓ No overlapping texts - datasets are completely unique!")


if __name__ == "__main__":
    # Analyze new dataset (event_text_mapping)
    new_file = "data/event_text_mapping.jsonl"
    temp_new = "/tmp/event_text_mapping_converted.jsonl"
    
    # Convert new dataset first
    with open(new_file, 'r', encoding='utf-8') as inf, \
         open(temp_new, 'w', encoding='utf-8') as outf:
        for line in inf:
            example = json.loads(line.strip())
            t5_example = {
                'input': f"parse event: {example['event_text']}",
                'output': json.dumps(example['output'], ensure_ascii=False)
            }
            outf.write(json.dumps(t5_example, ensure_ascii=False) + '\n')
    
    texts_new, fields_new = analyze_dataset(temp_new, "New Dataset (event_text_mapping)")
    
    # Analyze old dataset
    texts_old, fields_old = analyze_dataset(
        "data/event_training_data.jsonl", 
        "Old Dataset (augmented)"
    )
    
    # Check overlap
    check_overlap(texts_new, texts_old, "New", "Old")
    
    # Compare field structures
    print(f"\n{'='*60}")
    print(f"Field Structure Comparison")
    print(f"{'='*60}")
    print(f"\nFields in New but not Old: {fields_new - fields_old}")
    print(f"Fields in Old but not New: {fields_old - fields_new}")
    print(f"Common fields: {fields_new.intersection(fields_old)}")
    
    print(f"\n{'='*60}")
    print(f"Summary")
    print(f"{'='*60}")
    print(f"New dataset has different output schema (action, date, time, duration, attendees)")
    print(f"Old dataset has different output schema (title, start_time, end_time, location)")
    print(f"Combining them will teach the model to handle BOTH formats!")

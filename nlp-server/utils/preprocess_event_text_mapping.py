"""
Preprocessing script for event_text_mapping.jsonl dataset.
Converts to T5 seq2seq format for event parsing.
"""

import json


def convert_to_t5_format(input_file, output_file):
    """
    Convert event_text_mapping.jsonl to T5 training format.
    
    Input format:
    {
        "event_text": "Meeting with John...",
        "output": {
            "action": "Meeting",
            "date": "15/12/2024",
            "time": "9:00 PM",
            "attendees": ["John"],
            "location": "café",
            "duration": "2 hours",
            "recurrence": null,
            "notes": null
        }
    }
    
    Output format:
    {
        "input": "parse event: Meeting with John...",
        "output": "{\"action\": \"Meeting\", \"date\": \"15/12/2024\", ...}"
    }
    """
    converted_count = 0
    
    with open(input_file, 'r', encoding='utf-8') as infile, \
         open(output_file, 'w', encoding='utf-8') as outfile:
        
        for line in infile:
            example = json.loads(line.strip())
            
            # Extract input text
            event_text = example['event_text']
            
            # Extract output fields
            output_data = example['output']
            
            # Create T5 training example
            t5_example = {
                'input': f"parse event: {event_text}",
                'output': json.dumps(output_data, ensure_ascii=False)
            }
            
            outfile.write(json.dumps(t5_example, ensure_ascii=False) + '\n')
            converted_count += 1
    
    print(f"✓ Converted {converted_count} examples")
    print(f"  Input:  {input_file}")
    print(f"  Output: {output_file}")


def combine_datasets(file1, file2, output_file):
    """
    Combine two T5-formatted datasets into one.
    """
    total_count = 0
    
    with open(output_file, 'w', encoding='utf-8') as outfile:
        # Read first file
        with open(file1, 'r', encoding='utf-8') as f1:
            for line in f1:
                outfile.write(line)
                total_count += 1
        
        # Read second file
        with open(file2, 'r', encoding='utf-8') as f2:
            for line in f2:
                outfile.write(line)
                total_count += 1
    
    print(f"✓ Combined datasets: {total_count} total examples")
    print(f"  Output: {output_file}")


if __name__ == "__main__":
    import sys
    
    if len(sys.argv) < 2:
        print("Usage:")
        print("  Convert only:")
        print("    python preprocess_event_text_mapping.py <input.jsonl> <output.jsonl>")
        print("  Convert and combine:")
        print("    python preprocess_event_text_mapping.py <new.jsonl> <old.jsonl> <combined.jsonl>")
        sys.exit(1)
    
    if len(sys.argv) == 3:
        # Convert only
        convert_to_t5_format(sys.argv[1], sys.argv[2])
    elif len(sys.argv) == 4:
        # Convert new dataset
        print("[1/2] Converting new dataset...")
        temp_file = "/tmp/event_text_mapping_converted.jsonl"
        convert_to_t5_format(sys.argv[1], temp_file)
        
        # Combine with old dataset
        print("\n[2/2] Combining datasets...")
        combine_datasets(temp_file, sys.argv[2], sys.argv[3])
        print("\n✓ Done! Use the combined dataset for training.")
    else:
        print("Error: Invalid number of arguments")
        sys.exit(1)

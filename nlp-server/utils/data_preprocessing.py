"""
Data preprocessing utilities for event/task parser fine-tuning
Converts augmented.jsonl to T5 seq2seq format

IMPORTANT: T5's SentencePiece vocabulary does NOT contain { and }.
They map to <unk> (token ID 2), which means the model can NEVER
learn to output them. So we use a pipe-delimited format instead:

  action: Meeting | date: 12/11/2023 | time: 11:30 AM | attendees: Tina | ...

The server converts this back to JSON during post-processing.
"""

import json
from typing import Dict, Any, Optional, List
import sys
import os

# Add parent directory to path to import date_resolver
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from utils.date_resolver import convert_time_range_to_duration


def output_to_pipe_format(output: dict) -> str:
    """
    Convert a JSON output dict to pipe-delimited string format.
    
    Input:  {"action": "Meeting", "date": "12/11/2023", "time": "11:30 AM",
             "attendees": ["John"], "location": "Zoom", "duration": "1 hour",
             "recurrence": "Weekly", "notes": null}
    
    Output: "action: Meeting | date: 12/11/2023 | time: 11:30 AM | attendees: John | 
             location: Zoom | duration: 1 hour | recurrence: Weekly | notes: none"
    """
    parts = []
    for key, value in output.items():
        if value is None:
            parts.append(f"{key}: none")
        elif isinstance(value, list):
            # Join list items with comma
            list_str = ", ".join(str(v) for v in value) if value else "none"
            parts.append(f"{key}: {list_str}")
        else:
            parts.append(f"{key}: {value}")
    
    return " | ".join(parts)


def pipe_format_to_dict(pipe_str: str) -> dict:
    """
    Convert pipe-delimited string back to a Python dict.
    
    Input:  "action: Meeting | date: 12/11/2023 | time: 11:30 AM | attendees: John, Sarah | 
             location: Zoom | duration: 1 hour | recurrence: Weekly | notes: none"
    
    Output: {"action": "Meeting", "date": "12/11/2023", "time": "11:30 AM",
             "attendees": ["John", "Sarah"], "location": "Zoom", "duration": "1 hour",
             "recurrence": "Weekly", "notes": null}
    """
    result = {}
    # Fields that should be lists
    list_fields = {"attendees"}
    
    parts = pipe_str.split(" | ")
    for part in parts:
        part = part.strip()
        if ": " not in part:
            continue
        key, value = part.split(": ", 1)
        key = key.strip()
        value = value.strip()
        
        if value.lower() == "none" or value.lower() == "null":
            result[key] = None
        elif key in list_fields:
            # Split comma-separated values into list
            items = [v.strip() for v in value.split(",")]
            result[key] = items if items != ["none"] else None
        else:
            result[key] = value
    
    return result


def prepare_event_training_data(input_file: str, output_file: str):
    """
    Convert event_text_mapping.jsonl to T5 seq2seq format for events.
    Uses pipe-delimited output format (not JSON) because T5 can't tokenize { }.
    
    IMPORTANT: Preprocesses input text to convert time ranges to durations,
    so the model learns from the same format it will see during inference.
    
    T5 Format:
    Input:  "parse event: Meeting with John tomorrow at 3pm for 1 hour"
    Output: "action: Meeting | date: 15/01/2025 | time: 03:00 PM | attendees: John | ..."
    """
    count = 0
    with open(input_file, 'r', encoding='utf-8') as f_in, open(output_file, 'w', encoding='utf-8') as f_out:
        for line in f_in:
            line = line.strip()
            if not line:
                continue
            data = json.loads(line)
            
            # Preprocess input text: convert time ranges to durations
            # This ensures training examples match inference format
            event_text = data['event_text']
            preprocessed_text = convert_time_range_to_duration(event_text)
            
            # Convert output dict to pipe format
            pipe_output = output_to_pipe_format(data['output'])
            
            # Create T5 training example
            training_example = {
                'input': f"parse event: {preprocessed_text}",
                'output': pipe_output
            }
            
            f_out.write(json.dumps(training_example, ensure_ascii=False) + '\n')
            count += 1
    
    print(f"Converted {count} examples from {input_file} to {output_file}")


def prepare_task_training_data(input_file: str, output_file: str):
    """
    Convert task dataset to T5 seq2seq format for tasks.
    Uses pipe-delimited output format.
    """
    count = 0
    with open(input_file, 'r', encoding='utf-8') as f_in, open(output_file, 'w', encoding='utf-8') as f_out:
        for line in f_in:
            line = line.strip()
            if not line:
                continue
            data = json.loads(line)
            
            text_field = data.get('task_text') or data.get('event_text') or data.get('text')
            if not text_field:
                continue
            
            pipe_output = output_to_pipe_format(data['output'])
            
            training_example = {
                'input': f"parse task: {text_field}",
                'output': pipe_output
            }
            
            f_out.write(json.dumps(training_example, ensure_ascii=False) + '\n')
            count += 1
    
    print(f"Converted {count} examples from {input_file} to {output_file}")


if __name__ == '__main__':
    import sys
    
    print("=" * 50)
    print("T5 Training Data Preparation")
    print("=" * 50)
    print("Format: pipe-delimited (T5 can't tokenize { } )")
    
    if len(sys.argv) > 1 and sys.argv[1] == 'task':
        print("\nPreparing TASK parser training data...")
        prepare_task_training_data(
            'data/task_augmented.jsonl',
            'data/task_training_data.jsonl'
        )
    else:
        print("\nPreparing EVENT parser training data...")
        # Use merged dataset with recurrence + time range examples
        prepare_event_training_data(
            'data/event_text_mapping_with_timeranges.jsonl',
            'data/event_training_data.jsonl'
        )
    
    # Show sample
    print("\nSample output:")
    with open('data/event_training_data.jsonl', 'r', encoding='utf-8') as f:
        sample = json.loads(f.readline())
        print(f"  Input:  {sample['input'][:80]}...")
        print(f"  Output: {sample['output'][:80]}...")
    
    # Verify round-trip
    print("\nVerifying round-trip conversion...")
    parsed = pipe_format_to_dict(sample['output'])
    print(f"  Parsed back: {json.dumps(parsed)[:80]}...")
    
    print("\nDone!")

"""
Generate training examples for time ranges

This script creates diverse examples of events with time ranges (e.g., 10am-11:20am)
which will be preprocessed into explicit durations (e.g., "for 1 hour 20 minutes").
"""

import json
import random
from datetime import datetime, timedelta

# Time range templates (start_time, end_time, duration_text)
TIME_RANGES = [
    ("9am", "10am", "1 hour"),
    ("10am", "11am", "1 hour"),
    ("10am", "11:30am", "1 hour 30 minutes"),
    ("10am", "12pm", "2 hours"),
    ("2pm", "3pm", "1 hour"),
    ("2pm", "4pm", "2 hours"),
    ("3pm", "5pm", "2 hours"),
    ("6pm", "7pm", "1 hour"),
    ("6pm", "7:30pm", "1 hour 30 minutes"),
    ("7pm", "8pm", "1 hour"),
    ("9:30am", "11am", "1 hour 30 minutes"),
    ("1pm", "2:30pm", "1 hour 30 minutes"),
    ("3:30pm", "5pm", "1 hour 30 minutes"),
    ("12pm", "1pm", "1 hour"),
    ("8am", "9:30am", "1 hour 30 minutes"),
    ("11am", "12:30pm", "1 hour 30 minutes"),
    ("4pm", "6pm", "2 hours"),
    ("5pm", "6:30pm", "1 hour 30 minutes"),
    ("10:30am", "12pm", "1 hour 30 minutes"),
    ("2:30pm", "4pm", "1 hour 30 minutes"),
]

# Event types with typical activities
EVENT_TEMPLATES = [
    # Meetings
    ("Meeting with {person}", "Conference room {location}", "Discuss {topic}"),
    ("Team sync with {person}", "Office", "Project update"),
    ("1-on-1 with {person}", "Zoom", "Performance review"),
    ("Client call with {person}", "Virtual", "Product demo"),
    
    # Classes/Courses
    ("{course} lecture", "Room {location}", "Chapter {topic}"),
    ("{course} tutorial", "Lab {location}", "Assignment help"),
    ("{course} seminar", "Building {location}", "Guest speaker on {topic}"),
    ("Workshop on {topic}", "Room {location}", "Hands-on training"),
    
    # Personal events
    ("Gym session", "Fitness center", "Cardio and weights"),
    ("Yoga class", "Studio {location}", "Beginner session"),
    ("Coffee with {person}", "Cafe {location}", "Catch up"),
    ("Lunch with {person}", "Restaurant {location}", "Networking"),
    ("Dinner with {person}", "Restaurant {location}", "Celebration"),
    
    # Work activities
    ("Code review session", "Virtual", "PR discussion"),
    ("Design review", "Conference room {location}", "UI mockups"),
    ("Sprint planning", "Conference room {location}", "Next sprint goals"),
    ("Standup meeting", "Office", "Daily sync"),
]

# Replacement tokens
PERSONS = ["Alice", "Bob", "Charlie", "David", "Emma", "Frank", "Grace", "Henry", "Iris", "Jack"]
COURSES = ["COMP 2012", "ELEC 2100", "MATH 2421", "PHYS 1112", "CHEM 1020", "ENGG 1100", "COMP 3111", "COMP 4901"]
TOPICS = ["AI", "databases", "algorithms", "networking", "security", "cloud computing", "web dev", "mobile dev"]
LOCATIONS = ["101", "202", "A", "B", "3", "Downtown", "Central"]

# Time contexts
TIME_CONTEXTS = [
    "tomorrow",
    "next Monday",
    "next Tuesday",
    "next Wednesday",
    "next Thursday",
    "next Friday",
    "this Friday",
    "next week",
]

# Recurrence patterns
RECURRENCE_PATTERNS = [
    ("every Monday", "Weekly"),
    ("every Tuesday", "Weekly"),
    ("every Wednesday", "Weekly"),
    ("every Thursday", "Weekly"),
    ("every Friday", "Weekly"),
    ("each Monday", "Weekly"),
    ("each Tuesday", "Weekly"),
    ("Mondays", "Weekly"),
    ("Tuesdays", "Weekly"),
    ("Wednesdays", "Weekly"),
    ("Thursdays", "Weekly"),
    ("Fridays", "Weekly"),
    ("daily", "Daily"),
    ("every day", "Daily"),
]


def generate_examples(num_examples=200):
    """Generate training examples with time ranges."""
    examples = []
    
    for i in range(num_examples):
        # Choose a random template and time range
        action, location_template, notes = random.choice(EVENT_TEMPLATES)
        start_time, end_time, duration = random.choice(TIME_RANGES)
        
        # Fill in placeholders
        if "{person}" in action:
            action = action.replace("{person}", random.choice(PERSONS))
        if "{course}" in action:
            action = action.replace("{course}", random.choice(COURSES))
        if "{topic}" in action:
            action = action.replace("{topic}", random.choice(TOPICS))
        
        if "{location}" in location_template:
            location_template = location_template.replace("{location}", random.choice(LOCATIONS))
        if "{topic}" in notes:
            notes = notes.replace("{topic}", random.choice(TOPICS))
        
        # Decide: recurring or one-time?
        is_recurring = random.random() < 0.4  # 40% recurring
        
        if is_recurring:
            # Add recurrence pattern
            recurrence_pattern, recurrence_type = random.choice(RECURRENCE_PATTERNS)
            
            # Build input text with time range
            input_text = f"{action} {recurrence_pattern} {start_time}-{end_time}"
            if random.random() < 0.5:
                input_text += f" at {location_template}"
            
            # Build expected output (preprocessed input: time range → duration)
            # Preprocessing converts "10am-11am" to "10am for 1 hour"
            preprocessed_input = f"{action} {recurrence_pattern} {start_time} for {duration}"
            if location_template and location_template not in preprocessed_input:
                preprocessed_input += f" at {location_template}"
            
            # Expected model output (as dict, NOT string)
            target_output = {
                "action": action,
                "date": None,
                "time": start_time,
                "attendees": None,
                "location": location_template,
                "duration": duration,
                "recurrence": recurrence_type,
                "notes": notes
            }
        else:
            # One-time event
            time_context = random.choice(TIME_CONTEXTS)
            
            # Resolve the date for expected output
            now = datetime.now()
            if time_context == "tomorrow":
                date_str = (now + timedelta(days=1)).strftime("%d/%m/%Y")
            elif time_context == "next Monday":
                days_ahead = (0 - now.weekday() + 7) % 7
                if days_ahead == 0:
                    days_ahead = 7
                date_str = (now + timedelta(days=days_ahead)).strftime("%d/%m/%Y")
            elif time_context == "next Tuesday":
                days_ahead = (1 - now.weekday() + 7) % 7
                if days_ahead == 0:
                    days_ahead = 7
                date_str = (now + timedelta(days=days_ahead)).strftime("%d/%m/%Y")
            elif time_context == "next Wednesday":
                days_ahead = (2 - now.weekday() + 7) % 7
                if days_ahead == 0:
                    days_ahead = 7
                date_str = (now + timedelta(days=days_ahead)).strftime("%d/%m/%Y")
            elif time_context == "next Thursday":
                days_ahead = (3 - now.weekday() + 7) % 7
                if days_ahead == 0:
                    days_ahead = 7
                date_str = (now + timedelta(days=days_ahead)).strftime("%d/%m/%Y")
            elif time_context == "next Friday":
                days_ahead = (4 - now.weekday() + 7) % 7
                if days_ahead == 0:
                    days_ahead = 7
                date_str = (now + timedelta(days=days_ahead)).strftime("%d/%m/%Y")
            elif time_context == "this Friday":
                days_ahead = (4 - now.weekday()) % 7
                date_str = (now + timedelta(days=days_ahead)).strftime("%d/%m/%Y")
            elif time_context == "next week":
                date_str = (now + timedelta(weeks=1)).strftime("%d/%m/%Y")
            else:
                date_str = now.strftime("%d/%m/%Y")
            
            # Build input text with time range
            input_text = f"{action} {time_context} {start_time}-{end_time}"
            if random.random() < 0.5 and location_template != "Virtual" and location_template != "Zoom":
                input_text += f" at {location_template}"
            
            # Expected output (as dict, NOT string)
            target_output = {
                "action": action,
                "date": date_str,
                "time": start_time,
                "attendees": None,
                "location": location_template,
                "duration": duration,
                "recurrence": "none",
                "notes": notes
            }
        
        examples.append({
            "event_text": input_text,
            "output": target_output
        })
    
    return examples


def main():
    """Generate and save time range examples."""
    print("Generating time range training examples...")
    
    examples = generate_examples(num_examples=200)
    
    # Save to file
    output_file = "data/time_range_examples.jsonl"
    with open(output_file, 'w', encoding='utf-8') as f:
        for example in examples:
            f.write(json.dumps(example, ensure_ascii=False) + '\n')
    
    print(f"✅ Generated {len(examples)} examples")
    print(f"   Saved to: {output_file}")
    
    # Show sample
    print("\nSample examples:")
    print("=" * 80)
    for i in range(min(5, len(examples))):
        print(f"Example {i+1}:")
        print(f"  Input:  {examples[i]['event_text']}")
        print(f"  Output: {json.dumps(examples[i]['output'], ensure_ascii=False)}")
        print()


if __name__ == '__main__':
    main()

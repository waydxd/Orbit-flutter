"""
Generate diverse recurrence training examples

This script generates synthetic training data for recurring events with varied
phrasing and patterns to improve model performance on recurrence detection.

Usage:
    python generate_recurrence_examples.py [--count 1000]
"""

import json
from datetime import datetime, timedelta
import random
import argparse


# Recurrence patterns with varied phrasing
RECURRENCE_PATTERNS = {
    'Weekly': [
        'every {day}',
        'each {day}',
        'weekly on {day}',
        '{day}s',  # "Mondays", "Tuesdays"
        'on {day}s',
    ],
    'Daily': [
        'every day',
        'daily',
        'each day',
        'everyday',
        'every single day',
    ],
    'Monthly': [
        'every month',
        'monthly',
        'once a month',
        'each month',
        'every 1st of the month',
        'first Monday of every month',
    ],
    'Yearly': [
        'every year',
        'yearly',
        'annually',
        'each year',
        'once a year',
    ],
}

DAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']

ACTIVITIES = [
    'Yoga class', 'Team meeting', 'Gym session', 'Study group',
    'Dance lesson', 'Music practice', 'Tennis match', 'Swimming',
    'Book club', 'Meditation', 'Therapy session', 'Language class',
    'Coding bootcamp', 'Art class', 'Cooking class', 'Running group',
    'Piano lessons', 'Guitar practice', 'Volleyball', 'Basketball practice',
    'Chess club', 'Debate club', 'Photography walk', 'Hiking group',
    'Spin class', 'Pilates', 'Zumba', 'Crossfit',
    'Board game night', 'Movie night', 'Dinner club', 'Wine tasting',
]

LOCATIONS = [
    '', 'at the gym', 'at HKUST', 'online', 'in Room 301',
    'at the studio', 'at the park', 'at the community center',
    'on Zoom', 'via Teams', 'at the office', 'in the cafeteria',
    'at Starbucks', 'at the library', 'in LSK Building',
]

DURATIONS = ['30 minutes', '45 minutes', '1 hour', '1.5 hours', '2 hours', '']


def generate_weekly_examples(count=500):
    """Generate weekly recurrence examples."""
    examples = []
    
    for _ in range(count):
        activity = random.choice(ACTIVITIES)
        day = random.choice(DAYS)
        pattern_template = random.choice(RECURRENCE_PATTERNS['Weekly'])
        pattern = pattern_template.format(day=day)
        
        # Generate time
        hour = random.randint(8, 20)
        minute = random.choice([0, 15, 30, 45])
        am_pm = "AM" if hour < 12 else "PM"
        display_hour = hour if hour <= 12 else hour - 12
        if display_hour == 0:
            display_hour = 12
        time_display = f"{display_hour}:{minute:02d} {am_pm}"
        
        # Random additions
        location = random.choice(LOCATIONS)
        duration = random.choice(DURATIONS)
        
        # Build text with varied structure
        text_parts = [activity, pattern]
        
        # Vary sentence structure
        if random.random() > 0.3:
            text_parts.append(f"at {time_display}")
        if location:
            text_parts.append(location)
        if duration:
            text_parts.append(f"for {duration}")
        
        event_text = ' '.join(text_parts)
        
        # Calculate a sample date (next occurrence of that day)
        today = datetime.now()
        days_ahead = (DAYS.index(day) - today.weekday()) % 7
        if days_ahead == 0:
            days_ahead = 7
        next_date = today + timedelta(days=days_ahead)
        
        # Output
        output = {
            "action": activity,
            "date": next_date.strftime("%d/%m/%Y"),
            "time": time_display,
            "attendees": None,
            "location": location.replace('at ', '').replace('on ', '').replace('via ', '') if location else None,
            "duration": duration if duration else None,
            "recurrence": "Weekly",
            "notes": None
        }
        
        examples.append({
            "event_text": event_text,
            "output": output
        })
    
    return examples


def generate_daily_examples(count=200):
    """Generate daily recurrence examples."""
    examples = []
    
    for _ in range(count):
        activity = random.choice(ACTIVITIES)
        pattern = random.choice(RECURRENCE_PATTERNS['Daily'])
        
        # Generate time
        hour = random.randint(6, 22)
        minute = random.choice([0, 15, 30, 45])
        am_pm = "AM" if hour < 12 else "PM"
        display_hour = hour if hour <= 12 else hour - 12
        if display_hour == 0:
            display_hour = 12
        time_display = f"{display_hour}:{minute:02d} {am_pm}"
        
        location = random.choice(LOCATIONS)
        duration = random.choice(DURATIONS)
        
        # Build text
        text_parts = [activity, pattern]
        if random.random() > 0.3:
            text_parts.append(f"at {time_display}")
        if location:
            text_parts.append(location)
        if duration:
            text_parts.append(f"for {duration}")
        
        event_text = ' '.join(text_parts)
        
        output = {
            "action": activity,
            "date": datetime.now().strftime("%d/%m/%Y"),
            "time": time_display,
            "attendees": None,
            "location": location.replace('at ', '').replace('on ', '').replace('via ', '') if location else None,
            "duration": duration if duration else None,
            "recurrence": "Daily",
            "notes": None
        }
        
        examples.append({
            "event_text": event_text,
            "output": output
        })
    
    return examples


def generate_monthly_examples(count=150):
    """Generate monthly recurrence examples."""
    examples = []
    
    for _ in range(count):
        activity = random.choice(ACTIVITIES)
        pattern = random.choice(RECURRENCE_PATTERNS['Monthly'])
        
        hour = random.randint(9, 19)
        minute = random.choice([0, 15, 30, 45])
        am_pm = "AM" if hour < 12 else "PM"
        display_hour = hour if hour <= 12 else hour - 12
        if display_hour == 0:
            display_hour = 12
        time_display = f"{display_hour}:{minute:02d} {am_pm}"
        
        location = random.choice(LOCATIONS)
        duration = random.choice(DURATIONS)
        
        text_parts = [activity, pattern]
        if random.random() > 0.3:
            text_parts.append(f"at {time_display}")
        if location:
            text_parts.append(location)
        if duration:
            text_parts.append(f"for {duration}")
        
        event_text = ' '.join(text_parts)
        
        output = {
            "action": activity,
            "date": datetime.now().strftime("%d/%m/%Y"),
            "time": time_display,
            "attendees": None,
            "location": location.replace('at ', '').replace('on ', '').replace('via ', '') if location else None,
            "duration": duration if duration else None,
            "recurrence": "Monthly",
            "notes": None
        }
        
        examples.append({
            "event_text": event_text,
            "output": output
        })
    
    return examples


def generate_yearly_examples(count=150):
    """Generate yearly recurrence examples."""
    examples = []
    
    for _ in range(count):
        activity = random.choice(ACTIVITIES)
        pattern = random.choice(RECURRENCE_PATTERNS['Yearly'])
        
        hour = random.randint(10, 18)
        minute = random.choice([0, 30])
        am_pm = "AM" if hour < 12 else "PM"
        display_hour = hour if hour <= 12 else hour - 12
        if display_hour == 0:
            display_hour = 12
        time_display = f"{display_hour}:{minute:02d} {am_pm}"
        
        location = random.choice(LOCATIONS)
        duration = random.choice(DURATIONS)
        
        text_parts = [activity, pattern]
        if random.random() > 0.3:
            text_parts.append(f"at {time_display}")
        if location:
            text_parts.append(location)
        if duration:
            text_parts.append(f"for {duration}")
        
        event_text = ' '.join(text_parts)
        
        output = {
            "action": activity,
            "date": datetime.now().strftime("%d/%m/%Y"),
            "time": time_display,
            "attendees": None,
            "location": location.replace('at ', '').replace('on ', '').replace('via ', '') if location else None,
            "duration": duration if duration else None,
            "recurrence": "Yearly",
            "notes": None
        }
        
        examples.append({
            "event_text": event_text,
            "output": output
        })
    
    return examples


def generate_all_recurrence_examples(total_count=1000):
    """Generate comprehensive recurrence dataset."""
    print("=" * 70)
    print("GENERATING RECURRENCE EXAMPLES")
    print("=" * 70)
    print()
    
    # Distribute examples across types
    weekly_count = int(total_count * 0.50)  # 50% weekly
    daily_count = int(total_count * 0.20)   # 20% daily
    monthly_count = int(total_count * 0.20) # 20% monthly
    yearly_count = int(total_count * 0.10)  # 10% yearly
    
    print(f"Generating examples:")
    print(f"  Weekly:  {weekly_count}")
    print(f"  Daily:   {daily_count}")
    print(f"  Monthly: {monthly_count}")
    print(f"  Yearly:  {yearly_count}")
    print(f"  Total:   {total_count}")
    print()
    
    examples = []
    
    print("Generating weekly examples...")
    examples.extend(generate_weekly_examples(weekly_count))
    
    print("Generating daily examples...")
    examples.extend(generate_daily_examples(daily_count))
    
    print("Generating monthly examples...")
    examples.extend(generate_monthly_examples(monthly_count))
    
    print("Generating yearly examples...")
    examples.extend(generate_yearly_examples(yearly_count))
    
    # Shuffle to mix types
    random.shuffle(examples)
    
    # Save
    output_file = 'data/recurrence_augmented.jsonl'
    with open(output_file, 'w', encoding='utf-8') as f:
        for ex in examples:
            f.write(json.dumps(ex, ensure_ascii=False) + '\n')
    
    print()
    print(f"✅ Generated {len(examples)} recurrence examples")
    print(f"✅ Saved to {output_file}")
    print()
    
    # Show samples
    print("Sample examples:")
    print("-" * 70)
    for i, ex in enumerate(examples[:5], 1):
        print(f"{i}. {ex['event_text']}")
        print(f"   → Recurrence: {ex['output']['recurrence']}")
    
    print()
    print("=" * 70)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Generate recurrence training examples')
    parser.add_argument('--count', type=int, default=1000,
                       help='Total number of examples to generate (default: 1000)')
    
    args = parser.parse_args()
    
    generate_all_recurrence_examples(args.count)

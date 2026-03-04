"""
Generate synthetic calendar event data in event_text_mapping.jsonl format.
Creates diverse, realistic event examples for training.
"""

import json
import random
from datetime import datetime, timedelta


# Configuration
SEED = 42
TARGET_COUNT = 1620  # To reach ~2500 total with existing 882

random.seed(SEED)


# Data pools
ACTIONS = [
    "Meeting", "Team meeting", "One-on-one", "Standup", "Sync", "Check-in",
    "Call", "Video call", "Conference call", "Quick call",
    "Presentation", "Demo", "Workshop", "Seminar", "Training", "Webinar",
    "Lunch", "Dinner", "Breakfast", "Coffee", "Coffee chat", "Brunch",
    "Interview", "Phone interview",
    "Brainstorm", "Brainstorming session", "Planning session", "Strategy session",
    "Review", "Code review", "Design review", "Project review", "Performance review",
    "Appointment", "Doctor appointment", "Dentist appointment",
    "Workout", "Gym session", "Yoga", "Running", "Swimming",
    "Study session", "Tutorial", "Lecture", "Lab session", "Office hours",
    "Shopping", "Grocery shopping",
    "Party", "Birthday party", "Celebration",
    "Event", "Concert", "Movie", "Show",
]

HKUST_LOCATIONS = [
    "HKUST Room 4504", "HKUST LT-A", "HKUST LT-B", "HKUST LT-C", "HKUST LT-D",
    "HKUST Lecture Theatre G", "HKUST Room 2465", "HKUST Room 4472", "HKUST Room 4620",
    "HKUST Library", "HKUST Library G/F", "HKUST Learning Commons",
    "HKUST Atrium", "HKUST Piazza", "HKUST Canteen",
    "HKUST Computer Lab", "HKUST Computer Lab 4", "HKUST Physics Lab",
    "HKUST Engineering Building Room 2302", "HKUST CYT Building Room 506", "HKUST CYT 707",
    "HKUST LSK Building Room 1001", "HKUST LSK 3042",
    "HKUST Sports Hall", "HKUST gym", "HKUST pool", "HKUST outdoor court",
    "HKUST waterfront", "HKUST Student Center Room 201",
]

HK_LOCATIONS = [
    "Central", "Causeway Bay", "Tsim Sha Tsui", "Mong Kok", "Admiralty",
    "Victoria Harbour", "IFC Tower", "Harbour City", "Times Square",
    "Temple Street Night Market", "Ladies Market",
    "Dragon's Back trail", "Victoria Peak",
    "Starbucks", "Pacific Coffee",
]

GENERIC_LOCATIONS = [
    "Office", "Home", "Conference Room A", "Meeting Room", "Reception",
    "Zoom", "Teams", "Google Meet", "Skype", "Webex",
    "Café", "Restaurant", "Park", "Library", "Gym",
]

COURSE_CODES = [
    "COMP 2012", "COMP 3711", "COMP 4211", "COMP 3511", "COMP 2611", "COMP 4901",
    "MATH 1013", "MATH 2023", "MATH 2421", "MATH 2121",
    "ELEC 2100", "PHYS 1112", "CHEM 1010",
    "HUMA 1903", "HUMA 1000", "LANG 1002", "LANG 1003",
    "ISOM 2500", "MGMT 2010", "CIVL 1100",
]

NAMES = [
    "John", "Sarah", "Mike", "Emma", "David", "Lisa", "Tom", "Anna",
    "Chris", "Amy", "Alex", "Kate", "Matt", "Jenny", "Ryan", "Lucy",
    "Ben", "Grace", "Leo", "Zoe", "Tim", "Ruby", "Nick", "Ella",
    "Paul", "Ivy", "Jake", "Lana", "Max", "Pam", "Joe", "Mia",
    "Professor", "TA", "Manager", "team", "classmates", "colleagues",
]

DURATIONS = [
    "30 minutes", "45 minutes", "1 hour", "1.5 hours", "2 hours", "3 hours",
    "30 mins", "45 mins", "1 hr", "2 hrs", "90 minutes",
]

RECURRENCE_PATTERNS = [
    None, None, None,  # Most events are non-recurring
    "Daily", "Weekly", "Monthly", "Annual",
]

RECURRENCE_TEXTS = [
    "every day", "every Monday", "every Tuesday", "every Wednesday", "every Thursday", "every Friday",
    "every Saturday", "every Sunday", "every weekday",
    "every Monday and Wednesday", "every Tuesday and Thursday",
    "once a week", "once a month", "once a year",
]


def generate_date():
    """Generate a random date between Jan 2024 and Dec 2026."""
    start = datetime(2024, 1, 1)
    end = datetime(2026, 12, 31)
    delta = end - start
    random_days = random.randint(0, delta.days)
    date = start + timedelta(days=random_days)
    return date.strftime("%d/%m/%Y")


def generate_time():
    """Generate a random time."""
    hour = random.randint(7, 21)  # 7am to 9pm
    minute = random.choice([0, 15, 30, 45])
    period = "AM" if hour < 12 else "PM"
    display_hour = hour if hour <= 12 else hour - 12
    if display_hour == 0:
        display_hour = 12
    return f"{display_hour:02d}:{minute:02d} {period}"


def generate_event_with_recurrence():
    """Generate a recurring event."""
    action = random.choice(ACTIONS)
    recurrence_text = random.choice(RECURRENCE_TEXTS)
    time = generate_time()
    date = generate_date()
    
    location_type = random.choice(["hkust", "hk", "generic", "online"])
    if location_type == "hkust":
        location = random.choice(HKUST_LOCATIONS)
    elif location_type == "hk":
        location = random.choice(HK_LOCATIONS)
    elif location_type == "online":
        location = random.choice(["Zoom", "Teams", "Google Meet", "Skype", "Webex"])
    else:
        location = random.choice(GENERIC_LOCATIONS)
    
    duration = random.choice(DURATIONS + [None])
    attendees = [random.choice(NAMES)] if random.random() > 0.5 else None
    
    # Map recurrence_text to standard recurrence value
    recurrence = None
    if "day" in recurrence_text and "week" not in recurrence_text:
        recurrence = "Daily"
    elif "Monday" in recurrence_text or "Tuesday" in recurrence_text or "week" in recurrence_text:
        recurrence = "Weekly"
    elif "month" in recurrence_text:
        recurrence = "Monthly"
    elif "year" in recurrence_text:
        recurrence = "Annual"
    
    # Build event text
    duration_text = f" for {duration}" if duration else ""
    attendees_text = f" with {attendees[0]}" if attendees else ""
    
    event_text = f"{action} {recurrence_text} at {time} at {location}{attendees_text}{duration_text}"
    
    return {
        "event_text": event_text,
        "output": {
            "action": action,
            "date": date,
            "time": time,
            "attendees": attendees,
            "location": location,
            "duration": duration,
            "recurrence": recurrence,
            "notes": None
        }
    }


def generate_course_event():
    """Generate HKUST course event."""
    course = random.choice(COURSE_CODES)
    event_type = random.choice(["lecture", "tutorial", "lab", "exam", "midterm", "office hours"])
    date = generate_date()
    time = generate_time()
    location = random.choice(HKUST_LOCATIONS)
    
    recurrence_text = random.choice([None, "every Monday", "every Tuesday", "every Wednesday", 
                                      "every Thursday", "every Friday", 
                                      "every Monday and Wednesday", "every Tuesday and Thursday"])
    recurrence = "Weekly" if recurrence_text else None
    
    duration = random.choice(["1 hour", "1.5 hours", "2 hours", "3 hours"])
    attendees = ["TA"] if event_type in ["tutorial", "office hours"] and random.random() > 0.6 else None
    
    if recurrence_text:
        event_text = f"{course} {event_type} {recurrence_text} from {time} at {location}"
    else:
        event_text = f"{course} {event_type} on {date.split('/')[0]}th, {get_month_name(date)} {date.split('/')[2]} from {time} at {location}"
    
    if duration:
        event_text += f" for {duration}"
    if attendees:
        event_text += f" with {attendees[0]}"
    
    return {
        "event_text": event_text,
        "output": {
            "action": f"{course} {event_type}",
            "date": date,
            "time": time,
            "attendees": attendees,
            "location": location,
            "duration": duration,
            "recurrence": recurrence,
            "notes": None
        }
    }


def generate_hk_event():
    """Generate Hong Kong-specific event."""
    actions = [
        "Dim sum", "Yum cha", "Shopping", "Hiking", "Visit", "Ferry ride",
        "Movie", "Dinner", "Lunch", "Brunch", "Afternoon tea",
        "Tram ride", "Museum visit", "Concert", "Show"
    ]
    
    action = random.choice(actions)
    date = generate_date()
    time = generate_time()
    location = random.choice(HK_LOCATIONS + HKUST_LOCATIONS[:5])  # Mix HK and some HKUST
    duration = random.choice(DURATIONS + [None, None])
    attendees = [random.choice(NAMES)] if random.random() > 0.4 else None
    
    attendees_text = f" with {attendees[0]}" if attendees else ""
    duration_text = f" for {duration}" if duration else ""
    
    event_text = f"{action} at {location} on {format_date_natural(date)} at {time}{attendees_text}{duration_text}"
    
    return {
        "event_text": event_text,
        "output": {
            "action": action,
            "date": date,
            "time": time,
            "attendees": attendees,
            "location": location,
            "duration": duration,
            "recurrence": None,
            "notes": None
        }
    }


def generate_generic_event():
    """Generate generic calendar event."""
    action = random.choice(ACTIONS)
    date = generate_date()
    time = generate_time()
    location = random.choice(GENERIC_LOCATIONS) if random.random() > 0.3 else None
    duration = random.choice(DURATIONS) if random.random() > 0.2 else None
    attendees = [random.choice(NAMES), random.choice(NAMES)] if random.random() > 0.7 else \
                [random.choice(NAMES)] if random.random() > 0.5 else None
    
    # Various text formats
    format_choice = random.randint(1, 4)
    
    if format_choice == 1:
        # "Action on Date at Time at Location"
        location_text = f" at {location}" if location else ""
        duration_text = f" for {duration}" if duration else ""
        attendees_text = f" with {', '.join(attendees)}" if attendees else ""
        event_text = f"{action} on {format_date_natural(date)} at {time}{location_text}{attendees_text}{duration_text}"
    
    elif format_choice == 2:
        # "Action Date Time Location Duration"
        parts = [action, format_date_short(date), time]
        if attendees:
            parts.append(f"with {', '.join(attendees)}")
        if location:
            parts.append(location)
        if duration:
            parts.append(duration)
        event_text = " ".join(parts)
    
    elif format_choice == 3:
        # "Time Action Date Location"
        location_text = f" at {location}" if location else ""
        attendees_text = f" with {', '.join(attendees)}" if attendees else ""
        duration_text = f" for {duration}" if duration else ""
        event_text = f"{time} {action} {format_date_short(date)}{location_text}{attendees_text}{duration_text}"
    
    else:
        # "Action at Location on Date at Time"
        location_text = f" at {location}" if location else ""
        attendees_text = f" with {', '.join(attendees)}" if attendees else ""
        duration_text = f" lasting {duration}" if duration else ""
        event_text = f"{action}{location_text} on {format_date_natural(date)} at {time}{attendees_text}{duration_text}"
    
    return {
        "event_text": event_text,
        "output": {
            "action": action,
            "date": date,
            "time": time,
            "attendees": attendees,
            "location": location,
            "duration": duration,
            "recurrence": None,
            "notes": None
        }
    }


def format_date_natural(date_str):
    """Convert DD/MM/YYYY to natural format like '15th, Jan 2025'."""
    day, month, year = date_str.split('/')
    months = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    suffix = "th"
    if day.endswith('1') and day != '11':
        suffix = "st"
    elif day.endswith('2') and day != '12':
        suffix = "nd"
    elif day.endswith('3') and day != '13':
        suffix = "rd"
    
    return f"{int(day)}{suffix}, {months[int(month)]} {year}"


def format_date_short(date_str):
    """Convert DD/MM/YYYY to short format like '15th, Jan 2025'."""
    return format_date_natural(date_str)


def get_month_name(date_str):
    """Get month name from DD/MM/YYYY."""
    month_num = int(date_str.split('/')[1])
    months = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    return months[month_num]


def generate_all_events(output_file, count=TARGET_COUNT):
    """Generate all synthetic events."""
    print(f"Generating {count} calendar events...")
    
    events = []
    
    # Distribution: 30% recurring, 25% HKUST courses, 20% HK-specific, 25% generic
    for i in range(count):
        rand = random.random()
        
        if rand < 0.30:
            # Recurring events
            event = generate_event_with_recurrence()
        elif rand < 0.55:
            # HKUST course events
            event = generate_course_event()
        elif rand < 0.75:
            # Hong Kong events
            event = generate_hk_event()
        else:
            # Generic events
            event = generate_generic_event()
        
        events.append(event)
        
        if (i + 1) % 100 == 0:
            print(f"  Generated {i + 1}/{count} events...")
    
    # Write to file
    with open(output_file, 'w', encoding='utf-8') as f:
        for event in events:
            f.write(json.dumps(event, ensure_ascii=False) + '\n')
    
    print(f"\n✓ Generated {len(events)} events")
    print(f"  Output: {output_file}")
    
    return events


if __name__ == "__main__":
    import sys
    
    output_file = sys.argv[1] if len(sys.argv) > 1 else "data/generated_events.jsonl"
    count = int(sys.argv[2]) if len(sys.argv) > 2 else TARGET_COUNT
    
    print("="*60)
    print("Calendar Event Generator")
    print("="*60)
    
    events = generate_all_events(output_file, count)
    
    # Show sample
    print("\nSample generated events:")
    for i in range(min(5, len(events))):
        print(f"\n[{i+1}] {events[i]['event_text'][:80]}...")
        print(f"    Action: {events[i]['output']['action']}")
        print(f"    Date: {events[i]['output']['date']}, Time: {events[i]['output']['time']}")
        if events[i]['output']['recurrence']:
            print(f"    Recurrence: {events[i]['output']['recurrence']}")
    
    print(f"\n✓ Done! Generated {len(events)} events in {output_file}")

# Calendar Event Dataset Information

## Overview

This document describes the calendar event datasets used for training the FLAN-T5 event parser model.

## Files

### 1. `event_text_mapping.jsonl` (882 examples)
Original hand-curated dataset with diverse calendar events.

**Format:**
```json
{
  "event_text": "Meeting with John tomorrow at 3pm for 1 hour",
  "output": {
    "action": "Meeting",
    "date": "15/01/2025",
    "time": "03:00 PM",
    "attendees": ["John"],
    "location": null,
    "duration": "1 hour",
    "recurrence": null,
    "notes": null
  }
}
```

### 2. `generated_events.jsonl` (1,620 examples)
Synthetically generated calendar events with diverse patterns.

**Generation Script:** `utils/generate_calendar_events.py`

**Distribution:**
- 30% Recurring events (daily, weekly, monthly, annual patterns)
- 25% HKUST course events (COMP, MATH, ELEC, HUMA courses)
- 20% Hong Kong-specific events (dim sum, MTR, Victoria Harbour, etc.)
- 25% Generic events (meetings, appointments, workouts, etc.)

**Features:**
- Diverse date/time formats
- Multiple recurrence patterns
- HKUST locations and course codes
- Hong Kong cultural activities
- Varied durations and attendees

### 3. `event_text_mapping_expanded.jsonl` (2,502 examples)
Combined dataset = `event_text_mapping.jsonl` + `generated_events.jsonl`

**This is the primary training dataset.**

### 4. `event_training_data.jsonl` (2,502 examples)
T5-formatted version of `event_text_mapping_expanded.jsonl` for model training.

**Format:**
```json
{
  "input": "parse event: Meeting with John tomorrow at 3pm for 1 hour",
  "output": "{\"action\": \"Meeting\", \"date\": \"15/01/2025\", \"time\": \"03:00 PM\", \"attendees\": [\"John\"], \"location\": null, \"duration\": \"1 hour\", \"recurrence\": null, \"notes\": null}"
}
```

## Dataset Statistics

| Dataset | Examples | Type |
|---------|----------|------|
| `event_text_mapping.jsonl` | 882 | Original |
| `generated_events.jsonl` | 1,620 | Generated |
| `event_text_mapping_expanded.jsonl` | 2,502 | Combined |
| `event_training_data.jsonl` | 2,502 | T5 Format |

## Generating More Data

To generate additional synthetic events:

```bash
# Generate 1000 more events
python utils/generate_calendar_events.py data/more_events.jsonl 1000

# Combine with existing data
cat data/event_text_mapping_expanded.jsonl data/more_events.jsonl > data/event_text_mapping_final.jsonl

# Regenerate T5 training data
# (Update data_preprocessing.py to use new file)
python utils/data_preprocessing.py
```

## Training with Expanded Dataset

The expanded dataset is now the default for training:

```bash
# In Colab or locally
python train_event_parser.py
```

The training script will automatically use `event_training_data.jsonl` (2,502 examples).

## Event Categories Included

### Time Patterns
- Specific dates and times
- Relative dates (tomorrow, next Monday, etc.)
- Recurring events (daily, weekly, monthly, annual)
- Time ranges (9am-10am, from 3pm)

### Locations
- **HKUST**: Lecture theatres (LT-A, LT-B), rooms (4504, 2465), facilities (library, gym)
- **Hong Kong**: Central, Causeway Bay, TST, Victoria Harbour, IFC, etc.
- **Generic**: Office, home, Zoom, Teams, café, restaurant
- **Online**: Zoom, Teams, Google Meet, Skype, Webex

### Event Types
- Meetings (team, one-on-one, standup, sync)
- Academic (lecture, tutorial, lab, exam, office hours)
- Social (lunch, dinner, coffee, party, celebration)
- Health (doctor, dentist, gym, yoga, swimming)
- Entertainment (movie, concert, show)
- Cultural (dim sum, museum, hiking)

### Recurrence Patterns
- Daily (every day, weekdays)
- Weekly (specific days: Mon/Tue/Wed/Thu/Fri/Sat/Sun)
- Multiple days per week (Mon & Wed, Tue & Thu)
- Monthly (once a month)
- Annual (once a year)

## Data Quality

All generated events:
- ✅ Follow exact JSON schema from original dataset
- ✅ Use proper date format (DD/MM/YYYY)
- ✅ Use proper time format (HH:MM AM/PM)
- ✅ Include realistic HKUST course codes
- ✅ Include Hong Kong locations and cultural activities
- ✅ Have diverse natural language phrasings
- ✅ Include optional fields (attendees, location, duration, recurrence)

## Next Steps

1. **Train model** with expanded dataset (2,502 examples)
2. **Evaluate** model performance on validation set
3. **Generate more** examples if needed for specific categories
4. **Fine-tune** generation script based on model weaknesses

---

Generated: 2026-01-29
Script: `utils/generate_calendar_events.py`

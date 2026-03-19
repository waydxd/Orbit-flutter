"""
FastAPI server for event/task parsing.

- Events: fine-tuned FLAN-T5-small model (pipe-delimited output → JSON)
- Tasks:  rule-based parser (regex + date resolver, no model required)

Usage:
  python server.py

Then test with:
  curl -X POST http://localhost:5001/parse/event \
    -H "Content-Type: application/json" \
    -d '{"text": "Meeting with John tomorrow at 3pm for 1 hour"}'
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
import json
import os
import re
from datetime import datetime, timedelta
from utils.date_resolver import resolve_relative_dates, has_recurrence_pattern, get_next_weekday

app = FastAPI(title="Orbit NLP Parser", version="1.0.0")

# Enable CORS for Flutter web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, restrict this
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global models and tokenizers
event_model = None
event_tokenizer = None
task_model = None
task_tokenizer = None

EVENT_MODEL_PATH = "./models/event-parser"
TASK_MODEL_PATH = "./models/task-parser"


class ParseInput(BaseModel):
    text: str


class EventOutput(BaseModel):
    title: str
    start_time: str  # ISO 8601 format
    end_time: str    # ISO 8601 format
    location: str
    description: str
    recurrence: str  # "Daily", "Weekly", "Monthly", or "" for one-time events


class TaskOutput(BaseModel):
    title: str
    due_date: str    # ISO 8601 format
    priority: str    # low, medium, high
    description: str


# ============================================================
# Conversion functions: Original format -> Flutter format
# ============================================================

def parse_duration_to_minutes(duration_str: str) -> int:
    """Convert duration string to minutes."""
    if not duration_str:
        return 60  # Default 1 hour
    
    duration_str = duration_str.lower().replace('~', '').replace('about', '').strip()
    
    if 'hour' in duration_str or 'hr' in duration_str:
        try:
            numbers = re.findall(r'\d+\.?\d*', duration_str)
            if not numbers:
                return 60

            # Support both "2 hours" and "1 hour 30 minutes" style strings.
            hours = float(numbers[0])
            extra_minutes = 0

            # If minutes are also mentioned, treat the second number as minutes.
            if ('min' in duration_str or 'minute' in duration_str) and len(numbers) > 1:
                try:
                    extra_minutes = int(float(numbers[1]))
                except Exception:
                    extra_minutes = 0

            return int(hours * 60 + extra_minutes)
        except:
            return 60
    elif 'min' in duration_str:
        try:
            numbers = re.findall(r'\d+', duration_str)
            if numbers:
                return int(numbers[0])
        except:
            return 60
    return 60


def _parse_time_flexible(time_str: str) -> tuple:
    """
    Parse a time string in any common format and return (hour, minute).

    Handles: "03:00 PM", "3pm", "3:00PM", "3:00 pm", "15:00", "9:30 AM"
    Returns (hour, minute) in 24-hour integers, or None on failure.
    """
    if not time_str:
        return None
    s = time_str.strip()

    # Try formats in order of specificity
    for fmt in ('%I:%M %p', '%I:%M%p', '%I:%M %P', '%H:%M'):
        try:
            t = datetime.strptime(s, fmt)
            return (t.hour, t.minute)
        except ValueError:
            pass

    # Handle bare "3pm" / "3 PM" / "15" style
    m = re.match(r'^(\d{1,2})\s*(am|pm)$', s, re.IGNORECASE)
    if m:
        h = int(m.group(1))
        meridiem = m.group(2).lower()
        if meridiem == 'pm' and h != 12:
            h += 12
        elif meridiem == 'am' and h == 12:
            h = 0
        return (h, 0)

    return None


def extract_duration_from_text(text: str) -> str:
    """
    Best-effort extraction of a duration string from raw input text.

    Returns a normalised duration string that parse_duration_to_minutes()
    can understand, e.g. "2 hours", "90 minutes", "1 hour 30 minutes".
    Returns empty string if nothing is found.
    """
    if not text:
        return ""

    # 1) Explicit "for X hours/minutes" wording
    m = re.search(
        r'\bfor\s+(\d+)\s*(hour|hours|hr|hrs)\s*(\d+)?\s*(minute|minutes|min|mins)?',
        text,
        re.IGNORECASE,
    )
    if m:
        hours = int(m.group(1))
        minute_part = m.group(3)
        minutes = int(minute_part) if minute_part else 0

        if hours > 0 and minutes > 0:
            return f"{hours} hour{'s' if hours != 1 else ''} {minutes} minutes"
        elif hours > 0:
            return f"{hours} hour{'s' if hours != 1 else ''}"
        elif minutes > 0:
            return f"{minutes} minutes"

    # 2) Pure minutes: "for 90 minutes", "for 30 min"
    m = re.search(
        r'\bfor\s+(\d+)\s*(minute|minutes|min|mins)\b',
        text,
        re.IGNORECASE,
    )
    if m:
        minutes = int(m.group(1))
        return f"{minutes} minutes"

    # 3) Time ranges: "2pm-4pm", "14:00-15:30"
    # AM/PM form
    m = re.search(
        r'(\d{1,2}(?::\d{2})?\s*(?:am|pm))\s*-\s*(\d{1,2}(?::\d{2})?\s*(?:am|pm))',
        text,
        re.IGNORECASE,
    )
    if not m:
        # 24h form: "14:00-15:30"
        m = re.search(
            r'(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})',
            text,
        )

    if m:
        start_raw = m.group(1)
        end_raw = m.group(2)

        start_hm = _parse_time_flexible(start_raw)
        end_hm = _parse_time_flexible(end_raw)

        if start_hm and end_hm:
            start_minutes = start_hm[0] * 60 + start_hm[1]
            end_minutes = end_hm[0] * 60 + end_hm[1]

            # Handle overnight ranges like "11pm-1am"
            if end_minutes < start_minutes:
                end_minutes += 24 * 60

            duration_minutes = end_minutes - start_minutes
            hours = duration_minutes // 60
            minutes = duration_minutes % 60

            if hours > 0 and minutes > 0:
                return f"{hours} hour{'s' if hours != 1 else ''} {minutes} minutes"
            elif hours > 0:
                return f"{hours} hour{'s' if hours != 1 else ''}"
            elif minutes > 0:
                return f"{minutes} minutes"

    return ""


def convert_event_to_flutter(parsed_data: dict) -> EventOutput:
    """
    Convert model output (original format) to Flutter EventModel format.

    Date priority:
      1. _resolved_date / _resolved_time  — extracted from preprocessed text
         (these use the current date, so "tomorrow" becomes the correct date)
      2. model date / time fields          — fallback when preprocessing found nothing

    Original model format:
    {
        "action": "Meeting",
        "date": "12/11/2023",
        "time": "3pm",
        "attendees": ["Tina"],
        "location": "Google Meet",
        "duration": "1 hour",
        "recurrence": "weekly",
        "notes": "some notes"
    }
    """
    title = parsed_data.get('action', 'Untitled Event')

    # ── Resolve date ──────────────────────────────────────────────────────────
    # Prefer the preprocessed-resolved date; fall back to the model's own date.
    date_str = parsed_data.get('_resolved_date') or parsed_data.get('date') or ''
    time_str = parsed_data.get('_resolved_time') or parsed_data.get('time') or ''

    try:
        if date_str:
            # All date strings in this project are DD/MM/YYYY
            parts = date_str.split('/')
            day, month, year = int(parts[0]), int(parts[1]), int(parts[2])

            hm = _parse_time_flexible(time_str)
            if hm:
                start_time = datetime(year, month, day, hm[0], hm[1])
            else:
                start_time = datetime(year, month, day, 9, 0)  # default 9 AM
        else:
            start_time = datetime.now().replace(second=0, microsecond=0)
    except Exception as e:
        print(f"Error parsing date/time (date='{date_str}', time='{time_str}'): {e}")
        start_time = datetime.now().replace(second=0, microsecond=0)

    # ── Duration → end time ───────────────────────────────────────────────────
    duration_minutes = parse_duration_to_minutes(parsed_data.get('duration'))
    end_time = start_time + timedelta(minutes=duration_minutes)

    # ── Recurrence ────────────────────────────────────────────────────────────
    raw_recurrence = parsed_data.get('recurrence') or ''
    if raw_recurrence.lower() in ('none', 'null', ''):
        recurrence_out = ''
    else:
        # Normalise to the values the Flutter dropdown expects
        norm = raw_recurrence.strip().lower()
        if 'daily' in norm or 'every day' in norm:
            recurrence_out = 'Daily'
        elif 'weekly' in norm or 'every week' in norm:
            recurrence_out = 'Weekly'
        elif 'monthly' in norm or 'every month' in norm:
            recurrence_out = 'Monthly'
        else:
            recurrence_out = raw_recurrence.strip().capitalize()

    # ── Description (attendees + notes; recurrence is now its own field) ──────
    description_parts = []

    attendees = parsed_data.get('attendees')
    if attendees and isinstance(attendees, list):
        valid = [a for a in attendees if a and a.lower() not in ('none', 'null')]
        if valid:
            description_parts.append(f"With: {', '.join(valid)}")

    notes = parsed_data.get('notes')
    if notes and notes.lower() not in ('none', 'null', ''):
        description_parts.append(f"Notes: {notes}")

    description = '. '.join(description_parts)

    return EventOutput(
        title=title,
        start_time=start_time.isoformat(),
        end_time=end_time.isoformat(),
        location=parsed_data.get('location') or '',
        description=description,
        recurrence=recurrence_out,
    )


def convert_task_to_flutter(parsed_data: dict) -> TaskOutput:
    """
    Convert model output (original format) to Flutter TaskModel format.
    
    Original format:
    {
        "action": "Submit report",
        "date": "12/11/2023",
        "time": "5:00 PM",
        "priority": "high",
        "notes": "Include Q3 data"
    }
    """
    title = parsed_data.get('action', 'Untitled Task')
    
    # Parse date and time (prefer preprocessed resolved values)
    try:
        date_str = parsed_data.get('_resolved_date') or parsed_data.get('date') or ''
        time_str = parsed_data.get('_resolved_time') or parsed_data.get('time') or ''

        if date_str:
            parts = date_str.split('/')
            day, month, year = int(parts[0]), int(parts[1]), int(parts[2])

            hm = _parse_time_flexible(time_str)
            if hm:
                due_date = datetime(year, month, day, hm[0], hm[1])
            else:
                due_date = datetime(year, month, day, 23, 59)  # End of day
        else:
            due_date = datetime.now() + timedelta(days=1)  # Default tomorrow
    except Exception as e:
        print(f"Error parsing date/time: {e}")
        due_date = datetime.now() + timedelta(days=1)
    
    return TaskOutput(
        title=title,
        due_date=due_date.isoformat(),
        priority=parsed_data.get('priority', 'medium'),
        description=parsed_data.get('notes') or ''
    )


# ──────────────────────────────────────────────────────────────────────────────
# Rule-based task parser  (no model required)
# ──────────────────────────────────────────────────────────────────────────────

# Deadline-introducer phrases to strip from the title
_DEADLINE_PHRASES = re.compile(
    r'\b(by|before|due|until|at|no\s+later\s+than|deadline[:\s])\b',
    re.IGNORECASE,
)

# Time-of-day words that imply "today" (no explicit date) — map to today's date
_TODAY_TIMEOFDAY = re.compile(
    r'\b(tonight|today|this\s+morning|this\s+afternoon|this\s+evening|this\s+night)\b',
    re.IGNORECASE,
)

# Bare weekday names that were NOT resolved (still present as English words)
# → strip from title after date resolution
_BARE_WEEKDAY = re.compile(
    r'\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
    re.IGNORECASE,
)

# Residual words left after stripping date/time phrases
_RESIDUAL_WORDS = re.compile(
    r'\b(this|in|the)\b',
    re.IGNORECASE,
)

# Time-only expressions after the date has been resolved
_TIME_EXPR = re.compile(
    r'\b\d{1,2}:\d{2}\s*(?:AM|PM)|\b\d{1,2}\s*(?:am|pm)\b',
    re.IGNORECASE,
)

# Date in DD/MM/YYYY form (produced by resolve_relative_dates)
_DATE_EXPR = re.compile(r'\b(\d{2}/\d{2}/\d{4})\b')

# Priority keywords  →  normalised value
_PRIORITY_MAP = {
    'urgent': 'urgent',
    'asap': 'urgent',
    'high': 'high',
    'important': 'high',
    'medium': 'medium',
    'normal': 'medium',
    'low': 'low',
    'whenever': 'low',
}
_PRIORITY_RE = re.compile(
    r'\b(' + '|'.join(re.escape(k) for k in _PRIORITY_MAP) + r')\s*(priority)?\b',
    re.IGNORECASE,
)

# Noise words that appear after the task verb and should not be in the title
_NOISE_RE = re.compile(
    r'\b(priority|task|todo|to-do|reminder|remind me to)\b',
    re.IGNORECASE,
)


def parse_task_rule_based(text: str) -> TaskOutput:
    """
    Extract title + due_date + priority from natural language without a model.

    Strategy
    --------
    1. Detect and extract priority keywords (high / medium / low / urgent).
    2. Run resolve_relative_dates() to turn "tomorrow", "next Friday", "3pm"
       into concrete DD/MM/YYYY and time strings.
    3. Extract the resolved date and time using regex.
    4. Strip deadline phrases, resolved date, resolved time, and priority tokens
       from the original text to get the clean task title.
    5. Build TaskOutput.

    Examples
    --------
      "Submit report by tomorrow 5pm high priority"
        → title="Submit report", due_date=<tomorrow>T17:00, priority="high"

      "Call dentist next Monday"
        → title="Call dentist", due_date=<next Monday>T23:59, priority="medium"

      "Finish homework tonight"
        → title="Finish homework", due_date=<today>T23:59, priority="medium"
    """
    original = text.strip()

    # ── 1. Priority ────────────────────────────────────────────────────────────
    priority = 'medium'
    m = _PRIORITY_RE.search(original)
    if m:
        priority = _PRIORITY_MAP[m.group(1).lower()]

    # ── 2. Pre-detect "today"-class and bare-weekday words BEFORE resolving ───
    # "tonight", "today", "this morning/afternoon/evening" don't produce a date
    # literal via resolve_relative_dates (only times), so we capture them here.
    # Bare weekdays ("before Monday", "by Friday") are also not resolved unless
    # prefixed with next/this/last, so we catch them separately.
    today_match = _TODAY_TIMEOFDAY.search(original)
    weekday_match = _BARE_WEEKDAY.search(original)

    # ── 3. Resolve dates / times in the text ──────────────────────────────────
    resolved = resolve_relative_dates(original)

    # ── 4. Extract resolved date + time ───────────────────────────────────────
    date_match = _DATE_EXPR.search(resolved)
    time_match = _TIME_EXPR.search(resolved)

    resolved_date = date_match.group(1) if date_match else None
    resolved_time = time_match.group(0).strip() if time_match else None

    # Build due_date datetime
    _today_midnight = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    try:
        if resolved_date:
            # Explicit date found (e.g. "tomorrow", "next Monday", "in 3 days")
            parts = resolved_date.split('/')
            day, month, year = int(parts[0]), int(parts[1]), int(parts[2])
            hm = _parse_time_flexible(resolved_time) if resolved_time else None
            if hm:
                due_date = datetime(year, month, day, hm[0], hm[1])
            else:
                due_date = datetime(year, month, day, 23, 59)

        elif today_match:
            # "tonight" / "this evening" etc. → today with explicit time or 23:59
            hm = _parse_time_flexible(resolved_time) if resolved_time else None
            if hm:
                due_date = _today_midnight.replace(hour=hm[0], minute=hm[1])
            else:
                due_date = _today_midnight.replace(hour=23, minute=59)

        elif weekday_match:
            # Bare weekday without qualifier: "before Monday", "by Friday"
            # → next occurrence of that weekday at 23:59
            weekday_name = weekday_match.group(1)
            target = get_next_weekday(_today_midnight, weekday_name)
            hm = _parse_time_flexible(resolved_time) if resolved_time else None
            if hm:
                due_date = target.replace(hour=hm[0], minute=hm[1])
            else:
                due_date = target.replace(hour=23, minute=59)

        else:
            # No date information at all → tomorrow at 23:59
            due_date = (_today_midnight + timedelta(days=1)).replace(hour=23, minute=59)

    except Exception as e:
        print(f"[rule-based task] date parse error: {e}")
        due_date = (_today_midnight + timedelta(days=1)).replace(hour=23, minute=59)

    # ── 5. Clean title ────────────────────────────────────────────────────────
    # Work on the resolved text so we can strip the date/time literals too,
    # but keep the *original* casing for words that are not date/time/priority.
    title_text = resolved

    # Remove resolved date literal
    if date_match:
        title_text = title_text.replace(date_match.group(1), '')

    # Remove resolved time literal
    if time_match:
        title_text = re.sub(re.escape(time_match.group(0)), '', title_text, count=1, flags=re.IGNORECASE)

    # Remove deadline-introducer phrase that comes just before the date/time
    title_text = _DEADLINE_PHRASES.sub('', title_text)

    # Remove priority tokens
    title_text = _PRIORITY_RE.sub('', title_text)

    # Remove noise words
    title_text = _NOISE_RE.sub('', title_text)

    # Remove today-class words ("tonight", "this evening", etc.)
    title_text = _TODAY_TIMEOFDAY.sub('', title_text)

    # Remove bare weekday names that weren't resolved (e.g. "by Friday" → "by" removed,
    # but "Friday" itself remains when there's no "next/this/last" qualifier)
    title_text = _BARE_WEEKDAY.sub('', title_text)

    # Remove common residual linking words that become dangling after all the above strips
    title_text = _RESIDUAL_WORDS.sub('', title_text)

    # Collapse multiple spaces / trailing punctuation
    title_text = re.sub(r'\s+', ' ', title_text).strip(' .,;:-')

    # Capitalise first letter
    title = title_text[:1].upper() + title_text[1:] if title_text else original

    if not title:
        title = original

    print(f"[rule-based task] '{original}' → title='{title}' due={due_date.isoformat()} priority={priority}")

    return TaskOutput(
        title=title,
        due_date=due_date.isoformat(),
        priority=priority,
        description='',
    )


# ============================================================
# Model loading and inference
# ============================================================

def load_models():
    """Load the fine-tuned models on startup."""
    global event_model, event_tokenizer, task_model, task_tokenizer
    
    # Load event parser
    if os.path.exists(EVENT_MODEL_PATH):
        print(f"Loading event parser from {EVENT_MODEL_PATH}...")
        event_tokenizer = AutoTokenizer.from_pretrained(EVENT_MODEL_PATH, use_fast=False)
        event_model = AutoModelForSeq2SeqLM.from_pretrained(EVENT_MODEL_PATH)
        event_model.eval()
        print("Event parser loaded!")
    else:
        print(f"WARNING: Event model not found at {EVENT_MODEL_PATH}")
    
    # Load task parser
    if os.path.exists(TASK_MODEL_PATH):
        print(f"Loading task parser from {TASK_MODEL_PATH}...")
        task_tokenizer = AutoTokenizer.from_pretrained(TASK_MODEL_PATH, use_fast=False)
        task_model = AutoModelForSeq2SeqLM.from_pretrained(TASK_MODEL_PATH)
        task_model.eval()
        print("Task parser loaded!")
    else:
        print(f"WARNING: Task model not found at {TASK_MODEL_PATH}")


def pipe_to_dict(pipe_str: str) -> dict:
    """Convert pipe-delimited model output to dict.
    
    Example: "action: Meeting | date: 12/03/2026 | time: 03:00 PM | ..."
    Returns: {"action": "Meeting", "date": "12/03/2026", "time": "03:00 PM", ...}
    """
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


def extract_recurrence_from_text(text: str) -> str:
    """
    Derive a normalised recurrence label directly from the input text.

    Used as a fallback when the model does not emit a `recurrence` field.
    Returns one of: "Daily", "Weekly", "Monthly", or "" (no recurrence).
    """
    lower = text.lower()

    # Daily
    if re.search(r'\b(daily|every\s+day|every\s+single\s+day|once\s+a\s+day)\b', lower):
        return 'Daily'

    # Monthly
    if re.search(r'\b(monthly|every\s+month|once\s+a\s+month)\b', lower):
        return 'Monthly'

    # Weekly (explicit keyword or "every <weekday>")
    if re.search(
        r'\b(weekly|every\s+week|once\s+a\s+week'
        r'|every\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)'
        r'|(mondays|tuesdays|wednesdays|thursdays|fridays|saturdays|sundays))\b',
        lower,
    ):
        return 'Weekly'

    return ''


def resolve_relative_dates_for_recurring(text: str) -> str:
    """Resolve dates for recurring events without breaking recurrence patterns.
    
    Strategy:
    - Detect recurrence keywords: every, daily, weekly, monthly, each
    - If found: Only resolve dates NOT part of the recurrence pattern
    - Preserve the recurrence pattern itself (e.g., "every Monday")
    
    Example:
      Input:  "Yoga every Wednesday starting tomorrow"
      Output: "Yoga every Wednesday starting 02/03/2026"
                                            ↑ resolved
      NOT:    "Yoga every 02/03/2026"  ❌ Would break recurrence
    """
    import re
    
    # Check if text contains recurrence keywords
    recurrence_keywords = r'\b(every|each|daily|weekly|monthly|yearly)\b'
    has_recurrence = bool(re.search(recurrence_keywords, text, re.IGNORECASE))
    
    if not has_recurrence:
        # No recurrence, resolve all dates normally
        return resolve_relative_dates(text)
    
    # For recurring events: Only resolve dates that are NOT the recurrence pattern
    # Strategy: Protect "every <weekday>" and similar patterns from date resolution
    
    # Find and protect recurrence patterns
    protected_patterns = []
    
    # Pattern 1: "every Monday/Tuesday/etc"
    weekday_pattern = r'\b(every|each)\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b'
    for match in re.finditer(weekday_pattern, text, re.IGNORECASE):
        protected_patterns.append((match.start(), match.end(), match.group()))
    
    # Pattern 2: "daily", "weekly", etc. (standalone)
    standalone_pattern = r'\b(daily|weekly|monthly|yearly)\b'
    for match in re.finditer(standalone_pattern, text, re.IGNORECASE):
        protected_patterns.append((match.start(), match.end(), match.group()))
    
    # If we have protected patterns, work around them
    if protected_patterns:
        # Sort by position
        protected_patterns.sort()
        
        # Build result by processing text in segments
        result = ""
        last_end = 0
        
        for start, end, pattern in protected_patterns:
            # Resolve the part before this pattern
            before = text[last_end:start]
            result += resolve_relative_dates(before)
            # Keep the pattern unchanged
            result += pattern
            last_end = end
        
        # Resolve any remaining part after last pattern
        after = text[last_end:]
        result += resolve_relative_dates(after)
        
        return result
    else:
        # No protected patterns found, resolve all
        return resolve_relative_dates(text)


def generate_output(model, tokenizer, text: str, prefix: str) -> dict:
    """Generate structured output with dual-path processing.
    
    Model outputs pipe-delimited format (T5 can't tokenize { }),
    which is then converted to a dict.
    
    DUAL-PATH APPROACH:
    Path 1: Original text → Model (preserves recurrence keywords like "every Monday")
    Path 2: Preprocessed text → Dates resolved (for UI display)
    
    This fixes the conflict where date preprocessing was breaking recurrence detection.
    """
    # Path 1: Send ORIGINAL text to model (NO date preprocessing)
    # This allows the model to see "every Wednesday" instead of "every 05/03/2026".
    # However, we still want the model to see explicit time ranges normalised
    # into durations (e.g. "2pm-4pm" → "2pm for 2 hours"), just like in training.
    text_for_model = text
    duration_hint = extract_duration_from_text(text_for_model)
    # If we can infer a duration from the raw text (e.g. "2pm-4pm"), we keep
    # the original wording for the model and add the duration as a separate
    # field later. The model is currently not strongly trained on emitting a
    # duration field, so this is mainly for server-side robustness.
    input_text = f"{prefix}: {text_for_model}"
    inputs = tokenizer(input_text, return_tensors="pt", max_length=128, truncation=True)
    
    outputs = model.generate(
        **inputs,
        max_new_tokens=150,
        num_beams=4,
        early_stopping=True,
        no_repeat_ngram_size=3,
        repetition_penalty=2.5,
    )
    
    generated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)
    
    # Parse model output.
    # All fine-tuned T5 models in this project are trained to emit a
    # pipe-delimited format (e.g. "action: X | date: Y | ...").
    # JSON output is no longer used, and attempting json.loads here has been
    # the source of fragile failures when the model output is empty or noisy.
    # So we always prefer pipe parsing, and fall back to a minimal dict.
    if "|" in generated_text and ":" in generated_text:
        model_result = pipe_to_dict(generated_text)
    else:
        # Fallback: treat the whole string as an "action" title to avoid hard failures.
        text_clean = (generated_text or "").strip()
        model_result = {"action": text_clean or "Untitled Event"}

    # If the model did not emit a duration, but we can infer one from the
    # original text (time ranges or "for X hours"), attach it here so that
    # end_time can be computed correctly.
    if not model_result.get('duration') and duration_hint:
        model_result['duration'] = duration_hint
    
    # Path 2: Preprocess dates separately (smart handling for recurring events)
    # If the model missed the recurrence field, derive it from the raw text.
    recurrence = model_result.get('recurrence') or ''
    if not recurrence or recurrence.lower() in ('none', 'null', ''):
        recurrence = extract_recurrence_from_text(text)
        if recurrence:
            model_result['recurrence'] = recurrence

    # Check if this is a recurring event (after potential fallback above)
    if recurrence and recurrence.lower() not in ['none', 'null', '']:
        # For recurring events, use smart resolution (preserves recurrence patterns)
        resolved_text = resolve_relative_dates_for_recurring(text)
    else:
        # For one-time events, resolve all dates normally
        resolved_text = resolve_relative_dates(text)

    # Extract resolved date (DD/MM/YYYY) and time from the preprocessed text.
    # These will override the model's own date/time in convert_event_to_flutter()
    # because the model has no knowledge of "today's" date at inference time.
    date_match = re.search(r'\b(\d{2}/\d{2}/\d{4})\b', resolved_text)
    time_match = re.search(
        r'\b(\d{1,2}:\d{2}\s*(?:AM|PM)|\d{1,2}\s*(?:am|pm))\b',
        resolved_text,
        re.IGNORECASE,
    )

    model_result['_original_input'] = text
    model_result['_preprocessed_input'] = resolved_text
    model_result['_resolved_date'] = date_match.group(1) if date_match else None
    model_result['_resolved_time'] = time_match.group(1) if time_match else None

    return model_result


# ============================================================
# API Endpoints
# ============================================================

@app.on_event("startup")
async def startup_event():
    """Load models when server starts."""
    load_models()


@app.get("/")
def root():
    """Root endpoint."""
    return {
        "service": "Orbit NLP Parser (T5)",
        "status": "running",
        "event_model_loaded": event_model is not None,
        "task_model_loaded": task_model is not None
    }


@app.get("/health")
def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "event_model_loaded": event_model is not None,
        "task_model_loaded": task_model is not None
    }


@app.post("/parse/event", response_model=EventOutput)
def parse_event(input_data: ParseInput):
    """
    Parse natural language event description into structured data.
    
    The model outputs the original dataset format, then we convert
    to Flutter-compatible format.
    
    Example input: "Meeting with John tomorrow at 3pm for 1 hour"
    Example output: {
        "title": "Meeting",
        "start_time": "2026-01-30T15:00:00",
        "end_time": "2026-01-30T16:00:00",
        "location": "",
        "description": "With: John"
    }
    """
    if event_model is None or event_tokenizer is None:
        raise HTTPException(
            status_code=503,
            detail="Event model not loaded. Please train the model first."
        )
    
    try:
        # Generate output in original format
        parsed_data = generate_output(event_model, event_tokenizer, input_data.text, "parse event")
        
        # Convert to Flutter format
        return convert_event_to_flutter(parsed_data)
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error parsing event: {str(e)}"
        )


@app.post("/parse/task", response_model=TaskOutput)
def parse_task(input_data: ParseInput):
    """
    Parse natural language task description into structured data.

    Uses a rule-based parser (no model required): date/time resolution +
    priority keywords + title cleaning.

    Example input:  "Submit report by Friday 5pm high priority"
    Example output: {
        "title": "Submit report",
        "due_date": "2026-01-31T17:00:00",
        "priority": "high",
        "description": ""
    }
    """
    try:
        return parse_task_rule_based(input_data.text)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error parsing task: {str(e)}"
        )


if __name__ == "__main__":
    import uvicorn
    
    print("=" * 60)
    print("Orbit NLP Parser Server (T5)")
    print("=" * 60)
    print(f"Event model path: {EVENT_MODEL_PATH}")
    print(f"Task model path: {TASK_MODEL_PATH}")
    print("Starting server on http://localhost:5001")
    print("\nEndpoints:")
    print("  GET  /            - Service info")
    print("  GET  /health      - Health check")
    print("  POST /parse/event - Parse event text")
    print("  POST /parse/task  - Parse task text")
    print("=" * 60)
    
    uvicorn.run(app, host="0.0.0.0", port=5001, log_level="info")

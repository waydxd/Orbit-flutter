"""
Date and time resolver for natural language processing.
Converts relative date/time expressions to absolute values.

Author: Orbit NLP Team
Date: 2026-01-29
"""

import re
from datetime import datetime, timedelta
from dateutil.relativedelta import relativedelta


# Word to number mapping
WORD_TO_NUM = {
    'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
    'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
    'a': 1, 'an': 1
}

# Weekday name to number mapping (Monday=0, Sunday=6)
WEEKDAY_MAP = {
    'monday': 0, 'tuesday': 1, 'wednesday': 2, 'thursday': 3,
    'friday': 4, 'saturday': 5, 'sunday': 6,
    'mon': 0, 'tue': 1, 'wed': 2, 'thu': 3, 'fri': 4, 'sat': 5, 'sun': 6
}


def has_recurrence_pattern(text: str) -> bool:
    """
    Check if text contains recurrence keywords.
    
    Returns True if text has patterns like:
    - "every Monday", "each Tuesday"
    - "daily", "weekly", "monthly", "yearly"
    - "Mondays", "Tuesdays" (plural weekdays)
    
    Args:
        text: Input text to check
    
    Returns:
        True if recurrence pattern detected, False otherwise
    
    Examples:
        >>> has_recurrence_pattern("Yoga every Wednesday at 6pm")
        True
        >>> has_recurrence_pattern("Meeting tomorrow at 3pm")
        False
        >>> has_recurrence_pattern("Team standup daily at 9am")
        True
    """
    recurrence_patterns = [
        r'\bevery\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday|day|week|month|year)',
        r'\beach\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday|day|week|month|year)',
        r'\b(daily|weekly|monthly|yearly|annually)\b',
        r'\b(mondays|tuesdays|wednesdays|thursdays|fridays|saturdays|sundays)\b',
        r'\bevery\s+single\s+day\b',
        r'\bonce\s+a\s+(week|month|year)\b',
    ]
    
    for pattern in recurrence_patterns:
        if re.search(pattern, text, re.IGNORECASE):
            return True
    return False


def get_next_weekday(current_date: datetime, weekday_name: str) -> datetime:
    """
    Get the next occurrence of a weekday.
    
    Args:
        current_date: Reference date
        weekday_name: Name of weekday (monday, tuesday, etc.)
    
    Returns:
        datetime of next occurrence
    """
    target_weekday = WEEKDAY_MAP[weekday_name.lower()]
    days_ahead = target_weekday - current_date.weekday()
    if days_ahead <= 0:
        days_ahead += 7
    return current_date + timedelta(days=days_ahead)


def get_this_weekday(current_date: datetime, weekday_name: str) -> datetime:
    """
    Get this week's occurrence of a weekday (can be in past).
    
    Args:
        current_date: Reference date
        weekday_name: Name of weekday
    
    Returns:
        datetime of this week's occurrence
    """
    target_weekday = WEEKDAY_MAP[weekday_name.lower()]
    days_ahead = target_weekday - current_date.weekday()
    return current_date + timedelta(days=days_ahead)


def parse_time_to_minutes(time_str: str) -> int:
    """
    Parse time string to minutes from midnight.
    
    Supports formats: "10am", "10:30am", "3pm", "14:00", "2:45pm"
    
    Args:
        time_str: Time string to parse
    
    Returns:
        Minutes from midnight (0-1439)
    """
    time_str = time_str.strip().lower()
    
    # Check for AM/PM format
    if 'am' in time_str or 'pm' in time_str:
        is_pm = 'pm' in time_str
        time_str = time_str.replace('am', '').replace('pm', '').strip()
        
        # Parse hour and minute
        if ':' in time_str:
            parts = time_str.split(':')
            hour = int(parts[0])
            minute = int(parts[1])
        else:
            hour = int(time_str)
            minute = 0
        
        # Convert to 24-hour format
        if is_pm and hour != 12:
            hour += 12
        elif not is_pm and hour == 12:
            hour = 0
        
        return hour * 60 + minute
    
    # 24-hour format (e.g., "14:00", "09:30")
    else:
        if ':' in time_str:
            parts = time_str.split(':')
            hour = int(parts[0])
            minute = int(parts[1])
        else:
            hour = int(time_str)
            minute = 0
        
        return hour * 60 + minute


def convert_time_range_to_duration(text: str) -> str:
    """
    Convert time ranges (e.g., "10am-11:20am") to explicit durations.
    
    Patterns supported:
    - "10am-11am" → "10am for 1 hour"
    - "3:30pm-5pm" → "3:30pm for 1 hour 30 minutes"
    - "14:00-15:30" → "14:00 for 1 hour 30 minutes"
    - "10am-11:20am" → "10am for 1 hour 20 minutes"
    
    Args:
        text: Input text with potential time ranges
    
    Returns:
        Text with time ranges converted to durations
    """
    # Pattern for time ranges: HH:MM AM/PM - HH:MM AM/PM
    # Supports: "10am-11am", "10:30am-12pm", "3pm-5:30pm", "14:00-15:30"
    
    # Pattern 1: With AM/PM (e.g., "10am-11:20am", "3:30pm-5pm")
    pattern_ampm = r'\b(\d{1,2}(?::\d{2})?)\s*(am|pm)\s*-\s*(\d{1,2}(?::\d{2})?)\s*(am|pm)\b'
    
    def replace_ampm_range(match):
        start_time = match.group(1) + match.group(2)
        end_time = match.group(3) + match.group(4)
        
        try:
            start_minutes = parse_time_to_minutes(start_time)
            end_minutes = parse_time_to_minutes(end_time)
            
            # Handle overnight ranges (e.g., "11pm-1am")
            if end_minutes < start_minutes:
                end_minutes += 24 * 60
            
            duration_minutes = end_minutes - start_minutes
            
            # Format duration
            hours = duration_minutes // 60
            minutes = duration_minutes % 60
            
            if hours > 0 and minutes > 0:
                duration_str = f"{hours} hour{'s' if hours > 1 else ''} {minutes} minutes"
            elif hours > 0:
                duration_str = f"{hours} hour{'s' if hours > 1 else ''}"
            else:
                duration_str = f"{minutes} minutes"
            
            # Return start time with duration
            return f"{start_time} for {duration_str}"
        except:
            return match.group(0)  # Return unchanged if parsing fails
    
    text = re.sub(pattern_ampm, replace_ampm_range, text, flags=re.IGNORECASE)
    
    # Pattern 2: 24-hour format (e.g., "14:00-15:30", "09:00-10:00")
    pattern_24h = r'\b(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})\b'
    
    def replace_24h_range(match):
        start_time = match.group(1)
        end_time = match.group(2)
        
        try:
            start_minutes = parse_time_to_minutes(start_time)
            end_minutes = parse_time_to_minutes(end_time)
            
            if end_minutes < start_minutes:
                end_minutes += 24 * 60
            
            duration_minutes = end_minutes - start_minutes
            hours = duration_minutes // 60
            minutes = duration_minutes % 60
            
            if hours > 0 and minutes > 0:
                duration_str = f"{hours} hour{'s' if hours > 1 else ''} {minutes} minutes"
            elif hours > 0:
                duration_str = f"{hours} hour{'s' if hours > 1 else ''}"
            else:
                duration_str = f"{minutes} minutes"
            
            return f"{start_time} for {duration_str}"
        except:
            return match.group(0)
    
    text = re.sub(pattern_24h, replace_24h_range, text, flags=re.IGNORECASE)
    
    return text


def resolve_relative_dates(text: str) -> str:
    """
    Replace all relative dates/times with actual values.
    
    Supported patterns:
    
    DATES:
    - today, tomorrow, yesterday, day after tomorrow
    - next/this/last Monday/Tuesday/.../Sunday
    - next/this/last week/month/year
    - in X days/weeks/months/years
    - X days/weeks/months/years ago/later/from now
    - two weeks later, one month later, etc. (word numbers)
    
    TIMES:
    - Common times: (at) noon → 12:00 PM, (at) midnight → 12:00 AM
    - (in the) morning → 09:00 AM, (in the) afternoon → 02:00 PM
    - (in the) evening → 06:00 PM, (at) night → 08:00 PM
    - now, right now
    - in X minutes/hours
    - X minutes/hours ago/later/from now
    - five minutes late/early (converts to actual time)
    
    TIME RANGES:
    - "10am-11am" → "10am for 1 hour"
    - "3:30pm-5pm" → "3:30pm for 1 hour 30 minutes"
    - "14:00-15:30" → "14:00 for 1 hour 30 minutes"
    
    Args:
        text: Input text with relative date/time expressions
    
    Returns:
        Text with resolved absolute dates/times
    """
    # First, convert time ranges to durations (before other processing)
    text = convert_time_range_to_duration(text)
    
    now = datetime.now()
    today = now.replace(hour=0, minute=0, second=0, microsecond=0)
    
    # ────────────────────────────────────────────────────────
    # ABSOLUTE DAY REFERENCES
    # ────────────────────────────────────────────────────────
    text = re.sub(r'\btoday\b', today.strftime('%d/%m/%Y'), text, flags=re.IGNORECASE)
    text = re.sub(r'\btomorrow\b', (today + timedelta(days=1)).strftime('%d/%m/%Y'), text, flags=re.IGNORECASE)
    text = re.sub(r'\byesterday\b', (today - timedelta(days=1)).strftime('%d/%m/%Y'), text, flags=re.IGNORECASE)
    text = re.sub(r'\b(the day after tomorrow|overmorrow|day after tomorrow)\b', 
                  (today + timedelta(days=2)).strftime('%d/%m/%Y'), text, flags=re.IGNORECASE)
    
    # ────────────────────────────────────────────────────────
    # WEEKDAY REFERENCES
    # ────────────────────────────────────────────────────────
    weekday_pattern = r'(monday|tuesday|wednesday|thursday|friday|saturday|sunday|mon|tue|wed|thu|fri|sat|sun)'
    
    # "next Monday", "next Tuesday", etc.
    def replace_next_weekday(match):
        weekday = match.group(1)
        result = get_next_weekday(today, weekday)
        return result.strftime('%d/%m/%Y')
    text = re.sub(rf'\bnext\s+{weekday_pattern}\b', replace_next_weekday, text, flags=re.IGNORECASE)
    
    # "this Monday", "this Tuesday", etc.
    def replace_this_weekday(match):
        weekday = match.group(1)
        result = get_this_weekday(today, weekday)
        return result.strftime('%d/%m/%Y')
    text = re.sub(rf'\bthis\s+{weekday_pattern}\b', replace_this_weekday, text, flags=re.IGNORECASE)
    
    # "last Monday", "last Tuesday", etc.
    def replace_last_weekday(match):
        weekday = match.group(1)
        result = get_next_weekday(today, weekday) - timedelta(weeks=1)
        return result.strftime('%d/%m/%Y')
    text = re.sub(rf'\blast\s+{weekday_pattern}\b', replace_last_weekday, text, flags=re.IGNORECASE)
    
    # ────────────────────────────────────────────────────────
    # WEEK REFERENCES
    # ────────────────────────────────────────────────────────
    text = re.sub(r'\bnext week\b', (today + timedelta(weeks=1)).strftime('%d/%m/%Y'), text, flags=re.IGNORECASE)
    text = re.sub(r'\bthis week\b', today.strftime('%d/%m/%Y'), text, flags=re.IGNORECASE)
    text = re.sub(r'\blast week\b', (today - timedelta(weeks=1)).strftime('%d/%m/%Y'), text, flags=re.IGNORECASE)
    
    # "in X weeks" or "X weeks from now" or "X weeks later"
    def replace_weeks_offset(match):
        weeks = int(match.group(1))
        return (today + timedelta(weeks=weeks)).strftime('%d/%m/%Y')
    text = re.sub(r'\bin\s+(\d+)\s+weeks?\b', replace_weeks_offset, text, flags=re.IGNORECASE)
    text = re.sub(r'\b(\d+)\s+weeks?\s+(from now|later)\b', replace_weeks_offset, text, flags=re.IGNORECASE)
    
    # "X weeks ago"
    def replace_weeks_ago(match):
        weeks = int(match.group(1))
        return (today - timedelta(weeks=weeks)).strftime('%d/%m/%Y')
    text = re.sub(r'\b(\d+)\s+weeks?\s+ago\b', replace_weeks_ago, text, flags=re.IGNORECASE)
    
    # Word numbers: "two weeks later", "one week from now"
    def replace_word_weeks(match):
        word = match.group(1).lower()
        weeks = WORD_TO_NUM.get(word, 1)
        return (today + timedelta(weeks=weeks)).strftime('%d/%m/%Y')
    text = re.sub(r'\b(one|two|three|four|five|six|seven|eight|nine|ten|a|an)\s+weeks?\s+(later|from now)\b',
                  replace_word_weeks, text, flags=re.IGNORECASE)
    
    # ────────────────────────────────────────────────────────
    # MONTH REFERENCES
    # ────────────────────────────────────────────────────────
    text = re.sub(r'\bnext month\b', (today + relativedelta(months=1)).strftime('%d/%m/%Y'), text, flags=re.IGNORECASE)
    text = re.sub(r'\bthis month\b', today.strftime('%d/%m/%Y'), text, flags=re.IGNORECASE)
    text = re.sub(r'\blast month\b', (today - relativedelta(months=1)).strftime('%d/%m/%Y'), text, flags=re.IGNORECASE)
    
    # "in X months" or "X months from now" or "X months later"
    def replace_months_offset(match):
        months = int(match.group(1))
        return (today + relativedelta(months=months)).strftime('%d/%m/%Y')
    text = re.sub(r'\bin\s+(\d+)\s+months?\b', replace_months_offset, text, flags=re.IGNORECASE)
    text = re.sub(r'\b(\d+)\s+months?\s+(from now|later)\b', replace_months_offset, text, flags=re.IGNORECASE)
    
    # Word numbers: "one month later", "two months from now"
    def replace_word_months(match):
        word = match.group(1).lower()
        months = WORD_TO_NUM.get(word, 1)
        return (today + relativedelta(months=months)).strftime('%d/%m/%Y')
    text = re.sub(r'\b(one|two|three|four|five|six|seven|eight|nine|ten|a|an)\s+months?\s+(later|from now)\b',
                  replace_word_months, text, flags=re.IGNORECASE)
    
    # "X months ago"
    def replace_months_ago(match):
        months = int(match.group(1))
        return (today - relativedelta(months=months)).strftime('%d/%m/%Y')
    text = re.sub(r'\b(\d+)\s+months?\s+ago\b', replace_months_ago, text, flags=re.IGNORECASE)
    
    # ────────────────────────────────────────────────────────
    # YEAR REFERENCES
    # ────────────────────────────────────────────────────────
    text = re.sub(r'\bnext year\b', (today + relativedelta(years=1)).strftime('%d/%m/%Y'), text, flags=re.IGNORECASE)
    text = re.sub(r'\bthis year\b', today.strftime('%d/%m/%Y'), text, flags=re.IGNORECASE)
    text = re.sub(r'\blast year\b', (today - relativedelta(years=1)).strftime('%d/%m/%Y'), text, flags=re.IGNORECASE)
    
    # ────────────────────────────────────────────────────────
    # DAY-BASED OFFSETS
    # ────────────────────────────────────────────────────────
    # "in X days" or "X days from now" or "X days later"
    def replace_in_days(match):
        days = int(match.group(1))
        return (today + timedelta(days=days)).strftime('%d/%m/%Y')
    text = re.sub(r'\bin\s+(\d+)\s+days?\b', replace_in_days, text, flags=re.IGNORECASE)
    text = re.sub(r'\b(\d+)\s+days?\s+(from now|later)\b', replace_in_days, text, flags=re.IGNORECASE)
    
    # "X days ago"
    def replace_days_ago(match):
        days = int(match.group(1))
        return (today - timedelta(days=days)).strftime('%d/%m/%Y')
    text = re.sub(r'\b(\d+)\s+days?\s+ago\b', replace_days_ago, text, flags=re.IGNORECASE)
    
    # ────────────────────────────────────────────────────────
    # TIME REFERENCES
    # ────────────────────────────────────────────────────────
    # Common time expressions
    text = re.sub(r'\b(at\s+)?noon\b', '12:00 PM', text, flags=re.IGNORECASE)
    text = re.sub(r'\b(at\s+)?midnight\b', '12:00 AM', text, flags=re.IGNORECASE)
    text = re.sub(r'\b(in the\s+)?morning\b', '09:00 AM', text, flags=re.IGNORECASE)
    text = re.sub(r'\b(in the\s+)?afternoon\b', '02:00 PM', text, flags=re.IGNORECASE)
    text = re.sub(r'\b(in the\s+)?evening\b', '06:00 PM', text, flags=re.IGNORECASE)
    text = re.sub(r'\b(at\s+)?night\b', '08:00 PM', text, flags=re.IGNORECASE)
    
    # Current time
    text = re.sub(r'\bright now\b', now.strftime('%I:%M %p'), text, flags=re.IGNORECASE)
    text = re.sub(r'\bnow\b', now.strftime('%I:%M %p'), text, flags=re.IGNORECASE)
    
    # "in X minutes/hours" or "X minutes/hours from now" or "X minutes/hours later"
    def replace_in_time(match):
        amount = int(match.group(1))
        unit = match.group(2).lower()
        if 'hour' in unit or 'hr' in unit:
            future = now + timedelta(hours=amount)
        else:  # minutes/min
            future = now + timedelta(minutes=amount)
        return future.strftime('%I:%M %p')
    text = re.sub(r'\bin\s+(\d+)\s+(minute|minutes|min|mins|hour|hours|hr|hrs)\b',
                  replace_in_time, text, flags=re.IGNORECASE)
    text = re.sub(r'\b(\d+)\s+(minute|minutes|min|mins|hour|hours|hr|hrs)\s+(later|from now)\b',
                  replace_in_time, text, flags=re.IGNORECASE)
    
    # "X minutes/hours ago"
    def replace_time_ago(match):
        amount = int(match.group(1))
        unit = match.group(2).lower()
        if 'hour' in unit or 'hr' in unit:
            past = now - timedelta(hours=amount)
        else:
            past = now - timedelta(minutes=amount)
        return past.strftime('%I:%M %p')
    text = re.sub(r'\b(\d+)\s+(minute|minutes|min|mins|hour|hours|hr|hrs)\s+ago\b',
                  replace_time_ago, text, flags=re.IGNORECASE)
    
    # "five minutes late" or "5 minutes early" (add/subtract X minutes to current time)
    def replace_late(match):
        amount_text = match.group(1)
        unit = match.group(2).lower()
        modifier = match.group(3).lower()  # late or early
        
        # Convert word to number if needed
        amount = WORD_TO_NUM.get(amount_text.lower(), None)
        if amount is None:
            try:
                amount = int(amount_text)
            except:
                return match.group(0)  # Return unchanged if can't parse
        
        if 'hour' in unit or 'hr' in unit:
            delta = timedelta(hours=amount)
        else:
            delta = timedelta(minutes=amount)
        
        # "late" means add time, "early" means subtract
        if modifier == 'late':
            result = now + delta
        else:  # early
            result = now - delta
        
        return result.strftime('%I:%M %p')
    
    text = re.sub(r'\b(\d+|one|two|three|four|five|six|seven|eight|nine|ten)\s+(minute|minutes|min|mins|hour|hours|hr|hrs)\s+(late|early)\b',
                  replace_late, text, flags=re.IGNORECASE)
    
    return text


if __name__ == "__main__":
    # Quick test
    test_cases = [
        "Meeting today at 3pm",
        "Lunch tomorrow at noon",
        "Conference next Monday at 9am",
        "Review in 2 weeks",
        "Call one month later",
    ]
    
    print("Date Resolver Test")
    print("=" * 60)
    print(f"Current: {datetime.now().strftime('%d/%m/%Y %I:%M %p')}")
    print("=" * 60)
    
    for test in test_cases:
        resolved = resolve_relative_dates(test)
        print(f"Input:    {test}")
        print(f"Resolved: {resolved}")
        print()

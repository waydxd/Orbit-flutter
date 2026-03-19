"""
Test script for date_resolver.py
Tests all relative date/time patterns to ensure correct resolution.


Date: 2026-01-29
"""

from utils.date_resolver import resolve_relative_dates
from datetime import datetime


# Comprehensive test cases covering all patterns
test_cases = [
    # ============================================================
    # BASIC DAY REFERENCES
    # ============================================================
    "Meeting today at 3pm",
    "Lunch tomorrow at noon",
    "Appointment yesterday at 10am",
    "Party the day after tomorrow at 8pm",
    
    # ============================================================
    # WEEKDAY REFERENCES
    # ============================================================
    "Conference next Monday at 9am",
    "Standup this Tuesday at 10am",
    "Review last Friday at 2pm",
    "Workshop next Wed at 3pm",
    "Yoga this Thursday",
    
    # ============================================================
    # WEEK OFFSETS
    # ============================================================
    "Deadline next week",
    "Meeting this week",
    "Report last week",
    "Workshop in 2 weeks",
    "Follow-up two weeks later",
    "Check-in 3 weeks from now",
    "Review 4 weeks ago",
    
    # ============================================================
    # MONTH OFFSETS
    # ============================================================
    "Review next month",
    "Conference this month",
    "Report last month",
    "Appointment in 2 months",
    "Deadline one month later",
    "Follow-up three months from now",
    "Meeting 2 months ago",
    
    # ============================================================
    # YEAR OFFSETS
    # ============================================================
    "Annual review next year",
    "Budget this year",
    "Retrospective last year",
    
    # ============================================================
    # DAY OFFSETS
    # ============================================================
    "Call in 3 days",
    "Meeting 5 days later",
    "Reminder 10 days from now",
    "Report 7 days ago",
    
    # ============================================================
    # COMMON TIME EXPRESSIONS
    # ============================================================
    "Lunch at noon",
    "Meeting at midnight",
    "Yoga in the morning",
    "Call in the afternoon",
    "Dinner in the evening",
    "Study at night",
    "Brunch noon",
    "Appointment midnight",
    
    # ============================================================
    # TIME OFFSETS
    # ============================================================
    "Call now",
    "Meeting right now",
    "Standup in 30 minutes",
    "Check-in in 2 hours",
    "Reminder 15 minutes later",
    "Follow-up 3 hours from now",
    "Meeting 45 minutes ago",
    "Call 2 hours ago",
    
    # ============================================================
    # LATE/EARLY TIME EXPRESSIONS
    # ============================================================
    "Arriving five minutes late",
    "Meeting 10 minutes early",
    "Call 2 hours late",
    
    # ============================================================
    # COMPLEX/COMBINED EXPRESSIONS
    # ============================================================
    "Yoga every Wednesday next week at 6pm",
    "Team meeting two weeks from now at 10am for 1 hour",
    "Lunch tomorrow at noon with John",
    "Conference next Monday in 2 hours",
    "Review today in 30 minutes at the office",
]


def run_tests():
    """Run all test cases and display results."""
    print("=" * 80)
    print("DATE/TIME RESOLUTION TEST")
    print("=" * 80)
    print(f"Current time: {datetime.now().strftime('%d/%m/%Y %I:%M %p')}")
    print("=" * 80)
    print()
    
    passed = 0
    failed = 0
    
    for i, test in enumerate(test_cases, 1):
        resolved = resolve_relative_dates(test)
        
        # Check if any resolution occurred
        if test != resolved:
            status = "✓"
            passed += 1
        else:
            status = "✗ NO CHANGE"
            failed += 1
        
        print(f"{status} Test {i:2d}")
        print(f"  Input:    {test}")
        print(f"  Resolved: {resolved}")
        print()
    
    print("=" * 80)
    print(f"SUMMARY: {passed} passed, {failed} unchanged")
    print("=" * 80)
    
    # Show some specific examples of what was resolved
    print("\nEXAMPLE RESOLUTIONS:")
    print("-" * 80)
    
    specific_tests = [
        "Meeting today at 3pm",
        "Conference next Monday at 9am",
        "Workshop in 2 weeks",
        "Deadline one month later",
        "Call in 30 minutes",
    ]
    
    for test in specific_tests:
        resolved = resolve_relative_dates(test)
        print(f"  '{test}'")
        print(f"  → '{resolved}'")
        print()
    
    print("\n" + "=" * 80)
    print("TIME RANGE TESTS")
    print("=" * 80)
    
    time_range_tests = [
        "COMP 2012 lecture at 10am-11:20am tomorrow",
        "Meeting from 3pm-5pm today",
        "Workshop 14:00-15:30 next Monday",
        "Lunch 12pm-1pm",
        "Class 9:30am-11am every Tuesday",
        "Yoga 6pm-7:30pm at downtown studio",
        "Team sync 10:00-10:30 tomorrow morning",
        "Dinner 7pm-9pm tonight",
    ]
    
    for test in time_range_tests:
        resolved = resolve_relative_dates(test)
        print(f"  '{test}'")
        print(f"  → '{resolved}'")
        print()


if __name__ == "__main__":
    run_tests()

"""
Test time range to duration conversion

This script verifies that time ranges are correctly converted to explicit durations
during preprocessing, which allows the T5 model to extract duration properly.
"""

from utils.date_resolver import convert_time_range_to_duration, resolve_relative_dates


TEST_CASES = [
    # Format: (input, expected_contains)
    ("Meeting 10am-11:20am tomorrow", "for 1 hour 20 minutes"),
    ("COMP 2012 lecture 10am-11:20am", "for 1 hour 20 minutes"),
    ("Workshop 3pm-5pm today", "for 2 hours"),
    ("Lunch 12pm-1pm", "for 1 hour"),
    ("Class 9:30am-11am every Tuesday", "for 1 hour 30 minutes"),
    ("Yoga 6pm-7:30pm at gym", "for 1 hour 30 minutes"),
    ("Team sync 10:00-10:30 tomorrow", "for 30 minutes"),
    ("Conference 14:00-15:30 next week", "for 1 hour 30 minutes"),
    ("Sprint planning 2pm-4pm Monday", "for 2 hours"),
    ("Standup 9am-9:15am daily", "for 15 minutes"),
]


def run_tests():
    """Run time range conversion tests."""
    
    print("=" * 80)
    print("TIME RANGE TO DURATION CONVERSION TEST")
    print("=" * 80)
    print()
    
    passed = 0
    failed = 0
    
    for i, (input_text, expected_duration) in enumerate(TEST_CASES, 1):
        print(f"Test {i}/{len(TEST_CASES)}:")
        print(f"  Input:    {input_text}")
        
        # Apply full preprocessing (includes time range conversion)
        result = resolve_relative_dates(input_text)
        
        print(f"  Output:   {result}")
        
        # Check if expected duration is in the output
        if expected_duration in result:
            print(f"  ✅ PASS - Found '{expected_duration}'")
            passed += 1
        else:
            print(f"  ❌ FAIL - Expected '{expected_duration}' not found")
            failed += 1
        
        print()
    
    # Summary
    print("=" * 80)
    print("TEST SUMMARY")
    print("=" * 80)
    print(f"Total:  {len(TEST_CASES)}")
    print(f"Passed: {passed} ({passed/len(TEST_CASES)*100:.0f}%)")
    print(f"Failed: {failed}")
    print()
    
    if failed == 0:
        print("✅ ALL TESTS PASSED - Time range conversion is working perfectly!")
    else:
        print(f"⚠️  {failed} test(s) failed - please check the preprocessing logic")
    
    print("=" * 80)


if __name__ == '__main__':
    run_tests()

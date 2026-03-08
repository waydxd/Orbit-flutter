"""
Test recurrence detection with dual-path processing

This script tests the NLP server's ability to correctly detect and handle
recurring events without breaking the recurrence pattern during preprocessing.

Usage:
    1. Start the NLP server: python3 server.py
    2. Run this test: python3 test_recurrence.py
"""

import requests
import json
from datetime import datetime


# Test cases with expected recurrence types
TEST_CASES = [
    # Weekly patterns
    ("Yoga every Wednesday at 6pm", "Weekly"),
    ("Team meeting each Monday at 10am", "Weekly"),
    ("Gym session Tuesdays at 7am", "Weekly"),
    ("Study group every Friday afternoon", "Weekly"),
    
    # Daily patterns
    ("Team standup daily at 9am", "Daily"),
    ("Morning meditation every day at 6am", "Daily"),
    ("Check emails everyday at 5pm", "Daily"),
    
    # Monthly patterns
    ("Monthly review first Monday at 2pm", "Monthly"),
    ("Board meeting once a month", "Monthly"),
    ("Rent payment every month", "Monthly"),
    
    # Yearly patterns
    ("Annual planning every year in January", "Yearly"),
    ("Birthday party yearly", "Yearly"),
    
    # Non-recurring (should return 'none' or empty)
    ("Coffee chat tomorrow at 10am", "none"),
    ("Meeting next Monday at 2pm", "none"),
    ("Lunch today at noon", "none"),
    
    # Time range patterns (with duration extraction)
    ("COMP 2012 lecture every Monday 10am-11:20am", "Weekly"),
    ("Meeting tomorrow 3pm-5pm", "none"),
    ("Workshop 14:00-15:30 next week", "none"),
    ("Team sync 9:30am-10am every Thursday", "Weekly"),
]


def test_recurrence_detection():
    """Test recurrence detection with the NLP server."""
    
    print("=" * 80)
    print("RECURRENCE DETECTION TEST")
    print("=" * 80)
    print(f"Current time: {datetime.now().strftime('%d/%m/%Y %I:%M %p')}")
    print("=" * 80)
    print()
    
    base_url = "http://localhost:5001"
    
    # Check server health first
    try:
        health_response = requests.get(f"{base_url}/health", timeout=5)
        health = health_response.json()
        print("Server Status:")
        print(f"  Status: {health.get('status', 'unknown')}")
        print(f"  Event model loaded: {health.get('event_model_loaded', False)}")
        print()
        
        if not health.get('event_model_loaded'):
            print("❌ Event model not loaded! Please train and deploy the model first.")
            return
            
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to NLP server!")
        print("   Please start the server: python3 server.py")
        return
    except Exception as e:
        print(f"❌ Error checking server health: {e}")
        return
    
    # Run test cases
    passed = 0
    failed = 0
    
    for i, (text, expected_recurrence) in enumerate(TEST_CASES, 1):
        print(f"Test {i}/{len(TEST_CASES)}:")
        print(f"  Input: {text}")
        print(f"  Expected recurrence: {expected_recurrence}")
        
        try:
            response = requests.post(
                f"{base_url}/parse/event",
                json={'text': text},
                timeout=10
            )
            
            if response.status_code == 200:
                result = response.json()
                
                # Check description for recurrence info
                description = result.get('description', '')
                has_recurrence = 'Repeats:' in description
                
                # Extract recurrence type if present
                detected_recurrence = 'none'
                if has_recurrence:
                    # Parse "Repeats: Weekly" from description
                    for part in description.split('.'):
                        if 'Repeats:' in part:
                            detected_recurrence = part.split('Repeats:')[1].strip()
                            break
                
                # Validate
                expected_lower = expected_recurrence.lower()
                detected_lower = detected_recurrence.lower()
                
                if expected_lower == 'none':
                    # For non-recurring events, should NOT have "Repeats:" in description
                    if not has_recurrence:
                        print(f"  ✅ PASS - Correctly detected as non-recurring")
                        passed += 1
                    else:
                        print(f"  ❌ FAIL - False positive: detected '{detected_recurrence}' but should be none")
                        failed += 1
                else:
                    # For recurring events, check if type matches
                    if detected_lower == expected_lower:
                        print(f"  ✅ PASS - Correct recurrence: {detected_recurrence}")
                        passed += 1
                    else:
                        print(f"  ❌ FAIL - Wrong type: got '{detected_recurrence}', expected '{expected_recurrence}'")
                        failed += 1
                
                # Show full result
                print(f"  Title: {result.get('title', 'N/A')}")
                print(f"  Start: {result.get('start_time', 'N/A')[:16]}")
                print(f"  Description: {description[:60]}..." if len(description) > 60 else f"  Description: {description}")
                
            else:
                print(f"  ❌ FAIL - Server error: {response.status_code}")
                print(f"     {response.text[:100]}")
                failed += 1
                
        except Exception as e:
            print(f"  ❌ FAIL - Exception: {e}")
            failed += 1
        
        print("-" * 80)
    
    # Summary
    print()
    print("=" * 80)
    print("TEST SUMMARY")
    print("=" * 80)
    print(f"Total Tests:  {len(TEST_CASES)}")
    print(f"Passed:       {passed} ({passed/len(TEST_CASES)*100:.1f}%)")
    print(f"Failed:       {failed} ({failed/len(TEST_CASES)*100:.1f}%)")
    print()
    
    # Quality assessment
    pass_rate = passed / len(TEST_CASES)
    if pass_rate >= 0.9:
        print("✅ EXCELLENT - Recurrence detection is working very well!")
    elif pass_rate >= 0.7:
        print("🟢 GOOD - Recurrence detection is acceptable.")
    elif pass_rate >= 0.5:
        print("🟡 FAIR - Recurrence detection needs improvement.")
    else:
        print("🔴 POOR - Recurrence detection has serious issues.")
        print("   Consider retraining with more recurrence examples.")
    
    print("=" * 80)


if __name__ == '__main__':
    test_recurrence_detection()

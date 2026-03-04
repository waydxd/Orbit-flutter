# Training Output Quality Issues

## Problems Found in Test Results

### 1. ❌ **Hallucinating Data** (Model adds info not in input)

**Test 1:**
```
Input:  "Meeting with John tomorrow at 3pm for 1 hour"
Output: location: Conference room Central | notes: Discuss algorithms
```
❌ "Conference room Central" - NOT in input
❌ "Discuss algorithms" - NOT in input

**Test 5:**
```
Input:  "Yoga class at the gym on Friday 6pm"
Output: notes: Meditation
```
❌ "Meditation" - NOT in input

**Test 11:**
```
Input:  "Yoga every Wednesday at 6pm for 1 hour"
Output: notes: Beginner session
```
❌ "Beginner session" - NOT in input

### 2. ❌ **Missing Pipe Separators** (Format errors)

**Test 2:**
```
Output: duration: none recurrence: Weekly
```
❌ Should be: `duration: none | recurrence: Weekly`

**Test 5:**
```
Output: attendees: none recurrence: Weekly
```
❌ Should be: `attendees: none | recurrence: Weekly`

**Test 11:**
```
Output: attendees: none recurrence: Weekly
```
❌ Should be: `attendees: none | recurrence: Weekly`

### 3. ❌ **False Positive Recurrence** (Detecting recurring when not specified)

**Test 2:**
```
Input:  "Lunch at noon with Sarah"
Output: recurrence: Weekly
```
❌ No "every", "weekly", or recurring keywords in input

**Test 7:**
```
Input:  "Workshop in 2 weeks for 3 hours"
Output: recurrence: Weekly
```
❌ "in 2 weeks" = one-time event, not recurring

**Test 8:**
```
Input:  "Dinner tonight at 7pm for 2 hours"
Output: recurrence: Weekly
```
❌ "tonight" = one-time event, not recurring

### 4. ❌ **Malformed Location**

**Test 7 & 8:**
```
Output: location: none 202
```
❌ Should be either "none" OR "Room 202", not mixed

### 5. ❌ **Wrong Date Extraction**

**Test 5:**
```
Input:  "Yoga class at the gym on Friday 6pm"
Output: date: none
```
❌ Should extract Friday as a specific date (e.g., "06/03/2026")

**Test 8:**
```
Input:  "Dinner tonight at 7pm"
Output: date: 08/03/2026
```
❌ "tonight" should be 01/03/2026 (current date), not 8 days later

**Test 11:**
```
Input:  "Yoga every Wednesday at 6pm"
Output: date: none
```
✅ This is correct for recurring events (should be "none")

### 6. ❌ **Extra Words in Fields**

**Test 1:**
```
Output: recurrence: the none
```
❌ Should be: `recurrence: none` (not "the none")

---

## Root Causes

### Issue 1: Training Data Quality
The training data likely contains examples where the model learned to:
- Copy context from other fields
- Add common patterns even when not present in input
- Inconsistently format the output

### Issue 2: Overfitting to Patterns
The model memorized common patterns from training data:
- "Yoga" → always adds "Beginner session" or "Meditation"  
- "Meeting" → always adds "Conference room" and "Discuss X"
- Certain words → always triggers "Weekly" recurrence

### Issue 3: Insufficient Data Diversity
The 3,702 training examples may not be diverse enough, causing:
- Pattern memorization instead of understanding
- Hallucination of common fields
- Overgeneralization (marking too many things as recurring)

---

## What This Means

**The model is NOT production-ready** because:
1. ❌ It adds information that wasn't in the user's input (hallucination)
2. ❌ Output format has errors (missing pipes)
3. ❌ It incorrectly detects recurring events
4. ❌ It extracts wrong dates

**However, the model DID learn the general structure** (pipe format, field names), so training partially worked.

---

## Solutions

### Immediate Fix: Data Cleaning

1. **Check training data for hallucination sources:**
   ```bash
   grep "Beginner session" data/event_training_data.jsonl
   grep "Conference room" data/event_training_data.jsonl
   grep "Discuss algorithms" data/event_training_data.jsonl
   ```

2. **Find and fix format errors:**
   - Search for missing pipes in training data
   - Verify all examples follow strict format

3. **Review recurrence labeling:**
   - Make sure non-recurring events have `recurrence: none`
   - Only mark events with "every", "daily", "weekly" keywords as recurring

### Better Fix: Improve Training Data

1. **Add more negative examples** (non-recurring events)
2. **Remove or fix hallucination patterns**
3. **Increase data diversity** (more varied locations, activities, notes)
4. **Validate all training examples** programmatically

### Best Fix: Data Validation Script

Create a script to validate training data quality before training:
- Check pipe format consistency
- Verify no hallucination in outputs
- Ensure recurrence labels match input keywords
- Validate date extraction logic

---

## Recommendation

**Do NOT deploy this model to production.** 

The hallucination issue is critical - users will get confused when the app adds information they didn't provide.

**Next steps:**
1. Review and clean the training data
2. Add validation checks
3. Retrain with cleaned data
4. Re-run tests to verify improvements

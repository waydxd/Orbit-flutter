"""
Analyze recurrence patterns in training data

This script analyzes the distribution of recurrence types in the training dataset
and provides insights into the variety and frequency of recurrence patterns.

Usage:
    python analyze_recurrence_data.py
"""

import json
from collections import Counter
import sys


def analyze_recurrence():
    """Analyze recurrence distribution in the expanded event dataset."""
    
    print("=" * 70)
    print("RECURRENCE DATA ANALYSIS")
    print("=" * 70)
    print()
    
    input_file = 'data/event_text_mapping_expanded.jsonl'
    
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            recurrence_counter = Counter()
            recurrence_phrases = []
            phrase_patterns = Counter()
            total = 0
            
            for line in f:
                line = line.strip()
                if not line:
                    continue
                    
                try:
                    data = json.loads(line)
                    total += 1
                    
                    rec = data['output'].get('recurrence')
                    if rec:
                        recurrence_counter[rec] += 1
                        
                        # Extract the phrase pattern
                        text = data['event_text'].lower()
                        
                        # Collect examples with recurrence keywords
                        if any(keyword in text for keyword in ['every', 'daily', 'weekly', 'monthly', 'each']):
                            recurrence_phrases.append(text)
                            
                            # Categorize by pattern type
                            if 'every' in text:
                                phrase_patterns['every'] += 1
                            if 'each' in text:
                                phrase_patterns['each'] += 1
                            if 'daily' in text:
                                phrase_patterns['daily'] += 1
                            if 'weekly' in text:
                                phrase_patterns['weekly'] += 1
                            if 'monthly' in text:
                                phrase_patterns['monthly'] += 1
                                
                except json.JSONDecodeError:
                    continue
        
        # Print results
        print(f"Total examples: {total}")
        print(f"Examples with recurrence: {sum(recurrence_counter.values())} ({sum(recurrence_counter.values())/total*100:.1f}%)")
        print()
        
        print("Recurrence Type Distribution:")
        print("-" * 70)
        for rec_type, count in recurrence_counter.most_common():
            percentage = (count / total) * 100
            bar_length = int(percentage / 2)  # Scale to 50 chars max
            bar = "█" * bar_length
            print(f"  {rec_type:12} {count:5} ({percentage:5.1f}%) {bar}")
        print()
        
        print("Phrase Pattern Distribution:")
        print("-" * 70)
        for pattern, count in phrase_patterns.most_common():
            percentage = (count / sum(phrase_patterns.values())) * 100
            bar_length = int(percentage / 2)
            bar = "█" * bar_length
            print(f"  {pattern:12} {count:5} ({percentage:5.1f}%) {bar}")
        print()
        
        print("Sample Recurrence Phrases:")
        print("-" * 70)
        for i, phrase in enumerate(recurrence_phrases[:15], 1):
            print(f"  {i:2}. {phrase[:65]}...")
        print()
        
        # Analysis and recommendations
        print("Analysis:")
        print("-" * 70)
        
        total_recurrence = sum(recurrence_counter.values())
        recurrence_percentage = (total_recurrence / total) * 100
        
        if recurrence_percentage < 30:
            print(f"  ⚠️  Low recurrence coverage ({recurrence_percentage:.1f}%)")
            print(f"     Recommend increasing to 50%+ for better model performance")
        elif recurrence_percentage < 50:
            print(f"  🟡 Moderate recurrence coverage ({recurrence_percentage:.1f}%)")
            print(f"     Consider adding more examples to reach 50%+")
        else:
            print(f"  ✅ Good recurrence coverage ({recurrence_percentage:.1f}%)")
        
        print()
        
        # Check balance across types
        if len(recurrence_counter) > 0:
            max_count = recurrence_counter.most_common(1)[0][1]
            min_count = recurrence_counter.most_common()[-1][1]
            ratio = max_count / min_count if min_count > 0 else float('inf')
            
            if ratio > 5:
                print(f"  ⚠️  Imbalanced distribution (ratio: {ratio:.1f}:1)")
                print(f"     Underrepresented types should be increased")
            else:
                print(f"  ✅ Balanced distribution (ratio: {ratio:.1f}:1)")
        
        print()
        print("=" * 70)
        
    except FileNotFoundError:
        print(f"❌ Error: File not found: {input_file}")
        print(f"   Please ensure you're running from the nlp-server directory")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    analyze_recurrence()

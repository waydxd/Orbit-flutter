/// Model for hashtag prediction response from the API
class HashtagPrediction {
  final List<String> suggested;
  final List<HashtagScore> top5;

  HashtagPrediction({required this.suggested, required this.top5});

  factory HashtagPrediction.fromJson(Map<String, dynamic> json) {
    return HashtagPrediction(
      suggested: List<String>.from(json['suggested'] ?? []),
      top5:
          (json['top_5'] as List?)
              ?.map((e) => HashtagScore.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'suggested': suggested,
      'top_5': top5.map((e) => e.toJson()).toList(),
    };
  }
}

/// Model for individual hashtag with confidence score
class HashtagScore {
  final String hashtag;
  final double confidence;

  HashtagScore({required this.hashtag, required this.confidence});

  factory HashtagScore.fromJson(Map<String, dynamic> json) {
    return HashtagScore(
      hashtag: json['hashtag'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'hashtag': hashtag, 'confidence': confidence};
  }
}

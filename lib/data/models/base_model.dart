import 'package:equatable/equatable.dart';

/// Base model class for all data models
abstract class BaseModel extends Equatable {
  const BaseModel();
  
  /// Convert model to JSON
  Map<String, dynamic> toJson();
  
  /// Create model from JSON
  static BaseModel fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('fromJson must be implemented by subclasses');
  }
}
/// Base repository interface for common CRUD operations
abstract class BaseRepository<T> {
  /// Get all items
  Future<List<T>> getAll();
  
  /// Get item by ID
  Future<T?> getById(String id);
  
  /// Create new item
  Future<T> create(T item);
  
  /// Update existing item
  Future<T> update(String id, T item);
  
  /// Delete item by ID
  Future<void> delete(String id);
  
  /// Check if item exists
  Future<bool> exists(String id);
}
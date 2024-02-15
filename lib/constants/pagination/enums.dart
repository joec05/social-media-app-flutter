/// Enum which stores pagination status. Specifically for pagination only
enum PaginationStatus{
  loading, error, loaded
}

/// Enum which stores loading status. Includes loading (when a page loads for the first time), 
/// paginating and refreshing values
enum LoadingState{
  loaded, loading, paginating, refreshing
}
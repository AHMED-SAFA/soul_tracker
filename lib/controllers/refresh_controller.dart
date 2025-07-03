class RefreshController {
  bool _isRefreshing = false;

  bool get isRefreshing => _isRefreshing;

  void refreshCompleted() {
    _isRefreshing = false;
  }

  void refreshFailed() {
    _isRefreshing = false;
  }

  void dispose() {
    refreshCompleted();
  }
}

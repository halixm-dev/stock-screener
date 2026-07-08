class CacheEntry<T> {
  final T data;
  final DateTime createdAt;

  const CacheEntry({required this.data, required this.createdAt});

  bool isExpired(Duration ttl) {
    return DateTime.now().difference(createdAt) > ttl;
  }

  Map<String, dynamic> toMap() {
    return {'data': data, 'createdAt': createdAt.toIso8601String()};
  }

  factory CacheEntry.fromMap(
    Map<dynamic, dynamic> map,
    T Function(dynamic) dataParser,
  ) {
    return CacheEntry(
      data: dataParser(map['data']),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

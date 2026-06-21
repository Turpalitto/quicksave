import 'package:uuid/uuid.dart';

/// User-defined collection of saved media items.
class MediaCollection {
  const MediaCollection({
    required this.id,
    required this.name,
    required this.itemIds,
    required this.createdAt,
  });

  final String id;
  final String name;
  final List<String> itemIds;
  final DateTime createdAt;

  MediaCollection copyWith({
    String? name,
    List<String>? itemIds,
  }) =>
      MediaCollection(
        id: id,
        name: name ?? this.name,
        itemIds: itemIds ?? this.itemIds,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'itemIds': itemIds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory MediaCollection.fromJson(Map<String, dynamic> json) =>
      MediaCollection(
        id: json['id'] as String,
        name: json['name'] as String,
        itemIds: (json['itemIds'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  factory MediaCollection.create(String name) => MediaCollection(
        id: const Uuid().v4(),
        name: name,
        itemIds: const [],
        createdAt: DateTime.now(),
      );
}

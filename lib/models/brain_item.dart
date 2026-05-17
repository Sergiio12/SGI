/// Clase base para todos los items del segundo cerebro
abstract class BrainItem {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;

  BrainItem({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
  });

  Map<String, dynamic> toJson();
}

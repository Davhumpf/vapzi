class Client {
  final int? id;
  final String name;
  final String phone;
  const Client({this.id, required this.name, required this.phone});
  Map<String, Object?> toMap() => {'id': id, 'name': name, 'phone': phone};
  factory Client.fromMap(Map<String, Object?> map) => Client(
    id: map['id'] as int?,
    name: map['name'] as String,
    phone: map['phone'] as String,
  );
}

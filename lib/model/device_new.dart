import 'package:hive/hive.dart';

@HiveType(typeId: 5)
class Device extends HiveObject {
  @HiveField(0)
  late String id;
  
  @HiveField(1)
  late String name;
  
  @HiveField(2)
  late String description;
  
  @HiveField(3)
  late String image;
  
  @HiveField(4)
  late bool isAvailable;
  
  @HiveField(5)
  late int totalQuantity;

  Device({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.isAvailable,
    required this.totalQuantity,
  });

  Device.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    name = json['name'] ?? '';
    description = json['description'] ?? '';
    image = json['image'] ?? '';
    isAvailable = json['is_available'] ?? false;
    totalQuantity = json['total_quantity'] ?? 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'is_available': isAvailable,
      'total_quantity': totalQuantity,
    };
  }

  static List<Device> devicesFromJson(List<dynamic> jsonList) {
    return jsonList.map((json) => Device.fromJson(json)).toList();
  }
}

class DeviceAdapter extends TypeAdapter<Device> {
  @override
  final int typeId = 5;

  @override
  Device read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Device(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      image: fields[3] as String,
      isAvailable: fields[4] as bool,
      totalQuantity: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Device obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.image)
      ..writeByte(4)
      ..write(obj.isAvailable)
      ..writeByte(5)
      ..write(obj.totalQuantity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

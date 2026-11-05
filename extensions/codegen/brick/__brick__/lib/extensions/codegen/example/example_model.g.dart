// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExampleModel _$ExampleModelFromJson(Map<String, dynamic> json) =>
    _ExampleModel(
      id: json['id'] as String,
      itemCount: (json['item_count'] as num).toInt(),
      createdAt: const NullableEpochDateTimeConverter().fromJson(
        (json['created_at'] as num?)?.toInt(),
      ),
      link: const UriStringConverter().fromJson(json['link'] as String?),
    );

Map<String, dynamic> _$ExampleModelToJson(_ExampleModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'item_count': instance.itemCount,
      'created_at': const NullableEpochDateTimeConverter().toJson(
        instance.createdAt,
      ),
      'link': const UriStringConverter().toJson(instance.link),
    };

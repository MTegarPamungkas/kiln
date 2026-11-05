// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'example_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExampleModel {

 String get id; int get itemCount;@NullableEpochDateTimeConverter() DateTime? get createdAt;@UriStringConverter() Uri? get link;
/// Create a copy of ExampleModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExampleModelCopyWith<ExampleModel> get copyWith => _$ExampleModelCopyWithImpl<ExampleModel>(this as ExampleModel, _$identity);

  /// Serializes this ExampleModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ExampleModel;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExampleModel&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.itemCount, _this.itemCount) || other.itemCount == _this.itemCount)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.link, _this.link) || other.link == _this.link));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ExampleModel;
  return Object.hash(runtimeType,_this.id,_this.itemCount,_this.createdAt,_this.link);
}

@override
String toString() {
  final _this = this as ExampleModel;
  return 'ExampleModel(id: ${_this.id}, itemCount: ${_this.itemCount}, createdAt: ${_this.createdAt}, link: ${_this.link})';
}


}

/// @nodoc
abstract mixin class $ExampleModelCopyWith<$Res>  {
  factory $ExampleModelCopyWith(ExampleModel value, $Res Function(ExampleModel) _then) = _$ExampleModelCopyWithImpl;
@useResult
$Res call({
 String id, int itemCount,@NullableEpochDateTimeConverter() DateTime? createdAt,@UriStringConverter() Uri? link
});




}
/// @nodoc
class _$ExampleModelCopyWithImpl<$Res>
    implements $ExampleModelCopyWith<$Res> {
  _$ExampleModelCopyWithImpl(this._self, this._then);

  final ExampleModel _self;
  final $Res Function(ExampleModel) _then;

/// Create a copy of ExampleModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? itemCount = null,Object? createdAt = freezed,Object? link = freezed,}) {
  return _then(ExampleModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,itemCount: null == itemCount ? _self.itemCount : itemCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,link: freezed == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as Uri?,
  ));
}

}


/// Adds pattern-matching-related methods to [ExampleModel].
extension ExampleModelPatterns on ExampleModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExampleModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExampleModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExampleModel value)  $default,){
final _that = this;
switch (_that) {
case _ExampleModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExampleModel value)?  $default,){
final _that = this;
switch (_that) {
case _ExampleModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int itemCount, @NullableEpochDateTimeConverter()  DateTime? createdAt, @UriStringConverter()  Uri? link)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExampleModel() when $default != null:
return $default(_that.id,_that.itemCount,_that.createdAt,_that.link);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int itemCount, @NullableEpochDateTimeConverter()  DateTime? createdAt, @UriStringConverter()  Uri? link)  $default,) {final _that = this;
switch (_that) {
case _ExampleModel():
return $default(_that.id,_that.itemCount,_that.createdAt,_that.link);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int itemCount, @NullableEpochDateTimeConverter()  DateTime? createdAt, @UriStringConverter()  Uri? link)?  $default,) {final _that = this;
switch (_that) {
case _ExampleModel() when $default != null:
return $default(_that.id,_that.itemCount,_that.createdAt,_that.link);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExampleModel implements ExampleModel {
  const _ExampleModel({required this.id, required this.itemCount, @NullableEpochDateTimeConverter() this.createdAt, @UriStringConverter() this.link});
  factory _ExampleModel.fromJson(Map<String, dynamic> json) => _$ExampleModelFromJson(json);

@override final  String id;
@override final  int itemCount;
@override@NullableEpochDateTimeConverter() final  DateTime? createdAt;
@override@UriStringConverter() final  Uri? link;

/// Create a copy of ExampleModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExampleModelCopyWith<_ExampleModel> get copyWith => __$ExampleModelCopyWithImpl<_ExampleModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExampleModelToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExampleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.itemCount, itemCount) || other.itemCount == itemCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.link, link) || other.link == link));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,itemCount,createdAt,link);
}

@override
String toString() {
    return 'ExampleModel(id: $id, itemCount: $itemCount, createdAt: $createdAt, link: $link)';
}


}

/// @nodoc
abstract mixin class _$ExampleModelCopyWith<$Res> implements $ExampleModelCopyWith<$Res> {
  factory _$ExampleModelCopyWith(_ExampleModel value, $Res Function(_ExampleModel) _then) = __$ExampleModelCopyWithImpl;
@override @useResult
$Res call({
 String id, int itemCount,@NullableEpochDateTimeConverter() DateTime? createdAt,@UriStringConverter() Uri? link
});




}
/// @nodoc
class __$ExampleModelCopyWithImpl<$Res>
    implements _$ExampleModelCopyWith<$Res> {
  __$ExampleModelCopyWithImpl(this._self, this._then);

  final _ExampleModel _self;
  final $Res Function(_ExampleModel) _then;

/// Create a copy of ExampleModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? itemCount = null,Object? createdAt = freezed,Object? link = freezed,}) {
  return _then(_ExampleModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,itemCount: null == itemCount ? _self.itemCount : itemCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,link: freezed == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as Uri?,
  ));
}


}

// dart format on

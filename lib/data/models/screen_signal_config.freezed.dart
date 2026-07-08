// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'screen_signal_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScreenSignalConfig {

 String get leadingIndicator; List<String> get confirmations; Map<String, Map<String, dynamic>> get parameters;
/// Create a copy of ScreenSignalConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScreenSignalConfigCopyWith<ScreenSignalConfig> get copyWith => _$ScreenSignalConfigCopyWithImpl<ScreenSignalConfig>(this as ScreenSignalConfig, _$identity);

  /// Serializes this ScreenSignalConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScreenSignalConfig&&(identical(other.leadingIndicator, leadingIndicator) || other.leadingIndicator == leadingIndicator)&&const DeepCollectionEquality().equals(other.confirmations, confirmations)&&const DeepCollectionEquality().equals(other.parameters, parameters));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,leadingIndicator,const DeepCollectionEquality().hash(confirmations),const DeepCollectionEquality().hash(parameters));

@override
String toString() {
  return 'ScreenSignalConfig(leadingIndicator: $leadingIndicator, confirmations: $confirmations, parameters: $parameters)';
}


}

/// @nodoc
abstract mixin class $ScreenSignalConfigCopyWith<$Res>  {
  factory $ScreenSignalConfigCopyWith(ScreenSignalConfig value, $Res Function(ScreenSignalConfig) _then) = _$ScreenSignalConfigCopyWithImpl;
@useResult
$Res call({
 String leadingIndicator, List<String> confirmations, Map<String, Map<String, dynamic>> parameters
});




}
/// @nodoc
class _$ScreenSignalConfigCopyWithImpl<$Res>
    implements $ScreenSignalConfigCopyWith<$Res> {
  _$ScreenSignalConfigCopyWithImpl(this._self, this._then);

  final ScreenSignalConfig _self;
  final $Res Function(ScreenSignalConfig) _then;

/// Create a copy of ScreenSignalConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? leadingIndicator = null,Object? confirmations = null,Object? parameters = null,}) {
  return _then(_self.copyWith(
leadingIndicator: null == leadingIndicator ? _self.leadingIndicator : leadingIndicator // ignore: cast_nullable_to_non_nullable
as String,confirmations: null == confirmations ? _self.confirmations : confirmations // ignore: cast_nullable_to_non_nullable
as List<String>,parameters: null == parameters ? _self.parameters : parameters // ignore: cast_nullable_to_non_nullable
as Map<String, Map<String, dynamic>>,
  ));
}

}


/// Adds pattern-matching-related methods to [ScreenSignalConfig].
extension ScreenSignalConfigPatterns on ScreenSignalConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScreenSignalConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScreenSignalConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScreenSignalConfig value)  $default,){
final _that = this;
switch (_that) {
case _ScreenSignalConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScreenSignalConfig value)?  $default,){
final _that = this;
switch (_that) {
case _ScreenSignalConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String leadingIndicator,  List<String> confirmations,  Map<String, Map<String, dynamic>> parameters)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScreenSignalConfig() when $default != null:
return $default(_that.leadingIndicator,_that.confirmations,_that.parameters);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String leadingIndicator,  List<String> confirmations,  Map<String, Map<String, dynamic>> parameters)  $default,) {final _that = this;
switch (_that) {
case _ScreenSignalConfig():
return $default(_that.leadingIndicator,_that.confirmations,_that.parameters);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String leadingIndicator,  List<String> confirmations,  Map<String, Map<String, dynamic>> parameters)?  $default,) {final _that = this;
switch (_that) {
case _ScreenSignalConfig() when $default != null:
return $default(_that.leadingIndicator,_that.confirmations,_that.parameters);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScreenSignalConfig extends ScreenSignalConfig {
  const _ScreenSignalConfig({this.leadingIndicator = 'Range Filter', final  List<String> confirmations = const [], final  Map<String, Map<String, dynamic>> parameters = const {}}): _confirmations = confirmations,_parameters = parameters,super._();
  factory _ScreenSignalConfig.fromJson(Map<String, dynamic> json) => _$ScreenSignalConfigFromJson(json);

@override@JsonKey() final  String leadingIndicator;
 final  List<String> _confirmations;
@override@JsonKey() List<String> get confirmations {
  if (_confirmations is EqualUnmodifiableListView) return _confirmations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_confirmations);
}

 final  Map<String, Map<String, dynamic>> _parameters;
@override@JsonKey() Map<String, Map<String, dynamic>> get parameters {
  if (_parameters is EqualUnmodifiableMapView) return _parameters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_parameters);
}


/// Create a copy of ScreenSignalConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScreenSignalConfigCopyWith<_ScreenSignalConfig> get copyWith => __$ScreenSignalConfigCopyWithImpl<_ScreenSignalConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScreenSignalConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScreenSignalConfig&&(identical(other.leadingIndicator, leadingIndicator) || other.leadingIndicator == leadingIndicator)&&const DeepCollectionEquality().equals(other._confirmations, _confirmations)&&const DeepCollectionEquality().equals(other._parameters, _parameters));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,leadingIndicator,const DeepCollectionEquality().hash(_confirmations),const DeepCollectionEquality().hash(_parameters));

@override
String toString() {
  return 'ScreenSignalConfig(leadingIndicator: $leadingIndicator, confirmations: $confirmations, parameters: $parameters)';
}


}

/// @nodoc
abstract mixin class _$ScreenSignalConfigCopyWith<$Res> implements $ScreenSignalConfigCopyWith<$Res> {
  factory _$ScreenSignalConfigCopyWith(_ScreenSignalConfig value, $Res Function(_ScreenSignalConfig) _then) = __$ScreenSignalConfigCopyWithImpl;
@override @useResult
$Res call({
 String leadingIndicator, List<String> confirmations, Map<String, Map<String, dynamic>> parameters
});




}
/// @nodoc
class __$ScreenSignalConfigCopyWithImpl<$Res>
    implements _$ScreenSignalConfigCopyWith<$Res> {
  __$ScreenSignalConfigCopyWithImpl(this._self, this._then);

  final _ScreenSignalConfig _self;
  final $Res Function(_ScreenSignalConfig) _then;

/// Create a copy of ScreenSignalConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? leadingIndicator = null,Object? confirmations = null,Object? parameters = null,}) {
  return _then(_ScreenSignalConfig(
leadingIndicator: null == leadingIndicator ? _self.leadingIndicator : leadingIndicator // ignore: cast_nullable_to_non_nullable
as String,confirmations: null == confirmations ? _self._confirmations : confirmations // ignore: cast_nullable_to_non_nullable
as List<String>,parameters: null == parameters ? _self._parameters : parameters // ignore: cast_nullable_to_non_nullable
as Map<String, Map<String, dynamic>>,
  ));
}


}

// dart format on

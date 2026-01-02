// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'connect_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ConnectState {

 ConnectFlowState get flowState; String? get myInviteCode; String? get errorMessage; bool get isProcessing;
/// Create a copy of ConnectState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConnectStateCopyWith<ConnectState> get copyWith => _$ConnectStateCopyWithImpl<ConnectState>(this as ConnectState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConnectState&&(identical(other.flowState, flowState) || other.flowState == flowState)&&(identical(other.myInviteCode, myInviteCode) || other.myInviteCode == myInviteCode)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.isProcessing, isProcessing) || other.isProcessing == isProcessing));
}


@override
int get hashCode => Object.hash(runtimeType,flowState,myInviteCode,errorMessage,isProcessing);

@override
String toString() {
  return 'ConnectState(flowState: $flowState, myInviteCode: $myInviteCode, errorMessage: $errorMessage, isProcessing: $isProcessing)';
}


}

/// @nodoc
abstract mixin class $ConnectStateCopyWith<$Res>  {
  factory $ConnectStateCopyWith(ConnectState value, $Res Function(ConnectState) _then) = _$ConnectStateCopyWithImpl;
@useResult
$Res call({
 ConnectFlowState flowState, String? myInviteCode, String? errorMessage, bool isProcessing
});




}
/// @nodoc
class _$ConnectStateCopyWithImpl<$Res>
    implements $ConnectStateCopyWith<$Res> {
  _$ConnectStateCopyWithImpl(this._self, this._then);

  final ConnectState _self;
  final $Res Function(ConnectState) _then;

/// Create a copy of ConnectState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? flowState = null,Object? myInviteCode = freezed,Object? errorMessage = freezed,Object? isProcessing = null,}) {
  return _then(_self.copyWith(
flowState: null == flowState ? _self.flowState : flowState // ignore: cast_nullable_to_non_nullable
as ConnectFlowState,myInviteCode: freezed == myInviteCode ? _self.myInviteCode : myInviteCode // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,isProcessing: null == isProcessing ? _self.isProcessing : isProcessing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ConnectState].
extension ConnectStatePatterns on ConnectState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConnectState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConnectState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConnectState value)  $default,){
final _that = this;
switch (_that) {
case _ConnectState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConnectState value)?  $default,){
final _that = this;
switch (_that) {
case _ConnectState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ConnectFlowState flowState,  String? myInviteCode,  String? errorMessage,  bool isProcessing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConnectState() when $default != null:
return $default(_that.flowState,_that.myInviteCode,_that.errorMessage,_that.isProcessing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ConnectFlowState flowState,  String? myInviteCode,  String? errorMessage,  bool isProcessing)  $default,) {final _that = this;
switch (_that) {
case _ConnectState():
return $default(_that.flowState,_that.myInviteCode,_that.errorMessage,_that.isProcessing);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ConnectFlowState flowState,  String? myInviteCode,  String? errorMessage,  bool isProcessing)?  $default,) {final _that = this;
switch (_that) {
case _ConnectState() when $default != null:
return $default(_that.flowState,_that.myInviteCode,_that.errorMessage,_that.isProcessing);case _:
  return null;

}
}

}

/// @nodoc


class _ConnectState implements ConnectState {
  const _ConnectState({this.flowState = ConnectFlowState.initial, this.myInviteCode, this.errorMessage, this.isProcessing = false});
  

@override@JsonKey() final  ConnectFlowState flowState;
@override final  String? myInviteCode;
@override final  String? errorMessage;
@override@JsonKey() final  bool isProcessing;

/// Create a copy of ConnectState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConnectStateCopyWith<_ConnectState> get copyWith => __$ConnectStateCopyWithImpl<_ConnectState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConnectState&&(identical(other.flowState, flowState) || other.flowState == flowState)&&(identical(other.myInviteCode, myInviteCode) || other.myInviteCode == myInviteCode)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.isProcessing, isProcessing) || other.isProcessing == isProcessing));
}


@override
int get hashCode => Object.hash(runtimeType,flowState,myInviteCode,errorMessage,isProcessing);

@override
String toString() {
  return 'ConnectState(flowState: $flowState, myInviteCode: $myInviteCode, errorMessage: $errorMessage, isProcessing: $isProcessing)';
}


}

/// @nodoc
abstract mixin class _$ConnectStateCopyWith<$Res> implements $ConnectStateCopyWith<$Res> {
  factory _$ConnectStateCopyWith(_ConnectState value, $Res Function(_ConnectState) _then) = __$ConnectStateCopyWithImpl;
@override @useResult
$Res call({
 ConnectFlowState flowState, String? myInviteCode, String? errorMessage, bool isProcessing
});




}
/// @nodoc
class __$ConnectStateCopyWithImpl<$Res>
    implements _$ConnectStateCopyWith<$Res> {
  __$ConnectStateCopyWithImpl(this._self, this._then);

  final _ConnectState _self;
  final $Res Function(_ConnectState) _then;

/// Create a copy of ConnectState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? flowState = null,Object? myInviteCode = freezed,Object? errorMessage = freezed,Object? isProcessing = null,}) {
  return _then(_ConnectState(
flowState: null == flowState ? _self.flowState : flowState // ignore: cast_nullable_to_non_nullable
as ConnectFlowState,myInviteCode: freezed == myInviteCode ? _self.myInviteCode : myInviteCode // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,isProcessing: null == isProcessing ? _self.isProcessing : isProcessing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

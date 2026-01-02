// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plan_create_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlanCreateState {

 int get currentStep; String get action; int get selectedFrequency; String get description; Set<int> get selectedDays; NotificationTime get notificationTime; bool get isSaving; String? get errorMessage;
/// Create a copy of PlanCreateState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanCreateStateCopyWith<PlanCreateState> get copyWith => _$PlanCreateStateCopyWithImpl<PlanCreateState>(this as PlanCreateState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanCreateState&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.action, action) || other.action == action)&&(identical(other.selectedFrequency, selectedFrequency) || other.selectedFrequency == selectedFrequency)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.selectedDays, selectedDays)&&(identical(other.notificationTime, notificationTime) || other.notificationTime == notificationTime)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,currentStep,action,selectedFrequency,description,const DeepCollectionEquality().hash(selectedDays),notificationTime,isSaving,errorMessage);

@override
String toString() {
  return 'PlanCreateState(currentStep: $currentStep, action: $action, selectedFrequency: $selectedFrequency, description: $description, selectedDays: $selectedDays, notificationTime: $notificationTime, isSaving: $isSaving, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $PlanCreateStateCopyWith<$Res>  {
  factory $PlanCreateStateCopyWith(PlanCreateState value, $Res Function(PlanCreateState) _then) = _$PlanCreateStateCopyWithImpl;
@useResult
$Res call({
 int currentStep, String action, int selectedFrequency, String description, Set<int> selectedDays, NotificationTime notificationTime, bool isSaving, String? errorMessage
});




}
/// @nodoc
class _$PlanCreateStateCopyWithImpl<$Res>
    implements $PlanCreateStateCopyWith<$Res> {
  _$PlanCreateStateCopyWithImpl(this._self, this._then);

  final PlanCreateState _self;
  final $Res Function(PlanCreateState) _then;

/// Create a copy of PlanCreateState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentStep = null,Object? action = null,Object? selectedFrequency = null,Object? description = null,Object? selectedDays = null,Object? notificationTime = null,Object? isSaving = null,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as int,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,selectedFrequency: null == selectedFrequency ? _self.selectedFrequency : selectedFrequency // ignore: cast_nullable_to_non_nullable
as int,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,selectedDays: null == selectedDays ? _self.selectedDays : selectedDays // ignore: cast_nullable_to_non_nullable
as Set<int>,notificationTime: null == notificationTime ? _self.notificationTime : notificationTime // ignore: cast_nullable_to_non_nullable
as NotificationTime,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlanCreateState].
extension PlanCreateStatePatterns on PlanCreateState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanCreateState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanCreateState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanCreateState value)  $default,){
final _that = this;
switch (_that) {
case _PlanCreateState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanCreateState value)?  $default,){
final _that = this;
switch (_that) {
case _PlanCreateState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int currentStep,  String action,  int selectedFrequency,  String description,  Set<int> selectedDays,  NotificationTime notificationTime,  bool isSaving,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanCreateState() when $default != null:
return $default(_that.currentStep,_that.action,_that.selectedFrequency,_that.description,_that.selectedDays,_that.notificationTime,_that.isSaving,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int currentStep,  String action,  int selectedFrequency,  String description,  Set<int> selectedDays,  NotificationTime notificationTime,  bool isSaving,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _PlanCreateState():
return $default(_that.currentStep,_that.action,_that.selectedFrequency,_that.description,_that.selectedDays,_that.notificationTime,_that.isSaving,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int currentStep,  String action,  int selectedFrequency,  String description,  Set<int> selectedDays,  NotificationTime notificationTime,  bool isSaving,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _PlanCreateState() when $default != null:
return $default(_that.currentStep,_that.action,_that.selectedFrequency,_that.description,_that.selectedDays,_that.notificationTime,_that.isSaving,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _PlanCreateState implements PlanCreateState {
  const _PlanCreateState({this.currentStep = 1, this.action = '', this.selectedFrequency = 3, this.description = '', final  Set<int> selectedDays = const {}, required this.notificationTime, this.isSaving = false, this.errorMessage}): _selectedDays = selectedDays;
  

@override@JsonKey() final  int currentStep;
@override@JsonKey() final  String action;
@override@JsonKey() final  int selectedFrequency;
@override@JsonKey() final  String description;
 final  Set<int> _selectedDays;
@override@JsonKey() Set<int> get selectedDays {
  if (_selectedDays is EqualUnmodifiableSetView) return _selectedDays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_selectedDays);
}

@override final  NotificationTime notificationTime;
@override@JsonKey() final  bool isSaving;
@override final  String? errorMessage;

/// Create a copy of PlanCreateState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanCreateStateCopyWith<_PlanCreateState> get copyWith => __$PlanCreateStateCopyWithImpl<_PlanCreateState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanCreateState&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.action, action) || other.action == action)&&(identical(other.selectedFrequency, selectedFrequency) || other.selectedFrequency == selectedFrequency)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._selectedDays, _selectedDays)&&(identical(other.notificationTime, notificationTime) || other.notificationTime == notificationTime)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,currentStep,action,selectedFrequency,description,const DeepCollectionEquality().hash(_selectedDays),notificationTime,isSaving,errorMessage);

@override
String toString() {
  return 'PlanCreateState(currentStep: $currentStep, action: $action, selectedFrequency: $selectedFrequency, description: $description, selectedDays: $selectedDays, notificationTime: $notificationTime, isSaving: $isSaving, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$PlanCreateStateCopyWith<$Res> implements $PlanCreateStateCopyWith<$Res> {
  factory _$PlanCreateStateCopyWith(_PlanCreateState value, $Res Function(_PlanCreateState) _then) = __$PlanCreateStateCopyWithImpl;
@override @useResult
$Res call({
 int currentStep, String action, int selectedFrequency, String description, Set<int> selectedDays, NotificationTime notificationTime, bool isSaving, String? errorMessage
});




}
/// @nodoc
class __$PlanCreateStateCopyWithImpl<$Res>
    implements _$PlanCreateStateCopyWith<$Res> {
  __$PlanCreateStateCopyWithImpl(this._self, this._then);

  final _PlanCreateState _self;
  final $Res Function(_PlanCreateState) _then;

/// Create a copy of PlanCreateState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentStep = null,Object? action = null,Object? selectedFrequency = null,Object? description = null,Object? selectedDays = null,Object? notificationTime = null,Object? isSaving = null,Object? errorMessage = freezed,}) {
  return _then(_PlanCreateState(
currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as int,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,selectedFrequency: null == selectedFrequency ? _self.selectedFrequency : selectedFrequency // ignore: cast_nullable_to_non_nullable
as int,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,selectedDays: null == selectedDays ? _self._selectedDays : selectedDays // ignore: cast_nullable_to_non_nullable
as Set<int>,notificationTime: null == notificationTime ? _self.notificationTime : notificationTime // ignore: cast_nullable_to_non_nullable
as NotificationTime,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

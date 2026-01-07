// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'history_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HistoryState {

 List<HistoryItem> get activeItems; List<PlanSummary> get finishedPlanSummaries; bool get isLoading; HistoryFilter get filter;
/// Create a copy of HistoryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HistoryStateCopyWith<HistoryState> get copyWith => _$HistoryStateCopyWithImpl<HistoryState>(this as HistoryState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryState&&const DeepCollectionEquality().equals(other.activeItems, activeItems)&&const DeepCollectionEquality().equals(other.finishedPlanSummaries, finishedPlanSummaries)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.filter, filter) || other.filter == filter));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(activeItems),const DeepCollectionEquality().hash(finishedPlanSummaries),isLoading,filter);

@override
String toString() {
  return 'HistoryState(activeItems: $activeItems, finishedPlanSummaries: $finishedPlanSummaries, isLoading: $isLoading, filter: $filter)';
}


}

/// @nodoc
abstract mixin class $HistoryStateCopyWith<$Res>  {
  factory $HistoryStateCopyWith(HistoryState value, $Res Function(HistoryState) _then) = _$HistoryStateCopyWithImpl;
@useResult
$Res call({
 List<HistoryItem> activeItems, List<PlanSummary> finishedPlanSummaries, bool isLoading, HistoryFilter filter
});




}
/// @nodoc
class _$HistoryStateCopyWithImpl<$Res>
    implements $HistoryStateCopyWith<$Res> {
  _$HistoryStateCopyWithImpl(this._self, this._then);

  final HistoryState _self;
  final $Res Function(HistoryState) _then;

/// Create a copy of HistoryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? activeItems = null,Object? finishedPlanSummaries = null,Object? isLoading = null,Object? filter = null,}) {
  return _then(_self.copyWith(
activeItems: null == activeItems ? _self.activeItems : activeItems // ignore: cast_nullable_to_non_nullable
as List<HistoryItem>,finishedPlanSummaries: null == finishedPlanSummaries ? _self.finishedPlanSummaries : finishedPlanSummaries // ignore: cast_nullable_to_non_nullable
as List<PlanSummary>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as HistoryFilter,
  ));
}

}


/// Adds pattern-matching-related methods to [HistoryState].
extension HistoryStatePatterns on HistoryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HistoryState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HistoryState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HistoryState value)  $default,){
final _that = this;
switch (_that) {
case _HistoryState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HistoryState value)?  $default,){
final _that = this;
switch (_that) {
case _HistoryState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<HistoryItem> activeItems,  List<PlanSummary> finishedPlanSummaries,  bool isLoading,  HistoryFilter filter)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HistoryState() when $default != null:
return $default(_that.activeItems,_that.finishedPlanSummaries,_that.isLoading,_that.filter);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<HistoryItem> activeItems,  List<PlanSummary> finishedPlanSummaries,  bool isLoading,  HistoryFilter filter)  $default,) {final _that = this;
switch (_that) {
case _HistoryState():
return $default(_that.activeItems,_that.finishedPlanSummaries,_that.isLoading,_that.filter);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<HistoryItem> activeItems,  List<PlanSummary> finishedPlanSummaries,  bool isLoading,  HistoryFilter filter)?  $default,) {final _that = this;
switch (_that) {
case _HistoryState() when $default != null:
return $default(_that.activeItems,_that.finishedPlanSummaries,_that.isLoading,_that.filter);case _:
  return null;

}
}

}

/// @nodoc


class _HistoryState extends HistoryState {
  const _HistoryState({final  List<HistoryItem> activeItems = const [], final  List<PlanSummary> finishedPlanSummaries = const [], this.isLoading = false, this.filter = HistoryFilter.all}): _activeItems = activeItems,_finishedPlanSummaries = finishedPlanSummaries,super._();
  

 final  List<HistoryItem> _activeItems;
@override@JsonKey() List<HistoryItem> get activeItems {
  if (_activeItems is EqualUnmodifiableListView) return _activeItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activeItems);
}

 final  List<PlanSummary> _finishedPlanSummaries;
@override@JsonKey() List<PlanSummary> get finishedPlanSummaries {
  if (_finishedPlanSummaries is EqualUnmodifiableListView) return _finishedPlanSummaries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_finishedPlanSummaries);
}

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  HistoryFilter filter;

/// Create a copy of HistoryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HistoryStateCopyWith<_HistoryState> get copyWith => __$HistoryStateCopyWithImpl<_HistoryState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HistoryState&&const DeepCollectionEquality().equals(other._activeItems, _activeItems)&&const DeepCollectionEquality().equals(other._finishedPlanSummaries, _finishedPlanSummaries)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.filter, filter) || other.filter == filter));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_activeItems),const DeepCollectionEquality().hash(_finishedPlanSummaries),isLoading,filter);

@override
String toString() {
  return 'HistoryState(activeItems: $activeItems, finishedPlanSummaries: $finishedPlanSummaries, isLoading: $isLoading, filter: $filter)';
}


}

/// @nodoc
abstract mixin class _$HistoryStateCopyWith<$Res> implements $HistoryStateCopyWith<$Res> {
  factory _$HistoryStateCopyWith(_HistoryState value, $Res Function(_HistoryState) _then) = __$HistoryStateCopyWithImpl;
@override @useResult
$Res call({
 List<HistoryItem> activeItems, List<PlanSummary> finishedPlanSummaries, bool isLoading, HistoryFilter filter
});




}
/// @nodoc
class __$HistoryStateCopyWithImpl<$Res>
    implements _$HistoryStateCopyWith<$Res> {
  __$HistoryStateCopyWithImpl(this._self, this._then);

  final _HistoryState _self;
  final $Res Function(_HistoryState) _then;

/// Create a copy of HistoryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? activeItems = null,Object? finishedPlanSummaries = null,Object? isLoading = null,Object? filter = null,}) {
  return _then(_HistoryState(
activeItems: null == activeItems ? _self._activeItems : activeItems // ignore: cast_nullable_to_non_nullable
as List<HistoryItem>,finishedPlanSummaries: null == finishedPlanSummaries ? _self._finishedPlanSummaries : finishedPlanSummaries // ignore: cast_nullable_to_non_nullable
as List<PlanSummary>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as HistoryFilter,
  ));
}


}

/// @nodoc
mixin _$HistoryIntent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryIntent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HistoryIntent()';
}


}

/// @nodoc
class $HistoryIntentCopyWith<$Res>  {
$HistoryIntentCopyWith(HistoryIntent _, $Res Function(HistoryIntent) __);
}


/// Adds pattern-matching-related methods to [HistoryIntent].
extension HistoryIntentPatterns on HistoryIntent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RefreshIntent value)?  refresh,TResult Function( ReconcileIntent value)?  reconcile,TResult Function( SetFilterIntent value)?  setFilter,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RefreshIntent() when refresh != null:
return refresh(_that);case ReconcileIntent() when reconcile != null:
return reconcile(_that);case SetFilterIntent() when setFilter != null:
return setFilter(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RefreshIntent value)  refresh,required TResult Function( ReconcileIntent value)  reconcile,required TResult Function( SetFilterIntent value)  setFilter,}){
final _that = this;
switch (_that) {
case RefreshIntent():
return refresh(_that);case ReconcileIntent():
return reconcile(_that);case SetFilterIntent():
return setFilter(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RefreshIntent value)?  refresh,TResult? Function( ReconcileIntent value)?  reconcile,TResult? Function( SetFilterIntent value)?  setFilter,}){
final _that = this;
switch (_that) {
case RefreshIntent() when refresh != null:
return refresh(_that);case ReconcileIntent() when reconcile != null:
return reconcile(_that);case SetFilterIntent() when setFilter != null:
return setFilter(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  refresh,TResult Function( String historyId,  HistoryStatus status)?  reconcile,TResult Function( HistoryFilter filter)?  setFilter,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RefreshIntent() when refresh != null:
return refresh();case ReconcileIntent() when reconcile != null:
return reconcile(_that.historyId,_that.status);case SetFilterIntent() when setFilter != null:
return setFilter(_that.filter);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  refresh,required TResult Function( String historyId,  HistoryStatus status)  reconcile,required TResult Function( HistoryFilter filter)  setFilter,}) {final _that = this;
switch (_that) {
case RefreshIntent():
return refresh();case ReconcileIntent():
return reconcile(_that.historyId,_that.status);case SetFilterIntent():
return setFilter(_that.filter);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  refresh,TResult? Function( String historyId,  HistoryStatus status)?  reconcile,TResult? Function( HistoryFilter filter)?  setFilter,}) {final _that = this;
switch (_that) {
case RefreshIntent() when refresh != null:
return refresh();case ReconcileIntent() when reconcile != null:
return reconcile(_that.historyId,_that.status);case SetFilterIntent() when setFilter != null:
return setFilter(_that.filter);case _:
  return null;

}
}

}

/// @nodoc


class RefreshIntent implements HistoryIntent {
  const RefreshIntent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RefreshIntent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HistoryIntent.refresh()';
}


}




/// @nodoc


class ReconcileIntent implements HistoryIntent {
  const ReconcileIntent(this.historyId, this.status);
  

 final  String historyId;
 final  HistoryStatus status;

/// Create a copy of HistoryIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReconcileIntentCopyWith<ReconcileIntent> get copyWith => _$ReconcileIntentCopyWithImpl<ReconcileIntent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReconcileIntent&&(identical(other.historyId, historyId) || other.historyId == historyId)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,historyId,status);

@override
String toString() {
  return 'HistoryIntent.reconcile(historyId: $historyId, status: $status)';
}


}

/// @nodoc
abstract mixin class $ReconcileIntentCopyWith<$Res> implements $HistoryIntentCopyWith<$Res> {
  factory $ReconcileIntentCopyWith(ReconcileIntent value, $Res Function(ReconcileIntent) _then) = _$ReconcileIntentCopyWithImpl;
@useResult
$Res call({
 String historyId, HistoryStatus status
});




}
/// @nodoc
class _$ReconcileIntentCopyWithImpl<$Res>
    implements $ReconcileIntentCopyWith<$Res> {
  _$ReconcileIntentCopyWithImpl(this._self, this._then);

  final ReconcileIntent _self;
  final $Res Function(ReconcileIntent) _then;

/// Create a copy of HistoryIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? historyId = null,Object? status = null,}) {
  return _then(ReconcileIntent(
null == historyId ? _self.historyId : historyId // ignore: cast_nullable_to_non_nullable
as String,null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as HistoryStatus,
  ));
}


}

/// @nodoc


class SetFilterIntent implements HistoryIntent {
  const SetFilterIntent(this.filter);
  

 final  HistoryFilter filter;

/// Create a copy of HistoryIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetFilterIntentCopyWith<SetFilterIntent> get copyWith => _$SetFilterIntentCopyWithImpl<SetFilterIntent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetFilterIntent&&(identical(other.filter, filter) || other.filter == filter));
}


@override
int get hashCode => Object.hash(runtimeType,filter);

@override
String toString() {
  return 'HistoryIntent.setFilter(filter: $filter)';
}


}

/// @nodoc
abstract mixin class $SetFilterIntentCopyWith<$Res> implements $HistoryIntentCopyWith<$Res> {
  factory $SetFilterIntentCopyWith(SetFilterIntent value, $Res Function(SetFilterIntent) _then) = _$SetFilterIntentCopyWithImpl;
@useResult
$Res call({
 HistoryFilter filter
});




}
/// @nodoc
class _$SetFilterIntentCopyWithImpl<$Res>
    implements $SetFilterIntentCopyWith<$Res> {
  _$SetFilterIntentCopyWithImpl(this._self, this._then);

  final SetFilterIntent _self;
  final $Res Function(SetFilterIntent) _then;

/// Create a copy of HistoryIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? filter = null,}) {
  return _then(SetFilterIntent(
null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as HistoryFilter,
  ));
}


}

// dart format on

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

 List<HistoryItem> get items; HistoryFilterType get currentFilter; bool get isLoading;
/// Create a copy of HistoryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HistoryStateCopyWith<HistoryState> get copyWith => _$HistoryStateCopyWithImpl<HistoryState>(this as HistoryState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryState&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.currentFilter, currentFilter) || other.currentFilter == currentFilter)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),currentFilter,isLoading);

@override
String toString() {
  return 'HistoryState(items: $items, currentFilter: $currentFilter, isLoading: $isLoading)';
}


}

/// @nodoc
abstract mixin class $HistoryStateCopyWith<$Res>  {
  factory $HistoryStateCopyWith(HistoryState value, $Res Function(HistoryState) _then) = _$HistoryStateCopyWithImpl;
@useResult
$Res call({
 List<HistoryItem> items, HistoryFilterType currentFilter, bool isLoading
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
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? currentFilter = null,Object? isLoading = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<HistoryItem>,currentFilter: null == currentFilter ? _self.currentFilter : currentFilter // ignore: cast_nullable_to_non_nullable
as HistoryFilterType,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<HistoryItem> items,  HistoryFilterType currentFilter,  bool isLoading)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HistoryState() when $default != null:
return $default(_that.items,_that.currentFilter,_that.isLoading);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<HistoryItem> items,  HistoryFilterType currentFilter,  bool isLoading)  $default,) {final _that = this;
switch (_that) {
case _HistoryState():
return $default(_that.items,_that.currentFilter,_that.isLoading);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<HistoryItem> items,  HistoryFilterType currentFilter,  bool isLoading)?  $default,) {final _that = this;
switch (_that) {
case _HistoryState() when $default != null:
return $default(_that.items,_that.currentFilter,_that.isLoading);case _:
  return null;

}
}

}

/// @nodoc


class _HistoryState extends HistoryState {
  const _HistoryState({final  List<HistoryItem> items = const [], this.currentFilter = HistoryFilterType.all, this.isLoading = false}): _items = items,super._();
  

 final  List<HistoryItem> _items;
@override@JsonKey() List<HistoryItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  HistoryFilterType currentFilter;
@override@JsonKey() final  bool isLoading;

/// Create a copy of HistoryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HistoryStateCopyWith<_HistoryState> get copyWith => __$HistoryStateCopyWithImpl<_HistoryState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HistoryState&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.currentFilter, currentFilter) || other.currentFilter == currentFilter)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),currentFilter,isLoading);

@override
String toString() {
  return 'HistoryState(items: $items, currentFilter: $currentFilter, isLoading: $isLoading)';
}


}

/// @nodoc
abstract mixin class _$HistoryStateCopyWith<$Res> implements $HistoryStateCopyWith<$Res> {
  factory _$HistoryStateCopyWith(_HistoryState value, $Res Function(_HistoryState) _then) = __$HistoryStateCopyWithImpl;
@override @useResult
$Res call({
 List<HistoryItem> items, HistoryFilterType currentFilter, bool isLoading
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
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? currentFilter = null,Object? isLoading = null,}) {
  return _then(_HistoryState(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<HistoryItem>,currentFilter: null == currentFilter ? _self.currentFilter : currentFilter // ignore: cast_nullable_to_non_nullable
as HistoryFilterType,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RefreshIntent value)?  refresh,TResult Function( SetFilterIntent value)?  setFilter,TResult Function( ReconcileIntent value)?  reconcile,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RefreshIntent() when refresh != null:
return refresh(_that);case SetFilterIntent() when setFilter != null:
return setFilter(_that);case ReconcileIntent() when reconcile != null:
return reconcile(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RefreshIntent value)  refresh,required TResult Function( SetFilterIntent value)  setFilter,required TResult Function( ReconcileIntent value)  reconcile,}){
final _that = this;
switch (_that) {
case RefreshIntent():
return refresh(_that);case SetFilterIntent():
return setFilter(_that);case ReconcileIntent():
return reconcile(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RefreshIntent value)?  refresh,TResult? Function( SetFilterIntent value)?  setFilter,TResult? Function( ReconcileIntent value)?  reconcile,}){
final _that = this;
switch (_that) {
case RefreshIntent() when refresh != null:
return refresh(_that);case SetFilterIntent() when setFilter != null:
return setFilter(_that);case ReconcileIntent() when reconcile != null:
return reconcile(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  refresh,TResult Function( HistoryFilterType filter)?  setFilter,TResult Function( String historyId,  HistoryStatus status)?  reconcile,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RefreshIntent() when refresh != null:
return refresh();case SetFilterIntent() when setFilter != null:
return setFilter(_that.filter);case ReconcileIntent() when reconcile != null:
return reconcile(_that.historyId,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  refresh,required TResult Function( HistoryFilterType filter)  setFilter,required TResult Function( String historyId,  HistoryStatus status)  reconcile,}) {final _that = this;
switch (_that) {
case RefreshIntent():
return refresh();case SetFilterIntent():
return setFilter(_that.filter);case ReconcileIntent():
return reconcile(_that.historyId,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  refresh,TResult? Function( HistoryFilterType filter)?  setFilter,TResult? Function( String historyId,  HistoryStatus status)?  reconcile,}) {final _that = this;
switch (_that) {
case RefreshIntent() when refresh != null:
return refresh();case SetFilterIntent() when setFilter != null:
return setFilter(_that.filter);case ReconcileIntent() when reconcile != null:
return reconcile(_that.historyId,_that.status);case _:
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


class SetFilterIntent implements HistoryIntent {
  const SetFilterIntent(this.filter);
  

 final  HistoryFilterType filter;

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
 HistoryFilterType filter
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
as HistoryFilterType,
  ));
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

// dart format on

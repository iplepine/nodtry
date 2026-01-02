// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'now_tab_ui_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NowTabUiState {

/// 전체 카드 리스트 (Raw Data)
 List<HomeCardModel> get allCards;/// 메인 실행 카드 (가장 큰 카드)
 HomeCardModel? get primaryCard;/// 서브 실행 카드 리스트 (우측 정렬 작은 카드들)
 List<HomeCardModel> get secondaryCards;/// 관리자/파트너 카드 (좌측 정렬)
 HomeCardModel? get managerCard;
/// Create a copy of NowTabUiState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NowTabUiStateCopyWith<NowTabUiState> get copyWith => _$NowTabUiStateCopyWithImpl<NowTabUiState>(this as NowTabUiState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NowTabUiState&&const DeepCollectionEquality().equals(other.allCards, allCards)&&(identical(other.primaryCard, primaryCard) || other.primaryCard == primaryCard)&&const DeepCollectionEquality().equals(other.secondaryCards, secondaryCards)&&(identical(other.managerCard, managerCard) || other.managerCard == managerCard));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(allCards),primaryCard,const DeepCollectionEquality().hash(secondaryCards),managerCard);

@override
String toString() {
  return 'NowTabUiState(allCards: $allCards, primaryCard: $primaryCard, secondaryCards: $secondaryCards, managerCard: $managerCard)';
}


}

/// @nodoc
abstract mixin class $NowTabUiStateCopyWith<$Res>  {
  factory $NowTabUiStateCopyWith(NowTabUiState value, $Res Function(NowTabUiState) _then) = _$NowTabUiStateCopyWithImpl;
@useResult
$Res call({
 List<HomeCardModel> allCards, HomeCardModel? primaryCard, List<HomeCardModel> secondaryCards, HomeCardModel? managerCard
});




}
/// @nodoc
class _$NowTabUiStateCopyWithImpl<$Res>
    implements $NowTabUiStateCopyWith<$Res> {
  _$NowTabUiStateCopyWithImpl(this._self, this._then);

  final NowTabUiState _self;
  final $Res Function(NowTabUiState) _then;

/// Create a copy of NowTabUiState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? allCards = null,Object? primaryCard = freezed,Object? secondaryCards = null,Object? managerCard = freezed,}) {
  return _then(_self.copyWith(
allCards: null == allCards ? _self.allCards : allCards // ignore: cast_nullable_to_non_nullable
as List<HomeCardModel>,primaryCard: freezed == primaryCard ? _self.primaryCard : primaryCard // ignore: cast_nullable_to_non_nullable
as HomeCardModel?,secondaryCards: null == secondaryCards ? _self.secondaryCards : secondaryCards // ignore: cast_nullable_to_non_nullable
as List<HomeCardModel>,managerCard: freezed == managerCard ? _self.managerCard : managerCard // ignore: cast_nullable_to_non_nullable
as HomeCardModel?,
  ));
}

}


/// Adds pattern-matching-related methods to [NowTabUiState].
extension NowTabUiStatePatterns on NowTabUiState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NowTabUiState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NowTabUiState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NowTabUiState value)  $default,){
final _that = this;
switch (_that) {
case _NowTabUiState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NowTabUiState value)?  $default,){
final _that = this;
switch (_that) {
case _NowTabUiState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<HomeCardModel> allCards,  HomeCardModel? primaryCard,  List<HomeCardModel> secondaryCards,  HomeCardModel? managerCard)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NowTabUiState() when $default != null:
return $default(_that.allCards,_that.primaryCard,_that.secondaryCards,_that.managerCard);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<HomeCardModel> allCards,  HomeCardModel? primaryCard,  List<HomeCardModel> secondaryCards,  HomeCardModel? managerCard)  $default,) {final _that = this;
switch (_that) {
case _NowTabUiState():
return $default(_that.allCards,_that.primaryCard,_that.secondaryCards,_that.managerCard);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<HomeCardModel> allCards,  HomeCardModel? primaryCard,  List<HomeCardModel> secondaryCards,  HomeCardModel? managerCard)?  $default,) {final _that = this;
switch (_that) {
case _NowTabUiState() when $default != null:
return $default(_that.allCards,_that.primaryCard,_that.secondaryCards,_that.managerCard);case _:
  return null;

}
}

}

/// @nodoc


class _NowTabUiState extends NowTabUiState {
  const _NowTabUiState({required final  List<HomeCardModel> allCards, this.primaryCard, final  List<HomeCardModel> secondaryCards = const [], this.managerCard}): _allCards = allCards,_secondaryCards = secondaryCards,super._();
  

/// 전체 카드 리스트 (Raw Data)
 final  List<HomeCardModel> _allCards;
/// 전체 카드 리스트 (Raw Data)
@override List<HomeCardModel> get allCards {
  if (_allCards is EqualUnmodifiableListView) return _allCards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allCards);
}

/// 메인 실행 카드 (가장 큰 카드)
@override final  HomeCardModel? primaryCard;
/// 서브 실행 카드 리스트 (우측 정렬 작은 카드들)
 final  List<HomeCardModel> _secondaryCards;
/// 서브 실행 카드 리스트 (우측 정렬 작은 카드들)
@override@JsonKey() List<HomeCardModel> get secondaryCards {
  if (_secondaryCards is EqualUnmodifiableListView) return _secondaryCards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_secondaryCards);
}

/// 관리자/파트너 카드 (좌측 정렬)
@override final  HomeCardModel? managerCard;

/// Create a copy of NowTabUiState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NowTabUiStateCopyWith<_NowTabUiState> get copyWith => __$NowTabUiStateCopyWithImpl<_NowTabUiState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NowTabUiState&&const DeepCollectionEquality().equals(other._allCards, _allCards)&&(identical(other.primaryCard, primaryCard) || other.primaryCard == primaryCard)&&const DeepCollectionEquality().equals(other._secondaryCards, _secondaryCards)&&(identical(other.managerCard, managerCard) || other.managerCard == managerCard));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_allCards),primaryCard,const DeepCollectionEquality().hash(_secondaryCards),managerCard);

@override
String toString() {
  return 'NowTabUiState(allCards: $allCards, primaryCard: $primaryCard, secondaryCards: $secondaryCards, managerCard: $managerCard)';
}


}

/// @nodoc
abstract mixin class _$NowTabUiStateCopyWith<$Res> implements $NowTabUiStateCopyWith<$Res> {
  factory _$NowTabUiStateCopyWith(_NowTabUiState value, $Res Function(_NowTabUiState) _then) = __$NowTabUiStateCopyWithImpl;
@override @useResult
$Res call({
 List<HomeCardModel> allCards, HomeCardModel? primaryCard, List<HomeCardModel> secondaryCards, HomeCardModel? managerCard
});




}
/// @nodoc
class __$NowTabUiStateCopyWithImpl<$Res>
    implements _$NowTabUiStateCopyWith<$Res> {
  __$NowTabUiStateCopyWithImpl(this._self, this._then);

  final _NowTabUiState _self;
  final $Res Function(_NowTabUiState) _then;

/// Create a copy of NowTabUiState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? allCards = null,Object? primaryCard = freezed,Object? secondaryCards = null,Object? managerCard = freezed,}) {
  return _then(_NowTabUiState(
allCards: null == allCards ? _self._allCards : allCards // ignore: cast_nullable_to_non_nullable
as List<HomeCardModel>,primaryCard: freezed == primaryCard ? _self.primaryCard : primaryCard // ignore: cast_nullable_to_non_nullable
as HomeCardModel?,secondaryCards: null == secondaryCards ? _self._secondaryCards : secondaryCards // ignore: cast_nullable_to_non_nullable
as List<HomeCardModel>,managerCard: freezed == managerCard ? _self.managerCard : managerCard // ignore: cast_nullable_to_non_nullable
as HomeCardModel?,
  ));
}


}

// dart format on

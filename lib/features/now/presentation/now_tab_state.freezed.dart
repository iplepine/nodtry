// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'now_tab_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NowTabState {

/// 전체 카드 리스트 (Raw Data)
 List<HomeCardModel> get allCards;/// 메인 실행 카드 (가장 큰 카드)
 HomeCardModel? get primaryCard;/// 서브 실행 카드 리스트 (우측 정렬 작은 카드들)
 List<HomeCardModel> get secondaryCards;/// 관리자/파트너 카드 리스트 (좌측 정렬)
 List<HomeCardModel> get managerCards;
/// Create a copy of NowTabState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NowTabStateCopyWith<NowTabState> get copyWith => _$NowTabStateCopyWithImpl<NowTabState>(this as NowTabState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NowTabState&&const DeepCollectionEquality().equals(other.allCards, allCards)&&(identical(other.primaryCard, primaryCard) || other.primaryCard == primaryCard)&&const DeepCollectionEquality().equals(other.secondaryCards, secondaryCards)&&const DeepCollectionEquality().equals(other.managerCards, managerCards));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(allCards),primaryCard,const DeepCollectionEquality().hash(secondaryCards),const DeepCollectionEquality().hash(managerCards));

@override
String toString() {
  return 'NowTabState(allCards: $allCards, primaryCard: $primaryCard, secondaryCards: $secondaryCards, managerCards: $managerCards)';
}


}

/// @nodoc
abstract mixin class $NowTabStateCopyWith<$Res>  {
  factory $NowTabStateCopyWith(NowTabState value, $Res Function(NowTabState) _then) = _$NowTabStateCopyWithImpl;
@useResult
$Res call({
 List<HomeCardModel> allCards, HomeCardModel? primaryCard, List<HomeCardModel> secondaryCards, List<HomeCardModel> managerCards
});




}
/// @nodoc
class _$NowTabStateCopyWithImpl<$Res>
    implements $NowTabStateCopyWith<$Res> {
  _$NowTabStateCopyWithImpl(this._self, this._then);

  final NowTabState _self;
  final $Res Function(NowTabState) _then;

/// Create a copy of NowTabState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? allCards = null,Object? primaryCard = freezed,Object? secondaryCards = null,Object? managerCards = null,}) {
  return _then(_self.copyWith(
allCards: null == allCards ? _self.allCards : allCards // ignore: cast_nullable_to_non_nullable
as List<HomeCardModel>,primaryCard: freezed == primaryCard ? _self.primaryCard : primaryCard // ignore: cast_nullable_to_non_nullable
as HomeCardModel?,secondaryCards: null == secondaryCards ? _self.secondaryCards : secondaryCards // ignore: cast_nullable_to_non_nullable
as List<HomeCardModel>,managerCards: null == managerCards ? _self.managerCards : managerCards // ignore: cast_nullable_to_non_nullable
as List<HomeCardModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [NowTabState].
extension NowTabStatePatterns on NowTabState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NowTabState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NowTabState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NowTabState value)  $default,){
final _that = this;
switch (_that) {
case _NowTabState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NowTabState value)?  $default,){
final _that = this;
switch (_that) {
case _NowTabState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<HomeCardModel> allCards,  HomeCardModel? primaryCard,  List<HomeCardModel> secondaryCards,  List<HomeCardModel> managerCards)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NowTabState() when $default != null:
return $default(_that.allCards,_that.primaryCard,_that.secondaryCards,_that.managerCards);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<HomeCardModel> allCards,  HomeCardModel? primaryCard,  List<HomeCardModel> secondaryCards,  List<HomeCardModel> managerCards)  $default,) {final _that = this;
switch (_that) {
case _NowTabState():
return $default(_that.allCards,_that.primaryCard,_that.secondaryCards,_that.managerCards);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<HomeCardModel> allCards,  HomeCardModel? primaryCard,  List<HomeCardModel> secondaryCards,  List<HomeCardModel> managerCards)?  $default,) {final _that = this;
switch (_that) {
case _NowTabState() when $default != null:
return $default(_that.allCards,_that.primaryCard,_that.secondaryCards,_that.managerCards);case _:
  return null;

}
}

}

/// @nodoc


class _NowTabState extends NowTabState {
  const _NowTabState({required final  List<HomeCardModel> allCards, this.primaryCard, final  List<HomeCardModel> secondaryCards = const [], final  List<HomeCardModel> managerCards = const []}): _allCards = allCards,_secondaryCards = secondaryCards,_managerCards = managerCards,super._();
  

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

/// 관리자/파트너 카드 리스트 (좌측 정렬)
 final  List<HomeCardModel> _managerCards;
/// 관리자/파트너 카드 리스트 (좌측 정렬)
@override@JsonKey() List<HomeCardModel> get managerCards {
  if (_managerCards is EqualUnmodifiableListView) return _managerCards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_managerCards);
}


/// Create a copy of NowTabState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NowTabStateCopyWith<_NowTabState> get copyWith => __$NowTabStateCopyWithImpl<_NowTabState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NowTabState&&const DeepCollectionEquality().equals(other._allCards, _allCards)&&(identical(other.primaryCard, primaryCard) || other.primaryCard == primaryCard)&&const DeepCollectionEquality().equals(other._secondaryCards, _secondaryCards)&&const DeepCollectionEquality().equals(other._managerCards, _managerCards));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_allCards),primaryCard,const DeepCollectionEquality().hash(_secondaryCards),const DeepCollectionEquality().hash(_managerCards));

@override
String toString() {
  return 'NowTabState(allCards: $allCards, primaryCard: $primaryCard, secondaryCards: $secondaryCards, managerCards: $managerCards)';
}


}

/// @nodoc
abstract mixin class _$NowTabStateCopyWith<$Res> implements $NowTabStateCopyWith<$Res> {
  factory _$NowTabStateCopyWith(_NowTabState value, $Res Function(_NowTabState) _then) = __$NowTabStateCopyWithImpl;
@override @useResult
$Res call({
 List<HomeCardModel> allCards, HomeCardModel? primaryCard, List<HomeCardModel> secondaryCards, List<HomeCardModel> managerCards
});




}
/// @nodoc
class __$NowTabStateCopyWithImpl<$Res>
    implements _$NowTabStateCopyWith<$Res> {
  __$NowTabStateCopyWithImpl(this._self, this._then);

  final _NowTabState _self;
  final $Res Function(_NowTabState) _then;

/// Create a copy of NowTabState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? allCards = null,Object? primaryCard = freezed,Object? secondaryCards = null,Object? managerCards = null,}) {
  return _then(_NowTabState(
allCards: null == allCards ? _self._allCards : allCards // ignore: cast_nullable_to_non_nullable
as List<HomeCardModel>,primaryCard: freezed == primaryCard ? _self.primaryCard : primaryCard // ignore: cast_nullable_to_non_nullable
as HomeCardModel?,secondaryCards: null == secondaryCards ? _self._secondaryCards : secondaryCards // ignore: cast_nullable_to_non_nullable
as List<HomeCardModel>,managerCards: null == managerCards ? _self._managerCards : managerCards // ignore: cast_nullable_to_non_nullable
as List<HomeCardModel>,
  ));
}


}

// dart format on

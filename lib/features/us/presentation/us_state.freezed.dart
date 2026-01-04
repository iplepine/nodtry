// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'us_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UsState {

 UserModel? get myProfile; List<ConnectedUser> get connectedProfiles; bool get isLinking; bool get isUpdatingProfile; String? get errorNotification;
/// Create a copy of UsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UsStateCopyWith<UsState> get copyWith => _$UsStateCopyWithImpl<UsState>(this as UsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UsState&&(identical(other.myProfile, myProfile) || other.myProfile == myProfile)&&const DeepCollectionEquality().equals(other.connectedProfiles, connectedProfiles)&&(identical(other.isLinking, isLinking) || other.isLinking == isLinking)&&(identical(other.isUpdatingProfile, isUpdatingProfile) || other.isUpdatingProfile == isUpdatingProfile)&&(identical(other.errorNotification, errorNotification) || other.errorNotification == errorNotification));
}


@override
int get hashCode => Object.hash(runtimeType,myProfile,const DeepCollectionEquality().hash(connectedProfiles),isLinking,isUpdatingProfile,errorNotification);

@override
String toString() {
  return 'UsState(myProfile: $myProfile, connectedProfiles: $connectedProfiles, isLinking: $isLinking, isUpdatingProfile: $isUpdatingProfile, errorNotification: $errorNotification)';
}


}

/// @nodoc
abstract mixin class $UsStateCopyWith<$Res>  {
  factory $UsStateCopyWith(UsState value, $Res Function(UsState) _then) = _$UsStateCopyWithImpl;
@useResult
$Res call({
 UserModel? myProfile, List<ConnectedUser> connectedProfiles, bool isLinking, bool isUpdatingProfile, String? errorNotification
});




}
/// @nodoc
class _$UsStateCopyWithImpl<$Res>
    implements $UsStateCopyWith<$Res> {
  _$UsStateCopyWithImpl(this._self, this._then);

  final UsState _self;
  final $Res Function(UsState) _then;

/// Create a copy of UsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? myProfile = freezed,Object? connectedProfiles = null,Object? isLinking = null,Object? isUpdatingProfile = null,Object? errorNotification = freezed,}) {
  return _then(_self.copyWith(
myProfile: freezed == myProfile ? _self.myProfile : myProfile // ignore: cast_nullable_to_non_nullable
as UserModel?,connectedProfiles: null == connectedProfiles ? _self.connectedProfiles : connectedProfiles // ignore: cast_nullable_to_non_nullable
as List<ConnectedUser>,isLinking: null == isLinking ? _self.isLinking : isLinking // ignore: cast_nullable_to_non_nullable
as bool,isUpdatingProfile: null == isUpdatingProfile ? _self.isUpdatingProfile : isUpdatingProfile // ignore: cast_nullable_to_non_nullable
as bool,errorNotification: freezed == errorNotification ? _self.errorNotification : errorNotification // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UsState].
extension UsStatePatterns on UsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UsState value)  $default,){
final _that = this;
switch (_that) {
case _UsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UsState value)?  $default,){
final _that = this;
switch (_that) {
case _UsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( UserModel? myProfile,  List<ConnectedUser> connectedProfiles,  bool isLinking,  bool isUpdatingProfile,  String? errorNotification)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UsState() when $default != null:
return $default(_that.myProfile,_that.connectedProfiles,_that.isLinking,_that.isUpdatingProfile,_that.errorNotification);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( UserModel? myProfile,  List<ConnectedUser> connectedProfiles,  bool isLinking,  bool isUpdatingProfile,  String? errorNotification)  $default,) {final _that = this;
switch (_that) {
case _UsState():
return $default(_that.myProfile,_that.connectedProfiles,_that.isLinking,_that.isUpdatingProfile,_that.errorNotification);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( UserModel? myProfile,  List<ConnectedUser> connectedProfiles,  bool isLinking,  bool isUpdatingProfile,  String? errorNotification)?  $default,) {final _that = this;
switch (_that) {
case _UsState() when $default != null:
return $default(_that.myProfile,_that.connectedProfiles,_that.isLinking,_that.isUpdatingProfile,_that.errorNotification);case _:
  return null;

}
}

}

/// @nodoc


class _UsState extends UsState {
  const _UsState({this.myProfile, final  List<ConnectedUser> connectedProfiles = const [], this.isLinking = false, this.isUpdatingProfile = false, this.errorNotification}): _connectedProfiles = connectedProfiles,super._();
  

@override final  UserModel? myProfile;
 final  List<ConnectedUser> _connectedProfiles;
@override@JsonKey() List<ConnectedUser> get connectedProfiles {
  if (_connectedProfiles is EqualUnmodifiableListView) return _connectedProfiles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_connectedProfiles);
}

@override@JsonKey() final  bool isLinking;
@override@JsonKey() final  bool isUpdatingProfile;
@override final  String? errorNotification;

/// Create a copy of UsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UsStateCopyWith<_UsState> get copyWith => __$UsStateCopyWithImpl<_UsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UsState&&(identical(other.myProfile, myProfile) || other.myProfile == myProfile)&&const DeepCollectionEquality().equals(other._connectedProfiles, _connectedProfiles)&&(identical(other.isLinking, isLinking) || other.isLinking == isLinking)&&(identical(other.isUpdatingProfile, isUpdatingProfile) || other.isUpdatingProfile == isUpdatingProfile)&&(identical(other.errorNotification, errorNotification) || other.errorNotification == errorNotification));
}


@override
int get hashCode => Object.hash(runtimeType,myProfile,const DeepCollectionEquality().hash(_connectedProfiles),isLinking,isUpdatingProfile,errorNotification);

@override
String toString() {
  return 'UsState(myProfile: $myProfile, connectedProfiles: $connectedProfiles, isLinking: $isLinking, isUpdatingProfile: $isUpdatingProfile, errorNotification: $errorNotification)';
}


}

/// @nodoc
abstract mixin class _$UsStateCopyWith<$Res> implements $UsStateCopyWith<$Res> {
  factory _$UsStateCopyWith(_UsState value, $Res Function(_UsState) _then) = __$UsStateCopyWithImpl;
@override @useResult
$Res call({
 UserModel? myProfile, List<ConnectedUser> connectedProfiles, bool isLinking, bool isUpdatingProfile, String? errorNotification
});




}
/// @nodoc
class __$UsStateCopyWithImpl<$Res>
    implements _$UsStateCopyWith<$Res> {
  __$UsStateCopyWithImpl(this._self, this._then);

  final _UsState _self;
  final $Res Function(_UsState) _then;

/// Create a copy of UsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? myProfile = freezed,Object? connectedProfiles = null,Object? isLinking = null,Object? isUpdatingProfile = null,Object? errorNotification = freezed,}) {
  return _then(_UsState(
myProfile: freezed == myProfile ? _self.myProfile : myProfile // ignore: cast_nullable_to_non_nullable
as UserModel?,connectedProfiles: null == connectedProfiles ? _self._connectedProfiles : connectedProfiles // ignore: cast_nullable_to_non_nullable
as List<ConnectedUser>,isLinking: null == isLinking ? _self.isLinking : isLinking // ignore: cast_nullable_to_non_nullable
as bool,isUpdatingProfile: null == isUpdatingProfile ? _self.isUpdatingProfile : isUpdatingProfile // ignore: cast_nullable_to_non_nullable
as bool,errorNotification: freezed == errorNotification ? _self.errorNotification : errorNotification // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$UsIntent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UsIntent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UsIntent()';
}


}

/// @nodoc
class $UsIntentCopyWith<$Res>  {
$UsIntentCopyWith(UsIntent _, $Res Function(UsIntent) __);
}


/// Adds pattern-matching-related methods to [UsIntent].
extension UsIntentPatterns on UsIntent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RefreshIntent value)?  refresh,TResult Function( UpdateProfileIntent value)?  updateProfile,TResult Function( LinkGoogleIntent value)?  linkGoogle,TResult Function( DisconnectIntent value)?  disconnect,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RefreshIntent() when refresh != null:
return refresh(_that);case UpdateProfileIntent() when updateProfile != null:
return updateProfile(_that);case LinkGoogleIntent() when linkGoogle != null:
return linkGoogle(_that);case DisconnectIntent() when disconnect != null:
return disconnect(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RefreshIntent value)  refresh,required TResult Function( UpdateProfileIntent value)  updateProfile,required TResult Function( LinkGoogleIntent value)  linkGoogle,required TResult Function( DisconnectIntent value)  disconnect,}){
final _that = this;
switch (_that) {
case RefreshIntent():
return refresh(_that);case UpdateProfileIntent():
return updateProfile(_that);case LinkGoogleIntent():
return linkGoogle(_that);case DisconnectIntent():
return disconnect(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RefreshIntent value)?  refresh,TResult? Function( UpdateProfileIntent value)?  updateProfile,TResult? Function( LinkGoogleIntent value)?  linkGoogle,TResult? Function( DisconnectIntent value)?  disconnect,}){
final _that = this;
switch (_that) {
case RefreshIntent() when refresh != null:
return refresh(_that);case UpdateProfileIntent() when updateProfile != null:
return updateProfile(_that);case LinkGoogleIntent() when linkGoogle != null:
return linkGoogle(_that);case DisconnectIntent() when disconnect != null:
return disconnect(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  refresh,TResult Function( String? displayName,  String? statusMessage,  String? profileImageUrl)?  updateProfile,TResult Function()?  linkGoogle,TResult Function( String partnerId)?  disconnect,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RefreshIntent() when refresh != null:
return refresh();case UpdateProfileIntent() when updateProfile != null:
return updateProfile(_that.displayName,_that.statusMessage,_that.profileImageUrl);case LinkGoogleIntent() when linkGoogle != null:
return linkGoogle();case DisconnectIntent() when disconnect != null:
return disconnect(_that.partnerId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  refresh,required TResult Function( String? displayName,  String? statusMessage,  String? profileImageUrl)  updateProfile,required TResult Function()  linkGoogle,required TResult Function( String partnerId)  disconnect,}) {final _that = this;
switch (_that) {
case RefreshIntent():
return refresh();case UpdateProfileIntent():
return updateProfile(_that.displayName,_that.statusMessage,_that.profileImageUrl);case LinkGoogleIntent():
return linkGoogle();case DisconnectIntent():
return disconnect(_that.partnerId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  refresh,TResult? Function( String? displayName,  String? statusMessage,  String? profileImageUrl)?  updateProfile,TResult? Function()?  linkGoogle,TResult? Function( String partnerId)?  disconnect,}) {final _that = this;
switch (_that) {
case RefreshIntent() when refresh != null:
return refresh();case UpdateProfileIntent() when updateProfile != null:
return updateProfile(_that.displayName,_that.statusMessage,_that.profileImageUrl);case LinkGoogleIntent() when linkGoogle != null:
return linkGoogle();case DisconnectIntent() when disconnect != null:
return disconnect(_that.partnerId);case _:
  return null;

}
}

}

/// @nodoc


class RefreshIntent implements UsIntent {
  const RefreshIntent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RefreshIntent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UsIntent.refresh()';
}


}




/// @nodoc


class UpdateProfileIntent implements UsIntent {
  const UpdateProfileIntent({this.displayName, this.statusMessage, this.profileImageUrl});
  

 final  String? displayName;
 final  String? statusMessage;
 final  String? profileImageUrl;

/// Create a copy of UsIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateProfileIntentCopyWith<UpdateProfileIntent> get copyWith => _$UpdateProfileIntentCopyWithImpl<UpdateProfileIntent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateProfileIntent&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.statusMessage, statusMessage) || other.statusMessage == statusMessage)&&(identical(other.profileImageUrl, profileImageUrl) || other.profileImageUrl == profileImageUrl));
}


@override
int get hashCode => Object.hash(runtimeType,displayName,statusMessage,profileImageUrl);

@override
String toString() {
  return 'UsIntent.updateProfile(displayName: $displayName, statusMessage: $statusMessage, profileImageUrl: $profileImageUrl)';
}


}

/// @nodoc
abstract mixin class $UpdateProfileIntentCopyWith<$Res> implements $UsIntentCopyWith<$Res> {
  factory $UpdateProfileIntentCopyWith(UpdateProfileIntent value, $Res Function(UpdateProfileIntent) _then) = _$UpdateProfileIntentCopyWithImpl;
@useResult
$Res call({
 String? displayName, String? statusMessage, String? profileImageUrl
});




}
/// @nodoc
class _$UpdateProfileIntentCopyWithImpl<$Res>
    implements $UpdateProfileIntentCopyWith<$Res> {
  _$UpdateProfileIntentCopyWithImpl(this._self, this._then);

  final UpdateProfileIntent _self;
  final $Res Function(UpdateProfileIntent) _then;

/// Create a copy of UsIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? displayName = freezed,Object? statusMessage = freezed,Object? profileImageUrl = freezed,}) {
  return _then(UpdateProfileIntent(
displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,statusMessage: freezed == statusMessage ? _self.statusMessage : statusMessage // ignore: cast_nullable_to_non_nullable
as String?,profileImageUrl: freezed == profileImageUrl ? _self.profileImageUrl : profileImageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class LinkGoogleIntent implements UsIntent {
  const LinkGoogleIntent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LinkGoogleIntent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UsIntent.linkGoogle()';
}


}




/// @nodoc


class DisconnectIntent implements UsIntent {
  const DisconnectIntent(this.partnerId);
  

 final  String partnerId;

/// Create a copy of UsIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DisconnectIntentCopyWith<DisconnectIntent> get copyWith => _$DisconnectIntentCopyWithImpl<DisconnectIntent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DisconnectIntent&&(identical(other.partnerId, partnerId) || other.partnerId == partnerId));
}


@override
int get hashCode => Object.hash(runtimeType,partnerId);

@override
String toString() {
  return 'UsIntent.disconnect(partnerId: $partnerId)';
}


}

/// @nodoc
abstract mixin class $DisconnectIntentCopyWith<$Res> implements $UsIntentCopyWith<$Res> {
  factory $DisconnectIntentCopyWith(DisconnectIntent value, $Res Function(DisconnectIntent) _then) = _$DisconnectIntentCopyWithImpl;
@useResult
$Res call({
 String partnerId
});




}
/// @nodoc
class _$DisconnectIntentCopyWithImpl<$Res>
    implements $DisconnectIntentCopyWith<$Res> {
  _$DisconnectIntentCopyWithImpl(this._self, this._then);

  final DisconnectIntent _self;
  final $Res Function(DisconnectIntent) _then;

/// Create a copy of UsIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? partnerId = null,}) {
  return _then(DisconnectIntent(
null == partnerId ? _self.partnerId : partnerId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

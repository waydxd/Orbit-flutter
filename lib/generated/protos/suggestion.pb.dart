// This is a generated file - do not edit.
//
// Generated from suggestion.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'suggestion.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'suggestion.pbenum.dart';

/// EventRequest contains the metadata of a calendar event for which
/// the client is requesting AI-driven suggestions.
class EventRequest extends $pb.GeneratedMessage {
  factory EventRequest({
    $core.String? id,
    $core.String? userId,
    $core.String? title,
    $core.String? description,
    $core.String? startTime,
    $core.String? endTime,
    $core.String? location,
    $core.Iterable<$core.String>? hashtags,
    $core.String? createdAt,
    $core.String? updatedAt,
    $core.String? userLocation,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (userId != null) result.userId = userId;
    if (title != null) result.title = title;
    if (description != null) result.description = description;
    if (startTime != null) result.startTime = startTime;
    if (endTime != null) result.endTime = endTime;
    if (location != null) result.location = location;
    if (hashtags != null) result.hashtags.addAll(hashtags);
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    if (userLocation != null) result.userLocation = userLocation;
    return result;
  }

  EventRequest._();

  factory EventRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EventRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EventRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'suggestion'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'userId')
    ..aOS(3, _omitFieldNames ? '' : 'title')
    ..aOS(4, _omitFieldNames ? '' : 'description')
    ..aOS(5, _omitFieldNames ? '' : 'startTime')
    ..aOS(6, _omitFieldNames ? '' : 'endTime')
    ..aOS(7, _omitFieldNames ? '' : 'location')
    ..pPS(8, _omitFieldNames ? '' : 'hashtags')
    ..aOS(9, _omitFieldNames ? '' : 'createdAt')
    ..aOS(10, _omitFieldNames ? '' : 'updatedAt')
    ..aOS(11, _omitFieldNames ? '' : 'userLocation')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventRequest copyWith(void Function(EventRequest) updates) =>
      super.copyWith((message) => updates(message as EventRequest))
          as EventRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EventRequest create() => EventRequest._();
  @$core.override
  EventRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EventRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EventRequest>(create);
  static EventRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get title => $_getSZ(2);
  @$pb.TagNumber(3)
  set title($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTitle() => $_has(2);
  @$pb.TagNumber(3)
  void clearTitle() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get description => $_getSZ(3);
  @$pb.TagNumber(4)
  set description($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDescription() => $_has(3);
  @$pb.TagNumber(4)
  void clearDescription() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get startTime => $_getSZ(4);
  @$pb.TagNumber(5)
  set startTime($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasStartTime() => $_has(4);
  @$pb.TagNumber(5)
  void clearStartTime() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get endTime => $_getSZ(5);
  @$pb.TagNumber(6)
  set endTime($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasEndTime() => $_has(5);
  @$pb.TagNumber(6)
  void clearEndTime() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get location => $_getSZ(6);
  @$pb.TagNumber(7)
  set location($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasLocation() => $_has(6);
  @$pb.TagNumber(7)
  void clearLocation() => $_clearField(7);

  @$pb.TagNumber(8)
  $pb.PbList<$core.String> get hashtags => $_getList(7);

  @$pb.TagNumber(9)
  $core.String get createdAt => $_getSZ(8);
  @$pb.TagNumber(9)
  set createdAt($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasCreatedAt() => $_has(8);
  @$pb.TagNumber(9)
  void clearCreatedAt() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get updatedAt => $_getSZ(9);
  @$pb.TagNumber(10)
  set updatedAt($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasUpdatedAt() => $_has(9);
  @$pb.TagNumber(10)
  void clearUpdatedAt() => $_clearField(10);

  /// Optional: the user's current location for routing suggestions.
  @$pb.TagNumber(11)
  $core.String get userLocation => $_getSZ(10);
  @$pb.TagNumber(11)
  set userLocation($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasUserLocation() => $_has(10);
  @$pb.TagNumber(11)
  void clearUserLocation() => $_clearField(11);
}

/// UserRequest contains the user's profile information.
class UserRequest extends $pb.GeneratedMessage {
  factory UserRequest({
    $core.String? id,
    $core.String? email,
    $core.String? firstName,
    $core.String? lastName,
    $core.String? username,
    $core.String? profilePicture,
    $core.String? region,
    $core.String? timezone,
    $core.String? gender,
    $core.String? birthDate,
    $core.bool? emailVerified,
    $core.String? createdAt,
    $core.String? updatedAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (email != null) result.email = email;
    if (firstName != null) result.firstName = firstName;
    if (lastName != null) result.lastName = lastName;
    if (username != null) result.username = username;
    if (profilePicture != null) result.profilePicture = profilePicture;
    if (region != null) result.region = region;
    if (timezone != null) result.timezone = timezone;
    if (gender != null) result.gender = gender;
    if (birthDate != null) result.birthDate = birthDate;
    if (emailVerified != null) result.emailVerified = emailVerified;
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    return result;
  }

  UserRequest._();

  factory UserRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UserRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UserRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'suggestion'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'email')
    ..aOS(3, _omitFieldNames ? '' : 'firstName')
    ..aOS(4, _omitFieldNames ? '' : 'lastName')
    ..aOS(5, _omitFieldNames ? '' : 'username')
    ..aOS(6, _omitFieldNames ? '' : 'profilePicture')
    ..aOS(7, _omitFieldNames ? '' : 'region')
    ..aOS(8, _omitFieldNames ? '' : 'timezone')
    ..aOS(9, _omitFieldNames ? '' : 'gender')
    ..aOS(10, _omitFieldNames ? '' : 'birthDate')
    ..aOB(11, _omitFieldNames ? '' : 'emailVerified')
    ..aOS(12, _omitFieldNames ? '' : 'createdAt')
    ..aOS(13, _omitFieldNames ? '' : 'updatedAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserRequest copyWith(void Function(UserRequest) updates) =>
      super.copyWith((message) => updates(message as UserRequest))
          as UserRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UserRequest create() => UserRequest._();
  @$core.override
  UserRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UserRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UserRequest>(create);
  static UserRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get email => $_getSZ(1);
  @$pb.TagNumber(2)
  set email($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEmail() => $_has(1);
  @$pb.TagNumber(2)
  void clearEmail() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get firstName => $_getSZ(2);
  @$pb.TagNumber(3)
  set firstName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFirstName() => $_has(2);
  @$pb.TagNumber(3)
  void clearFirstName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get lastName => $_getSZ(3);
  @$pb.TagNumber(4)
  set lastName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLastName() => $_has(3);
  @$pb.TagNumber(4)
  void clearLastName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get username => $_getSZ(4);
  @$pb.TagNumber(5)
  set username($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasUsername() => $_has(4);
  @$pb.TagNumber(5)
  void clearUsername() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get profilePicture => $_getSZ(5);
  @$pb.TagNumber(6)
  set profilePicture($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasProfilePicture() => $_has(5);
  @$pb.TagNumber(6)
  void clearProfilePicture() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get region => $_getSZ(6);
  @$pb.TagNumber(7)
  set region($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasRegion() => $_has(6);
  @$pb.TagNumber(7)
  void clearRegion() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get timezone => $_getSZ(7);
  @$pb.TagNumber(8)
  set timezone($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasTimezone() => $_has(7);
  @$pb.TagNumber(8)
  void clearTimezone() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get gender => $_getSZ(8);
  @$pb.TagNumber(9)
  set gender($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasGender() => $_has(8);
  @$pb.TagNumber(9)
  void clearGender() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get birthDate => $_getSZ(9);
  @$pb.TagNumber(10)
  set birthDate($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasBirthDate() => $_has(9);
  @$pb.TagNumber(10)
  void clearBirthDate() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.bool get emailVerified => $_getBF(10);
  @$pb.TagNumber(11)
  set emailVerified($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(11)
  $core.bool hasEmailVerified() => $_has(10);
  @$pb.TagNumber(11)
  void clearEmailVerified() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get createdAt => $_getSZ(11);
  @$pb.TagNumber(12)
  set createdAt($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasCreatedAt() => $_has(11);
  @$pb.TagNumber(12)
  void clearCreatedAt() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get updatedAt => $_getSZ(12);
  @$pb.TagNumber(13)
  set updatedAt($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasUpdatedAt() => $_has(12);
  @$pb.TagNumber(13)
  void clearUpdatedAt() => $_clearField(13);
}

/// DailySuggestionRequest contains info for generating full day recommendations based on past info.
class DailySuggestionRequest extends $pb.GeneratedMessage {
  factory DailySuggestionRequest({
    UserRequest? user,
    $core.String? date,
    $core.Iterable<EventRequest>? recentEvents,
  }) {
    final result = create();
    if (user != null) result.user = user;
    if (date != null) result.date = date;
    if (recentEvents != null) result.recentEvents.addAll(recentEvents);
    return result;
  }

  DailySuggestionRequest._();

  factory DailySuggestionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DailySuggestionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DailySuggestionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'suggestion'),
      createEmptyInstance: create)
    ..aOM<UserRequest>(1, _omitFieldNames ? '' : 'user',
        subBuilder: UserRequest.create)
    ..aOS(2, _omitFieldNames ? '' : 'date')
    ..pPM<EventRequest>(3, _omitFieldNames ? '' : 'recentEvents',
        subBuilder: EventRequest.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DailySuggestionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DailySuggestionRequest copyWith(
          void Function(DailySuggestionRequest) updates) =>
      super.copyWith((message) => updates(message as DailySuggestionRequest))
          as DailySuggestionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DailySuggestionRequest create() => DailySuggestionRequest._();
  @$core.override
  DailySuggestionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DailySuggestionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DailySuggestionRequest>(create);
  static DailySuggestionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  UserRequest get user => $_getN(0);
  @$pb.TagNumber(1)
  set user(UserRequest value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasUser() => $_has(0);
  @$pb.TagNumber(1)
  void clearUser() => $_clearField(1);
  @$pb.TagNumber(1)
  UserRequest ensureUser() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get date => $_getSZ(1);
  @$pb.TagNumber(2)
  set date($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDate() => $_has(1);
  @$pb.TagNumber(2)
  void clearDate() => $_clearField(2);

  /// Previous recent events to infer user preferences/activities
  @$pb.TagNumber(3)
  $pb.PbList<EventRequest> get recentEvents => $_getList(2);
}

/// Suggestion is a single actionable recommendation.
class Suggestion extends $pb.GeneratedMessage {
  factory Suggestion({
    SuggestionType? type,
    $core.String? title,
    $core.String? description,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? metadata,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (title != null) result.title = title;
    if (description != null) result.description = description;
    if (metadata != null) result.metadata.addEntries(metadata);
    return result;
  }

  Suggestion._();

  factory Suggestion.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Suggestion.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Suggestion',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'suggestion'),
      createEmptyInstance: create)
    ..aE<SuggestionType>(1, _omitFieldNames ? '' : 'type',
        enumValues: SuggestionType.values)
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..m<$core.String, $core.String>(4, _omitFieldNames ? '' : 'metadata',
        entryClassName: 'Suggestion.MetadataEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('suggestion'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Suggestion clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Suggestion copyWith(void Function(Suggestion) updates) =>
      super.copyWith((message) => updates(message as Suggestion)) as Suggestion;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Suggestion create() => Suggestion._();
  @$core.override
  Suggestion createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Suggestion getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Suggestion>(create);
  static Suggestion? _defaultInstance;

  @$pb.TagNumber(1)
  SuggestionType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SuggestionType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(3)
  set description($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescription() => $_clearField(3);

  /// Arbitrary key-value metadata (e.g. route_url, temperature, etc.)
  @$pb.TagNumber(4)
  $pb.PbMap<$core.String, $core.String> get metadata => $_getMap(3);
}

/// SuggestionResponse wraps the list of suggestions returned to the client.
class SuggestionResponse extends $pb.GeneratedMessage {
  factory SuggestionResponse({
    $core.Iterable<Suggestion>? suggestions,
    $core.String? id,
  }) {
    final result = create();
    if (suggestions != null) result.suggestions.addAll(suggestions);
    if (id != null) result.id = id;
    return result;
  }

  SuggestionResponse._();

  factory SuggestionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SuggestionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SuggestionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'suggestion'),
      createEmptyInstance: create)
    ..pPM<Suggestion>(1, _omitFieldNames ? '' : 'suggestions',
        subBuilder: Suggestion.create)
    ..aOS(2, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SuggestionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SuggestionResponse copyWith(void Function(SuggestionResponse) updates) =>
      super.copyWith((message) => updates(message as SuggestionResponse))
          as SuggestionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SuggestionResponse create() => SuggestionResponse._();
  @$core.override
  SuggestionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SuggestionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SuggestionResponse>(create);
  static SuggestionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Suggestion> get suggestions => $_getList(0);

  /// The event_id that was analyzed, echoed back for correlation.
  @$pb.TagNumber(2)
  $core.String get id => $_getSZ(1);
  @$pb.TagNumber(2)
  set id($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => $_clearField(2);
}

/// DailySuggestionResponse wraps the list of suggestions for a day.
class DailySuggestionResponse extends $pb.GeneratedMessage {
  factory DailySuggestionResponse({
    $core.Iterable<Suggestion>? suggestions,
    $core.String? date,
  }) {
    final result = create();
    if (suggestions != null) result.suggestions.addAll(suggestions);
    if (date != null) result.date = date;
    return result;
  }

  DailySuggestionResponse._();

  factory DailySuggestionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DailySuggestionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DailySuggestionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'suggestion'),
      createEmptyInstance: create)
    ..pPM<Suggestion>(1, _omitFieldNames ? '' : 'suggestions',
        subBuilder: Suggestion.create)
    ..aOS(2, _omitFieldNames ? '' : 'date')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DailySuggestionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DailySuggestionResponse copyWith(
          void Function(DailySuggestionResponse) updates) =>
      super.copyWith((message) => updates(message as DailySuggestionResponse))
          as DailySuggestionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DailySuggestionResponse create() => DailySuggestionResponse._();
  @$core.override
  DailySuggestionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DailySuggestionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DailySuggestionResponse>(create);
  static DailySuggestionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Suggestion> get suggestions => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get date => $_getSZ(1);
  @$pb.TagNumber(2)
  set date($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDate() => $_has(1);
  @$pb.TagNumber(2)
  void clearDate() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');

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

/// SuggestionType categorises the kind of suggestion provided.
class SuggestionType extends $pb.ProtobufEnum {
  static const SuggestionType SUGGESTION_TYPE_UNSPECIFIED =
      SuggestionType._(0, _omitEnumNames ? '' : 'SUGGESTION_TYPE_UNSPECIFIED');
  static const SuggestionType SUGGESTION_TYPE_TRANSPORTATION = SuggestionType._(
      1, _omitEnumNames ? '' : 'SUGGESTION_TYPE_TRANSPORTATION');
  static const SuggestionType SUGGESTION_TYPE_ATTIRE =
      SuggestionType._(2, _omitEnumNames ? '' : 'SUGGESTION_TYPE_ATTIRE');
  static const SuggestionType SUGGESTION_TYPE_PREPARATION =
      SuggestionType._(3, _omitEnumNames ? '' : 'SUGGESTION_TYPE_PREPARATION');
  static const SuggestionType SUGGESTION_TYPE_GENERAL =
      SuggestionType._(4, _omitEnumNames ? '' : 'SUGGESTION_TYPE_GENERAL');

  static const $core.List<SuggestionType> values = <SuggestionType>[
    SUGGESTION_TYPE_UNSPECIFIED,
    SUGGESTION_TYPE_TRANSPORTATION,
    SUGGESTION_TYPE_ATTIRE,
    SUGGESTION_TYPE_PREPARATION,
    SUGGESTION_TYPE_GENERAL,
  ];

  static final $core.List<SuggestionType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static SuggestionType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SuggestionType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');

// This is a generated file - do not edit.
//
// Generated from suggestion.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use suggestionTypeDescriptor instead')
const SuggestionType$json = {
  '1': 'SuggestionType',
  '2': [
    {'1': 'SUGGESTION_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'SUGGESTION_TYPE_TRANSPORTATION', '2': 1},
    {'1': 'SUGGESTION_TYPE_ATTIRE', '2': 2},
    {'1': 'SUGGESTION_TYPE_PREPARATION', '2': 3},
    {'1': 'SUGGESTION_TYPE_GENERAL', '2': 4},
  ],
};

/// Descriptor for `SuggestionType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List suggestionTypeDescriptor = $convert.base64Decode(
    'Cg5TdWdnZXN0aW9uVHlwZRIfChtTVUdHRVNUSU9OX1RZUEVfVU5TUEVDSUZJRUQQABIiCh5TVU'
    'dHRVNUSU9OX1RZUEVfVFJBTlNQT1JUQVRJT04QARIaChZTVUdHRVNUSU9OX1RZUEVfQVRUSVJF'
    'EAISHwobU1VHR0VTVElPTl9UWVBFX1BSRVBBUkFUSU9OEAMSGwoXU1VHR0VTVElPTl9UWVBFX0'
    'dFTkVSQUwQBA==');

@$core.Deprecated('Use eventRequestDescriptor instead')
const EventRequest$json = {
  '1': 'EventRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'user_id', '3': 2, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'title', '3': 3, '4': 1, '5': 9, '10': 'title'},
    {'1': 'description', '3': 4, '4': 1, '5': 9, '10': 'description'},
    {'1': 'start_time', '3': 5, '4': 1, '5': 9, '10': 'startTime'},
    {'1': 'end_time', '3': 6, '4': 1, '5': 9, '10': 'endTime'},
    {'1': 'location', '3': 7, '4': 1, '5': 9, '10': 'location'},
    {'1': 'hashtags', '3': 8, '4': 3, '5': 9, '10': 'hashtags'},
    {'1': 'created_at', '3': 9, '4': 1, '5': 9, '10': 'createdAt'},
    {'1': 'updated_at', '3': 10, '4': 1, '5': 9, '10': 'updatedAt'},
    {'1': 'user_location', '3': 11, '4': 1, '5': 9, '10': 'userLocation'},
  ],
};

/// Descriptor for `EventRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventRequestDescriptor = $convert.base64Decode(
    'CgxFdmVudFJlcXVlc3QSDgoCaWQYASABKAlSAmlkEhcKB3VzZXJfaWQYAiABKAlSBnVzZXJJZB'
    'IUCgV0aXRsZRgDIAEoCVIFdGl0bGUSIAoLZGVzY3JpcHRpb24YBCABKAlSC2Rlc2NyaXB0aW9u'
    'Eh0KCnN0YXJ0X3RpbWUYBSABKAlSCXN0YXJ0VGltZRIZCghlbmRfdGltZRgGIAEoCVIHZW5kVG'
    'ltZRIaCghsb2NhdGlvbhgHIAEoCVIIbG9jYXRpb24SGgoIaGFzaHRhZ3MYCCADKAlSCGhhc2h0'
    'YWdzEh0KCmNyZWF0ZWRfYXQYCSABKAlSCWNyZWF0ZWRBdBIdCgp1cGRhdGVkX2F0GAogASgJUg'
    'l1cGRhdGVkQXQSIwoNdXNlcl9sb2NhdGlvbhgLIAEoCVIMdXNlckxvY2F0aW9u');

@$core.Deprecated('Use userRequestDescriptor instead')
const UserRequest$json = {
  '1': 'UserRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'email', '3': 2, '4': 1, '5': 9, '10': 'email'},
    {'1': 'first_name', '3': 3, '4': 1, '5': 9, '10': 'firstName'},
    {'1': 'last_name', '3': 4, '4': 1, '5': 9, '10': 'lastName'},
    {'1': 'username', '3': 5, '4': 1, '5': 9, '10': 'username'},
    {'1': 'profile_picture', '3': 6, '4': 1, '5': 9, '10': 'profilePicture'},
    {'1': 'region', '3': 7, '4': 1, '5': 9, '10': 'region'},
    {'1': 'timezone', '3': 8, '4': 1, '5': 9, '10': 'timezone'},
    {'1': 'gender', '3': 9, '4': 1, '5': 9, '10': 'gender'},
    {'1': 'birth_date', '3': 10, '4': 1, '5': 9, '10': 'birthDate'},
    {'1': 'email_verified', '3': 11, '4': 1, '5': 8, '10': 'emailVerified'},
    {'1': 'created_at', '3': 12, '4': 1, '5': 9, '10': 'createdAt'},
    {'1': 'updated_at', '3': 13, '4': 1, '5': 9, '10': 'updatedAt'},
  ],
};

/// Descriptor for `UserRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userRequestDescriptor = $convert.base64Decode(
    'CgtVc2VyUmVxdWVzdBIOCgJpZBgBIAEoCVICaWQSFAoFZW1haWwYAiABKAlSBWVtYWlsEh0KCm'
    'ZpcnN0X25hbWUYAyABKAlSCWZpcnN0TmFtZRIbCglsYXN0X25hbWUYBCABKAlSCGxhc3ROYW1l'
    'EhoKCHVzZXJuYW1lGAUgASgJUgh1c2VybmFtZRInCg9wcm9maWxlX3BpY3R1cmUYBiABKAlSDn'
    'Byb2ZpbGVQaWN0dXJlEhYKBnJlZ2lvbhgHIAEoCVIGcmVnaW9uEhoKCHRpbWV6b25lGAggASgJ'
    'Ugh0aW1lem9uZRIWCgZnZW5kZXIYCSABKAlSBmdlbmRlchIdCgpiaXJ0aF9kYXRlGAogASgJUg'
    'liaXJ0aERhdGUSJQoOZW1haWxfdmVyaWZpZWQYCyABKAhSDWVtYWlsVmVyaWZpZWQSHQoKY3Jl'
    'YXRlZF9hdBgMIAEoCVIJY3JlYXRlZEF0Eh0KCnVwZGF0ZWRfYXQYDSABKAlSCXVwZGF0ZWRBdA'
    '==');

@$core.Deprecated('Use dailySuggestionRequestDescriptor instead')
const DailySuggestionRequest$json = {
  '1': 'DailySuggestionRequest',
  '2': [
    {
      '1': 'user',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.suggestion.UserRequest',
      '10': 'user'
    },
    {'1': 'date', '3': 2, '4': 1, '5': 9, '10': 'date'},
    {
      '1': 'recent_events',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.suggestion.EventRequest',
      '10': 'recentEvents'
    },
  ],
};

/// Descriptor for `DailySuggestionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dailySuggestionRequestDescriptor = $convert.base64Decode(
    'ChZEYWlseVN1Z2dlc3Rpb25SZXF1ZXN0EisKBHVzZXIYASABKAsyFy5zdWdnZXN0aW9uLlVzZX'
    'JSZXF1ZXN0UgR1c2VyEhIKBGRhdGUYAiABKAlSBGRhdGUSPQoNcmVjZW50X2V2ZW50cxgDIAMo'
    'CzIYLnN1Z2dlc3Rpb24uRXZlbnRSZXF1ZXN0UgxyZWNlbnRFdmVudHM=');

@$core.Deprecated('Use suggestionDescriptor instead')
const Suggestion$json = {
  '1': 'Suggestion',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.suggestion.SuggestionType',
      '10': 'type'
    },
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'description', '3': 3, '4': 1, '5': 9, '10': 'description'},
    {
      '1': 'metadata',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.suggestion.Suggestion.MetadataEntry',
      '10': 'metadata'
    },
  ],
  '3': [Suggestion_MetadataEntry$json],
};

@$core.Deprecated('Use suggestionDescriptor instead')
const Suggestion_MetadataEntry$json = {
  '1': 'MetadataEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `Suggestion`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List suggestionDescriptor = $convert.base64Decode(
    'CgpTdWdnZXN0aW9uEi4KBHR5cGUYASABKA4yGi5zdWdnZXN0aW9uLlN1Z2dlc3Rpb25UeXBlUg'
    'R0eXBlEhQKBXRpdGxlGAIgASgJUgV0aXRsZRIgCgtkZXNjcmlwdGlvbhgDIAEoCVILZGVzY3Jp'
    'cHRpb24SQAoIbWV0YWRhdGEYBCADKAsyJC5zdWdnZXN0aW9uLlN1Z2dlc3Rpb24uTWV0YWRhdG'
    'FFbnRyeVIIbWV0YWRhdGEaOwoNTWV0YWRhdGFFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2'
    'YWx1ZRgCIAEoCVIFdmFsdWU6AjgB');

@$core.Deprecated('Use suggestionResponseDescriptor instead')
const SuggestionResponse$json = {
  '1': 'SuggestionResponse',
  '2': [
    {
      '1': 'suggestions',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.suggestion.Suggestion',
      '10': 'suggestions'
    },
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `SuggestionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List suggestionResponseDescriptor = $convert.base64Decode(
    'ChJTdWdnZXN0aW9uUmVzcG9uc2USOAoLc3VnZ2VzdGlvbnMYASADKAsyFi5zdWdnZXN0aW9uLl'
    'N1Z2dlc3Rpb25SC3N1Z2dlc3Rpb25zEg4KAmlkGAIgASgJUgJpZA==');

@$core.Deprecated('Use dailySuggestionResponseDescriptor instead')
const DailySuggestionResponse$json = {
  '1': 'DailySuggestionResponse',
  '2': [
    {
      '1': 'suggestions',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.suggestion.Suggestion',
      '10': 'suggestions'
    },
    {'1': 'date', '3': 2, '4': 1, '5': 9, '10': 'date'},
  ],
};

/// Descriptor for `DailySuggestionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dailySuggestionResponseDescriptor =
    $convert.base64Decode(
        'ChdEYWlseVN1Z2dlc3Rpb25SZXNwb25zZRI4CgtzdWdnZXN0aW9ucxgBIAMoCzIWLnN1Z2dlc3'
        'Rpb24uU3VnZ2VzdGlvblILc3VnZ2VzdGlvbnMSEgoEZGF0ZRgCIAEoCVIEZGF0ZQ==');

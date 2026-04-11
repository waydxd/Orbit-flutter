// This is a generated file - do not edit.
//
// Generated from suggestion.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'suggestion.pb.dart' as $0;

export 'suggestion.pb.dart';

/// SuggestionService is the gRPC service for AI-driven event suggestions.
@$pb.GrpcServiceName('suggestion.SuggestionService')
class SuggestionServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  SuggestionServiceClient(super.channel, {super.options, super.interceptors});

  /// GetSuggestions analyzes an event and returns contextual suggestions.
  $grpc.ResponseFuture<$0.SuggestionResponse> getSuggestions(
    $0.EventRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getSuggestions, request, options: options);
  }

  /// GetDailySuggestions analyzes past activities and returns daily suggestions.
  $grpc.ResponseFuture<$0.DailySuggestionResponse> getDailySuggestions(
    $0.DailySuggestionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getDailySuggestions, request, options: options);
  }

  // method descriptors

  static final _$getSuggestions =
      $grpc.ClientMethod<$0.EventRequest, $0.SuggestionResponse>(
          '/suggestion.SuggestionService/GetSuggestions',
          ($0.EventRequest value) => value.writeToBuffer(),
          $0.SuggestionResponse.fromBuffer);
  static final _$getDailySuggestions =
      $grpc.ClientMethod<$0.DailySuggestionRequest, $0.DailySuggestionResponse>(
          '/suggestion.SuggestionService/GetDailySuggestions',
          ($0.DailySuggestionRequest value) => value.writeToBuffer(),
          $0.DailySuggestionResponse.fromBuffer);
}

@$pb.GrpcServiceName('suggestion.SuggestionService')
abstract class SuggestionServiceBase extends $grpc.Service {
  $core.String get $name => 'suggestion.SuggestionService';

  SuggestionServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.EventRequest, $0.SuggestionResponse>(
        'GetSuggestions',
        getSuggestions_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.EventRequest.fromBuffer(value),
        ($0.SuggestionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DailySuggestionRequest,
            $0.DailySuggestionResponse>(
        'GetDailySuggestions',
        getDailySuggestions_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DailySuggestionRequest.fromBuffer(value),
        ($0.DailySuggestionResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.SuggestionResponse> getSuggestions_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.EventRequest> $request) async {
    return getSuggestions($call, await $request);
  }

  $async.Future<$0.SuggestionResponse> getSuggestions(
      $grpc.ServiceCall call, $0.EventRequest request);

  $async.Future<$0.DailySuggestionResponse> getDailySuggestions_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DailySuggestionRequest> $request) async {
    return getDailySuggestions($call, await $request);
  }

  $async.Future<$0.DailySuggestionResponse> getDailySuggestions(
      $grpc.ServiceCall call, $0.DailySuggestionRequest request);
}

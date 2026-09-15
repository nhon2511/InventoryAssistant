// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_chat_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controller managing the AI assistant chat conversation.

@ProviderFor(AiChatController)
final aiChatControllerProvider = AiChatControllerProvider._();

/// Controller managing the AI assistant chat conversation.
final class AiChatControllerProvider
    extends $NotifierProvider<AiChatController, AiChatState> {
  /// Controller managing the AI assistant chat conversation.
  AiChatControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiChatControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiChatControllerHash();

  @$internal
  @override
  AiChatController create() => AiChatController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiChatState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiChatState>(value),
    );
  }
}

String _$aiChatControllerHash() => r'34215744c0d8d3c2e5840a4a904f4c3aaaf55ec7';

/// Controller managing the AI assistant chat conversation.

abstract class _$AiChatController extends $Notifier<AiChatState> {
  AiChatState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AiChatState, AiChatState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AiChatState, AiChatState>,
              AiChatState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

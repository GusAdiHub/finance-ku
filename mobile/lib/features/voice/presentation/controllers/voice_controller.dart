import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/voice_remote_datasource.dart';
import '../../data/models/voice_parsed_model.dart';

final voiceRemoteDataSourceProvider = Provider<VoiceRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return VoiceRemoteDataSourceImpl(dio);
});

class VoiceState {
  final bool isProcessing;
  final VoiceParsedModel? parsedResult;
  final String? errorMessage;

  const VoiceState({
    this.isProcessing = false,
    this.parsedResult,
    this.errorMessage,
  });

  VoiceState copyWith({
    bool? isProcessing,
    VoiceParsedModel? parsedResult,
    String? errorMessage,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return VoiceState(
      isProcessing: isProcessing ?? this.isProcessing,
      parsedResult: clearResult ? null : (parsedResult ?? this.parsedResult),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final voiceControllerProvider =
    NotifierProvider<VoiceController, VoiceState>(VoiceController.new);

class VoiceController extends Notifier<VoiceState> {
  late final VoiceRemoteDataSource _remoteDataSource;

  @override
  VoiceState build() {
    _remoteDataSource = ref.watch(voiceRemoteDataSourceProvider);
    return const VoiceState();
  }

  Future<VoiceParsedModel?> parseVoiceText(String text) async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final result = await _remoteDataSource.parseVoice(text);
      state = state.copyWith(
        isProcessing: false,
        parsedResult: result,
      );
      return result;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  void reset() {
    state = const VoiceState();
  }
}

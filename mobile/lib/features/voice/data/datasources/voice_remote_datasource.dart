import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/voice_parsed_model.dart';

abstract class VoiceRemoteDataSource {
  Future<VoiceParsedModel> parseVoice(String text);
}

class VoiceRemoteDataSourceImpl implements VoiceRemoteDataSource {
  final Dio _dio;

  VoiceRemoteDataSourceImpl(this._dio);

  @override
  Future<VoiceParsedModel> parseVoice(String text) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.voiceParse,
        data: {'text': text},
      );

      if (response.statusCode == 200) {
        return VoiceParsedModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          response.data['detail'] ?? 'Gagal memproses suara NLP.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response?.data['detail'] ?? e.message)
          : e.message;
      throw ServerException(
        detail?.toString() ?? 'Gagal memproses suara.',
        statusCode: e.response?.statusCode,
      );
    }
  }
}

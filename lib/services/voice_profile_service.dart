import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoiceProfileService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _recordingPath;

  /// Check if a voice profile exists
  Future<bool> hasVoiceProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profilePath = prefs.getString('voice_profile_path');
    if (profilePath == null) return false;

    final file = File(profilePath);
    return file.exists();
  }

  /// Start recording the voice profile
  Future<void> startRecording() async {
    // Check and request permission
    if (await _recorder.hasPermission()) {
      final directory = await getApplicationDocumentsDirectory();
      _recordingPath = '${directory.path}/voice_profile_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _recordingPath!,
      );
    } else {
      throw Exception('Microphone permission not granted');
    }
  }

  /// Stop recording
  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    return path;
  }

  /// Cancel recording without saving
  Future<void> cancelRecording() async {
    await _recorder.stop();
    if (_recordingPath != null) {
      final file = File(_recordingPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  /// Save the voice profile
  Future<void> saveVoiceProfile() async {
    if (_recordingPath == null) {
      throw Exception('No recording to save');
    }

    final prefs = await SharedPreferences.getInstance();

    // Delete old profile if exists
    final oldPath = prefs.getString('voice_profile_path');
    if (oldPath != null) {
      final oldFile = File(oldPath);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }
    }

    // Save new profile path
    await prefs.setString('voice_profile_path', _recordingPath!);
    await prefs.setInt('voice_profile_timestamp', DateTime.now().millisecondsSinceEpoch);

    // Extract and save voice characteristics
    await _extractVoiceCharacteristics(_recordingPath!);
  }

  /// Delete the voice profile
  Future<void> deleteVoiceProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profilePath = prefs.getString('voice_profile_path');

    if (profilePath != null) {
      final file = File(profilePath);
      if (await file.exists()) {
        await file.delete();
      }
    }

    await prefs.remove('voice_profile_path');
    await prefs.remove('voice_profile_timestamp');
    await prefs.remove('voice_avg_pitch');
    await prefs.remove('voice_pitch_variance');
  }

  /// Get voice profile path
  Future<String?> getVoiceProfilePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('voice_profile_path');
  }

  /// Extract voice characteristics for speaker identification
  /// This is a simplified version - in production, you'd use ML models
  Future<void> _extractVoiceCharacteristics(String audioPath) async {
    final prefs = await SharedPreferences.getInstance();

    // In a real implementation, you would:
    // 1. Load the audio file
    // 2. Extract features like pitch, frequency, timbre, etc.
    // 3. Store these characteristics

    // For now, we'll store placeholder values
    // These would be replaced with actual audio analysis
    await prefs.setDouble('voice_avg_pitch', 120.0); // Hz (placeholder)
    await prefs.setDouble('voice_pitch_variance', 15.0); // Hz (placeholder)

    // Additional characteristics that could be extracted:
    // - Speaking rate
    // - Energy/volume patterns
    // - Formant frequencies
    // - Mel-frequency cepstral coefficients (MFCCs)
  }

  /// Get voice characteristics
  Future<Map<String, double>> getVoiceCharacteristics() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'avg_pitch': prefs.getDouble('voice_avg_pitch') ?? 0,
      'pitch_variance': prefs.getDouble('voice_pitch_variance') ?? 0,
    };
  }
}

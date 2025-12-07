import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'voice_profile_service.dart';

/// Service for continuous speech-to-text with speaker identification
/// This service continuously listens and filters out the user's voice
class InterviewerSTTService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final VoiceProfileService _voiceProfileService = VoiceProfileService();

  bool _isListening = false;
  List<String> _interviewerTranscripts = [];
  Map<String, double>? _userVoiceProfile;

  /// Callback for when interviewer speech is detected
  Function(String)? onInterviewerSpeech;

  /// Initialize the STT service
  Future<bool> initialize() async {
    final available = await _speech.initialize(
      onError: (error) => print('STT Error: $error'),
      onStatus: (status) => print('STT Status: $status'),
    );

    if (available) {
      // Load user voice profile
      final hasProfile = await _voiceProfileService.hasVoiceProfile();
      if (hasProfile) {
        _userVoiceProfile = await _voiceProfileService.getVoiceCharacteristics();
      }
    }

    return available;
  }

  /// Start continuous listening
  Future<void> startListening() async {
    if (!_speech.isAvailable) {
      throw Exception('Speech recognition not available');
    }

    if (_isListening) return;

    _isListening = true;
    await _startContinuousListening();
  }

  /// Stop listening
  Future<void> stopListening() async {
    _isListening = false;
    await _speech.stop();
  }

  /// Internal method for continuous listening with automatic restart
  Future<void> _startContinuousListening() async {
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _processSpeechResult(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30), // Listen in 30-second chunks
      pauseFor: const Duration(seconds: 3), // Pause threshold
      partialResults: false,
      listenMode: stt.ListenMode.confirmation,
      cancelOnError: false,
    );

    // Automatically restart listening after each chunk
    if (_isListening) {
      await Future.delayed(const Duration(milliseconds: 500));
      await _startContinuousListening();
    }
  }

  /// Process speech result and determine if it's from the interviewer
  void _processSpeechResult(String text) {
    if (text.isEmpty) return;

    // If no voice profile, assume all speech is from interviewer
    if (_userVoiceProfile == null) {
      _addInterviewerTranscript(text);
      return;
    }

    // Speaker identification logic
    // In a real implementation, this would analyze audio characteristics
    // For now, we use a simplified approach:

    // Method 1: Use speech_to_text confidence scores
    // Lower confidence might indicate different speaker

    // Method 2: Implement basic heuristics
    // - Question detection (interviewer likely asks questions)
    // - Speaking pattern analysis

    final isQuestion = _isLikelyQuestion(text);
    final isInterviewer = _identifySpeaker(text, isQuestion);

    if (isInterviewer) {
      _addInterviewerTranscript(text);
    }
  }

  /// Identify if the speaker is the interviewer or the user
  /// Returns true if interviewer, false if user
  bool _identifySpeaker(String text, bool isQuestion) {
    // Simple heuristics for speaker identification:

    // 1. Questions are more likely from the interviewer
    if (isQuestion) return true;

    // 2. In a real implementation, you would:
    //    - Analyze audio pitch against user profile
    //    - Use ML model for speaker diarization
    //    - Compare voice characteristics

    // 3. For now, we'll use a probability-based approach
    //    If it's a question, high probability it's the interviewer
    //    Otherwise, we need more sophisticated analysis

    // This is a placeholder - in production, you'd use:
    // - Google Cloud Speech-to-Text with speaker diarization
    // - Azure Cognitive Services
    // - On-device ML model (TensorFlow Lite)

    return isQuestion;
  }

  /// Check if text is likely a question
  bool _isLikelyQuestion(String text) {
    final lowerText = text.toLowerCase().trim();

    // Question words
    final questionWords = [
      'what', 'when', 'where', 'who', 'why', 'how',
      'can you', 'could you', 'would you', 'will you',
      'do you', 'did you', 'have you', 'are you',
      'is there', 'tell me', 'explain', 'describe',
    ];

    for (final word in questionWords) {
      if (lowerText.startsWith(word)) return true;
    }

    // Ends with question mark (if STT includes punctuation)
    if (lowerText.endsWith('?')) return true;

    return false;
  }

  /// Add transcript to interviewer list
  void _addInterviewerTranscript(String text) {
    _interviewerTranscripts.add(text);
    onInterviewerSpeech?.call(text);
  }

  /// Get all interviewer transcripts
  List<String> getInterviewerTranscripts() {
    return List.unmodifiable(_interviewerTranscripts);
  }

  /// Clear all transcripts
  void clearTranscripts() {
    _interviewerTranscripts.clear();
  }

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Dispose resources
  void dispose() {
    _speech.stop();
  }
}

/// Advanced speaker identification service
/// This would be implemented in production with ML models
class SpeakerIdentificationService {
  /// Compare audio segment with user voice profile
  /// Returns confidence score (0-1) that audio is from the user
  Future<double> getUserSimilarityScore(
    String audioPath,
    Map<String, double> userProfile,
  ) async {
    // In production, this would:
    // 1. Extract audio features (MFCC, pitch, formants, etc.)
    // 2. Compare with stored user profile
    // 3. Use ML model to determine similarity
    // 4. Return confidence score

    // Placeholder implementation
    return 0.5;
  }

  /// Extract voice characteristics from audio segment
  Future<Map<String, double>> extractVoiceFeatures(String audioPath) async {
    // Would extract:
    // - Pitch (fundamental frequency)
    // - Formant frequencies (F1, F2, F3)
    // - MFCCs (Mel-frequency cepstral coefficients)
    // - Speaking rate
    // - Energy/amplitude patterns

    return {
      'pitch': 0.0,
      'pitch_variance': 0.0,
    };
  }
}

import 'dart:async';
import 'dart:math';
import 'package:record/record.dart';
import 'voice_profile_service.dart';

/// Mock STT Service for testing
/// Replace this with your actual STT API integration
///
/// Recommended APIs for production:
/// 1. AssemblyAI (Best for speaker diarization) - https://www.assemblyai.com/
/// 2. Google Cloud Speech-to-Text with speaker diarization
/// 3. Azure Cognitive Services Speech
/// 4. Deepgram API
/// 5. Amazon Transcribe with speaker identification
class MockSTTService {
  final AudioRecorder _recorder = AudioRecorder();
  final VoiceProfileService _voiceProfileService = VoiceProfileService();

  bool _isListening = false;
  Timer? _mockTranscriptionTimer;

  /// Callback when interviewer speech is detected (user voice filtered out)
  Function(String)? onInterviewerSpeech;

  /// Mock questions for testing
  final List<String> _mockInterviewQuestions = [
    "Can you tell me about yourself?",
    "What are your greatest strengths?",
    "Where do you see yourself in 5 years?",
    "Why do you want to work here?",
    "What is your biggest weakness?",
    "How do you handle stress and pressure?",
    "Can you describe a challenging project you worked on?",
    "What makes you a good fit for this position?",
    "Tell me about a time you showed leadership",
    "What are your salary expectations?",
  ];

  int _questionIndex = 0;

  /// Initialize the service
  Future<bool> initialize() async {
    // In production, this would:
    // 1. Initialize the STT API client
    // 2. Load API credentials
    // 3. Setup connection

    print('Mock STT Service initialized');
    return true;
  }

  /// Check if user has voice profile
  Future<bool> hasVoiceProfile() async {
    return await _voiceProfileService.hasVoiceProfile();
  }

  /// Start listening and transcribing
  Future<void> startListening() async {
    if (_isListening) return;

    // Check microphone permission
    if (await _recorder.hasPermission()) {
      _isListening = true;

      // Start actual audio recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
      );

      // ========================================
      // REPLACE THIS SECTION WITH YOUR STT API
      // ========================================
      // This mock implementation simulates periodic transcriptions
      // In production, you would:
      // 1. Stream audio to your STT API
      // 2. Receive real-time transcriptions
      // 3. Process speaker diarization results
      // 4. Filter based on user's voice profile

      _startMockTranscription();

      // Example for real API integration:
      /*
      // Stream audio to API
      audioStream = await _recorder.getAudioStream();

      // AssemblyAI Example:
      final transcript = await assemblyAI.transcribe(
        audioStream,
        options: TranscribeOptions(
          speakerLabels: true,
          speakerCount: 2,
        ),
      );

      // Process results
      for (final utterance in transcript.utterances) {
        if (utterance.speaker != userSpeakerId) {
          // This is the interviewer
          onInterviewerSpeech?.call(utterance.text);
        }
      }
      */
    } else {
      throw Exception('Microphone permission not granted');
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    _isListening = false;
    _mockTranscriptionTimer?.cancel();
    await _recorder.stop();
  }

  /// Mock transcription for testing
  /// REPLACE THIS WITH REAL API CALLS
  void _startMockTranscription() {
    _questionIndex = 0;

    // Simulate receiving transcriptions every 5-10 seconds
    _mockTranscriptionTimer = Timer.periodic(
      const Duration(seconds: 7),
      (timer) {
        if (!_isListening) {
          timer.cancel();
          return;
        }

        // Simulate receiving a transcription
        final mockTranscript = _getNextMockQuestion();

        // Simulate speaker identification
        // In production, your API would tell you which speaker this is
        final isInterviewer = _identifySpeaker(mockTranscript);

        if (isInterviewer) {
          // Only pass interviewer's speech to callback
          onInterviewerSpeech?.call(mockTranscript);
        }
      },
    );
  }

  String _getNextMockQuestion() {
    final question = _mockInterviewQuestions[_questionIndex];
    _questionIndex = (_questionIndex + 1) % _mockInterviewQuestions.length;
    return question;
  }

  /// Identify if the speaker is the interviewer (not the user)
  ///
  /// PRODUCTION IMPLEMENTATION:
  /// This should use the API's speaker diarization results or
  /// compare audio characteristics with the user's voice profile
  bool _identifySpeaker(String text) {
    // Mock implementation: assume all mock questions are from interviewer
    // In production, your API would provide speaker labels

    // For APIs like AssemblyAI, you would:
    // 1. Get speaker label from API response
    // 2. Compare with known user speaker ID
    // 3. Return true if speaker is NOT the user

    return true; // Mock: all are interviewer for testing
  }

  /// Question detection - enhanced version
  /// Detects if the given text is a question
  bool isQuestion(String text) {
    if (text.isEmpty) return false;

    final lowerText = text.toLowerCase().trim();

    // Method 1: Check for question mark
    if (lowerText.endsWith('?')) return true;

    // Method 2: Check for question words at start
    final questionStarters = [
      // WH-questions
      'what', 'when', 'where', 'who', 'why', 'how', 'which', 'whose',

      // Auxiliary verb questions
      'can you', 'could you', 'would you', 'will you', 'should you',
      'do you', 'did you', 'does', 'have you', 'has', 'had you',
      'are you', 'is', 'were you', 'was',

      // Polite requests
      'may i', 'might i', 'could we', 'shall we',

      // Common interview starters
      'tell me', 'explain', 'describe', 'walk me through',
      'can you talk about', 'give me an example',
    ];

    for (final starter in questionStarters) {
      if (lowerText.startsWith(starter)) return true;
    }

    // Method 3: Check for question phrases anywhere in text
    final questionPhrases = [
      'tell me about',
      'what do you think',
      'how would you',
      'can you describe',
      'give me an example of',
    ];

    for (final phrase in questionPhrases) {
      if (lowerText.contains(phrase)) return true;
    }

    // Method 4: Advanced heuristics (optional)
    // Check for inverted sentence structure typical of questions
    final words = lowerText.split(' ');
    if (words.length >= 2) {
      final firstTwoWords = '${words[0]} ${words[1]}';
      final invertedPatterns = [
        'are there', 'is there', 'were there', 'was there',
        'can i', 'could i', 'should i', 'would i',
        'do i', 'does it', 'did it',
      ];

      for (final pattern in invertedPatterns) {
        if (firstTwoWords.startsWith(pattern)) return true;
      }
    }

    return false;
  }

  /// Dispose resources
  void dispose() {
    _mockTranscriptionTimer?.cancel();
    _recorder.dispose();
  }
}

/// Configuration class for real STT API integration
/// Customize this based on your chosen API
class STTApiConfig {
  final String apiKey;
  final String apiUrl;
  final bool enableSpeakerDiarization;
  final int expectedSpeakers;
  final String language;

  STTApiConfig({
    required this.apiKey,
    required this.apiUrl,
    this.enableSpeakerDiarization = true,
    this.expectedSpeakers = 2, // User + Interviewer
    this.language = 'en-US',
  });
}

/// Example API response structure
/// Adapt this to match your actual API's response format
class TranscriptionResponse {
  final String text;
  final String speakerId;
  final double confidence;
  final double startTime;
  final double endTime;

  TranscriptionResponse({
    required this.text,
    required this.speakerId,
    required this.confidence,
    required this.startTime,
    required this.endTime,
  });

  factory TranscriptionResponse.fromJson(Map<String, dynamic> json) {
    return TranscriptionResponse(
      text: json['text'] ?? '',
      speakerId: json['speaker_id'] ?? '',
      confidence: json['confidence'] ?? 0.0,
      startTime: json['start_time'] ?? 0.0,
      endTime: json['end_time'] ?? 0.0,
    );
  }
}

/*
==============================================================================
PRODUCTION API INTEGRATION GUIDE
==============================================================================

OPTION 1: AssemblyAI (Recommended for speaker diarization)
---------------------------------------------------------
1. Add dependency: assemblyai_flutter (or use HTTP client)
2. Get API key from https://www.assemblyai.com/
3. Implementation:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class AssemblyAIService {
  final String apiKey = 'YOUR_API_KEY';

  Future<String> uploadAudio(String audioPath) async {
    final file = File(audioPath);
    final bytes = await file.readAsBytes();

    final response = await http.post(
      Uri.parse('https://api.assemblyai.com/v2/upload'),
      headers: {'authorization': apiKey},
      body: bytes,
    );

    return json.decode(response.body)['upload_url'];
  }

  Future<String> transcribe(String audioUrl) async {
    final response = await http.post(
      Uri.parse('https://api.assemblyai.com/v2/transcript'),
      headers: {
        'authorization': apiKey,
        'content-type': 'application/json',
      },
      body: json.encode({
        'audio_url': audioUrl,
        'speaker_labels': true,
      }),
    );

    return json.decode(response.body)['id'];
  }

  Future<Map<String, dynamic>> getTranscript(String transcriptId) async {
    final response = await http.get(
      Uri.parse('https://api.assemblyai.com/v2/transcript/$transcriptId'),
      headers: {'authorization': apiKey},
    );

    return json.decode(response.body);
  }
}
```

OPTION 2: Google Cloud Speech-to-Text
--------------------------------------
1. Add dependency: google_speech
2. Setup GCP project and enable Speech-to-Text API
3. Download service account credentials
4. Use speaker diarization feature

OPTION 3: Deepgram API
---------------------
- Real-time streaming transcription
- Good speaker diarization
- WebSocket-based streaming

OPTION 4: Azure Cognitive Services
----------------------------------
- Microsoft's Speech SDK
- Good for enterprise use
- Supports speaker recognition

For voice learning/identification:
-----------------------------------
1. Voice fingerprinting: Extract MFCC, pitch, formants from user's profile
2. Speaker embedding: Use pre-trained models (e.g., resemblyzer, pyannote)
3. Cloud APIs: Use speaker diarization from STT services above
4. Compare: Match real-time speaker with stored user voice profile
==============================================================================
*/

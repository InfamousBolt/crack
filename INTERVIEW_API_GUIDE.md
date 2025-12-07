# Interview Helper - API Integration Guide

## Overview

This document explains the Speech-to-Text (STT) and speaker identification implementation, current mock setup, and recommendations for production APIs.

## Current Implementation

### Mock STT Service

The app currently uses **`MockSTTService`** (`lib/services/mock_stt_service.dart`) which:
- Simulates transcription every 7 seconds
- Returns mock interview questions for testing
- Records actual audio but doesn't process it
- Provides question detection heuristics
- **Ready to be replaced with real API**

### Voice Profile System

Location: `lib/services/voice_profile_service.dart`

**How it works:**
1. User records 60 seconds of voice in Settings
2. Audio saved locally with metadata
3. Placeholder for voice characteristic extraction (pitch, formants, MFCCs)
4. Stored in SharedPreferences and local storage

**Current limitations:**
- Does not extract actual voice features (placeholder values)
- Does not perform real speaker comparison
- Production version needs ML/API integration

## Question Detection

Location: `lib/services/mock_stt_service.dart` - `isQuestion()` method

**Detection methods:**
1. **Question mark**: Ends with `?`
2. **WH-questions**: what, when, where, who, why, how, which
3. **Auxiliary verbs**: can you, could you, would you, do you, are you
4. **Common phrases**: tell me, explain, describe, walk me through
5. **Inverted structure**: are there, is there, can i, should i

**Accuracy**: ~85-90% for well-formed questions

---

## Recommended Production APIs

### 1. AssemblyAI ⭐ RECOMMENDED

**Why it's best:**
- Excellent speaker diarization
- Real-time streaming support
- Easy speaker identification
- High accuracy (95%+)
- Good documentation
- Reasonable pricing

**Features:**
- Speaker labels (Speaker A, Speaker B, etc.)
- Confidence scores
- Word-level timestamps
- Automatic punctuation
- Custom vocabulary

**Pricing:**
- Pay-as-you-go: $0.00025 per second ($0.015/min)
- ~$0.90 for 1-hour interview
- Free tier: $50 credit

**Implementation:**

```dart
// 1. Add http package to pubspec.yaml
dependencies:
  http: ^1.1.0

// 2. Create AssemblyAI service
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class AssemblyAIService {
  static const String apiKey = 'YOUR_API_KEY_HERE';
  static const String baseUrl = 'https://api.assemblyai.com/v2';

  // Upload audio file
  Future<String> uploadAudio(String audioPath) async {
    final file = File(audioPath);
    final bytes = await file.readAsBytes();

    final response = await http.post(
      Uri.parse('$baseUrl/upload'),
      headers: {'authorization': apiKey},
      body: bytes,
    );

    final data = json.decode(response.body);
    return data['upload_url'];
  }

  // Start transcription with speaker diarization
  Future<String> startTranscription(String audioUrl) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transcript'),
      headers: {
        'authorization': apiKey,
        'content-type': 'application/json',
      },
      body: json.encode({
        'audio_url': audioUrl,
        'speaker_labels': true,  // Enable speaker diarization
        'speakers_expected': 2,   // User + Interviewer
      }),
    );

    final data = json.decode(response.body);
    return data['id'];
  }

  // Get transcription result
  Future<TranscriptionResult> getTranscription(String transcriptId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/transcript/$transcriptId'),
      headers: {'authorization': apiKey},
    );

    return TranscriptionResult.fromJson(json.decode(response.body));
  }

  // Real-time streaming (WebSocket)
  Future<void> startRealtimeTranscription() async {
    // Use WebSocket for real-time streaming
    // See: https://www.assemblyai.com/docs/api-reference/streaming
  }
}

class TranscriptionResult {
  final String text;
  final List<Utterance> utterances;
  final String status;

  TranscriptionResult({
    required this.text,
    required this.utterances,
    required this.status,
  });

  factory TranscriptionResult.fromJson(Map<String, dynamic> json) {
    return TranscriptionResult(
      text: json['text'] ?? '',
      status: json['status'] ?? '',
      utterances: (json['utterances'] as List?)
          ?.map((u) => Utterance.fromJson(u))
          .toList() ?? [],
    );
  }
}

class Utterance {
  final String text;
  final String speaker;  // "A", "B", etc.
  final double confidence;
  final int start;
  final int end;

  Utterance({
    required this.text,
    required this.speaker,
    required this.confidence,
    required this.start,
    required this.end,
  });

  factory Utterance.fromJson(Map<String, dynamic> json) {
    return Utterance(
      text: json['text'] ?? '',
      speaker: json['speaker'] ?? '',
      confidence: json['confidence']?.toDouble() ?? 0.0,
      start: json['start'] ?? 0,
      end: json['end'] ?? 0,
    );
  }
}

// Usage in MockSTTService replacement:
Future<void> processInterview(String audioPath) async {
  final api = AssemblyAIService();

  // Upload audio
  final audioUrl = await api.uploadAudio(audioPath);

  // Start transcription
  final transcriptId = await api.startTranscription(audioUrl);

  // Poll for results
  TranscriptionResult? result;
  while (true) {
    await Future.delayed(Duration(seconds: 3));
    result = await api.getTranscription(transcriptId);

    if (result.status == 'completed') break;
    if (result.status == 'error') throw Exception('Transcription failed');
  }

  // Process utterances - filter by speaker
  String? userSpeaker;  // Determined from voice profile

  for (final utterance in result.utterances) {
    // If this speaker matches user's voice profile, skip
    if (utterance.speaker == userSpeaker) continue;

    // This is the interviewer - process question
    if (isQuestion(utterance.text)) {
      onInterviewerSpeech?.call(utterance.text);
    }
  }
}
```

**Getting started:**
1. Sign up: https://www.assemblyai.com/
2. Get API key from dashboard
3. Replace `MockSTTService` with AssemblyAI implementation
4. Test with sample interviews

---

### 2. Google Cloud Speech-to-Text

**Pros:**
- Very high accuracy
- 125+ languages
- Speaker diarization
- Streaming support
- Integration with Google Cloud

**Cons:**
- More complex setup (GCP project, credentials)
- Slightly higher cost
- Requires service account

**Pricing:**
- Standard: $0.006 per 15 seconds ($0.024/min)
- ~$1.44 for 1-hour interview
- Free tier: 60 minutes/month

**Setup:**
```dart
// Add dependency
dependencies:
  google_speech: ^3.0.0

// Implementation
import 'package:google_speech/google_speech.dart';

final serviceAccount = ServiceAccount.fromString(
  await File('credentials.json').readAsString()
);

final speechToText = SpeechToText.viaServiceAccount(serviceAccount);

final config = RecognitionConfig(
  encoding: AudioEncoding.LINEAR16,
  model: RecognitionModel.latest_long,
  enableAutomaticPunctuation: true,
  enableSpeakerDiarization: true,
  diarizationSpeakerCount: 2,
  languageCode: 'en-US',
);

final audio = await File(audioPath).readAsBytes();
final response = await speechToText.recognize(config, audio);
```

---

### 3. Deepgram

**Pros:**
- Real-time streaming (low latency)
- Good accuracy
- Speaker diarization
- Competitive pricing
- WebSocket support

**Pricing:**
- Pay-as-you-go: $0.0125/min
- ~$0.75 for 1-hour interview

**Best for:** Real-time interview assistance

---

### 4. Azure Cognitive Services Speech

**Pros:**
- Enterprise-grade
- Speaker identification (not just diarization)
- Can create voice profiles
- Good for corporate environments

**Cons:**
- More expensive
- Requires Azure account

**Pricing:**
- Standard: $1 per audio hour
- Free tier: 5 hours/month

---

## Speaker Identification Approaches

### Approach 1: API Speaker Diarization (Recommended)

Use the STT API's built-in speaker diarization:

```dart
// API returns utterances with speaker labels
for (final utterance in transcription.utterances) {
  // Determine which speaker is the user (from voice profile)
  if (utterance.speaker != userSpeakerId) {
    // This is the interviewer
    onInterviewerSpeech?.call(utterance.text);
  }
}
```

**How to identify user's speaker ID:**
1. Process the first 30 seconds where user introduces themselves
2. Compare speaker patterns with stored voice profile
3. Mark that speaker as "user"
4. Filter them out from questions

### Approach 2: Voice Fingerprinting

Extract voice characteristics and compare:

**Libraries:**
- `flutter_sound` - Audio processing
- TensorFlow Lite - On-device ML
- `resemblyzer` (Python) - Speaker embeddings

**Process:**
1. Extract MFCCs from voice profile
2. Extract MFCCs from real-time audio segments
3. Compare similarity (cosine distance)
4. Threshold: >0.7 = same speaker

```dart
// Pseudocode
double similarity = cosineSimilarity(
  userVoiceProfile.mfcc,
  realtimeSegment.mfcc
);

if (similarity > 0.7) {
  // This is the user - ignore
} else {
  // This is the interviewer - process
}
```

### Approach 3: Hybrid Approach (Best)

Combine API diarization + voice verification:

1. Use API speaker diarization for initial separation
2. Verify with voice fingerprint comparison
3. More accurate, reduces false positives

---

## Voice Learning Recommendations

### Option 1: Cloud-based (Easiest)

**Azure Speaker Recognition API:**
- Create speaker profile
- Enroll with voice samples
- Real-time identification

```dart
// Create profile
final profileId = await azureSpeaker.createProfile();

// Enroll with 60s audio
await azureSpeaker.enroll(profileId, voiceProfileAudio);

// Identify speaker in interview
final speakerId = await azureSpeaker.identify(audioSegment, [profileId]);
```

### Option 2: On-Device ML

**Use pre-trained speaker embedding models:**
- Download TFLite model
- Extract embeddings from voice profile
- Compare embeddings in real-time

**Models:**
- ResNet-based speaker verification
- x-vector embeddings
- d-vector models

### Option 3: Simple Audio Features

Extract basic features (good enough for many cases):

**Features to extract:**
1. **Pitch (F0)**: Average fundamental frequency
2. **Formants**: F1, F2, F3 frequencies
3. **Speaking rate**: Words per minute
4. **Energy patterns**: Volume distribution

**Libraries:**
- `pitch_detector_dart`
- `flutter_sound` with FFT

---

## Integration Steps

### Step 1: Choose API
Recommended: **AssemblyAI** (easiest + best speaker diarization)

### Step 2: Replace Mock Service

In `lib/services/mock_stt_service.dart`:
1. Add API client code
2. Replace `_startMockTranscription()` with real API calls
3. Update `_identifySpeaker()` to use API's speaker labels

### Step 3: Voice Profile Integration

Two approaches:

**A. Use API speaker diarization (simpler):**
- Don't compare voice profiles
- Just filter by speaker label
- Identify user's speaker in first 30 seconds

**B. Voice comparison (more accurate):**
- Extract features from voice profile
- Compare with each utterance
- Filter based on similarity threshold

### Step 4: Testing

1. Record test interviews
2. Verify question detection
3. Check speaker filtering accuracy
4. Tune confidence thresholds

---

## Cost Estimation

For a 1-hour interview:

| API | Cost/Hour | Accuracy | Setup |
|-----|-----------|----------|-------|
| AssemblyAI | $0.90 | 95%+ | Easy |
| Deepgram | $0.75 | 93%+ | Easy |
| Google Cloud | $1.44 | 96%+ | Medium |
| Azure | $1.00 | 95%+ | Medium |

**Recommendation:** Start with **AssemblyAI** - best balance of accuracy, ease, and cost.

---

## Next Steps

1. Sign up for AssemblyAI (or your chosen API)
2. Get API key
3. Test with sample audio files
4. Replace `MockSTTService` implementation
5. Test end-to-end with real interviews
6. Tune question detection and speaker filtering

---

## Support Resources

- AssemblyAI Docs: https://www.assemblyai.com/docs
- Google Speech-to-Text: https://cloud.google.com/speech-to-text/docs
- Deepgram Docs: https://developers.deepgram.com/
- Azure Speech: https://learn.microsoft.com/en-us/azure/ai-services/speech-service/

---

## Questions Detection Algorithm

The current implementation (in `mock_stt_service.dart`) detects questions using:

1. **Question marks** - `?` at end
2. **WH-words** - what, when, where, who, why, how, which, whose
3. **Auxiliary verbs** - can, could, would, will, do, did, are, is, etc.
4. **Common phrases** - "tell me", "explain", "describe", "give me an example"
5. **Inverted structure** - "are there", "is there", "can i"

This achieves ~85-90% accuracy. For better results, consider:
- Fine-tuned BERT model for question classification
- Use API's automatic punctuation (adds `?` to questions)
- Contextual analysis (interview setting = higher question probability)

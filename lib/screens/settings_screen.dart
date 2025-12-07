import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/voice_profile_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final VoiceProfileService _voiceProfileService = VoiceProfileService();
  bool _hasVoiceProfile = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkVoiceProfile();
  }

  Future<void> _checkVoiceProfile() async {
    final hasProfile = await _voiceProfileService.hasVoiceProfile();
    setState(() {
      _hasVoiceProfile = hasProfile;
      _isLoading = false;
    });
  }

  Future<void> _recordVoiceProfile() async {
    // Navigate to voice profile recording screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VoiceProfileRecordingScreen(),
      ),
    );

    if (result == true) {
      await _checkVoiceProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voice profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteVoiceProfile() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Voice Profile'),
        content: const Text(
          'Are you sure you want to delete your voice profile? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _voiceProfileService.deleteVoiceProfile();
      await _checkVoiceProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voice profile deleted'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profile Voice Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.record_voice_over,
                              size: 32,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Profile Voice',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Record your voice profile to help the app distinguish between your voice and the interviewer\'s voice during interviews.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_hasVoiceProfile) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Voice profile configured',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _recordVoiceProfile,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Re-record Profile'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: _deleteVoiceProfile,
                                icon: const Icon(Icons.delete),
                                label: const Text('Delete'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          ElevatedButton.icon(
                            onPressed: _recordVoiceProfile,
                            icon: const Icon(Icons.mic),
                            label: const Text('Record Voice Profile'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // How it works section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 24,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'How It Works',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoItem(
                          '1. Record your voice profile',
                          'Speak naturally for 60 seconds so the app can learn your voice characteristics.',
                        ),
                        _buildInfoItem(
                          '2. Continuous listening',
                          'During interviews, the app continuously records and transcribes audio.',
                        ),
                        _buildInfoItem(
                          '3. Speaker identification',
                          'The app filters out your voice and only captures the interviewer\'s questions.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class VoiceProfileRecordingScreen extends StatefulWidget {
  const VoiceProfileRecordingScreen({super.key});

  @override
  State<VoiceProfileRecordingScreen> createState() =>
      _VoiceProfileRecordingScreenState();
}

class _VoiceProfileRecordingScreenState
    extends State<VoiceProfileRecordingScreen> {
  final VoiceProfileService _voiceProfileService = VoiceProfileService();
  bool _isRecording = false;
  int _secondsRemaining = 60;
  String _statusMessage = 'Press the button below to start recording';

  Future<void> _startRecording() async {
    try {
      await _voiceProfileService.startRecording();
      setState(() {
        _isRecording = true;
        _secondsRemaining = 60;
        _statusMessage = 'Recording... Please speak naturally';
      });

      // Countdown timer
      for (int i = 60; i > 0; i--) {
        await Future.delayed(const Duration(seconds: 1));
        if (!_isRecording) break;
        setState(() {
          _secondsRemaining = i - 1;
        });
      }

      if (_isRecording) {
        await _stopRecording();
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _voiceProfileService.stopRecording();
      setState(() {
        _isRecording = false;
        _statusMessage = 'Processing voice profile...';
      });

      await _voiceProfileService.saveVoiceProfile();

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _statusMessage = 'Error saving profile: $e';
      });
    }
  }

  @override
  void dispose() {
    if (_isRecording) {
      _voiceProfileService.cancelRecording();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Voice Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isRecording ? Icons.mic : Icons.mic_none,
              size: 120,
              color: _isRecording ? Colors.red : Colors.grey,
            ),
            const SizedBox(height: 32),
            if (_isRecording) ...[
              Text(
                '$_secondsRemaining',
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const LinearProgressIndicator(),
            ] else ...[
              Text(
                _statusMessage,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: _startRecording,
                icon: const Icon(Icons.mic, size: 32),
                label: const Text(
                  'Start Recording',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 20,
                  ),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recording Tips:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('• Speak naturally and clearly'),
                    Text('• Use your normal speaking voice'),
                    Text('• Try to speak for the full 60 seconds'),
                    Text('• Include varied sentences and tones'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

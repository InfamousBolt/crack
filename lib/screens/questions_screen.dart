import 'package:flutter/material.dart';
import '../services/mock_stt_service.dart';

class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key});

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  final MockSTTService _sttService = MockSTTService();
  bool _isInterviewActive = false;
  bool _isInitialized = false;
  List<InterviewQuestion> _detectedQuestions = [];
  String _currentTranscript = '';

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final initialized = await _sttService.initialize();
    setState(() {
      _isInitialized = initialized;
    });

    // Set callback for when interviewer speech is detected
    _sttService.onInterviewerSpeech = (text) {
      setState(() {
        _currentTranscript = text;
      });

      // Detect if it's a question and add to list
      if (_sttService.isQuestion(text)) {
        setState(() {
          _detectedQuestions.add(InterviewQuestion(
            question: text,
            timestamp: DateTime.now(),
          ));
        });
      }
    };
  }

  Future<void> _toggleInterview() async {
    if (!_isInitialized) {
      _showErrorDialog('Service not initialized. Please wait.');
      return;
    }

    if (_isInterviewActive) {
      // Stop interview
      await _sttService.stopListening();
      setState(() {
        _isInterviewActive = false;
        _currentTranscript = '';
      });

      _showSuccessSnackbar('Interview stopped');
    } else {
      // Check if voice profile exists
      final hasProfile = await _sttService.hasVoiceProfile();
      if (!hasProfile) {
        _showErrorDialog(
          'Please record your voice profile in Settings before starting an interview.',
        );
        return;
      }

      // Start interview
      try {
        await _sttService.startListening();
        setState(() {
          _isInterviewActive = true;
          _detectedQuestions.clear();
        });

        _showSuccessSnackbar('Interview started');
      } catch (e) {
        _showErrorDialog('Error starting interview: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    if (_isInterviewActive) {
      _sttService.stopListening();
    }
    _sttService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interview'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_detectedQuestions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear all questions',
              onPressed: () {
                setState(() {
                  _detectedQuestions.clear();
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Control Panel
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              children: [
                // Status Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isInterviewActive ? Colors.red : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isInterviewActive
                          ? 'Recording Active'
                          : 'Interview Not Started',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _isInterviewActive ? Colors.red : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Start/Stop Button
                ElevatedButton.icon(
                  onPressed: _isInitialized ? _toggleInterview : null,
                  icon: Icon(
                    _isInterviewActive ? Icons.stop : Icons.play_arrow,
                    size: 32,
                  ),
                  label: Text(
                    _isInterviewActive ? 'Stop Interview' : 'Start Interview',
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isInterviewActive ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    minimumSize: const Size(200, 60),
                  ),
                ),

                // Live Transcript
                if (_isInterviewActive && _currentTranscript.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.mic, size: 16, color: Colors.blue),
                            SizedBox(width: 4),
                            Text(
                              'Live Transcript:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentTranscript,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Questions List
          Expanded(
            child: _detectedQuestions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.question_answer_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isInterviewActive
                              ? 'Listening for questions...'
                              : 'No questions detected yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (!_isInterviewActive) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Start an interview to begin',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _detectedQuestions.length,
                    itemBuilder: (context, index) {
                      final question = _detectedQuestions[index];
                      return _QuestionCard(
                        question: question,
                        index: index,
                        onDelete: () {
                          setState(() {
                            _detectedQuestions.removeAt(index);
                          });
                        },
                      );
                    },
                  ),
          ),

          // Questions Count
          if (_detectedQuestions.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Text(
                '${_detectedQuestions.length} question${_detectedQuestions.length != 1 ? 's' : ''} detected',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final InterviewQuestion question;
  final int index;
  final VoidCallback onDelete;

  const _QuestionCard({
    required this.question,
    required this.index,
    required this.onDelete,
  });

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Q${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(question.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                  color: Colors.red,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              question.question,
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InterviewQuestion {
  final String question;
  final DateTime timestamp;

  InterviewQuestion({
    required this.question,
    required this.timestamp,
  });
}

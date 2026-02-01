import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'models.dart';
import 'data_repository.dart';
import 'services/tts_service.dart';

class _LessonStats {
  int correct = 0;
  int wrong = 0;
  Set<String> characters = {};
}

class WhackAMoleGame extends StatefulWidget {
  const WhackAMoleGame({super.key});

  @override
  State<WhackAMoleGame> createState() => _WhackAMoleGameState();
}

class _WhackAMoleGameState extends State<WhackAMoleGame> with SingleTickerProviderStateMixin {
  final DataRepository _repository = DataRepository();
  final AudioPlayer _audioPlayer = AudioPlayer();
  TtsService? _ttsService;
  
  List<HanziChar> _allCharacters = [];
  List<HanziChar> _gridCharacters = [];
  HanziChar? _targetCharacter;
  HanziChar? _hitCharacter; // Track which character was correctly hit for animation
  
  bool _isLoading = true;
  int _score = 0;
  int _combo = 0;
  bool _isGameActive = false;
  final Map<String, _LessonStats> _sessionStats = {};
  
  // Animation for the "mole" pop up
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initGame();
  }
  
  @override
  void dispose() {
    _saveStats();
    _animationController.dispose();
    _audioPlayer.dispose();
    _ttsService?.stop();
    super.dispose();
  }

  void _saveStats() {
    if (_sessionStats.isEmpty) return;

    final records = _sessionStats.entries.map((entry) {
      return StudyRecord(
        date: DateTime.now(),
        lessonTitle: entry.key,
        characterCount: entry.value.characters.length,
        correctCount: entry.value.correct,
        wrongCount: entry.value.wrong,
      );
    }).toList();

    _repository.saveStudyRecords(records);
  }

  Future<void> _initGame() async {
    // Initialize TTS
    _ttsService = await TtsServiceFactory.getService();
    
    // Load characters
    await _loadCharacters();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _startGame();
    }
  }

  Future<void> _loadCharacters() async {
    try {
      // Check for configured game scope
      List<String> scopeIds = await _repository.getGameScope();
      
      // Load all lessons to filter by scope or default
      final lessons = await _repository.getLessonList(LessonType.literacy);
      
      List<LessonItem> targetLessons = [];
      if (scopeIds.isNotEmpty) {
        // Filter lessons by configured IDs
        targetLessons = lessons.where((l) => scopeIds.contains(l.id)).toList();
      } 
      
      // Fallback if no scope or filtered result is empty
      if (targetLessons.isEmpty) {
        // Load first 10 lessons as default
        final count = min(lessons.length, 10);
        targetLessons = lessons.take(count).toList();
      }
      
      for (var lesson in targetLessons) {
        final chars = await _repository.getCharacters(lesson.id);
        _allCharacters.addAll(chars);
      }
      
      // Shuffle initially
      _allCharacters.shuffle();
      
      if (_allCharacters.length < 9) {
        // Fallback if not enough chars
        print("Not enough characters loaded");
      }
    } catch (e) {
      print("Error loading game data: $e");
    }
  }

  void _startGame() {
    setState(() {
      _score = 0;
      _combo = 0;
      _isGameActive = true;
    });
    _startRound();
  }

  void _startRound() {
    if (_allCharacters.length < 9) return;

    setState(() {
      // Pick 9 random characters for the grid
      final random = Random();
      final pool = List<HanziChar>.from(_allCharacters);
      pool.shuffle();
      _gridCharacters = pool.take(9).toList();
      
      // Pick one as target
      _targetCharacter = _gridCharacters[random.nextInt(9)];
    });

    // Play sound after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _playTargetSound();
    });
  }

  Future<void> _playTargetSound() async {
    if (_targetCharacter != null && _ttsService != null) {
      StringBuffer sb = StringBuffer(_targetCharacter!.character);
      if (_targetCharacter!.words.isNotEmpty) {
        // Add a pause and read words
        sb.write("。"); 
        sb.write(_targetCharacter!.words.join("，"));
      }
      await _ttsService!.speak(sb.toString());
    }
  }

  void _onMoleTap(HanziChar char) {
    if (!_isGameActive) return;

    if (char == _targetCharacter) {
      // Correct!
      _handleCorrectHit();
    } else {
      // Wrong!
      _handleWrongHit();
    }
  }

  Future<void> _handleCorrectHit() async {
    if (_targetCharacter?.lessonName != null) {
      final stats = _sessionStats.putIfAbsent(
          _targetCharacter!.lessonName!, () => _LessonStats());
      stats.correct++;
      stats.characters.add(_targetCharacter!.character);
    }

    setState(() {
      _score += 10 + (_combo * 2);
      _combo++;
      _hitCharacter = _targetCharacter; // Trigger hide animation
    });
    
    // Visual feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('正确! Correct! ${_targetCharacter!.pinyin}'),
        duration: const Duration(milliseconds: 500),
        backgroundColor: Colors.green,
      ),
    );

    // Audio feedback
    if (_ttsService != null) {
      // Random praise
      final praises = ['太棒了', '真聪明', '答对了', '好样的'];
      final praise = praises[Random().nextInt(praises.length)];
      await _ttsService!.speak(praise);
    }

    // Wait a bit before next round (allow animation to finish)
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _hitCharacter = null;
        });
        _startRound();
      }
    });
  }

  Future<void> _handleWrongHit() async {
    if (_targetCharacter?.lessonName != null) {
      final stats = _sessionStats.putIfAbsent(
          _targetCharacter!.lessonName!, () => _LessonStats());
      stats.wrong++;
    }

    setState(() {
      _combo = 0;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('再试一次! Try again!'),
        duration: Duration(milliseconds: 500),
        backgroundColor: Colors.red,
      ),
    );
    
    // Audio feedback
    if (_ttsService != null) {
      await _ttsService!.speak("不对哦");
    }
    
    // Replay sound after feedback
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _playTargetSound();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF81C784), // Green grass background
      appBar: AppBar(
        title: const Text('Whack-a-Mole (打地鼠)'),
        backgroundColor: Colors.amber,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                'Score: $_score',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _gridCharacters.isEmpty
              ? const Center(
                  child: Text(
                    "Not enough characters to play.\nPlease check data files.",
                    textAlign: TextAlign.center,
                  ),
                )
              : Column(
              children: [
                const SizedBox(height: 20),
                // Instructions / Status
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade700, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Listen and find the character!',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _playTargetSound,
                        icon: const Icon(Icons.volume_up),
                        label: const Text('Replay Sound'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Game Grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _gridCharacters.length,
                      itemBuilder: (context, index) {
                        final char = _gridCharacters[index];
                        return _buildMole(char);
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMole(HanziChar char) {
    final isHit = char == _hitCharacter;

    return GestureDetector(
      onTap: () => _onMoleTap(char),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ClipRect(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // The Hole (Background) - Static at bottom
                Positioned(
                  bottom: 5,
                  child: Container(
                    width: constraints.maxWidth * 0.6,
                    height: constraints.maxWidth * 0.3,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.all(Radius.elliptical(constraints.maxWidth * 0.8, constraints.maxWidth * 0.3)),
                    ),
                  ),
                ),
                // The Animated Mole
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  // If hit, move down out of view (negative height). If not hit, stay at 0 (bottom).
                  bottom: isHit ? -constraints.maxHeight : 0,
                  left: 0,
                  right: 0,
                  height: constraints.maxHeight,
                    child: MoleVisual(
                      char: char,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                    ),
                  ),
                ],
              ),
            );
          }
        ),
      );
    }
  }

class MoleVisual extends StatefulWidget {
  final HanziChar char;
  final double width;
  final double height;

  const MoleVisual({
    super.key,
    required this.char,
    required this.width,
    required this.height,
  });

  @override
  State<MoleVisual> createState() => _MoleVisualState();
}

class _MoleVisualState extends State<MoleVisual> with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _startBlinking();
  }

  void _startBlinking() {
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 3000), (timer) {
      if (mounted && Random().nextBool()) {
        _blink();
      }
    });
  }

  void _blink() {
    _blinkController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) _blinkController.reverse();
      });
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        AnimatedBuilder(
          animation: _blinkController,
          builder: (context, child) {
            return CustomPaint(
              size: Size(widget.width, widget.height),
              painter: MolePainter(blinkValue: _blinkController.value),
            );
          },
        ),
        // The Character (on the belly/sign)
        Positioned(
          bottom: widget.height * 0.05,
          child: Container(
            width: widget.width * 0.5,
            height: widget.width * 0.4,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.brown, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              widget.char.character,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'KaiTi',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MolePainter extends CustomPainter {
  final double blinkValue;

  MolePainter({this.blinkValue = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final strokeWidth = 6.0;
    // Leave space at bottom for stroke to ensure it's visible
    final bottomY = size.height - strokeWidth;

    // Body Path
    final bodyPath = Path();
    bodyPath.moveTo(size.width * 0.15, bottomY);
    bodyPath.cubicTo(
      size.width * 0.15, size.height * 0.2, // Control point 1
      size.width * 0.85, size.height * 0.2, // Control point 2
      size.width * 0.85, bottomY // End point
    );
    bodyPath.close();

    // 1. Body Fill (Brown)
    paint.color = const Color(0xFF795548); // Brown
    paint.style = PaintingStyle.fill;
    canvas.drawPath(bodyPath, paint);

    // 2. Body Outline (Black) - Enhanced visibility
    paint.color = Colors.black;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = strokeWidth;
    paint.strokeCap = StrokeCap.round;
    paint.strokeJoin = StrokeJoin.round;
    canvas.drawPath(bodyPath, paint);

    // Reset to fill for details
    paint.style = PaintingStyle.fill;

    // 3. Face Details
    // Nose (Pink)
    paint.color = const Color(0xFFEF9A9A); // Pink
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.35),
        width: size.width * 0.2,
        height: size.height * 0.12
      ), 
      paint
    );
    
    // Nose shine (White)
    paint.color = Colors.white.withOpacity(0.6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.48, size.height * 0.33),
        width: size.width * 0.06,
        height: size.height * 0.04
      ), 
      paint
    );

    // Eyes
    paint.color = Colors.black;
    double eyeRadius = size.width * 0.08;
    double eyeY = size.height * 0.25;
    double leftEyeX = size.width * 0.35;
    double rightEyeX = size.width * 0.65;

    if (blinkValue > 0.5) {
      // Closed (Line)
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 3.0;
      // Curved closed eye or straight line
      canvas.drawLine(
        Offset(leftEyeX - eyeRadius, eyeY), 
        Offset(leftEyeX + eyeRadius, eyeY), 
        paint
      );
      canvas.drawLine(
        Offset(rightEyeX - eyeRadius, eyeY), 
        Offset(rightEyeX + eyeRadius, eyeY), 
        paint
      );
    } else {
      // Open
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(Offset(leftEyeX, eyeY), eyeRadius, paint);
      canvas.drawCircle(Offset(rightEyeX, eyeY), eyeRadius, paint);

      // Eye Sparkle (White)
      paint.color = Colors.white;
      // Make sparkle move slightly if wanted, but static is fine for now
      canvas.drawCircle(Offset(leftEyeX + eyeRadius * 0.2, eyeY - eyeRadius * 0.2), eyeRadius * 0.4, paint);
      canvas.drawCircle(Offset(rightEyeX + eyeRadius * 0.2, eyeY - eyeRadius * 0.2), eyeRadius * 0.4, paint);
    }

    // Whiskers (Black lines)
    paint.color = Colors.black;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.0;
    
    // Left Whiskers
    canvas.drawLine(Offset(size.width * 0.25, size.height * 0.38), Offset(size.width * 0.1, size.height * 0.35), paint);
    canvas.drawLine(Offset(size.width * 0.25, size.height * 0.42), Offset(size.width * 0.1, size.height * 0.42), paint);
    
    // Right Whiskers
    canvas.drawLine(Offset(size.width * 0.75, size.height * 0.38), Offset(size.width * 0.9, size.height * 0.35), paint);
    canvas.drawLine(Offset(size.width * 0.75, size.height * 0.42), Offset(size.width * 0.9, size.height * 0.42), paint);
  }

  @override
  bool shouldRepaint(covariant MolePainter oldDelegate) => oldDelegate.blinkValue != blinkValue;
}

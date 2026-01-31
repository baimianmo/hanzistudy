
import 'package:flutter/material.dart';
import 'dart:math';
import 'models.dart';
import 'services/tts_service.dart';

class FlashCardScreen extends StatefulWidget {
  final String lessonTitle;
  final List<HanziChar> characters;

  const FlashCardScreen({
    super.key,
    required this.lessonTitle,
    required this.characters,
  });

  @override
  State<FlashCardScreen> createState() => _FlashCardScreenState();
}

class _FlashCardScreenState extends State<FlashCardScreen> {
  final PageController _pageController = PageController();
  TtsService? _ttsService;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    _ttsService = await TtsServiceFactory.getService();
  }

  Future<void> _speak(String text) async {
    await _ttsService?.speak(text);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ttsService?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lessonTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: widget.characters.isEmpty
          ? const Center(child: Text("暂无数据"))
          : PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical, // Vertical scrolling like TikTok
              itemCount: widget.characters.length,
              onPageChanged: (index) {
                _speak(widget.characters[index].character);
              },
              itemBuilder: (context, index) {
                return FlashCardItem(
                  hanziChar: widget.characters[index],
                  onSpeak: _speak,
                );
              },
            ),
    );
  }
}

class FlashCardItem extends StatefulWidget {
  final HanziChar hanziChar;
  final Function(String) onSpeak;

  const FlashCardItem({
    super.key,
    required this.hanziChar,
    required this.onSpeak,
  });

  @override
  State<FlashCardItem> createState() => _FlashCardItemState();
}

class _FlashCardItemState extends State<FlashCardItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFront) {
      _controller.forward();
      // Speak when flipping to back (showing pinyin/details)
      widget.onSpeak(widget.hanziChar.character);
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: _flipCard,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final double rotation = _animation.value * pi;
            final bool isFrontVisible = rotation <= pi / 2;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(rotation),
              child: isFrontVisible
                  ? _buildFront()
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(pi),
                      child: _buildBack(),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFront() {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.all(32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: double.infinity,
        height: 500, // Fixed height for card look
        alignment: Alignment.center,
        child: Text(
          widget.hanziChar.character,
          style: const TextStyle(
            fontSize: 160,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
            fontFamily: "KaiTi", // Assuming system KaiTi or fallback
          ),
        ),
      ),
    );
  }

  Widget _buildBack() {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.all(32),
      color: const Color(0xFFFFF9E6), // Warm yellow tint
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: double.infinity,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.volume_up, size: 32),
                color: Colors.blue,
                onPressed: () => widget.onSpeak(widget.hanziChar.character),
              ),
            ),
            Text(
              widget.hanziChar.pinyin,
              style: const TextStyle(
                fontSize: 48,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.hanziChar.character,
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "组词",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              widget.hanziChar.words.join("  "),
              style: const TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text(
              "笔顺",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              widget.hanziChar.strokeOrder,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


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

class _FlashCardItemState extends State<FlashCardItem> {
  int _step = 0; // 0: Initial (Char only), 1: +Pinyin/Audio, 2: +Words, 3: +Stroke

  void _handleTap() {
    setState(() {
      _step++;
      if (_step > 3) {
        _step = 0; // Reset to homepage (Initial state)
      }
    });

    // Auto-speak when revealing Pinyin/Audio (Step 1)
    if (_step == 1) {
      widget.onSpeak(widget.hanziChar.character);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: _step == 0 ? _buildFront() : _buildBack(),
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
            // Pinyin and Audio (Visible from Step 1)
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    widget.hanziChar.pinyin,
                    style: const TextStyle(
                      fontSize: 48,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.volume_up, size: 32),
                    color: Colors.blue,
                    onPressed: () => widget.onSpeak(widget.hanziChar.character),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Character (Always visible in Back view)
            Text(
              widget.hanziChar.character,
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            
            // Words (Visible from Step 2)
            AnimatedOpacity(
              opacity: _step >= 2 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Column(
                children: [
                   if (_step >= 2) ...[
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
                   ] else ...[
                      // Placeholder to keep layout consistent or empty
                      // Actually if we want layout to expand, we shouldn't use Column inside Opacity for conditional children
                      // But to keep it simple, we just hide it.
                      // Wait, if _step < 2, the children are not rendered in the `if` block below in original code.
                      // To animate opacity, the children MUST be rendered but invisible.
                   ]
                ],
              ),
            ),
            
            // Re-implementing correctly for AnimatedOpacity
             if (_step >= 2) ...[
                // We use a key to ensure widget identity if needed, but here simplified
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) {
                    return Opacity(opacity: value, child: child);
                  },
                  child: Column(
                    children: [
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
                    ],
                  ),
                ),
             ],

            // Stroke Order (Visible from Step 3)
            if (_step >= 3) ...[
               TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) {
                    return Opacity(opacity: value, child: child);
                  },
                  child: Column(
                    children: [
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
            ],
          ],
        ),
      ),
    );
  }
}

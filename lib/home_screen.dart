
import 'package:flutter/material.dart';
import 'models.dart';
import 'lesson_list_screen.dart';
import 'settings_screen.dart';
import 'whack_a_mole_game.dart';
import 'study_plan_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('汉字卡片 (二年级下册)'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CategoryButton(
                title: '识字表',
                subtitle: 'Reading List',
                color: Colors.green,
                icon: Icons.menu_book,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LessonListScreen(
                        title: '识字表',
                        type: LessonType.literacy,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _CategoryButton(
                title: '写字表',
                subtitle: 'Writing List',
                color: Colors.blue,
                icon: Icons.edit,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LessonListScreen(
                        title: '写字表',
                        type: LessonType.writing,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _CategoryButton(
                title: '打地鼠游戏',
                subtitle: 'Whack-a-Mole Game',
                color: Colors.amber,
                icon: Icons.sports_esports,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WhackAMoleGame(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _CategoryButton(
                title: '学习计划',
                subtitle: 'Study Plan & History',
                color: Colors.purple,
                icon: Icons.calendar_today,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StudyPlanScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryButton({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 110,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 6,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40),
            const SizedBox(width: 24),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

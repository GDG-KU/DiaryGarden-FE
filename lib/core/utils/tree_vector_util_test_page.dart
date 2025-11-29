import 'dart:math';

import 'package:flutter/material.dart';
import 'tree_vector_util.dart';

/// Test page for validating TreeVectorUtil functionality
class TreeVectorUtilTestPage extends StatefulWidget {
  const TreeVectorUtilTestPage({super.key});

  @override
  State<TreeVectorUtilTestPage> createState() => _TreeVectorUtilTestPageState();
}

class _TreeVectorUtilTestPageState extends State<TreeVectorUtilTestPage> {
  final _random = Random();
  
  // Generate random emotion
  String _randomEmotion() {
    final emotions = ['happy', 'sad', 'angry', 'calm'];
    return emotions[_random.nextInt(emotions.length)];
  }
  
  // Generate random score between 0.0 and 1.0
  double _randomScore() {
    return (_random.nextDouble() * 100).round() / 100.0;
  }
  
  // Generate N random diary entries
  List<Map<String, dynamic>> _generateDiaries(int count) {
    return List.generate(
      count,
      (index) => {
        'emotion': _randomEmotion(),
        'score': _randomScore(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tree Vector Util Test'),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🌳 Tree Level Auto-Calculation',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('• 0 diaries → Level 1 (seed)'),
                    const Text('• 1-2 diaries → Level 2 (2 leaves)'),
                    const Text('• 3-4 diaries → Level 3 (5 leaves)'),
                    const Text('• 5-7 diaries → Level 4 (10 leaves)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Test Cases
            const Text(
              'Test Cases (0-7 Diaries):',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Generate test cases for 0-7 diaries
            for (int i = 0; i <= 7; i++) ...[
              _buildTestCase(
                title: 'Test Case: $i ${i == 1 ? 'Diary' : 'Diaries'}',
                emotionData: _generateDiaries(i),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Clear cache to force re-render
          TreeVectorUtil.clearCache();
          setState(() {}); // Regenerate with new random values
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Regenerated with new random diaries!')),
          );
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildTestCase({
    required String title,
    required List<Map<String, dynamic>> emotionData,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Diaries: ${emotionData.length} → Auto Level',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            Text(
              'Emotions: ${emotionData.map((e) => '${e['emotion']}${e['score'] != null ? '(${e['score']})' : ''}').join(', ')}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: FutureBuilder<TreeVectorData>(
                future: TreeVectorUtil.svgFor(
                  emotionData: emotionData,
                  debug: true, // Enable debug logging
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return Container(
                      height: 200,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 48),
                          const SizedBox(height: 8),
                          Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Text('No data');
                  }

                  final treeData = snapshot.data!;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFCF5), // AppColors.background
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: treeData.toPicture(width: 150),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

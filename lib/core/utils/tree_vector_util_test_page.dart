import 'package:flutter/material.dart';
import 'tree_vector_util.dart';

/// Test page for validating TreeVectorUtil functionality
class TreeVectorUtilTestPage extends StatefulWidget {
  const TreeVectorUtilTestPage({super.key});

  @override
  State<TreeVectorUtilTestPage> createState() => _TreeVectorUtilTestPageState();
}

class _TreeVectorUtilTestPageState extends State<TreeVectorUtilTestPage> {
  int _currentLevel = 2;
  final List<Map<String, dynamic>> _emotionData = [
    {'emotion': 'happy', 'score': 0.8},
    {'emotion': 'calm', 'score': 0.5},
  ];

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
            // Level Control
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tree Level: $_currentLevel',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Slider(
                      value: _currentLevel.toDouble(),
                      min: 1,
                      max: 4,
                      divisions: 3,
                      label: 'Level $_currentLevel',
                      onChanged: (value) {
                        setState(() {
                          _currentLevel = value.toInt();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Emotion Data Display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emotion Data:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ..._emotionData.map((data) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '${data['emotion']}: ${data['score']}',
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Test Cases
            const Text(
              'Test Cases:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Test 1: Single emotion
            _buildTestCase(
              title: 'Test 1: Single Happy Emotion',
              level: _currentLevel,
              emotionData: [
                {'emotion': 'happy', 'score': 1.0},
              ],
            ),
            const SizedBox(height: 16),

            // Test 2: Multiple emotions
            _buildTestCase(
              title: 'Test 2: Mixed Emotions',
              level: _currentLevel,
              emotionData: [
                {'emotion': 'happy', 'score': 0.6},
                {'emotion': 'calm', 'score': 0.3},
                {'emotion': 'sad', 'score': 0.1},
              ],
            ),
            const SizedBox(height: 16),

            // Test 3: No scores (should use defaults)
            _buildTestCase(
              title: 'Test 3: No Scores (Default Weights)',
              level: _currentLevel,
              emotionData: [
                {'emotion': 'angry'},
                {'emotion': 'calm'},
              ],
            ),
            const SizedBox(height: 16),

            // Test 4: Current emotion data
            _buildTestCase(
              title: 'Test 4: Current Emotion Data',
              level: _currentLevel,
              emotionData: _emotionData,
            ),
            const SizedBox(height: 16),

            // Test 5: All emotions
            _buildTestCase(
              title: 'Test 5: All Emotions',
              level: _currentLevel,
              emotionData: [
                {'emotion': 'happy', 'score': 0.25},
                {'emotion': 'sad', 'score': 0.25},
                {'emotion': 'angry', 'score': 0.25},
                {'emotion': 'calm', 'score': 0.25},
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Clear cache to force re-render
          TreeVectorUtil.clearCache();
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cache cleared! Trees will re-render.')),
          );
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildTestCase({
    required String title,
    required int level,
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
                  level: level,
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

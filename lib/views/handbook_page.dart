import 'package:flutter/material.dart';

class HandbookDetailPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Map<String, String>> steps;

  const HandbookDetailPage({super.key, required this.title, required this.icon, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1014),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: steps.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Text("${index + 1}", style: const TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 15),
                    Text(steps[index]['phase']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  ],
                ),
                const SizedBox(height: 15),
                Text(steps[index]['content']!, style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.5)),
              ],
            ),
          );
        },
      ),
    );
  }
}
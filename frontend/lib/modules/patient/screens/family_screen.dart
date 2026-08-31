import 'package:flutter/material.dart';
import '../services/local_store.dart';
import 'package:smriti/core/theme.dart';

/// "A Face She Already Knows" — family photos and a voice-note
/// button per person, instead of a generic contacts list.
class FamilyScreen extends StatelessWidget {
  final ElderProfile profile;
  const FamilyScreen({super.key, required this.profile});

  static const family = [
    ('👩', 'Daughter — Priya'),
    ('👨', 'Son — Arjun'),
    ('🧒', 'Grandchild — Ritu'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Family'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: family.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final f = family[i];
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              leading: Text(f.$1, style: const TextStyle(fontSize: 40)),
              title: Text(f.$2, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              trailing: IconButton(
                icon: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.play_arrow, color: Colors.white),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Playing voice message from ${f.$2}…')),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

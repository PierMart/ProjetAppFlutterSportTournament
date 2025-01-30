import 'package:flutter/material.dart';

class TournoisEnCours extends StatelessWidget {
  const TournoisEnCours({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournois en cours'),
      ),
      body: const Center(
        child: Text('Tournois en cours'),
      ),
    );
  }
}
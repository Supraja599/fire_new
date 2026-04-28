import 'package:flutter/material.dart';

const kRed = Color(0xFFC62828);

class AssetDetailScreen extends StatelessWidget {
  const AssetDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Asset Detail"),
        backgroundColor: kRed,
      ),
      body: const Center(
        child: Text("Asset Detail Screen"),
      ),
    );
  }
}

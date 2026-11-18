import 'package:flutter/material.dart';

class AdkarCategory {
  const AdkarCategory({
    required this.id,
    required this.titleAr,
    required this.subtitleAr,
    required this.icon,
  });

  final String id;
  final String titleAr;
  final String subtitleAr;
  final IconData icon;
}

class AdkarItem {
  const AdkarItem({
    required this.textAr,
    this.repeat = 1,
    this.reference,
  });

  final String textAr;
  final int repeat;
  final String? reference;
}

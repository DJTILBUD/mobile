import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';

/// Bold job ID shown on all job cards and detail screens.
/// Internal jobs: #230  — External (Udvalgte) jobs: #E342
class JobIdBadge extends StatelessWidget {
  const JobIdBadge({super.key, required this.id, this.isExtJob = false});

  final int id;
  final bool isExtJob;

  static const _c = lightColors;

  String get _label => isExtJob ? '#E$id' : '#$id';

  @override
  Widget build(BuildContext context) {
    return Text(
      _label,
      style: DSTextStyle.labelMd.copyWith(
        color: _c.text.primary,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

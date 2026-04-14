import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';

/// Thin wrapper around [DSToast] for convenience call sites that need
/// a simple success/error message without choosing a toast variant.
class AppSnackbar {
  const AppSnackbar._();

  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    DSToast.show(
      context,
      variant: isError ? DSToastVariant.error : DSToastVariant.success,
      title: message,
    );
  }
}

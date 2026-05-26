import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

class AppExceptionHandler {
  /// Global navigator key to access BuildContext from services or async events
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Formats the exception to a user-friendly message.
  static String formatError(Object error) {
    if (error is SocketException) {
      return "No internet connection or server is offline. Please check your network and try again.";
    } else if (error is TimeoutException) {
      return "The connection timed out. Please try again.";
    } else if (error is HttpException) {
      return "Server communication error: ${error.message}";
    } else if (error is FormatException) {
      return "Data format error: invalid response received.";
    } else {
      final errStr = error.toString().toLowerCase();
      if (errStr.contains('socket') || errStr.contains('failed host lookup')) {
        return "No internet connection or server is unreachable.";
      } else if (errStr.contains('timeout')) {
        return "Connection timed out. Please check your connection.";
      } else if (errStr.contains('handshake')) {
        return "Secure connection failed. Please try again.";
      }
      return error.toString();
    }
  }

  /// Checks if the error is a network error (SocketException, TimeoutException, etc.).
  static bool isNetworkError(Object error) {
    if (error is SocketException || error is TimeoutException || error is HttpException) {
      return true;
    }
    final errStr = error.toString().toLowerCase();
    return errStr.contains('socket') ||
        errStr.contains('handshake') ||
        errStr.contains('timeout') ||
        errStr.contains('clientexception') ||
        errStr.contains('network') ||
        errStr.contains('failed host lookup');
  }

  /// Handles the error by printing it to debug console, checking if it's a network error,
  /// and showing a standardized visual notification (dialog or snackbar).
  static void handleError(Object error, {BuildContext? context, StackTrace? stackTrace}) {
    debugPrint("----------------------------------------");
    debugPrint("[AppExceptionHandler] Error occurred: $error");
    if (stackTrace != null) {
      debugPrint("Stacktrace: $stackTrace");
    }
    debugPrint("----------------------------------------");

    final message = formatError(error);
    final ctx = context ?? navigatorKey.currentContext;

    if (ctx == null) {
      debugPrint("Warning: AppExceptionHandler could not find a BuildContext to show UI.");
      return;
    }

    final bool isNetwork = isNetworkError(error);

    // Ensure SnackBar is shown on the closest scaffold or top-level scaffold.
    try {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isNetwork ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: isNetwork ? const Color(0xFFD50000) : Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: "OK",
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint("Failed to show SnackBar via AppExceptionHandler: $e");
    }
  }

  /// Helper to display a standardized custom alert dialog for critical notifications.
  static void showAlertDialog({
    required String title,
    required String message,
    BuildContext? context,
    IconData icon = Icons.warning_amber_rounded,
    Color iconColor = const Color(0xFFD50000),
  }) {
    final ctx = context ?? navigatorKey.currentContext;
    if (ctx == null) return;

    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              "OK",
              style: TextStyle(color: iconColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

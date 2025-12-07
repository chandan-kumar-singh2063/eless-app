import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../theme/app_theme.dart';

class CustomToast {
  static void showSuccess(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 3,
      backgroundColor: Colors.green[600],
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  static void showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 4,
      backgroundColor: Colors.red[600],
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  static void showInfo(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: AppTheme.lightPrimaryColor,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  static void showWarning(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 3,
      backgroundColor: Colors.orange[600],
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  // Helper method to convert technical errors to user-friendly messages
  static String getUserFriendlyError(String technicalError) {
    String lowerError = technicalError.toLowerCase();
    
    if (lowerError.contains('network') || lowerError.contains('connection')) {
      return 'Please check your internet connection and try again';
    } else if (lowerError.contains('timeout')) {
      return 'Request timed out. Please try again';
    } else if (lowerError.contains('server') || lowerError.contains('500')) {
      return 'Server is currently unavailable. Please try later';
    } else if (lowerError.contains('not found') || lowerError.contains('404')) {
      return 'Requested resource not found';
    } else if (lowerError.contains('unauthorized') || lowerError.contains('401')) {
      return 'You are not authorized to perform this action';
    } else if (lowerError.contains('forbidden') || lowerError.contains('403')) {
      return 'Access denied. Please contact support';
    } else if (lowerError.contains('bad request') || lowerError.contains('400')) {
      return 'Invalid request. Please check your input';
    } else if (lowerError.contains('validation')) {
      return 'Please check all required fields';
    } else {
      return 'Something went wrong. Please try again';
    }
  }
}

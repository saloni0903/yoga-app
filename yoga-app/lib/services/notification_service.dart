// lib/services/notification_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../api_service.dart';

class FirebaseNotificationService {

  // A static method to initialize everything
  static Future<void> initialize(BuildContext context) async {
    final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

    // 1. Request Permission from the user
    await firebaseMessaging.requestPermission();

    // 2. Get the current FCM token and send it to the backend
    await _sendFcmToken(context);

    // 3. Set up a listener for when the token refreshes, and send the new one
    firebaseMessaging.onTokenRefresh.listen((newToken) {
      _sendFcmToken(context, token: newToken);
    });

    // 4. Listen for incoming messages while the app is open (in the foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Got a message whilst in the foreground!");
      if (message.notification != null) {
        // Optional: You can show a simple dialog or a local notification here
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(message.notification!.title ?? 'New Notification'),
            content: Text(message.notification!.body ?? ''),
            actions: [
              TextButton(
                child: const Text('Ok'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    });
  }

  // A private helper function to send the token to your server
  static Future<void> _sendFcmToken(BuildContext context, {String? token}) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Only send the token if the user is actually logged in
      if (!apiService.isAuthenticated) {
        print("User not logged in. Won't send FCM token.");
        return;
      }

      // Get the token if a new one wasn't provided
      final fcmToken = token ?? await FirebaseMessaging.instance.getToken();

      if (fcmToken != null) {
        print("Sending FCM Token to backend: $fcmToken");
        await apiService.updateUserFcmToken(fcmToken);
        print("Successfully sent FCM token.");
      }
    } catch (e) {
      print("Error sending FCM token: $e");
    }
  }
}
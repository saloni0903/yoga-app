import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

http.Client getClient() {
  // Your original web-specific logic
  return BrowserClient()..withCredentials = true;
}
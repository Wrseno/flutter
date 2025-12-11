import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

MqttClient createMqttClient(String server, String clientIdentifier, int port) {
  // For web, we need to use the WebSocket protocol
  // The server string should be just the hostname/IP. 
  // The port must be the WebSocket port (e.g. 8083, 9001), NOT the TCP port (1883).
  final client = MqttBrowserClient('ws://$server', clientIdentifier);
  client.port = port;
  return client;
}

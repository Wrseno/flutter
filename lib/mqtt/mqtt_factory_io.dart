import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

MqttClient createMqttClient(String server, String clientIdentifier, int port) {
  final client = MqttServerClient(server, clientIdentifier);
  client.port = port;
  client.secure = false;
  client.useWebSocket = false; 
  return client;
}

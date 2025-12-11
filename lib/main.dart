import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'mqtt/mqtt_factory.dart'
    if (dart.library.html) 'mqtt/mqtt_factory_web.dart'
    if (dart.library.io) 'mqtt/mqtt_factory_io.dart';
// import 'package:google_fonts/google_fonts.dart'; // Uncomment jika sudah install

void main() {
  runApp(const SmartHomeApp());
}

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IoT Controller',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        primaryColor: const Color(0xFFE94560),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE94560),
          secondary: Color(0xFF0F3460),
        ),
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // --- Controllers ---
  final TextEditingController _ipController = TextEditingController(
    text: '10.111.231.146',
  ); // Ganti Default IP Disini
  final TextEditingController _portController = TextEditingController(
    text: '1883',
  );
  final TextEditingController _userController = TextEditingController(
    text: 'uas25_seno',
  );
  final TextEditingController _passController = TextEditingController(
    text: 'uas25_seno',
  );

  // --- MQTT Variables ---
  MqttClient? client;
  String connectionStatus = 'Disconnected';
  bool isConnected = false;

  // --- Data Variables ---
  double temperature = 0.0;
  double humidity = 0.0;
  int ldrValue = 0;
  String ledStatus = "OFF";
  String lastUpdate = "-";

  // --- Functions ---

  Future<void> _connect() async {
    if (_ipController.text.isEmpty) return;

    // Tutup keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      connectionStatus = 'Connecting...';
    });

    String clientId = 'flutter_app_${DateTime.now().millisecondsSinceEpoch}';
    int port = int.tryParse(_portController.text) ?? 1883;

    // Use the factory to create the correct client for Web or Mobile
    client = createMqttClient(_ipController.text, clientId, port);

    client!.logging(on: true);
    client!.keepAlivePeriod = 20;
    client!.onDisconnected = _onDisconnected;
    client!.onConnected = _onConnected;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client!.connectionMessage = connMess;

    try {
      if (_userController.text.isNotEmpty) {
        await client!.connect(_userController.text, _passController.text);
      } else {
        await client!.connect();
      }
    } catch (e) {
      print('Exception: $e');
      _disconnect();
    }

    if (client != null &&
        client!.connectionStatus!.state == MqttConnectionState.connected) {
      setState(() {
        connectionStatus = 'Connected';
        isConnected = true;
      });

      // Subscribe Topic sesuai kode ESP32 Anda
      _subscribe('UAS25-IOT/Status');
      _subscribe('UAS25-IOT/43323125/SUHU');
      _subscribe('UAS25-IOT/43323125/KELEMBAPAN');
      _subscribe('UAS25-IOT/43323125/LDR');

      // Listener
      client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
        final MqttPublishMessage recMess = c![0].payload as MqttPublishMessage;
        final String pt = MqttPublishPayload.bytesToStringAsString(
          recMess.payload.message,
        );
        _handleMessage(c[0].topic, pt);
      });
    } else {
      _disconnect();
    }
  }

  void _disconnect() {
    client?.disconnect();
    _onDisconnected();
  }

  void _onConnected() {
    print('MQTT Connected');
  }

  void _onDisconnected() {
    setState(() {
      connectionStatus = 'Disconnected';
      isConnected = false;
    });
    print('MQTT Disconnected');
  }

  void _subscribe(String topic) {
    client?.subscribe(topic, MqttQos.atMostOnce);
  }

  void _publishMessage(String topic, String message) {
    if (client != null && isConnected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      client!.publishMessage(
        topic,
        MqttQos.atLeastOnce,
        builder.payload!,
        retain: true,
      );
      print('Published: $topic -> $message');
    } else {
      print('Cannot publish: client not connected');
    }
  }

  void _toggleLed(bool turnOn) {
    String command = turnOn ? 'ON' : 'OFF';
    _publishMessage('UAS25-IOT/Status', command);
    // Update status lokal langsung
    setState(() {
      ledStatus = command;
    });
  }

  void _handleMessage(String topic, String payload) {
    print("MSG: $topic -> $payload");
    setState(() {
      DateTime now = DateTime.now();
      lastUpdate =
          "${now.hour}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

      if (topic == 'UAS25-IOT/Status') {
        // Status LED dari ESP32
        ledStatus = payload.trim().toUpperCase();
      } else if (topic == 'UAS25-IOT/43323125/SUHU') {
        // Suhu dari DHT11
        temperature = double.tryParse(payload.trim()) ?? 0.0;
      } else if (topic == 'UAS25-IOT/43323125/KELEMBAPAN') {
        // Kelembapan dari DHT11
        humidity = double.tryParse(payload.trim()) ?? 0.0;
      } else if (topic == 'UAS25-IOT/43323125/LDR') {
        // Nilai LDR
        ldrValue = int.tryParse(payload.trim()) ?? 0;
      }
    });
  }

  // --- UI WIDGETS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background Gradient
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 20),

                // Connection Panel
                _buildConnectionPanel(),
                const SizedBox(height: 20),

                // Main Content (Hanya muncul jika connect)
                Expanded(
                  child: ListView(
                    children: [
                      const Text(
                        "DHT11 Sensor",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSensorCard(
                              "Suhu",
                              "$temperature°C",
                              Icons.thermostat,
                              Colors.orangeAccent,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildSensorCard(
                              "Kelembapan",
                              "$humidity%",
                              Icons.water_drop,
                              Colors.cyanAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        "LDR Sensor",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildSensorCard(
                        "Light Intensity",
                        "$ldrValue",
                        Icons.light_mode,
                        Colors.amberAccent,
                      ),

                      const SizedBox(height: 20),
                      const Text(
                        "LED Control",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildLedStatusCard(),

                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          "Last Update: $lastUpdate",
                          style: const TextStyle(color: Colors.white38),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "IoT Dashboard",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              "Smart Home System",
              style: TextStyle(fontSize: 14, color: Colors.white54),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isConnected
                ? Colors.green.withOpacity(0.2)
                : Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isConnected ? Colors.green : Colors.red),
          ),
          child: Row(
            children: [
              Icon(
                Icons.circle,
                size: 10,
                color: isConnected ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                isConnected ? "ONLINE" : "OFFLINE",
                style: TextStyle(
                  color: isConnected ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionPanel() {
    return ExpansionTile(
      title: const Text(
        "Broker Settings",
        style: TextStyle(color: Colors.white),
      ),
      collapsedBackgroundColor: Colors.white.withOpacity(0.05),
      backgroundColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      childrenPadding: const EdgeInsets.all(15),
      children: [
        TextField(
          controller: _ipController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration("IP Address", Icons.wifi),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _userController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Username", Icons.person),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _passController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Password", Icons.lock),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isConnected ? _disconnect : _connect,
            style: ElevatedButton.styleFrom(
              backgroundColor: isConnected
                  ? Colors.redAccent
                  : const Color(0xFFE94560),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isConnected ? "DISCONNECT" : "CONNECT TO BROKER",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.white54),
      labelStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildSensorCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildLedStatusCard() {
    bool isOn = ledStatus == "ON";
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: isOn
            ? Border.all(color: Colors.yellowAccent.withOpacity(0.5), width: 2)
            : Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: isOn
            ? [
                BoxShadow(
                  color: Colors.yellowAccent.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOn ? Colors.yellowAccent : Colors.grey,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOn ? Icons.lightbulb : Icons.lightbulb_outline,
              color: isOn ? Colors.black : Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "LED Control",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ledStatus,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isOn ? Colors.yellowAccent : Colors.white38,
                  ),
                ),
              ],
            ),
          ),
          // LED Control Buttons
          Row(
            children: [
              _buildLedButton("ON", Colors.green, isOn, () => _toggleLed(true)),
              const SizedBox(width: 10),
              _buildLedButton(
                "OFF",
                Colors.red,
                !isOn,
                () => _toggleLed(false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLedButton(
    String label,
    Color color,
    bool isActive,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: isConnected ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? color : color.withOpacity(0.3),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: isActive ? 5 : 0,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: isActive ? Colors.white : Colors.white54,
        ),
      ),
    );
  }
}

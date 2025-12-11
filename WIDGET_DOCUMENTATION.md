# Dokumentasi Widget & Topik MQTT - IoT Dashboard

## 📱 Deskripsi Aplikasi

Aplikasi Flutter IoT Dashboard untuk monitoring sensor DHT11, LDR, dan kontrol LED melalui protokol MQTT.

---

## 📊 Detail Widget & Topik MQTT

### 1. Suhu (Temperature)

| Aspek               | Detail                                                    |
| ------------------- | --------------------------------------------------------- |
| **Widget**          | `_buildSensorCard()` - Custom `Container` dengan `Column` |
| **Tipe Display**    | `Text` widget untuk menampilkan nilai suhu                |
| **Icon**            | `Icons.thermostat` (warna `Colors.orangeAccent`)          |
| **Topik Subscribe** | `UAS25-IOT/43323125/SUHU`                                 |
| **Topik Publish**   | - (read-only, tidak ada publish)                          |
| **Tipe Data**       | `double` (contoh: `28.5°C`)                               |
| **Lokasi Kode**     | Line 257-262 (UI), Line 184-185 (handler)                 |

**Kode Widget:**

```dart
_buildSensorCard(
  "Suhu",
  "$temperature°C",
  Icons.thermostat,
  Colors.orangeAccent,
)
```

---

### 2. Kelembapan (Humidity)

| Aspek               | Detail                                                    |
| ------------------- | --------------------------------------------------------- |
| **Widget**          | `_buildSensorCard()` - Custom `Container` dengan `Column` |
| **Tipe Display**    | `Text` widget untuk menampilkan nilai kelembapan          |
| **Icon**            | `Icons.water_drop` (warna `Colors.cyanAccent`)            |
| **Topik Subscribe** | `UAS25-IOT/43323125/KELEMBAPAN`                           |
| **Topik Publish**   | - (read-only, tidak ada publish)                          |
| **Tipe Data**       | `double` (contoh: `65.0%`)                                |
| **Lokasi Kode**     | Line 265-270 (UI), Line 187-188 (handler)                 |

**Kode Widget:**

```dart
_buildSensorCard(
  "Kelembapan",
  "$humidity%",
  Icons.water_drop,
  Colors.cyanAccent,
)
```

---

### 3. LDR / Light Intensity (Lumen)

| Aspek               | Detail                                                    |
| ------------------- | --------------------------------------------------------- |
| **Widget**          | `_buildSensorCard()` - Custom `Container` dengan `Column` |
| **Tipe Display**    | `Text` widget untuk menampilkan nilai intensitas cahaya   |
| **Icon**            | `Icons.light_mode` (warna `Colors.amberAccent`)           |
| **Topik Subscribe** | `UAS25-IOT/43323125/LDR`                                  |
| **Topik Publish**   | - (read-only, tidak ada publish)                          |
| **Tipe Data**       | `int` (contoh: `512`)                                     |
| **Lokasi Kode**     | Line 283-288 (UI), Line 190-191 (handler)                 |

**Kode Widget:**

```dart
_buildSensorCard(
  "Light Intensity",
  "$ldrValue",
  Icons.light_mode,
  Colors.amberAccent,
)
```

---

### 4. LED Control (Tombol ON/OFF)

| Aspek               | Detail                                                                |
| ------------------- | --------------------------------------------------------------------- |
| **Widget**          | `_buildLedStatusCard()` - Custom `Container` dengan `Row`             |
| **Tipe Kontrol**    | 2x `ElevatedButton` (ON & OFF) via `_buildLedButton()`                |
| **Icon**            | `Icons.lightbulb` (ON) / `Icons.lightbulb_outline` (OFF)              |
| **Warna Icon**      | `Colors.yellowAccent` (ON) / `Colors.grey` (OFF)                      |
| **Topik Subscribe** | `UAS25-IOT/Status` (menerima status dari ESP32)                       |
| **Topik Publish**   | `UAS25-IOT/Status` (mengirim "ON" atau "OFF")                         |
| **Tipe Data**       | `String` ("ON" atau "OFF")                                            |
| **QoS**             | `MqttQos.atLeastOnce` dengan `retain: true`                           |
| **Lokasi Kode**     | Line 299 (UI), Line 163-170 (toggle function), Line 181-182 (handler) |

**Kode Widget:**

```dart
_buildLedStatusCard()
```

**Kode Tombol:**

```dart
_buildLedButton("ON", Colors.green, isOn, () => _toggleLed(true))
_buildLedButton("OFF", Colors.red, !isOn, () => _toggleLed(false))
```

**Fungsi Publish:**

```dart
void _toggleLed(bool turnOn) {
  String command = turnOn ? 'ON' : 'OFF';
  _publishMessage('UAS25-IOT/Status', command);
  setState(() {
    ledStatus = command;
  });
}
```

---

## 🔄 Ringkasan Topik MQTT

| Komponen    | Subscribe                          | Publish               | QoS                  |
| ----------- | ---------------------------------- | --------------------- | -------------------- |
| Suhu        | ✅ `UAS25-IOT/43323125/SUHU`       | ❌                    | atMostOnce           |
| Kelembapan  | ✅ `UAS25-IOT/43323125/KELEMBAPAN` | ❌                    | atMostOnce           |
| LDR         | ✅ `UAS25-IOT/43323125/LDR`        | ❌                    | atMostOnce           |
| LED Control | ✅ `UAS25-IOT/Status`              | ✅ `UAS25-IOT/Status` | atLeastOnce (retain) |

---

## 🏗️ Struktur Hierarki Widget

```
Scaffold
└── Container (Gradient Background)
    └── SafeArea
        └── Padding
            └── Column
                ├── _buildHeader()
                │   └── Row
                │       ├── Column (Title: "IoT Dashboard", Subtitle: "Smart Home System")
                │       └── Container (Status Badge: ONLINE/OFFLINE)
                │
                ├── _buildConnectionPanel()
                │   └── ExpansionTile ("Broker Settings")
                │       ├── TextField (IP Address)
                │       ├── Row
                │       │   ├── TextField (Username)
                │       │   └── TextField (Password)
                │       └── ElevatedButton (CONNECT/DISCONNECT)
                │
                └── Expanded
                    └── ListView
                        ├── Text ("DHT11 Sensor")
                        ├── Row
                        │   ├── _buildSensorCard("Suhu") ──────► Subscribe: UAS25-IOT/43323125/SUHU
                        │   └── _buildSensorCard("Kelembapan") ► Subscribe: UAS25-IOT/43323125/KELEMBAPAN
                        │
                        ├── Text ("LDR Sensor")
                        ├── _buildSensorCard("Light Intensity") ► Subscribe: UAS25-IOT/43323125/LDR
                        │
                        ├── Text ("LED Control")
                        ├── _buildLedStatusCard() ─────────────► Subscribe & Publish: UAS25-IOT/Status
                        │   └── Row
                        │       ├── Container (Lightbulb Icon)
                        │       ├── Column (Label + Status Text)
                        │       └── Row
                        │           ├── ElevatedButton ("ON")  → Publish: "ON"
                        │           └── ElevatedButton ("OFF") → Publish: "OFF"
                        │
                        └── Text ("Last Update: ...")
```

---

## 📝 Fungsi Utama MQTT

### Subscribe Topics (Line 116-119)

```dart
_subscribe('UAS25-IOT/Status');
_subscribe('UAS25-IOT/43323125/SUHU');
_subscribe('UAS25-IOT/43323125/KELEMBAPAN');
_subscribe('UAS25-IOT/43323125/LDR');
```

### Message Handler (Line 172-193)

```dart
void _handleMessage(String topic, String payload) {
  if (topic == 'UAS25-IOT/Status') {
    ledStatus = payload.trim().toUpperCase();
  } else if (topic == 'UAS25-IOT/43323125/SUHU') {
    temperature = double.tryParse(payload.trim()) ?? 0.0;
  } else if (topic == 'UAS25-IOT/43323125/KELEMBAPAN') {
    humidity = double.tryParse(payload.trim()) ?? 0.0;
  } else if (topic == 'UAS25-IOT/43323125/LDR') {
    ldrValue = int.tryParse(payload.trim()) ?? 0;
  }
}
```

### Publish Message (Line 155-166)

```dart
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
  }
}
```

---

## 🎨 Komponen UI Reusable

### `_buildSensorCard()`

Widget kartu sensor yang menampilkan:

- Icon sensor dengan warna kustom
- Nilai sensor (Text)
- Label/judul sensor

### `_buildLedStatusCard()`

Widget kartu kontrol LED yang menampilkan:

- Icon lampu (berubah sesuai status)
- Label "LED Control"
- Status text (ON/OFF)
- Tombol ON dan OFF

### `_buildLedButton()`

Widget tombol LED:

- Label (ON/OFF)
- Warna (hijau/merah)
- Status aktif/tidak aktif
- Callback function untuk toggle

---

## 📌 Catatan Penting

1. **Retain Flag**: Pesan LED Control menggunakan `retain: true` agar ESP32 menerima status terakhir saat reconnect.

2. **QoS Level**:

   - Subscribe: `MqttQos.atMostOnce` (QoS 0)
   - Publish LED: `MqttQos.atLeastOnce` (QoS 1)

3. **Platform Support**: Aplikasi mendukung Web dan Mobile dengan conditional import untuk MQTT client.

/**
 * ZenWizard / ZenWizard Firmware (v2.5.0 - Dual USB Serial + HM-10 BLE)
 * Team Arduino Tres - Arduino Uno R3 (CH340) + HM-10 BLE 4.0
 * Non-blocking Cooperative Multitasking Architecture
 */

#include <Arduino.h>
#include <DHT.h>
#include <SoftwareSerial.h>
#include <math.h>

// =================== PIN DEFINITIONS ===================
#define PIN_DHT     2
#define DHT_TYPE    DHT11
#define PIN_BLE_RX  4   // Connected to HM-10 TXD
#define PIN_BLE_TX  5   // Connected to HM-10 RXD (use voltage divider 5V -> 3.3V)
#define PIN_LDR     A0
#define PIN_BUZZER  8
#define PIN_LED_R   9
#define PIN_LED_G   10
#define PIN_LED_B   11

// Set to true if your RGB LED longest pin goes to 5V instead of GND
const bool COMMON_ANODE = false;

// =================== TIMING CONSTANTS (ms) ===================
const unsigned long INTERVAL_LDR_MS        = 250;  // Poll LDR every 250ms
const unsigned long INTERVAL_DHT_MS        = 2000; // Poll DHT11 every 2000ms
const unsigned long INTERVAL_SERIAL_MS     = 500;  // Push JSON telemetry every 500ms
const unsigned long INTERVAL_ALERT_MS      = 250;  // Pomodoro flash/beep toggle interval
const unsigned long POMODORO_DURATION      = 8000; // Auto-stop Pomodoro alert after 8s
const unsigned long LOW_LIGHT_BEEP_PERIOD  = 4000; // Gentle beep cycle every 4s during low light
const unsigned long LOW_LIGHT_BEEP_ON_MS   = 120;  // Short 120ms pulse for low-light warning

// =================== LDR LUX CALIBRATION ===================
// Circuit: 5V -> LDR -> A0 -> 10k Ohm Resistor -> GND
// (If wired 5V -> 10k -> A0 -> LDR -> GND, set LDR_PULLUP = false)
const bool LDR_PULLUP = true;
const float VIN       = 5.0;
const float R_FIXED   = 10000.0; // 10k Ohm resistor

// Standard GL5528 photoresistor empirical constants (~300-500 lx in normal office light)
const float LUX_CALC_SCALAR   = 12518931.0;
const float LUX_CALC_EXPONENT = -1.405;

// =================== STATE & TELEMETRY GLOBALS ===================
DHT dht(PIN_DHT, DHT_TYPE);
SoftwareSerial bleSerial(4, 5); // RX = D4 (HM-10 TXD), TX = D5 (HM-10 RXD)

unsigned long lastLdrMillis        = 0;
unsigned long lastDhtMillis        = 250; // Staggered by 250ms from Serial/BLE TX
unsigned long lastSerialMillis     = 0;
unsigned long lastAlertToggle      = 0;
unsigned long alertStartMillis     = 0;
unsigned long lowLightCycleMillis  = 0;

// Sensor values (with EMA smoothing for LDR and fallback cache for DHT11)
float smoothedLux   = 400.0;
float lastValidTemp = 23.0;
float lastValidHum  = 50.0;
bool dhtInitialized = false;

// Configurable thresholds & settings
float luxThreshold = 300.0;
bool buzzerMuted = false;

// Actuator State Machine
enum SystemMode {
  MODE_AMBIENT_MONITOR,
  MODE_POMODORO_OVERRIDE,
  MODE_POMODORO_BREAK
};

SystemMode currentMode = MODE_AMBIENT_MONITOR;
bool alertPulseState = false;

// Non-blocking Dual Serial RX Buffers (USB Hardware Serial + HM-10 BLE SoftwareSerial)
const byte RX_BUFFER_SIZE = 64;
char usbRxBuffer[RX_BUFFER_SIZE];
byte usbRxIndex = 0;
char bleRxBuffer[RX_BUFFER_SIZE];
byte bleRxIndex = 0;

// =================== HELPER FUNCTIONS ===================
void setRgbColor(uint8_t r, uint8_t g, uint8_t b) {
  if (COMMON_ANODE) {
    analogWrite(PIN_LED_R, 255 - r);
    analogWrite(PIN_LED_G, 255 - g);
    analogWrite(PIN_LED_B, 255 - b);
  } else {
    analogWrite(PIN_LED_R, r);
    analogWrite(PIN_LED_G, g);
    analogWrite(PIN_LED_B, b);
  }
}

void setBuzzer(bool active) {
  if (buzzerMuted) {
    digitalWrite(PIN_BUZZER, LOW);
  } else {
    digitalWrite(PIN_BUZZER, active ? HIGH : LOW);
  }
}

/**
 * Converts 10-bit ADC (0-1023) to Lux using voltage divider & power-law curve:
 * Lux = Scalar * (R_ldr ^ Exponent)
 */
// Replace adcToLux() in zen_wizard_firmware.ino with this:
float adcToLux(int rawAdc) {
  rawAdc = constrain(rawAdc, 0, 1023);
  float ratio = rawAdc / 1023.0;

  // Scaled so your baseline room light matches your phone (~115 lux)
  float lux = ratio * 3500.0;

  return constrain(lux, 0.0, 2000.0);
}

// =================== NON-BLOCKING SERIAL COMMAND PARSER ===================
/**
 * Supported Incoming Commands from Flutter (terminated by '\n'):
 * - "CMD:POMODORO_ALERT" or "ALERT_START" or "POMODORO_DONE" -> Starts flash/buzzer
 * - "CMD:POMODORO_STOP" or "ALERT_STOP" -> Returns to ambient light monitor mode
 * - "CMD:LUX_MIN:300" -> Dynamically updates minimum lux threshold
 */
void processCommand(char* cmd) {
  size_t len = strlen(cmd);
  if (len > 0 && cmd[len - 1] == '\r') {
    cmd[len - 1] = '\0';
  }

  if (strcmp(cmd, "CMD:POMODORO_ALERT") == 0 ||
      strcmp(cmd, "ALERT_START") == 0 ||
      strcmp(cmd, "POMODORO_DONE") == 0 ||
      strcmp(cmd, "BREAK_START") == 0) {
    currentMode = MODE_POMODORO_OVERRIDE;
    alertStartMillis = millis();
    lastAlertToggle = millis();
    alertPulseState = true;
    setRgbColor(0, 180, 255); // Wizard Cyan/Blue flash
    setBuzzer(true);
  } else if (strcmp(cmd, "CMD:LED:BLUE") == 0 ||
             strcmp(cmd, "CMD:POMODORO_BREAK") == 0) {
    currentMode = MODE_POMODORO_BREAK;
    setBuzzer(false);
    setRgbColor(0, 80, 255); // Solid calm blue during break
  } else if (strcmp(cmd, "CMD:POMODORO_STOP") == 0 ||
             strcmp(cmd, "ALERT_STOP") == 0 ||
             strcmp(cmd, "RESET") == 0) {
    currentMode = MODE_AMBIENT_MONITOR;
    setBuzzer(false);
  } else if (strncmp(cmd, "CMD:LUX_MIN:", 12) == 0) {
    float parsedLux = atof(cmd + 12);
    if (parsedLux >= 50.0 && parsedLux <= 1500.0) {
      luxThreshold = parsedLux;
    }
  } else if (strcmp(cmd, "CMD:BUZZER:MUTE") == 0) {
    buzzerMuted = true;
    setBuzzer(false);
  } else if (strcmp(cmd, "CMD:BUZZER:UNMUTE") == 0) {
    buzzerMuted = false;
  }
}

void pollStreamRx(Stream& stream, char* buffer, byte& index, bool isBle) {
  while (stream.available() > 0) {
    char c = stream.read();
    if (c == '\n') {
      buffer[index] = '\0';
      if (index > 0) {
        if (isBle) {
          Serial.print(F("[BLE RX] "));
          Serial.println(buffer);
        }
        processCommand(buffer);
      }
      index = 0;
    } else if (index < RX_BUFFER_SIZE - 1) {
      buffer[index++] = c;
    } else {
      // Buffer overflow protection: reset index
      index = 0;
    }
  }
}

void pollSerialRx() {
  // Poll both USB Hardware Serial and HM-10 BLE SoftwareSerial independently
  pollStreamRx(Serial, usbRxBuffer, usbRxIndex, false);
  pollStreamRx(bleSerial, bleRxBuffer, bleRxIndex, true);
}

// =================== SENSOR & ACTUATOR TASKS ===================
void updateLdrTask(unsigned long now) {
  if (now - lastLdrMillis >= INTERVAL_LDR_MS) {
    lastLdrMillis = now;

    // Take 10 rapid samples and average them to eliminate USB power noise/jitter
    long rawSum = 0;
    for (int i = 0; i < 10; i++) {
      rawSum += analogRead(PIN_LDR);
      delayMicroseconds(50); // Tiny micro-delay between samples
    }
    int rawAdc = rawSum / 10;

    float instantLux = adcToLux(rawAdc);

    // Heavy exponential smoothing (alpha = 0.05) locks the value steady
    smoothedLux = (0.05 * instantLux) + (0.95 * smoothedLux);
  }
}

bool updateDhtTask(unsigned long now) {
  if (now - lastDhtMillis >= INTERVAL_DHT_MS) {
    lastDhtMillis = now;
    float h = dht.readHumidity();
    float t = dht.readTemperature(); // Celsius
    // Guard against NaN sensor read errors
    if (!isnan(h) && !isnan(t)) {
      lastValidHum = h;
      lastValidTemp = t;
      dhtInitialized = true;
    }
    return true;
  }
  return false;
}

void updateActuatorStateMachine(unsigned long now) {
  // a) Pomodoro Break Override Mode: pulse buzzer + flash RGB LED non-stop for 8 seconds
  if (currentMode == MODE_POMODORO_OVERRIDE) {
    if (now - alertStartMillis >= POMODORO_DURATION) {
      currentMode = MODE_AMBIENT_MONITOR;
      setBuzzer(false);
      return;
    }

    if (now - lastAlertToggle >= INTERVAL_ALERT_MS) {
      lastAlertToggle = now;
      alertPulseState = !alertPulseState;
      if (alertPulseState) {
        setRgbColor(0, 180, 255); // Flash Cyan/Blue
        setBuzzer(true);
      } else {
        setRgbColor(0, 0, 0); // Off
        setBuzzer(false);
      }
    }
  } else if (currentMode == MODE_POMODORO_BREAK) {
    // b) Pomodoro Break: solid calm blue LED, no buzzer
    setRgbColor(0, 80, 255);
    setBuzzer(false);
  } else {
    // b) Low Light Warning Mode (Ambient Monitor):
    // Green = Optimal (>= threshold), Red + periodic gentle short beep = Low Light (< threshold)
    if (smoothedLux < luxThreshold) {
      setRgbColor(255, 0, 0); // Red: Eye strain warning
      unsigned long elapsed = now - lowLightCycleMillis;
      if (elapsed >= LOW_LIGHT_BEEP_PERIOD) {
        lowLightCycleMillis = now;
        elapsed = 0;
      }
      setBuzzer(elapsed < LOW_LIGHT_BEEP_ON_MS);
    } else {
      setRgbColor(0, 255, 0); // Green: Optimal workspace lighting
      setBuzzer(false);
      lowLightCycleMillis = now;
    }
  }
}

void writeTelemetryJson(Print& out) {
  out.print(F("{\"lux\":"));
  out.print(smoothedLux, 1);
  out.print(F(",\"temp\":"));
  out.print(lastValidTemp, 1);
  out.print(F(",\"hum\":"));
  out.print(lastValidHum, 1);
  out.println(F("}")); // Emits "}\r\n" to flush BT05 UART notification buffer
}

void sendTelemetryTask(unsigned long now, bool dhtRanThisTick) {
  // Stagger SoftwareSerial TX so its 37.5ms interrupt-blocking burst never
  // collides with DHT11 microsecond bit-banging on the exact same tick
  if (dhtRanThisTick) {
    return;
  }
  if (now - lastSerialMillis >= INTERVAL_SERIAL_MS) {
    lastSerialMillis = now;
    // Emit strict newline-delimited JSON matching TelemetryData.fromJson()
    // to both USB Hardware Serial and HM-10 BLE SoftwareSerial
    writeTelemetryJson(Serial);
    writeTelemetryJson(bleSerial);
  }
}

void initBt05Ble() {
  bleSerial.begin(9600);
  bleSerial.listen();
  delay(50);

  // Probe BT05 at 9600 baud (only responds with OK when not yet BLE-connected)
  bleSerial.print(F("AT\r\n"));
  unsigned long t0 = millis();
  bool gotResponse = false;
  while (millis() - t0 < 120) {
    if (bleSerial.available() > 0) {
      if (!gotResponse) {
        Serial.print(F("[BLE RX] "));
        gotResponse = true;
      }
      Serial.write(bleSerial.read());
    }
  }
  if (gotResponse) {
    Serial.println();
    return;
  }

  // If no response at 9600, nudge common factory BT05 baud rates (38400 / 115200)
  // down to 9600 (AT+BAUD0 for HM-10/MLT-BT05, AT+BAUD4 for Bolutek CC2541)
  const long fallbackRates[2] = {38400, 115200};
  for (byte i = 0; i < 2; i++) {
    bleSerial.begin(fallbackRates[i]);
    delay(20);
    bleSerial.print(F("AT+BAUD0\r\n"));
    delay(40);
  }

  // Lock SoftwareSerial cleanly at 9600 baud for normal runtime streaming
  bleSerial.begin(9600);
  bleSerial.listen();
  while (bleSerial.available() > 0) {
    bleSerial.read();
  }
}

// =================== ARDUINO LIFECYCLE ===================
void setup() {
  pinMode(PIN_LED_R, OUTPUT);
  pinMode(PIN_LED_G, OUTPUT);
  pinMode(PIN_LED_B, OUTPUT);
  pinMode(PIN_BUZZER, OUTPUT);

  setRgbColor(0, 0, 0);
  setBuzzer(false);

  Serial.begin(9600);
  initBt05Ble();
  dht.begin();

  // Stagger DHT11 polling by 250ms relative to 500ms Serial/BLE telemetry interval
  lastDhtMillis = 250;

  // Prime initial LDR reading
  smoothedLux = adcToLux(analogRead(PIN_LDR));

  // Notify Flutter SerialPortService / BleService that initialization has completed
  Serial.println(F("{\"status\":\"READY\",\"fw\":\"2.5.0\"}"));
  bleSerial.println(F("{\"status\":\"READY\",\"fw\":\"2.5.0\"}"));
}

void loop() {
  unsigned long now = millis();

  // 1. Check incoming Serial & BLE commands on every single CPU tick
  pollSerialRx();

  // 2. Cooperative non-blocking sensor tasks
  updateLdrTask(now);
  bool dhtRanThisTick = updateDhtTask(now);

  // 3. Drive RGB LED & Active Buzzer state machine without delay()
  updateActuatorStateMachine(now);

  // 4. Stream JSON telemetry to Flutter over both USB Serial and HM-10 BLE
  sendTelemetryTask(now, dhtRanThisTick);
}
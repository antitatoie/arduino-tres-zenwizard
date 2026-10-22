/**
 * ZenWizard / ZenWizard Firmware (v2.4.1)
 * Team Arduino Tres - Arduino Uno R3 (CH340)
 * Non-blocking Cooperative Multitasking Architecture
 */

#include <Arduino.h>
#include <DHT.h>
#include <math.h>

// =================== PIN DEFINITIONS ===================
#define PIN_DHT     2
#define DHT_TYPE    DHT11
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

unsigned long lastLdrMillis        = 0;
unsigned long lastDhtMillis        = 0;
unsigned long lastSerialMillis     = 0;
unsigned long lastAlertToggle      = 0;
unsigned long alertStartMillis     = 0;
unsigned long lowLightCycleMillis  = 0;

// Sensor values (with EMA smoothing for LDR and fallback cache for DHT11)
float smoothedLux   = 400.0;
float lastValidTemp = 23.0;
float lastValidHum  = 50.0;
bool dhtInitialized = false;

// Configurable threshold (matches UI default: < 300 lux)
float luxThreshold = 300.0;

// Actuator State Machine
enum SystemMode {
  MODE_AMBIENT_MONITOR,
  MODE_POMODORO_OVERRIDE
};

SystemMode currentMode = MODE_AMBIENT_MONITOR;
bool alertPulseState = false;

// Non-blocking Serial RX Buffer
const byte RX_BUFFER_SIZE = 64;
char rxBuffer[RX_BUFFER_SIZE];
byte rxIndex = 0;

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
  digitalWrite(PIN_BUZZER, active ? HIGH : LOW);
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
  }
}

void pollSerialRx() {
  while (Serial.available() > 0) {
    char c = Serial.read();
    if (c == '\n') {
      rxBuffer[rxIndex] = '\0';
      if (rxIndex > 0) {
        processCommand(rxBuffer);
      }
      rxIndex = 0;
    } else if (rxIndex < RX_BUFFER_SIZE - 1) {
      rxBuffer[rxIndex++] = c;
    } else {
      // Buffer overflow protection: reset index
      rxIndex = 0;
    }
  }
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

void updateDhtTask(unsigned long now) {
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
  }
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

void sendTelemetryTask(unsigned long now) {
  if (now - lastSerialMillis >= INTERVAL_SERIAL_MS) {
    lastSerialMillis = now;
    // Emit strict newline-delimited JSON matching TelemetryData.fromJson()
    Serial.print(F("{\"lux\":"));
    Serial.print(smoothedLux, 1);
    Serial.print(F(",\"temp\":"));
    Serial.print(lastValidTemp, 1);
    Serial.print(F(",\"hum\":"));
    Serial.print(lastValidHum, 1);
    Serial.println(F("}"));
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
  dht.begin();

  // Prime initial LDR reading
  smoothedLux = adcToLux(analogRead(PIN_LDR));

  // Notify Flutter SerialPortService that CH340 DTR reset has completed
  Serial.println(F("{\"status\":\"READY\",\"fw\":\"2.4.1\"}"));
}

void loop() {
  unsigned long now = millis();

  // 1. Check incoming Serial commands on every single CPU tick
  pollSerialRx();

  // 2. Cooperative non-blocking sensor tasks
  updateLdrTask(now);
  updateDhtTask(now);

  // 3. Drive RGB LED & Active Buzzer state machine without delay()
  updateActuatorStateMachine(now);

  // 4. Stream JSON telemetry to Flutter
  sendTelemetryTask(now);
}
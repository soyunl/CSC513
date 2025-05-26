
const int POT_PIN = A0;
const int BUTTON_PINS[6] = {3, 4, 5, 6, 7, 8};
const int RED_PIN = 9;
const int GREEN_PIN = 10;
const int BLUE_PIN = 11;

// 6 moods × 2 intensities (mild to intense)
const uint8_t PALETTE[6][2][3] = {
  { {0, 255, 0}, { 0, 128, 0} },        // happiness - green
  { {255, 255, 0}, { 255, 165, 0} },    // disgust - yellow(ish)
  { {0, 0, 255}, { 0, 0, 128} },        // sadness - blue
  { {255, 0, 0}, { 128, 0, 0} },        // anger - red
  { {255, 0, 255}, { 128, 0, 128} },    // fear - pink
  { {0, 255, 255}, { 0, 128, 128} }     // surprise - cyan
};

// buttons to remember the previous input
unsigned long buttonPressTime[6] = {0, 0, 0, 0, 0, 0};
bool activeMoods[6] = {false, false, false, false, false, false};
const unsigned long LONG_PRESS_DURATION = 3000;  // pressing for 3 seconds to clear the input

void setup() {
  for (int i = 0; i < 6; i++) {
    pinMode(BUTTON_PINS[i], INPUT);  // external resistors
  }
  pinMode(RED_PIN, OUTPUT);
  pinMode(GREEN_PIN, OUTPUT);
  pinMode(BLUE_PIN, OUTPUT);

  Serial.begin(9600);
}

void loop() {
  float intensity = analogRead(POT_PIN) / 1023.0;
  for (int i = 0; i < 6; i++) {
    if (digitalRead(BUTTON_PINS[i]) == HIGH) {
      if (buttonPressTime[i] == 0) {
        buttonPressTime[i] = millis();
      }
      if (millis() - buttonPressTime[i] > LONG_PRESS_DURATION) {
        for (int j = 0; j < 6; j++) {
          activeMoods[j] = false;
        }
        Serial.println("clearing all moods");
      }
    } else {
      if (buttonPressTime[i] != 0 && millis() - buttonPressTime[i] < LONG_PRESS_DURATION) {
        activeMoods[i] = !activeMoods[i];
        Serial.print("Mood "); Serial.print(i);
        Serial.print(" toggled to ");
        Serial.println(activeMoods[i] ? "ON" : "OFF");
      }
      buttonPressTime[i] = 0;
    }
  }

  int rBase = 0, gBase = 0, bBase = 0;
  int activeCount = 0;

  for (int i = 0; i < 6; i++) {
    if (activeMoods[i]) {
      uint8_t rMild = PALETTE[i][0][0];
      uint8_t rIntense = PALETTE[i][1][0];
      uint8_t gMild = PALETTE[i][0][1];
      uint8_t gIntense = PALETTE[i][1][1];
      uint8_t bMild = PALETTE[i][0][2];
      uint8_t bIntense = PALETTE[i][1][2];
      rBase += rMild + (rIntense - rMild) * intensity;
      gBase += gMild + (gIntense - gMild) * intensity;
      bBase += bMild + (bIntense - bMild) * intensity;
      activeCount++;
    }
  }

  if (activeCount > 0) {
    rBase /= activeCount;
    gBase /= activeCount;
    bBase /= activeCount;

    analogWrite(RED_PIN, rBase);
    analogWrite(GREEN_PIN, gBase);
    analogWrite(BLUE_PIN, bBase);

    // generating palette to be used in Processing
    for (int i = 0; i < 5; i++) {
      float factor = 0.4 + 0.15 * i;  // 40% - 100% brightness
      int rOut = constrain(rBase * factor, 0, 255);
      int gOut = constrain(gBase * factor, 0, 255);
      int bOut = constrain(bBase * factor, 0, 255);
      Serial.print(rOut); Serial.print(",");
      Serial.print(gOut); Serial.print(",");
      Serial.print(bOut);
      if (i < 4) Serial.print(",");
    }
    Serial.print(",");
    Serial.println(intensity, 2);  // 2 decimal places
  } else {
    analogWrite(RED_PIN, 0);
    analogWrite(GREEN_PIN, 0);
    analogWrite(BLUE_PIN, 0);
  }

  delay(30);
}

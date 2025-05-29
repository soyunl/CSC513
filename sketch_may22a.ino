const int POT_PIN = A0;
const int BUTTON_PINS[6] = {3, 4, 5, 6, 7, 8};

unsigned long buttonPressTime[6] = {0, 0, 0, 0, 0, 0};
bool activeMoods[6] = {false, false, false, false, false, false};
const unsigned long LONG_PRESS_DURATION = 3000;

void setup() {
  for (int i = 0; i < 6; i++) {
    pinMode(BUTTON_PINS[i], INPUT);
  }

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

  bool sent = false;
  for (int i = 0; i < 6; i++) {
    if (activeMoods[i]) {
      Serial.print(i);  
      Serial.print(",");
      sent = true;
    }
  }

  if (sent) {
    Serial.println(intensity, 2); 
  } else {
    Serial.println("no active mood");
  }

  delay(100);
}

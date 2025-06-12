#include <Servo.h>

const int sunPin = A0;
const int waterPin = A1;
const int tempPin = A2;
const int servoPin = 9;
const int SPINACH_PIN = 3;
const int LETTUCE_PIN = 4;
const int LAVENDER_PIN = 5;
const int BASIL_PIN = 6;
const int TOMATO_PIN = 7;

int lastServoAngle = 180; // starting with down
const int servoDeadband = 3;


struct PlantProfile {
  int sunMin, sunMax;
  int waterMin, waterMax;
  int tempMin, tempMax;
};

const char* plantNames[6] = {
  "No Plant",    // 0
  "Spinach",     // 1
  "Lettuce",     // 2
  "Lavender",    // 3
  "Basil",       // 4
  "Tomato"       // 5
};

PlantProfile plantProfiles[6] = {
  {0, 0, 0, 0, 0, 0},               
  {400, 600, 600, 900, 300, 600},   
  {500, 700, 700, 1023, 300, 600}, 
  {800, 1023, 400, 600, 700, 900}, 
  {800, 1023, 700, 1023, 700, 900}, 
  {900, 1023, 600, 800, 800, 1023}  
};

Servo plantServo;
int currentPlant = 0;

void setup() {
  Serial.begin(9600);
  plantServo.attach(servoPin);
  pinMode(SPINACH_PIN, INPUT_PULLUP);
  pinMode(LETTUCE_PIN, INPUT_PULLUP);
  pinMode(LAVENDER_PIN, INPUT_PULLUP);
  pinMode(BASIL_PIN, INPUT_PULLUP);
  pinMode(TOMATO_PIN, INPUT_PULLUP);
}

int readAveragedAnalog(int pin) {
  int total = 0;
  const int samples = 5;

  for (int i = 0; i < samples; i++) {
    total += analogRead(pin);
  }

  return total / samples;
}

void loop() {
  readPlantToken();

  int sunValue = readAveragedAnalog(sunPin);
  int waterValue = readAveragedAnalog(waterPin);
  int tempValue = readAveragedAnalog(tempPin);

  // If no plant selected → move stem to min heightt
  if (currentPlant == 0) {
    plantServo.write(180); 
    Serial.println("No plant selected.");
  } else {
    PlantProfile profile = plantProfiles[currentPlant];

    float sunScore = computeMatchScore(sunValue, profile.sunMin, profile.sunMax);
    float waterScore = computeMatchScore(waterValue, profile.waterMin, profile.waterMax);
    float tempScore = computeMatchScore(tempValue, profile.tempMin, profile.tempMax);

    float growthScore = (sunScore + waterScore + tempScore) / 3.0;
    int servoAngle = 180 - (growthScore * 180); // 0° = fully up, 180° = fully down

    if (abs(servoAngle - lastServoAngle) >= servoDeadband) {
      plantServo.write(servoAngle);
      lastServoAngle = servoAngle;
    }


    Serial.print("Plant: "); Serial.print(plantNames[currentPlant]);
    Serial.print(" | Growth Score: "); Serial.print(growthScore, 2);
    Serial.print(" | Servo Angle: "); Serial.println(servoAngle);    

    Serial.print("Sun: "); Serial.print(sunValue);
    Serial.print(" | Water: "); Serial.print(waterValue);
    Serial.print(" | Temp: "); Serial.println(tempValue);            

    Serial.print("SunScore: "); Serial.print(sunScore);
    Serial.print(" | WaterScore: "); Serial.print(waterScore);
    Serial.print(" | TempScore: "); Serial.println(tempScore);

  }

  delay(100);
}

void readPlantToken() {
  if (digitalRead(SPINACH_PIN) == LOW) {
    currentPlant = 1;
  } else if (digitalRead(LETTUCE_PIN) == LOW) {
    currentPlant = 2;
  } else if (digitalRead(LAVENDER_PIN) == LOW) {
    currentPlant = 3;
  } else if (digitalRead(BASIL_PIN) == LOW) {
    currentPlant = 4;
  } else if (digitalRead(TOMATO_PIN) == LOW) {
    currentPlant = 5;
  } else {
    currentPlant = 0; 
  }
}

float computeMatchScore(int inputValue, int targetMin, int targetMax) {
  if (inputValue < targetMin) {
    return 0.0;
  } else if (inputValue > targetMax) {
    return 0.0;
  } else {
    int targetCenter = (targetMin + targetMax) / 2;
    int targetRange = (targetMax - targetMin) / 2;

    float distance = abs(inputValue - targetCenter);
    float score = 1.0 - (distance / targetRange);

    if (score < 0.0) score = 0.0;
    if (score > 1.0) score = 1.0;

    return score;
  }
}



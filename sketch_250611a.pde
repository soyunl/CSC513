import processing.serial.*;

Serial myPort;

String plantName = "None";
float growthScore = 0.0;
int sunValue = 0;
int waterValue = 0;
int tempValue = 0;

float sunScore = 0.0;
float waterScore = 0.0;
float tempScore = 0.0;

void setup() {
  size(600, 550);
  println(Serial.list());
  
  String portName = "/dev/cu.usbmodem11101";  
  myPort = new Serial(this, portName, 9600);
  myPort.bufferUntil('\n');
}

void draw() {
  background(255);

  fill(0);
  textSize(22);
  text("Current Plant: " + plantName, 20, 40);
  text("Growth Score: " + nf(growthScore, 1, 2), 20, 80);

  // Progress bar
  fill(100, 200, 100);
  rect(20, 100, growthScore * 500, 30);
  stroke(0);
  noFill();
  rect(20, 100, 500, 30);

  fill(0);
  textSize(16);
  text("Sunlight: " + sunValue, 20, 160);
  drawStatusLabel(sunScore, 200, 160);

  text("Water: " + waterValue, 20, 190);
  drawStatusLabel(waterScore, 200, 190);

  text("Temperature: " + tempValue, 20, 220);
  drawStatusLabel(tempScore, 200, 220);

  pushMatrix();
  translate(width/2, height - 50);

  stroke(50, 200, 50);
  strokeWeight(10);
  float stemHeight = map(growthScore, 0.0, 1.0, 20, 250);
  line(0, 0, 0, -stemHeight);

  noStroke();
  fill(50, 200, 50);

  if (growthScore > 0.2) {
    ellipse(-10, -stemHeight + 20, 20, 10);
    ellipse(10, -stemHeight + 20, 20, 10);
  }
  if (growthScore > 0.5) {
    ellipse(-15, -stemHeight + 60, 25, 12);
    ellipse(15, -stemHeight + 60, 25, 12);
  }
  if (growthScore > 0.8) {
    ellipse(-20, -stemHeight + 100, 30, 15);
    ellipse(20, -stemHeight + 100, 30, 15);
  }

  if (growthScore > 0.95) {
    fill(255, 100, 100);
    ellipse(0, -stemHeight - 20, 30, 30);
  }

  popMatrix();
}

void drawStatusLabel(float score, float x, float y) {
  textSize(16);
  if (score >= 0.8) {
    fill(0, 180, 0);
    text("Good", x, y);
  } else if (score >= 0.5) {
    fill(200, 150, 0);
    text("Close", x, y);
  } else {
    fill(200, 0, 0);
    text("Adjust", x, y);
  }
}

void serialEvent(Serial myPort) {
  String inString = myPort.readStringUntil('\n');
  if (inString != null) {
    inString = trim(inString);

    if (inString.startsWith("Plant:")) {
      String[] parts = splitTokens(inString, ":|");
      if (parts.length >= 4) {
        plantName = trim(parts[1]);
        growthScore = float(trim(parts[3]));
      }
    }

    else if (inString.startsWith("Sun:")) {
      String[] parts = splitTokens(inString, ":|");
      if (parts.length >= 6) {
        sunValue = int(trim(parts[1]));
        waterValue = int(trim(parts[3]));
        tempValue = int(trim(parts[5]));
      }
    }

    else if (inString.startsWith("SunScore:")) {
      String[] parts = splitTokens(inString, ":|");
      if (parts.length >= 6) {
        sunScore = float(trim(parts[1]));
        waterScore = float(trim(parts[3]));
        tempScore = float(trim(parts[5]));
      }
    }
  }
}

import processing.serial.*;

Serial myPort;
color[] palette = new color[6];  
color[][] moodColors = new color[6][3];  
String[] moodNames = {"Anger", "Surprise", "Disgust", "Sadness", "Happiness", "Fear"};
int selected = 0;
float brushIntensity = 0.5;
PImage mandala;
PGraphics coloringLayer;
String activeMoodsText = "No moods selected.";
boolean justCleared = false;


void setup() {
  size(544, 558);
  strokeWeight(5);

  moodColors[0][0] = color(180, 0, 0);
  moodColors[0][1] = color(255, 0, 0);
  moodColors[0][2] = color(0, 0, 0);

  moodColors[1][0] = color(255, 255, 0);
  moodColors[1][1] = color(255, 192, 203);
  moodColors[1][2] = color(0, 255, 0);

  moodColors[2][0] = color(85, 107, 47);
  moodColors[2][1] = color(107, 142, 35);
  moodColors[2][2] = color(139, 69, 19);

  moodColors[3][0] = color(128, 128, 128);
  moodColors[3][1] = color(135, 206, 250);
  moodColors[3][2] = color(0, 0, 139);

  moodColors[4][0] = color(255, 165, 0);
  moodColors[4][1] = color(0, 255, 0);
  moodColors[4][2] = color(255, 255, 0);

  moodColors[5][0] = color(0, 0, 139);
  moodColors[5][1] = color(139, 69, 19);
  moodColors[5][2] = color(210, 180, 140);

  mandala = loadImage("mandala-removebg.png");
  imageMode(CORNER);

  coloringLayer = createGraphics(mandala.width, mandala.height);
  coloringLayer.beginDraw();
  coloringLayer.background(255);
  coloringLayer.endDraw();

  String portName = "/dev/cu.usbmodem1101";  
  myPort = new Serial(this, portName, 9600);
  myPort.bufferUntil('\n');

  updatePalette(new int[]{}, brushIntensity);
}

void draw() {
  background(255);

  for (int i = 0; i < 6; i++) {
    if (mouseX > i * 50 && mouseX < (i + 1) * 50 && mouseY < 50) {
      fill(220);
      noStroke();
      rect(i * 50, 0, 50, 50, 8);
    }
    fill(palette[i]);
    stroke(180);
    strokeWeight(1);
    rect(i * 50, 0, 50, 50, 8);

    // Eraser 
    if (i == 5) {
      fill(200);
      noStroke();
      rect(i * 50 + 15, 10, 20, 15, 3);
      fill(160);
      triangle(i * 50 + 15, 25, i * 50 + 35, 25, i * 50 + 25, 40);
    }

    if (selected == i) {
      noFill();
      stroke(255, 0, 0);
      strokeWeight(2);
      rect(i * 50 + 2, 2, 46, 46, 8);
    }
  }
  strokeWeight(1);

  fill(240);
  noStroke();
  rect(0, 60, width, 50);
  fill(0);
  textSize(14);
  textAlign(LEFT, CENTER);
  text("Press ‘C’ to clear or hold any mood button for 3 seconds to reset", 10, 75);
  text(activeMoodsText, 10, 95);


  image(coloringLayer, 0, 110);
  image(mandala, 0, 110);

  // Drawing
  if (mousePressed && mouseY > 110) {
    coloringLayer.beginDraw();
    coloringLayer.stroke(palette[selected]);
    coloringLayer.strokeWeight(getStrokeWeightForIntensity());
    coloringLayer.line(pmouseX, pmouseY - 110, mouseX, mouseY - 110);
    coloringLayer.endDraw();
  }
}

void mousePressed() {
  if (mouseY < 50) {
    selected = mouseX / 50;
    println("Selected swatch: " + selected);
  }
}

void keyPressed() {
  if (key == 'c' || key == 'C') {
    coloringLayer.beginDraw();
    coloringLayer.background(255);
    coloringLayer.endDraw();
    justCleared = true; 
  }
}

void serialEvent(Serial p) {
  String data = p.readStringUntil('\n');
  if (data != null) {
    data = trim(data);
    if (data.equals("no active mood")) {
      activeMoodsText = "No moods selected.";
      updatePalette(new int[]{}, brushIntensity);
    } else if (data.equals("clearing all moods")) {
      activeMoodsText = "Moods cleared. Ready for new mood selection.";
      updatePalette(new int[]{}, brushIntensity);
    } else {
      String[] tokens = split(data, ',');
      if (tokens.length >= 2) {
        int numMoods = min(tokens.length - 1, 2);
        int[] activeMoods = new int[numMoods];
        for (int i = 0; i < numMoods; i++) {
          activeMoods[i] = int(tokens[i]);
        }
        brushIntensity = float(tokens[tokens.length - 1]);
        updatePalette(activeMoods, brushIntensity);
        updateActiveMoodsText(activeMoods);
      }
    }
  }
}

void updatePalette(int[] activeMoods, float intensity) {
  if (activeMoods.length == 0) {
    // No moods: blank (white) palette
    for (int i = 0; i < 5; i++) {
      palette[i] = color(255);
    }
  } else if (activeMoods.length == 1) {
    int mood = activeMoods[0];
    for (int i = 0; i < 3; i++) {
      color mild = lerpColor(moodColors[mood][i], color(255), 0.4);
      color intense = moodColors[mood][i];
      palette[i] = lerpColor(mild, intense, intensity);
    }
  } else if (activeMoods.length == 2) {
    int moodA = activeMoods[0];
    int moodB = activeMoods[1];
    for (int i = 0; i < 3; i++) {
      color cA = moodColors[moodA][i];
      color cB = moodColors[moodB][i];
      color blended = lerpColor(cA, cB, 0.5);
      color mild = lerpColor(blended, color(255), 0.4);
      palette[i] = lerpColor(mild, blended, intensity);
    }
  }
  palette[3] = lerpColor(palette[0], color(255), 0.4);
  palette[4] = lerpColor(palette[1], color(0), 0.4);
  palette[5] = color(255);  
}

void updateActiveMoodsText(int[] activeMoods) {
  activeMoodsText = "Selected moods: ";
  for (int i = 0; i < activeMoods.length; i++) {
    activeMoodsText += moodNames[activeMoods[i]];
    if (i < activeMoods.length - 1) {
      activeMoodsText += " + ";
    }
  }
}

float getStrokeWeightForIntensity() {
  if (brushIntensity < 0.3) {
    return 2;
  } else if (brushIntensity < 0.7) {
    return 5;
  } else {
    return 10;
  }
}

PImage getCombinedImage() {
  PImage combined = createImage(mandala.width, mandala.height, RGB);
  combined.copy(coloringLayer, 0, 0, mandala.width, mandala.height, 0, 0, mandala.width, mandala.height);
  combined.blend(mandala, 0, 0, mandala.width, mandala.height, 0, 0, mandala.width, mandala.height, BLEND);
  return combined;
}

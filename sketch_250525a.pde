import processing.serial.*;

Serial myPort;
color[] palette = new color[6];  // 5 moods + eraser
int selected = 0;
String[] rgbValues;
float brushIntensity = 0.5;
PImage mandala;
PGraphics coloringLayer;

void setup() {
  size(544, 558); 
  strokeWeight(5);
  mandala = loadImage("mandala-removebg.png");
  imageMode(CORNER);

  coloringLayer = createGraphics(mandala.width, mandala.height);
  coloringLayer.beginDraw();
  coloringLayer.background(255);
  coloringLayer.endDraw();

  String portName = "/dev/cu.usbmodem1101";
  myPort = new Serial(this, portName, 9600);
  myPort.bufferUntil('\n');

  for (int i = 0; i < 5; i++) {
    palette[i] = color(255);
  }
  palette[5] = color(255);  // eraser slot
}

void draw() {
  for (int i = 0; i < 6; i++) {
    // highlights hovering
    if (mouseX > i * 50 && mouseX < (i + 1) * 50 && mouseY < 50) {
      fill(220);
      noStroke();
      rect(i * 50, 0, 50, 50, 8);
    }

    fill(palette[i]);
    stroke(180);
    strokeWeight(1);
    rect(i * 50, 0, 50, 50, 8);

    // eraser icon for the last slot
    if (i == 5) {
      fill(200);
      noStroke();
      rect(i * 50 + 15, 10, 20, 15, 3);  
      fill(160);
      triangle(i * 50 + 15, 25, i * 50 + 35, 25, i * 50 + 25, 40);
    }

    // current selection
    if (selected == i) {
      noFill();
      stroke(255, 0, 0);
      strokeWeight(2);
      rect(i * 50 + 2, 2, 46, 46, 8);
    }
  }
  strokeWeight(1);  // reset

  // text instruction
  noStroke();
  fill(240);
  rect(0, 60, width, 30);
  stroke(200);
  noFill();
  rect(0, 60, width, 30);

  fill(0);
  textSize(16);
  textAlign(LEFT, CENTER);
  String prompt = getPromptForIntensity();
  text(prompt, 10, 75);

  image(coloringLayer, 0, 100);
  image(mandala, 0, 100);

  // colouring
  if (mousePressed && mouseY > 100) {
    coloringLayer.beginDraw();
    coloringLayer.stroke(palette[selected]);
    coloringLayer.strokeWeight(getStrokeWeightForIntensity());
    coloringLayer.line(pmouseX, pmouseY - 100, mouseX, mouseY - 100);
    coloringLayer.endDraw();
  }
}

void mousePressed() {
  if (mouseY < 50) {
    selected = mouseX / 50;
    println("Selected: " + selected + (selected == 5 ? " (ERASER)" : ""));
  }
}

void keyPressed() {
  if (key == 'c' || key == 'C') {
    coloringLayer.beginDraw();
    coloringLayer.background(255);
    coloringLayer.endDraw();
  }
  if (key == 's' || key == 'S') {
    PImage combined = getCombinedImage();
    combined.save("mood-coloring-####.png");
  }
}

String getPromptForIntensity() {
  return "Choose your color to express your mood!\nPress ‘S’ to save or ‘C’ to clear your drawing.";
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

void serialEvent(Serial p) {
  String data = p.readStringUntil('\n');
  if (data != null) {
    rgbValues = trim(data).split(",");
    if (rgbValues.length == 16) {
      for (int i = 0; i < 5; i++) {
        int r = int(rgbValues[i * 3]);
        int g = int(rgbValues[i * 3 + 1]);
        int b = int(rgbValues[i * 3 + 2]);
        palette[i] = color(r, g, b);
      }
      brushIntensity = float(rgbValues[15]);
    }
  }
}

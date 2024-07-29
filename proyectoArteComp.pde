import processing.core.PImage;
import processing.sound.SoundFile;
import java.util.ArrayList;

PImage img, sobelImg, originalImg;  
PImage playButtonImg, rewindButtonImg, fastForwardButtonImg;  // Imágenes de los botones
SoundFile sound;         
ArrayList<Subtitle> subtitles;  
String currentSubtitle = "";    
float startTime;          
boolean isPlaying = true; 
float playbackPosition;  
float buttonWidth = 100;
float buttonHeight = 50;
float progressBarWidth = 600;
float progressBarHeight = 20;
float progressBarX = 20;      
float progressBarY; 
int effectToggle = 0;  
float textSize = 50;

void setup() {
  size(645, 363);          
  
  img = loadImage("marowar.jpg");  
  originalImg = img.copy(); 
  sobelImg = createImage(img.width, img.height, RGB);
  img.resize(width, height);
  sobelImg.resize(width, height);
  applySobel();
  
  sound = new SoundFile(this, "marowar.mp3");
  
  loadSubtitles("subtitles.csv");   
  sound.play();          
  startTime = millis();  
  playbackPosition = 0;  
  
  textSize(textSize);          
  textAlign(CENTER, CENTER); 
  
  // Cargar imágenes de botones
  playButtonImg = loadImage("play.png");    // Asegúrate de tener esta imagen
  rewindButtonImg = loadImage("retroceder.jpg");  // Asegúrate de tener esta imagen
  fastForwardButtonImg = loadImage("adelantar.png");  // Asegúrate de tener esta imagen

  // Configura botones
  createButton(playButtonImg, width / 2 - 50, height - 50, buttonWidth, buttonHeight, () -> {
    if (isPlaying) {
      sound.pause();
      isPlaying = false;
    } else {
      sound.play();
      isPlaying = true;
    }
  });
  
  createButton(rewindButtonImg, 100, height - 50, buttonWidth, buttonHeight, () -> {
    float newPosition = sound.position() - 5;  
    if (newPosition < 0) newPosition = 0;
    sound.jump(newPosition);
  });
  
  createButton(fastForwardButtonImg, width - 200, height - 50, buttonWidth, buttonHeight, () -> {
    float newPosition = sound.position() + 5;  
    if (newPosition > sound.duration()) newPosition = sound.duration();
    sound.jump(newPosition);
  });
  
  progressBarY = height - 80; 
}

void draw() {
  background(0);  
  playbackPosition = sound.position();  
  
  if (frameCount % 60 < 30) {
    image(originalImg, 0, 0);  
  } else {
    image(sobelImg, 0, 0);  
  }
  
  displaySubtitle();
  drawProgressBar();
  drawButtons();
  displayTime();  // Muestra el contador de tiempo
}

void mousePressed() {
  if (mouseX > progressBarX && mouseX < progressBarX + progressBarWidth &&
      mouseY > progressBarY && mouseY < progressBarY + progressBarHeight) {
    float clickedPosition = map(mouseX, progressBarX, progressBarX + progressBarWidth, 0, sound.duration());
    sound.jump(clickedPosition);
  }
  
  buttons.forEach(button -> {
    if (mouseX > button.x && mouseX < button.x + button.width &&
        mouseY > button.y && mouseY < button.y + button.height) {
      button.action.run();
    }
  });
}

void loadSubtitles(String filename) {
  subtitles = new ArrayList<Subtitle>();
  String[] lines = loadStrings(filename);
  
  if (lines.length <= 1) {
    println("Error: El archivo CSV no contiene suficientes líneas.");
    return;
  }

  for (int i = 1; i < lines.length; i++) {  
    String line = lines[i];
    String[] parts = split(line, ',');
    
    if (parts.length < 3) {
      println("Error en la línea " + i + ": " + line);
      continue;
    }
    
    try {
      float start = float(parts[0]);
      float end = float(parts[1]);
      String text = join(subArray(parts, 2, parts.length), ",");
      subtitles.add(new Subtitle(start, end, text));
    } catch (NumberFormatException e) {
      println("Error al analizar el tiempo en la línea " + i + ": " + line);
    }
  }
}

String[] subArray(String[] array, int start, int end) {
  String[] result = new String[end - start];
  for (int i = start; i < end; i++) {
    result[i - start] = array[i];
  }
  return result;
}

void displaySubtitle() {
  currentSubtitle = "";  
  
  for (Subtitle subtitle : subtitles) {
    if (playbackPosition >= subtitle.start && playbackPosition <= subtitle.end) {
      currentSubtitle = subtitle.text;
      break;
    }
  }
  
  fill(0);  
  textSize(textSize);   //  tam del texto
  textAlign(CENTER, CENTER);  
  text(currentSubtitle, width / 2 + 2, height / 2 + 2);  
  
  fill(255, 0, 0);  
  text(currentSubtitle, width / 2, height / 2);  
}

void drawProgressBar() {
  float progress = map(playbackPosition, 0, sound.duration(), 0, progressBarWidth);
  
  fill(50);
  rect(progressBarX, progressBarY, progressBarWidth, progressBarHeight);
  
  fill(255, 0, 0);
  rect(progressBarX, progressBarY, progress, progressBarHeight);
  
  stroke(255);
  noFill();
  rect(progressBarX, progressBarY, progressBarWidth, progressBarHeight);
}

void displayTime() {
  int currentTime = int(playbackPosition);
  int totalTime = int(sound.duration());
  
  String currentTimeStr = nf(currentTime / 60, 2) + ":" + nf(currentTime % 60, 2);
  String totalTimeStr = nf(totalTime / 60, 2) + ":" + nf(totalTime % 60, 2);
  
  fill(255, 0, 0);  // Color rojo
  textSize(16);
  textAlign(RIGHT, CENTER);
  text(currentTimeStr + " / " + totalTimeStr, width - 20, height - 20);
}

void applySobel() {
  img.loadPixels();
  sobelImg.loadPixels();
  
  float[] hKernel = {
    -1, 0, 1,
    -2, 0, 2,
    -1, 0, 1
  };

  float[] vKernel = {
    -1, -2, -1,
    0, 0, 0,
    1, 2, 1
  };

  for (int x = 1; x < img.width - 1; x++) {
    for (int y = 1; y < img.height - 1; y++) {
      float hSum = 0;
      float vSum = 0;
      
      for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
          int pixelColor = img.get(x + i, y + j);
          float brightness = brightness(pixelColor);
          
          hSum += brightness * hKernel[(i + 1) * 3 + (j + 1)];
          vSum += brightness * vKernel[(i + 1) * 3 + (j + 1)];
        }
      }

      float edgeStrength = sqrt(hSum * hSum + vSum * vSum);
      int edgeColor = color(edgeStrength);

      sobelImg.pixels[y * img.width + x] = edgeColor;
    }
  }
  
  sobelImg.updatePixels();
}

class Subtitle {
  float start, end;
  String text;

  Subtitle(float start, float end, String text) {
    this.start = start;
    this.end = end;
    this.text = text;
  }
}

class Button {
  float x, y, width, height;
  PImage image;  // Imagen del botón
  Runnable action;

  Button(float x, float y, float width, float height, PImage image, Runnable action) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    this.image = image;
    this.action = action;
  }
}

ArrayList<Button> buttons = new ArrayList<Button>();

void createButton(PImage image, float x, float y, float width, float height, Runnable action) {
  buttons.add(new Button(x, y, width, height, image, action));
}

void drawButtons() {
  buttons.forEach(button -> {
    image(button.image, button.x, button.y, button.width, button.height);  // Dibuja la imagen del botón
  });
}

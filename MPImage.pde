import java.io.*;

class MPImage {
  int x, y;
  int w, h;
  int roll, fullRollNumber;
  
  File imageFolder = new File(sketchPath(initImageFolder));
  ArrayList<PImage> initImages = new ArrayList<PImage>();
  int currentInitImage = -1;
  PImage currentCamImage;
  int currentCamID;


  MPImage(int initX, int initY, int initWidth, int initHeight) {
    x = initX;
    y = initY;
    w = initWidth;
    h = initHeight;
    fullRollNumber = 5;
    roll = fullRollNumber;
    
    loadInitImages();
  }
  
  
  void loadInitImages() {
    File[] files = imageFolder.listFiles();
    
    for (File file : files) {
      if (!file.isHidden() && file.isFile()) {
        //println(file.getName());
        PImage img = loadImage(sketchPath(initImageFolder)+"/"+file.getName());
        img.resize(w, 0);
        initImages.add(img);
      }
    }
  }
  
  void decreaseRollNumber() {
    roll = roll - 1;
    if (roll < 0) {
      roll = 0;
    }
  }
  
  void resetRoll() {
    roll = fullRollNumber;
  }


  void show() {
    if (roll == fullRollNumber) {
      showInitImage();
    } else {
      showCamImage();
    } 
  }
  
  void showCamImage() {
    image(currentCamImage, x, y);
  }
  
  void setCamImage(int id, PImage img) {
    currentCamID = id;
    currentCamImage = img;
  }
  
  void showInitImage() {
    if (currentInitImage < 0) {
      showTestImage();
    } else {
      image(initImages.get(currentInitImage), x, y);
    }
  }
  
  
  void next() {
    currentInitImage++;
    if (currentInitImage >= initImages.size()) currentInitImage = 0;
  }


  void showTestImage() {
    int wLineNum = 16;
    int hLineNum = 9;
    float wLineGap = float(w) / wLineNum;
    float hLineGap = float(h) / hLineNum;

    fill(0, 0, 255);
    rect(x, y, w, h);
    
    stroke(255, 0, 0);
    strokeWeight(1);
    for (int i=0; i<=wLineNum; i++) {
      line(x+wLineGap*i, y, x+wLineGap*i, y+h);
    }
    
    for (int i=0; i<=hLineNum; i++) {
      line(x, y+hLineGap*i, x+w, y+hLineGap*i);
    }
  }
  
  
}
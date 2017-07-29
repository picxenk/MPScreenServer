/*
 MetaPixel ScreenServer
 by PROTOROOM, SeungBum Kim <picxenk@gmail.com>
 */

import websockets.*;
import ddf.minim.*;

Minim minim;
AudioSample shot;
AudioSample release;
AudioSample noise;
AudioPlayer feedback;


// ########## Configurations ########## 
int wsPort = 8080;


WebsocketServer ws;

int status = -1; // -1:ready, 0~2:cam is processing
int lastStatusUpdateTime = 0;
boolean turnOffMPCam = false;

boolean updateScreen = false;
String initImageFolder = "initImages";
String mpcamImageFolder = "MPCams";

int MPScreenX, MPScreenY, MPScreenWidth, MPScreenHeight;
MPImage mpImage;
int camNumber = 3;
MPCam[] mpCams = new MPCam[camNumber];

PFont font;

int screenResolution = 5; // check settings()
int defaultWaitSec = 15;
int t = defaultWaitSec;

void settings() {
  // 8:3 (4:3 x 2) = 2560x960, 1280x480
  // 16:9 in 8:3 = around 1700x960, 850x480
  if (screenResolution == 0) fullScreen(P2D, SPAN);
  if (screenResolution == 1) size(640, 240, P2D);
  if (screenResolution == 2) size(1280, 480, P2D);
  if (screenResolution == 3) size(2560, 960, P2D);
  if (screenResolution == 4) size(1920, 1080, P2D);
  if (screenResolution == 5) size(960, 540, P2D);
}


void setup() {
  //noLoop();
  frameRate(10);
  noCursor();
  background(0);
  noStroke();

  ws = new WebsocketServer(this, wsPort, "/screenserver");

  minim = new Minim(this);
  shot = minim.loadSample("shot1.wav", 512);
  release = minim.loadSample("release.wav", 512);
  noise = minim.loadSample("noise.wav", 512);
  feedback = minim.loadFile("sound126R_loop.wav", 1024*2);

  font = loadFont("8bitOperatorPlus8-Bold-40.vlw");

  //MPScreenWidth = floor(height*16/9);
  //MPScreenHeight = height;
  //MPScreenX = floor(width-MPScreenWidth)/2;
  //MPScreenY = 0;
  MPScreenWidth = width;
  MPScreenHeight = height;
  MPScreenX = 0;
  MPScreenY = 0;

  fill(200);
  rect(MPScreenX, MPScreenY, MPScreenWidth, MPScreenHeight);

  mpImage = new MPImage(MPScreenX, MPScreenY, MPScreenWidth, MPScreenHeight);
  for (int i=0; i<camNumber; i++) {
    mpCams[i] = new MPCam(i);
  }
}


void draw() {
  background(0);
  mpImage.show();
  if (mpImage.roll == 0) {
    showTimer(t);
    if (t <= 0) {
      mpImage.resetRoll();
      mpImage.next();
      t = defaultWaitSec;
      // become ready
      status = -1;
      ws.sendMessage(str(status));
    }
    if (frameCount % 10 == 0) {
      t--;
      // Do not shot now
      status = -2;
      ws.sendMessage(str(status));
    }
  } 

  if (turnOffMPCam) {
    showConfirmTurnOffMPCam();
  }

  // to check long cam process
  if (status > -1) {
    if (millis() - lastStatusUpdateTime > 90000) {
      status = -1;
      ws.sendMessage(str(status));
      lastStatusUpdateTime = millis();
    }
  }
}

void showTimer(int s) {
  int b, sx;
  if (screenResolution == 5) {
    b = 5;
  } else {
    b = 10;
  }
  sx = b * 50;
  fill(0);
  noStroke();
  //rect(MPScreenWidth-sx, MPScreenHeight-b*8, MPScreenWidth-b, b*7);
  rect(MPScreenWidth-sx, b, MPScreenWidth-b, b*7);
  fill(240);
  textAlign(LEFT, BOTTOM);
  textFont(font, b*5);
  //text("NEXT IMAGE: "+str(s)+"s", MPScreenWidth-sx+b, MPScreenHeight-b*3);
  text("NEXT IMAGE: "+str(s)+"s", MPScreenWidth-sx+b, b*7);
}

void showMPImageCaption(int id) {
  int b, sx;
  int s = 0;
  if (screenResolution == 5) {
    b = 5;
  } else {
    b = 10;
  }
  sx = b * 60;
  fill(0);
  noStroke();
  rect(MPScreenWidth-sx, MPScreenHeight-b*8, MPScreenWidth-b, b*7);
  fill(240);
  textFont(font, b*5);
  if (id == 0) s = 2;
  if (id == 1) s = 3;
  if (id == 2) s = 1;
  text("Image from camera #"+str(s), MPScreenWidth-sx+b, MPScreenHeight-b*3);
}

void showConfirmTurnOffMPCam() {
  fill(0);
  rectMode(CENTER);
  rect(MPScreenWidth/2, MPScreenHeight/2, MPScreenWidth/2, MPScreenHeight/2);
  fill(250);
  textAlign(CENTER, CENTER);
  textFont(font, 20);
  text("Turn off MetaPixelCamera? y / n", MPScreenWidth/2, MPScreenHeight/2);
  rectMode(CORNER);
}


void mouseClicked() {
}


void keyPressed() {
  if (key == ' ') {
    mpImage.next();
  }


  if (key =='0') {
    updateMPCamImage(0);
  }
  if (key =='1') {
    updateMPCamImage(1);
  }
  if (key =='2') {
    updateMPCamImage(2);
  }
  if (key =='t') {
    mpImage.currentInitImage = -1;
    mpImage.resetRoll();
  }
  if (key == 'n') {
    mpImage.next();
    mpImage.resetRoll();
  }
  if (key == 'p') {
    turnOffMPCam = true;
  }
  if (turnOffMPCam && key == 'y') {
    ws.sendMessage("turnoff");
    mpImage.currentInitImage = -1;
    mpImage.resetRoll();
  }
  if (turnOffMPCam && key == 'n') {
    turnOffMPCam = false;
  }
}

void updateMPCamImage(int id) {
  //updateScreen = true;
  print(mpImage.roll);
  print("--");
  println(mpCams[id].getLastFileName());
  mpCams[id].loadLastImage();
  mpCams[id].lastImage.resize(MPScreenWidth, 0);
  mpImage.setCamImage(id, mpCams[id].lastImage);
  mpImage.decreaseRollNumber();
  //image(mpCams[id].lastImage, MPScreenX, MPScreenY);
  //redraw();
}


/**
 handle Websocket data
 **/
void webSocketServerEvent(String msg) {
  println(msg);
  JSONObject obj;
  int camID = 0;
  String message = "";
  try {
    obj = parseJSONObject(msg);
    if (obj == null) {
    } else {
      camID = obj.getInt("id");
      message = obj.getString("msg");
    }
  } 
  catch(Exception e) {
    println(e);
  }

  println(camID);
  println(message);

  if (message.equals("live")) {
    ws.sendMessage(str(status));
  }
  if (message.equals("send")) {
    noise.trigger();
    updateMPCamImage(camID);
    status = -1;
    ws.sendMessage(str(status));
    feedback.pause();
    feedback.rewind();
  }

  if (message.equals("shot")) {
    shot.trigger();
    feedback.loop();
    status = camID;
    lastStatusUpdateTime = millis(); // to check long cam process
    ws.sendMessage(str(status));
  }
  if (message.equals("release")) {
    //release.trigger();
  }
}
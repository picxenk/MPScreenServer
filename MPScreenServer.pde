/*
 MetaPixel ScreenServer
 by PROTOROOM, SeungBum Kim <picxenk@gmail.com>
 */

import websockets.*;
import ddf.minim.*;

Minim minim;
AudioSample shot;
AudioSample release;

// ########## Configurations ########## 
int wsPort = 8080;


WebsocketServer ws;

boolean updateScreen = false;
String initImageFolder = "initImages";
String mpcamImageFolder = "MPCams";

int MPScreenX, MPScreenY, MPScreenWidth, MPScreenHeight;
MPImage mpImage;
int camNumber = 3;
MPCam[] mpCams = new MPCam[camNumber];

PFont font;

int screenResolution = 5; // check settings()
int defaultWaitSec = 10;
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
    }
    if (frameCount % 10 == 0) {
      t--;
    }
  } 
  
}

void showTimer(int s) {
  int b, sx;
  if (screenResolution == 5) {
    b = 10;
  } else {
    b = 20;
  }
  sx = b * 20;
  fill(0);
  noStroke();
  rect(MPScreenWidth-sx, b, MPScreenWidth-b, b*5);
  fill(240);
  textFont(font, b*2);
  text("NEXT IMAGE: "+str(s)+"s", MPScreenWidth-sx+b, b*4);
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
}

void updateMPCamImage(int id) {
  //updateScreen = true;
  print(mpImage.roll);print("--");
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

  if (message.equals("send")) {
    updateMPCamImage(camID);
  }

  if (message.equals("shot")) {
    shot.trigger();
  }
  if (message.equals("release")) {
    release.trigger();
  }
}
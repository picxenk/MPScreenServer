import java.io.*;


class MPCam {
  int id = -1;
  File imageFolder;
  PImage lastImage;


  MPCam(int camID) {
    id = camID;
    imageFolder = new File(sketchPath(mpcamImageFolder)+"/"+id);
    lastImage = createImage(100, 100, ARGB);
  }

  String getLastFileName() {
    File[] files = imageFolder.listFiles();
    if (files.length > 0) {
      File last = files[files.length-1];
      return last.getName();
    } else {
      return "None";
    }
  }
  
  void loadLastImage() {
    String fileName = this.getLastFileName();
    lastImage = loadImage(sketchPath(mpcamImageFolder)+"/"+id+"/"+fileName);
  }
}
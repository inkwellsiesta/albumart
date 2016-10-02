import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.io.File; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class albumartLocal extends PApplet {



ArrayList<PImage> images = new ArrayList<PImage>();
ArrayList<int[]> colorHistos = new ArrayList<int[]>();
ArrayList<float[]> avgSaturations = new ArrayList<float[]>();
ArrayList<float[]> avgBrightnesses = new ArrayList<float[]>();
ArrayList<Integer> sizes = new ArrayList<Integer>();

boolean loading, loaded;

public void setup() {
  
  colorMode(HSB);

  loading = false;
  loaded = false;

  selectFolder("Choose a directory of images:", "folderSelected");
}

public void draw() {
  background(255);

  float thumbWidth = 100;
  float xmin = 0 + thumbWidth/2; //width/4;
  float xmax = width - thumbWidth/2; //3*width/4;
  float ymin = height/2;
  float ymax = height/4;

  if (loading) {
    stroke(0);
    noFill();
    rect(xmin, ymax, xmax - xmin, ymin - ymax);
    fill(0);
    noStroke();
    rect(xmin, ymax, pctLoaded*(xmax - xmin), ymin - ymax);
  } else if (loaded) {
    noStroke();
    for (int i = 255; i >= 0; i--) {
      beginShape();
      for (int j = 0; j < sizes.size(); j++) {
        fill(color(i, avgSaturations.get(j)[i], avgBrightnesses.get(j)[i]));
        float x = map(j, 0, sizes.size()-1, xmin, xmax);
        float y = ymin;
        vertex(x, y);
      }
      for (int j = sizes.size() - 1; j >= 0; j--) {
        fill(color(i, avgSaturations.get(j)[i], avgBrightnesses.get(j)[i]));
        float x = map(j, 0, sizes.size()-1, xmin, xmax);
        float y = map(colorHistos.get(j)[i], 0, sizes.get(j), ymin, ymax);
        vertex(x, y);
      }
      endShape(CLOSE);
    }

    for (int j = 0; j < sizes.size(); j++) {
      if (mouseX > map(j-.5f, 0, sizes.size()-1, xmin, xmax) && 
        mouseX < map(j+.5f, 0, sizes.size()-1, xmin, xmax) &&
        mouseY > ymax) {
        image(images.get(j), 
          mouseX - thumbWidth/2, mouseY, 
          thumbWidth, thumbWidth*images.get(j).height/images.get(j).width);
        break;
      }
    }
  }
}

float pctLoaded;
public void folderSelected(File selection) {
  if (selection == null) exit();

  String[] filenames = selection.list();
  
  pctLoaded = 0.f;
  loading = true;
  for (int i = 0; i < filenames.length; i++) {
    println(filenames[i]);

    PImage img = loadImage(selection + File.separator + filenames[i]);
    if (img != null) {
      int[] colorHisto = new int[256];
      float[] avgSaturation = new float[256];
      float[] avgBrightness = new float[256];

      println(img.width + ", " + img.height);

      int imgSize = img.width*img.height;
      sizes.add(imgSize);

      img.loadPixels();

      for (int pIdx = 0; pIdx < imgSize; pIdx++) {
        int hueIdx = round(hue(color(img.pixels[pIdx])));
        colorHisto[hueIdx]++;
        avgSaturation[hueIdx]+=saturation(color(img.pixels[pIdx]));
        avgBrightness[hueIdx]+=brightness(color(img.pixels[pIdx]));
      }

      img.updatePixels();

      for (int bIdx = 0; bIdx < 256; bIdx++) {
        if (colorHisto[bIdx] > 0) {
          avgSaturation[bIdx]/=colorHisto[bIdx];
          avgBrightness[bIdx]/=colorHisto[bIdx];
        }


        if (bIdx > 0) {
          colorHisto[bIdx]+=colorHisto[bIdx-1];
        }
      }

      images.add(img);
      colorHistos.add(colorHisto);
      avgSaturations.add(avgSaturation);
      avgBrightnesses.add(avgBrightness);
    }
    pctLoaded = (float)i/(float)filenames.length;
  }
  loading = false;
  loaded = true;
}
  public void settings() {  size(800, 400, P2D); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "albumartLocal" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}

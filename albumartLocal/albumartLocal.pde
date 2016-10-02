import java.io.File;

ArrayList<PImage> images = new ArrayList<PImage>();
ArrayList<int[]> colorHistos = new ArrayList<int[]>();
ArrayList<float[]> avgSaturations = new ArrayList<float[]>();
ArrayList<float[]> avgBrightnesses = new ArrayList<float[]>();
ArrayList<Integer> sizes = new ArrayList<Integer>();


void setup() {
  size(800, 400, P2D);
  colorMode(HSB);

  selectFolder("Choose a directory of images:", "folderSelected");
  noLoop();
}

void draw() {
  background(255);

  float thumbWidth = 100;
  float xmin = 0 + thumbWidth/2; //width/4;
  float xmax = width - thumbWidth/2; //3*width/4;
  float ymin = height/2;
  float ymax = height/4;

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
    if (mouseX > map(j-.5, 0, sizes.size()-1, xmin, xmax) && 
      mouseX < map(j+.5, 0, sizes.size()-1, xmin, xmax) &&
      mouseY > ymax) {
      image(images.get(j), 
        mouseX - thumbWidth/2, mouseY, 
        thumbWidth, thumbWidth*images.get(j).height/images.get(j).width);
      break;
    }
  }
}


void folderSelected(File selection) {
  if (selection == null) exit();

  String[] filenames = selection.list();

  for (int i = 0; i < filenames.length; i++) {
    println(filenames[i]);

    PImage img = loadImage(selection + File.separator + filenames[i]);
    if (img != null) {
      int[] colorHisto = new int[256];
      float[] avgSaturation = new float[256];
      float[] avgBrightness = new float[256];

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
  }
  loop();
}
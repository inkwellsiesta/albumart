IntDict tsToIdx = new IntDict(); // used for sorting by timestamp
ArrayList<Integer> timestamps = new ArrayList<Integer>();
int tsmin, tsmax;

ArrayList<PImage> images = new ArrayList<PImage>();

ArrayList<Integer> sizes = new ArrayList<Integer>();
ArrayList<int[]> colorHistos = new ArrayList<int[]>();

ArrayList<Float> xposes = new ArrayList<Float>();
ArrayList<float[]> yposes = new ArrayList<float[]>();
ArrayList<int[]> colors = new ArrayList<int[]>();

void setup() {
  size(800, 400, P2D);
  colorMode(HSB);

  JSONObject json = loadJSONObject("https://picasaweb.google.com/data/feed/api/user/100973909693737793350/albumid/6315322913860683569?alt=json");
  JSONArray entries = json.getJSONObject("feed").getJSONArray("entry");
  int ct = 0;
  for (int i = 0; i < entries.size(); i++) {
    String url = entries.getJSONObject(i).getJSONObject("content").getString("src");
    println(url);
    PImage img = loadImage(url);
    if (img != null) {
      String ts = entries.getJSONObject(i).getJSONObject("gphoto$timestamp").getString("$t");
      println(ts);
      tsToIdx.set(ts, ct);
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


      int[] c = new int[256];
      for (int bIdx = 0; bIdx < 256; bIdx++) {
        if (colorHisto[bIdx] > 0) {
          avgSaturation[bIdx]/=colorHisto[bIdx];
          avgBrightness[bIdx]/=colorHisto[bIdx];
        }

        if (bIdx > 0) {
          colorHisto[bIdx]+=colorHisto[bIdx-1];
        }

        c[bIdx] = color(bIdx, avgSaturation[bIdx], avgBrightness[bIdx]);
      }

      images.add(img);
      colorHistos.add(colorHisto);

      yposes.add(new float[256]);
      xposes.add(0.);
      colors.add(c);

      ct++;
    }
  }

  for (int i = 0; i < ct; i++) {
    timestamps.add((int)(Long.valueOf(tsToIdx.keyArray()[i])/1000));
  }

  tsToIdx.sortKeys();
  tsmin = (int)(Long.valueOf(tsToIdx.keyArray()[0])/1000);
  tsmax = (int)(Long.valueOf(tsToIdx.keyArray()[ct-1])/1000);

  sortByTs(timestamps);
  sortByTs(images);
  sortByTs(sizes);
  sortByTs(colorHistos);
  sortByTs(xposes);
  sortByTs(yposes);
  sortByTs(colors);
}

void draw() {
  background(255);

  float thumbWidth = 200;
  float xmin = 0 + thumbWidth/2;
  float xmax = width - thumbWidth/2;
  float ymin = height/2;
  float ymax = height/4;

  for (int j = 0; j < timestamps.size(); j++) {
    int timestamp = timestamps.get(j);

    float xpos = map(timestamp, tsmin, tsmax, xmin, xmax);
    xposes.set(j, xpos);

    for (int i = 0; i < 256; i++) {
      float ypos = map(colorHistos.get(j)[i], 0, sizes.get(j), ymin, ymax);
      yposes.get(j)[i] = ypos;
    }
  }

  noStroke();
  for (int i = 255; i >= 0; i--) {
        beginShape();

    int idxabove = 0;
    for (float x = xmin; x < xmax; x+=5) {
      while (idxabove < xposes.size() &&
        xposes.get(idxabove) <= x) {
        idxabove++;
      }
      int idxbelow = idxabove -1;
      float xbelow = xposes.get(idxbelow);
      float xabove = xposes.get(idxabove);
      float ybelow = yposes.get(idxbelow)[i];
      float yabove = yposes.get(idxabove)[i];
      float y = map(x, xbelow, xabove, ybelow, yabove);
      fill(255);
      vertex(x,y);
    }

    for (float x = xmax; x > xmin; x-=5) {
      fill(255);
      vertex(x,ymin);
    }

    endShape(CLOSE);
    
    
    beginShape();

    idxabove = 0;
    for (float x = xmin; x < xmax; x+=5) {
      while (idxabove < xposes.size() &&
        xposes.get(idxabove) <= x) {
        idxabove++;
      }
      int idxbelow = idxabove -1;
      float xbelow = xposes.get(idxbelow);
      float xabove = xposes.get(idxabove);
      float ybelow = yposes.get(idxbelow)[i];
      float yabove = yposes.get(idxabove)[i];
      color cbelow = colors.get(idxbelow)[i];
      color cabove = colors.get(idxabove)[i];
      float y = map(x, xbelow, xabove, ybelow, yabove);
      color c = lerpColor(cbelow, cabove, map(x, xbelow, xabove, 0, 1));
      float xdist = min(x - xbelow, xabove - x);
      float a = map(xdist, -.001, 30, 255, 50);
      a = max(a,50);
      fill(c, a);
      vertex(x,y);
    }

    int idxbelow = xposes.size()-1;
    for (float x = xmax; x> xmin; x-=5) {
      while (idxbelow >= 0 &&
        xposes.get(idxbelow) >= x) {
        idxbelow--;
      }
      idxabove = idxbelow + 1;
      float xbelow = xposes.get(idxbelow);
      float xabove = xposes.get(idxabove);
      color cbelow = colors.get(idxbelow)[i];
      color cabove = colors.get(idxabove)[i];
      color c = lerpColor(cbelow, cabove, map(x, xbelow, xabove, 0, 1));
      float xdist = min(x - xbelow, xabove - x);
      float a = map(xdist, -.001, 30, 255, 50);
      a = max(a, 50);
      fill(c, a);
      vertex(x,ymin);
    }
  /*  for (int j = sizes.size()-1; j >= 0; j--) {
      fill(colors.get(j)[i]);
      vertex(xposes.get(j), ymin);
    }*/

    endShape(CLOSE);
  }

  // Show thumbnail of image when you hover over its slice
  for (int j = 0; j < xposes.size(); j++) {
    float xpos = xposes.get(j);
    if (mouseX > xpos - 10 && mouseX < xpos + 10 && mouseY > ymax) {
      image(images.get(j), mouseX - thumbWidth/2, mouseY, 
        thumbWidth, thumbWidth*images.get(j).height/images.get(j).width);
      break;
    }
  }
}

void sortByTs(ArrayList al) {
  ArrayList alCopy = new ArrayList(al);
  for (int idx = 0; idx < al.size(); idx++) {
    al.set(idx, alCopy.get(tsToIdx.valueArray()[idx]));
  }
}
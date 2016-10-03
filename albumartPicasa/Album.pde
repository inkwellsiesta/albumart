public class Album {
  IntDict tsToIdx = new IntDict(); // used for sorting by timestamp
  ArrayList<Integer> timestamps = new ArrayList<Integer>();
  int tsmin, tsmax;

  ArrayList<PImage> images = new ArrayList<PImage>();

  ArrayList<Integer> sizes = new ArrayList<Integer>();
  ArrayList<int[]> colorHistos = new ArrayList<int[]>();

  ArrayList<Float> xposes = new ArrayList<Float>();
  ArrayList<float[]> yposes = new ArrayList<float[]>();
  ArrayList<int[]> colors = new ArrayList<int[]>();

  boolean isCreated = false;

  public void createFromPicassa(String name) {
    JSONObject json = loadJSONObject(name);
    JSONArray entries = json.getJSONObject("feed").getJSONArray("entry");
    int ct = 0;
    for (int i = 0; i < entries.size(); i++) {
      String url = entries.getJSONObject(i).getJSONObject("content").getString("src");
      println(url);
      PImage img = loadImage(url);
      if (img != null) {
        String ts = entries.getJSONObject(i).getJSONObject("gphoto$timestamp").getString("$t");
        images.add(img);
        tsToIdx.set(ts, ct);
        ct++;
      }
    }
    createCommon();
  }

  public void createFromDirectory(File selection) {
    if (selection == null) return;
    String[] filenames = selection.list();
    int ct = 0;
    for (String filename : filenames) {
      println(filename);
      File file = new File(selection, filename);

      PImage img = loadImage(file.toString());
      if (img != null) {
        images.add(img);
        long timestamp = file.lastModified();
        
        String ts = String.valueOf(timestamp);
        while (tsToIdx.hasKey(ts)) {
          ts = String.valueOf(timestamp++);
        }
        tsToIdx.set(ts, ct);
        ct++;
      }
    }
    createCommon();
  }

  public void createCommon() {
    for (PImage img : images) {
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

      colorHistos.add(colorHisto);

      yposes.add(new float[256]);
      xposes.add(0.);
      colors.add(c);
    }

    for (String ts : tsToIdx.keyArray()) {
      timestamps.add((int)(Long.valueOf(ts)/1000));
    }

    tsToIdx.sortKeys();
    tsmin = (int)(Long.valueOf(tsToIdx.keyArray()[0])/1000);
    tsmax = (int)(Long.valueOf(tsToIdx.keyArray()[images.size()-1])/1000);

    sortByTs(timestamps);
    sortByTs(images);
    sortByTs(sizes);
    sortByTs(colorHistos);
    sortByTs(xposes);
    sortByTs(yposes);
    sortByTs(colors);

    isCreated = true;
  }

  private void sortByTs(ArrayList al) {
    ArrayList alCopy = new ArrayList(al);
    for (int idx = 0; idx < al.size(); idx++) {
      al.set(idx, alCopy.get(tsToIdx.valueArray()[idx]));
    }
  }

  void draw() {
    boolean scaleByDate = false;
    float thumbMax = 200;
    float xmin = 0 + thumbMax/2;
    float xmax = width - thumbMax/2;
    float ymin = height/2;
    float ymax = height/4;

    for (int j = 0; j < timestamps.size(); j++) {
      int timestamp = timestamps.get(j);
      float xpos;
      if (scaleByDate) {
        xpos = map(timestamp, tsmin, tsmax, xmin, xmax);
      } else {
        xpos = map(j, 0, timestamps.size(), xmin, xmax);
      }
      album.xposes.set(j, xpos);

      for (int i = 0; i < 256; i++) {
        float ypos = map(colorHistos.get(j)[i], 0, sizes.get(j), ymin, ymax);
        album.yposes.get(j)[i] = ypos;
      }
    }

    noStroke();
    for (int i = 255; i >= 0; i--) {
      beginShape();

      int idxabove = 0;
      for (float x = xmin; x < xmax; x+=5) {
        while (idxabove < album.xposes.size()-1 &&
          album.xposes.get(idxabove) <= x) {
          idxabove++;
        }
        int idxbelow = idxabove - 1;
        float xbelow = xposes.get(idxbelow);
        float xabove = xposes.get(idxabove);
        float ybelow = yposes.get(idxbelow)[i];
        float yabove = yposes.get(idxabove)[i];
        color cbelow = colors.get(idxbelow)[i];
        color cabove = colors.get(idxabove)[i];
        float y = map(x, xbelow, xabove, ybelow, yabove);
        color c = lerpColor(cbelow, cabove, map(x, xbelow, xabove, 0, 1));
        fill(c);
        vertex(x, y);
      }

      int idxbelow = xposes.size()-2;
      for (float x = xmax; x > xmin; x-=5) {
        while (idxbelow > 0 &&
          xposes.get(idxbelow) >= x) {
          idxbelow--;
        }
        idxabove = idxbelow + 1;
        float xbelow = xposes.get(idxbelow);
        float xabove = xposes.get(idxabove);
        color cbelow = colors.get(idxbelow)[i];
        color cabove = colors.get(idxabove)[i];
        color c = lerpColor(cbelow, cabove, map(x, xbelow, xabove, 0, 1));
        fill(c);
        vertex(x, ymin);
      }

      endShape(CLOSE);
    }

    // Show thumbnail of image when you hover over its slice
    float offset = 0;
    for (int j = 0; j < xposes.size(); j++) {
      float xpos = xposes.get(j);
      if (mouseX > xpos - 10 && mouseX < xpos + 10 && mouseY > ymax) {
        int imgWidth = images.get(j).width;
        int imgHeight = images.get(j).height;
        float thumbWidth, thumbHeight;
        if (imgWidth > imgHeight) {
          thumbWidth = thumbMax;
          thumbHeight = thumbWidth*imgHeight/imgWidth;
        }
        else {
          thumbHeight = thumbMax;
          thumbWidth = thumbHeight*imgWidth/imgHeight;
        }
        image(images.get(j), mouseX - thumbWidth/2, mouseY + offset, 
          thumbWidth, thumbHeight);
        offset +=thumbHeight + 5;
      }
    }
  }
}
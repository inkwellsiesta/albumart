public class Button {
  PImage img;
  float x, y, w, h;
  boolean hovered;

  Button(String imageName, float x, float y, float w, float h) {
    img = loadImage(imageName);
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;

    hovered = false;
  }

  void update() {
    hovered = mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h;
  }

  void draw() {
    image(img, x, y, w, h);
    if (hovered) { // draw an outline.
      pushStyle(); // workaround because there's
      noFill();    // a bug with the cursor
      strokeWeight(2);
      stroke(0);
      rect(x, y, w, h);
      popStyle();
    }
  }

  public void onClick() {
  }
}
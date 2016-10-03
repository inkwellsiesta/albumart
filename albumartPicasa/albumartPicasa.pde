Album album = new Album();

boolean startScreen = true;
Button computerLogo, googleLogo;

void setup() {
  size(800, 600, P2D);
  colorMode(HSB);


  computerLogo = new Button("computericon.png", 
    width/2-225, height/2-100, 200, 200) {
      @Override
      public void onClick() {
      if (hovered) {
        selectFolder("", "folderSelected");
      }
    }
  };
  googleLogo = new Button("googlephotoicon.png", 
    width/2+25, height/2-100, 200, 200) {
      @Override
      public void onClick() {
      if (hovered) {
        album.createFromPicassa("https://picasaweb.google.com/data/feed/api/user/100973909693737793350/albumid/6315322913860683569?alt=json");
        startScreen = false;
      }
    }
  };
}

void draw() {
  background(255);

  if (startScreen) {
    computerLogo.update();
    googleLogo.update();

    computerLogo.draw();
    googleLogo.draw();
    
  } else if (album.isCreated) {
    album.draw();
  }
}

void mouseClicked() {
  if (startScreen) {
    computerLogo.onClick();
    googleLogo.onClick();
  }
}

void folderSelected(File selection) {
  if (selection == null) {
    return;
  }
  album.createFromDirectory(selection);
  startScreen = false;
}
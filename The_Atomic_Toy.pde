import com.hamoid.*;
int R = 10;
Field F;
ArrayList<Particle>parts;
Boolean grid=false;
Boolean vector=false;
Boolean particles=true;
Boolean pause = false;
float spawnCharge = 5;
float spawnMass = 0.5;
int Width = 1920;
int Height = 1080;
//-------------------preferences
VideoExport videoExport;
void setup() {
  videoExport = new VideoExport(this);
  colorMode(HSB, 1);
  fullScreen(OPENGL);
  F = new Field();
  parts = new ArrayList<Particle>();
  frameRate(60);
  videoExport.startMovie();
}
void draw() {
  updateAndRender();
  UI();
  videoExport.saveFrame();
}
void updateAndRender() {
  background(0);
  if (grid||vector) {
    F.render();
  }
  F.initMatrixVectors();
  int x=mouseX;
  int y=mouseY;
  if ((x > 0 || x <=Width)&&( y > 0 || y <=Height )) {
    if ((x > 0 || x <=Width)&&( y > 0 || y <=Height )) {
      if (!(keyPressed&&keyCode==CONTROL)) {
        if (mouseButton==RIGHT) {
          parts.add(new Particle(x, y, -1*spawnCharge, spawnMass));
        }
        if (mouseButton == LEFT) {
          parts.add(new Particle(x, y, spawnCharge, spawnMass));
        }
      }
    }
    for (int i=0; i < parts.size(); i++) {
      parts.get(i).influence();
    }
    for (int i=0; i < parts.size(); i++) {
      parts.get(i).updateAndRender();
    }
  }
}
void UI() {
  noStroke();
  rect(0, 0, 200, 50);
  fill(1);
  text("parts = "+parts.size(), 20, 20);
  text("fps = "+(int)frameRate, 20, 30);
  noFill();
  noFill();
  stroke(0.55, 1, 1);
  rect(1, 1, Width-1, Height-1);
  noStroke();
  fill(0, 1, 0);
  //rect(Width,Height,Width,height-Height); -----------------------------------------------------------to do
}
class Field {
  PVector [][] Ematrix; 
  PVector [][] Gmatrix;
  Field() {
    Ematrix = new PVector[ceil(Width/R)+1][ceil(Height/R)+1];
    Gmatrix = new PVector[Ematrix.length][Ematrix[0].length];
  }
  void initMatrixVectors() {
    Ematrix = set(Ematrix);
    Gmatrix = set(Ematrix);
  }
  void render() {
    stroke(1);
    for (int i=0; i<Ematrix.length-1; i++) {
      for (int j=0; j<Ematrix[0].length-1; j++) {
        float mag = sroot((Ematrix[i][j].mag()));
        if (grid) {
          stroke(map(abs(mag), 0, 7, 0.92, 0.6), 1, map(abs(mag), 0, 7, 0, 1), 0.8);
          line(R*i+sroot(Ematrix[i][j].x), R*j+sroot(Ematrix[i][j].y), R*(i+1)+sroot(Ematrix[i+1][j].x), R*j+sroot(Ematrix[i+1][j].y));
          line(R*i+sroot(Ematrix[i][j].x), R*j+sroot(Ematrix[i][j].y), R*(i)+sroot(Ematrix[i][j+1].x), R*(j+1)+sroot(Ematrix[i+1][j].y));
        }
        if (vector) {
          strokeWeight(0.5);
          stroke(map(Ematrix[i][j].heading(), -PI, PI, 0.55, 0.85), 1, 1, map(mag, 0, 10, 0.9, 0.1));
          line(R*i, R*j, R*i+3*sroot(Ematrix[i][j].x), R*j+3*sroot(Ematrix[i][j].y));
          strokeWeight(1);
        }
      }
    }
  }
  float sroot(float x) {
    return x<0?-50*sqrt(abs(x)):50*sqrt(x);
  }
  PVector delta;
  PVector Pnode = new PVector(0, 0);
  void stim(PVector p, float mag) {
    for (int i =-1; i++ <Ematrix.length-1; ) {
      for (int  j=-1; j++ <Ematrix[0].length-1; ) {
        for (int n =0; n<1; n++) {
          for (int m=0; m<1; m++) {
            delta = PVector.sub(Pnode.set((i+n)*R, (j+m)*R), p);
            Ematrix[i][j].add(delta.mag()>1.41421*R?delta.setMag(mag/delta.magSq()):delta.setMag(0)); //don't ask
          }
        }
      }
    }
  }
  PVector [][] set(PVector [][] m) {
    for (int i=0; i<m.length; i++) {
      for (int j=0; j<m[0].length; j++) {
        m[i][j]=new PVector(0, 0);
      }
    }
    return m;
  }
}
void mousePressed() {
  int x=mouseX;
  int y=mouseY;

  if (keyPressed&&keyCode==CONTROL) {
    if (mouseButton==RIGHT) {
      parts.add(new Particle(x, y, -1*spawnCharge, spawnMass));
    }
    if (mouseButton == LEFT) {
      parts.add(new Particle(x, y, spawnCharge, spawnMass));
    }
  }
}
class Particle {
  float rad = R/15;
  PVector pos, vel, acc;
  float charge, inverseM, mass;
  int accessX;
  int accessY;
  Particle(float x, float y, float charge_, float mass_) {
    mass = mass_;
    charge = charge_;
    inverseM = pow(mass_, -1);
    pos=new PVector(x, y);
    vel = new PVector(0, 0);
    acc = new PVector(0, 0);
  }
  void influence() {
    F.stim(pos, charge);
  }
  void updateAndRender() {
    if (pos.x<=0||pos.x>Width) {
      vel.x*=-1;
      pos.x+=vel.x;
      if (pos.x<=0||pos.x>Width) {
        parts.remove(this);
      }
    }
    if (pos.y<0||pos.y>Height) {
      vel.y*=-1;
      pos.y+=vel.y;
      if (pos.y<0||pos.y>Height) {
        parts.remove(this);
      }
    }
    accessX = floor(map(pos.x, 0, Width, 0, F.Ematrix.length-1));
    accessY = floor(map(pos.y, 0, Height, 0, F.Ematrix[0].length-1));
    if (accessX<F.Ematrix.length-1&&accessY<F.Ematrix[0].length-1) {
      if (accessX>=0&&accessY>=0) {
        acc = del(pos, (charge>0)?1:-1);
        acc.mult(inverseM);
        if (particles) {
          strokeWeight(1);
          if (charge<0) {
            stroke(0.5, 1, 1, 0.9);
          } else {
            stroke(0.03, 1, 1, 0.9);
          }
          point(pos.x, pos.y);
          strokeWeight(1);
        }
      }
    } else {
      parts.remove(this);
    }
    if (!pause) {
      pos.add(vel.add(acc));
    }
  }
  PVector del(PVector P, float q) {
    float xdim1, xdim2;
    float ydim1, ydim2;
    PVector result;
    int i = accessX;
    int j= accessY;
    xdim1=map(P.x, R*i, R*(i+1), F.Ematrix[i][j].x, F.Ematrix[i+1][j].x);
    xdim2=map(P.x, R*i, R*(i+1), F.Ematrix[i][j+1].x, F.Ematrix[i+1][j+1].x);
    ydim1=map(P.y, R*j, R*(j+1), F.Ematrix[i][j].y, F.Ematrix[i][j+1].y);
    ydim2=map(P.y, R*accessY, R*(accessY+1), F.Ematrix[i+1][j].y, F.Ematrix[i+1][j+1].y);
    result = new PVector(map(P.x, R*i, R*(i+1), xdim1, xdim2), map(P.y, R*j, R*(j+1), ydim1, ydim2));
    return result.mult(q);
  }
}
void keyPressed() { 
  if (key == 'q') {
    videoExport.endMovie();
    exit();
  }
  if (key=='g'||key=='G') {
    grid=!grid;
  }
  if (key=='v'||key=='V') {
    vector=!vector;
  }
  if (key=='p'||key=='P') {
    particles=!particles;
    ;
  }
  if (key == ' ') {
    pause=!pause;
  }
  if (key == 'r'|| key == 'R') {
    parts.clear();
  }
}
//programmed by u/therocketeer1|Processing 3.2.3

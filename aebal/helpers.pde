//Literally 80% of this is practically useless

import java.util.Random;
import java.text.DecimalFormat;
float timerUpdateTime;

int sgn(float x)       { return x > 0 ? 1 : (x < 0 ? -1 : 0); }
int sign(float x)      { return sgn(x); }
int signnum(float x)   { return sgn(x); }

int sgnNZ(float x)         { return x >= 0 ? 1 : -1; }
int signNZ(float x)        { return sgnNZ(x); }
int signumNZ(float x)      { return sgnNZ(x); }
int sngNonZero(float x)    { return sgnNZ(x); }
int signNonZero(float x)   { return sgnNZ(x); }
int signumNonZero(float x) { return sgnNZ(x); }

class RNG {
    Random RNG;
    float seed;
    
    float setSeed(float seed) {
        this.seed = seed;
        RNG.setSeed((long) (1000000 * seed));
        return this.seed;
    }
    float randomizeSeed() {
        RNG = new Random(); 
        return setSeed(RNG.nextFloat());
    }

    RNG(float seed) {
        RNG = new Random();
        setSeed(seed);
    }
    RNG() {
        randomizeSeed();
    }

    float r(float a, float b)      { return lerp(a, b, RNG.nextFloat()); }
    float r(float x)               { return x * RNG.nextFloat(); }
    float r()                      { return RNG.nextFloat(); }
    float rng(float a, float b)    { return r(a, b);      }
    float rng(float x)             { return r(x);         }
    float rng()                    { return r();          }
    float rand(float a, float b)   { return r(a, b);      }
    float rand(float x)            { return r(x);         }
    float rand()                   { return r();          }
    float random(float a, float b) { return r(a, b);      }
    float random(float x)          { return r(x);         }
    float random()                 { return r();          }

    float rC(float x)             { return r(-x, x); }
    float rngC(float x)           { return rC(x);    }
    float randC(float x)          { return rC(x);    }
    float randomC(float x)        { return rC(x);    }
    float rCentered(float x)      { return rC(x);    }
    float rngCentered(float x)    { return rC(x);    }
    float randCentered(float x)   { return rC(x);    }
    float randomCentered(float x) { return rC(x);    }
    float rC()                    { return rC(1);    }
    float rngC()                  { return rC();     }
    float randC()                 { return rC();     }
    float randomC()               { return rC();     }
    float rCentered()             { return rC();     }
    float rngCentered()           { return rC();     }
    float randCentered()          { return rC();     }
    float randomCentered()        { return rC();     }

    boolean rB()            { return RNG.nextBoolean(); }
    boolean rBool()         { return rB(); }
    boolean rBoolean()      { return rB(); }
    boolean rngB()          { return rB(); }
    boolean rngBool()       { return rB(); }
    boolean rngBoolean()    { return rB(); }
    boolean randB()         { return rB(); }
    boolean randBool()      { return rB(); }
    boolean randBoolean()   { return rB(); }
    boolean randomB()       { return rB(); }
    boolean randomBool()    { return rB(); }
    boolean randomBoolean() { return rB(); }

    int rSgn()             { return rB() ? 1 : -1; }
    int rSign()            { return rSgn(); }
    int rSignum()          { return rSgn(); }
    int rngSgn()           { return rSgn(); }
    int rngSign()          { return rSgn(); }
    int rngSignum()        { return rSgn(); }
    int randSgn()          { return rSgn(); }
    int randSign()         { return rSgn(); }
    int randSignum()       { return rSgn(); }
    int randomSgn()        { return rSgn(); }
    int randomSign()       { return rSgn(); }
    int randomSignum()     { return rSgn(); }
    float rSgn(float x)         { return rSgn() * x; }
    float rSign(float x)        { return rSgn(x); }
    float rSignum(float x)      { return rSgn(x); }
    float rngSgn(float x)       { return rSgn(x); }
    float rngSign(float x)      { return rSgn(x); }
    float rngSignum(float x)    { return rSgn(x); }
    float randSgn(float x)      { return rSgn(x); }
    float randSign(float x)     { return rSgn(x); }
    float randSignum(float x)   { return rSgn(x); }
    float randomSgn(float x)    { return rSgn(x); }
    float randomSign(float x)   { return rSgn(x); }
    float randomSignum(float x) { return rSgn(x); }

    boolean rP(float x)               { return random() < x; }
    boolean rngP(float x)             { return rP(x); }
    boolean randP(float x)            { return rP(x); }
    boolean randomP(float x)          { return rP(x); }
    boolean rProp(float x)            { return rP(x); }
    boolean rngProp(float x)          { return rP(x); }
    boolean randProp(float x)         { return rP(x); }
    boolean randomProp(float x)       { return rP(x); }
    boolean rProportion(float x)      { return rP(x); }
    boolean rngProportion(float x)    { return rP(x); }
    boolean randProportion(float x)   { return rP(x); }
    boolean randomProportion(float x) { return rP(x); }
    boolean rP()               { return rP(1); }
    boolean rngP()             { return rP();  }
    boolean randP()            { return rP();  }
    boolean randomP()          { return rP();  }
    boolean rProp()            { return rP();  }
    boolean rngProp()          { return rP();  }
    boolean randProp()         { return rP();  }
    boolean randomProp()       { return rP();  }
    boolean rProportion()      { return rP();  }
    boolean rngProportion()    { return rP();  }
    boolean randProportion()   { return rP();  }
    boolean randomProportion() { return rP();  }

}

boolean GTLT  (float a, float b, float c) { return a >  b && a <  c; }
boolean LTGT  (float a, float b, float c) { return a <  c && a >  b; }
boolean GTLTE (float a, float b, float c) { return a >= b && a <= c; }
boolean LTGTE (float a, float b, float c) { return a <= c && a >= b; }
boolean GTLT  (int   a, int   b, int   c) { return a >  b && a <  c; }
boolean LTGT  (int   a, int   b, int   c) { return a <  c && a >  b; }
boolean GTLTE (int   a, int   b, int   c) { return a >= b && a <= c; }
boolean LTGTE (int   a, int   b, int   c) { return a <= c && a >= b; }
boolean NGTLT (float a, float b, float c) { return a <  b || a >  c; }
boolean NLTGT (float a, float b, float c) { return a >  c || a <  b; }
boolean NGTLTE(float a, float b, float c) { return a <= b || a >= c; }
boolean NLTGTE(float a, float b, float c) { return a >= c || a <= b; }
boolean NGTLT (int   a, int   b, int   c) { return a <  b || a >  c; }
boolean NLTGT (int   a, int   b, int   c) { return a >  c || a <  b; }
boolean NGTLTE(int   a, int   b, int   c) { return a <= b || a >= c; }
boolean NLTGTE(int   a, int   b, int   c) { return a >= c || a <= b; }

float multiplyLenient(float a, float b) {
    return a > 0 && b > 0 ? a * b - abs((a - b) / (a + b)) : a * b;
}

float cNorm(float a, float b, float c) {
    return constrain(norm(a, b, c), 0, 1);
}
float clamp(float x, float a, float b) {
    return constrain(x, min(a, b), max(a, b));
}
float clampMap(float x, float r1_min, float r1_max, float r2_min, float r2_max) {
    return clamp(map(x, r1_min, r1_max, r2_min, r2_max), r2_min, r2_max);
}
float constrainMap(float x, float r1_min, float r1_max, float r2_min, float r2_max) {
    return constrain(map(x, r1_min, r1_max, r2_min, r2_max), r2_min, r2_max);
}

color mulColor(color c, PVector v) {
    return color(red(c) * v.x, green(c) * v.y, blue(c) * v.z);
}
color lerpColors(float v, color... colors) {
    v *= 0.9999 * (colors.length - 1);
    int indx = constrain(int(v), 0, colors.length - 2);
    return lerpColor(colors[indx], colors[indx + 1], v % 1.0);
}
import java.util.Arrays;
import java.util.Iterator;
import net.objecthunter.exp4j.*;
import net.objecthunter.exp4j.shuntingyard.*;
import net.objecthunter.exp4j.tokenizer.*;
import net.objecthunter.exp4j.function.*;
import net.objecthunter.exp4j.operator.*;

Function[] customEquationFunctions = new Function[] {
    new Function("max", 2) {
        public double apply(double... args) {
            return Math.max(args[0], args[1]);
        }
    }, new Function("min", 2) {
        public double apply(double... args) {
            return Math.max(args[0], args[1]);
        }
    }
};

abstract class Transformation {
    abstract PVector apply(PVector p);
}
class Scale extends Transformation {
    PVector scale;
    Scale(PVector scale) {
        this.scale = scale;
    }
    PVector apply(PVector p) {
        mulVec(p, scale);
        return p;
    }
    String toString() {
        return String.format("Scale: (%s, %s)", scale.x, scale.y);
    }
}
class Rotate extends Transformation {
    float angle;
    Rotate(float angle) {
        this.angle = angle;
    }
    PVector apply(PVector p) {
        p.rotate(angle);
        return p;
    }
    String toString() {
        return String.format("Rotation: %srad", angle);
    }
}
class Translate extends Transformation {
    PVector translation;
    Translate(PVector translation) {
        this.translation = translation;
    }
    PVector apply(PVector p) {
        p.add(translation);
        return p;
    }
    String toString() {
        return String.format("Translation: (%s, %s)", translation.x, translation.y);
    }
}

class ChainedTransformation {
    ArrayList<Transformation> transformations;
    ChainedTransformation(ArrayList<Transformation> transformations) {
        this.transformations = transformations;
    }
    PVector apply(PVector p) {
        for(Transformation t : transformations) t.apply(p);
        return p;
    }
    PVector applyCopy(PVector p) {
        apply(p = p.copy());
        return p;
    }
    String toString() {
        String r = "";
        for(int i = 0; i < transformations.size(); i++) {
            r += transformations.get(i).toString() + (i == transformations.size() - 1 ? "" : "\n");
        }
        return r;
    }
}
class EnemyPatternProperties {
    float difficulty, range;
    boolean disableRandomRotation, disableRotationStacking;
    PVector distBounds, speedBounds, countBounds, scaleBounds, angleSweep;
    ChainedTransformation defaultTransformation;
    EnemyPatternProperties(float difficulty, ChainedTransformation defaultTransformation) {
        this.difficulty = difficulty;
        this.defaultTransformation = defaultTransformation;
    }
    String toString() {
        return String.format(
            "difficulty: %s\n"+
            "Parametric Angle Bounds: %s\n"+
            "Implicit coordinate range: %s\n"+
            "Modifiers: [disableRandomRotation=%s, disableRotationStacking=%s]\n"+
            "Bounds:\n"+
            "    Distance Bounds : %s\n"+
            "    Speed Bounds: %s\n"+
            "    Count Bounds: %s\n"+
            "    Scale Bounds: %s\n"+
            "Default Transformations:%s",
            difficulty, angleSweep, range, disableRandomRotation, disableRotationStacking,
            distBounds, speedBounds, countBounds, scaleBounds, defaultTransformation.transformations.size() > 0 ? ('\n' + defaultTransformation.toString().replaceAll("(?m)^", "\t")) : " None"
        );
    }
}
class Equation {
    static final int IMPLICIT   = 0;
    static final int PARAMETRIC = 1;

    int type;
    String ID, equationPrintable;
    String[] relatedEquationNames;

    EnemyPatternProperties spawnProperties;
    Equation(int type, String ID, String[] relatedEquationNames, String equationPrintable, EnemyPatternProperties spawnProperties) {
        this.type = type;
        this.ID = ID;
        this.relatedEquationNames = relatedEquationNames;
        this.equationPrintable = equationPrintable;
        this.spawnProperties = spawnProperties;
    }
    String toString() {
        return String.format(
            "\"%s\": %s\nConnections: %s\nProperties:\n%s",
            ID, equationPrintable, Arrays.toString(relatedEquationNames), spawnProperties.toString().replaceAll("(?m)^", "\t")
        );
    }
}
class Equation1D extends Equation { //1 output dimension; implicit equation
    String equationStr;
    Expression equation;
    Equation1D(String ID, String[] relatedEquationNames, EnemyPatternProperties spawnProperties, String eq) {
        super(IMPLICIT, ID, relatedEquationNames, eq, spawnProperties);
        equation = new ExpressionBuilder(eq).functions(customEquationFunctions).variables("x", "y").build();
    }
    float getVal(float x, float y, float t) {
        return (float)equation.setVariable("x", x).setVariable("y", y).setVariable("t", t).evaluate();
    }
}
class Equation2D extends Equation { //2 output dimensions; parametric equation
    String equationXStr, equationYStr;
    Expression equationX, equationY;
    Equation2D(String ID, String[] relatedEquationNames, EnemyPatternProperties spawnProperties, String eqX, String eqY) {
        super(PARAMETRIC, ID, relatedEquationNames, String.format("[%s, %s]", eqX, eqY), spawnProperties);
        equationX = new ExpressionBuilder(eqX).functions(customEquationFunctions).variables("x", "y", "t").build();
        equationY = new ExpressionBuilder(eqY).functions(customEquationFunctions).variables("x", "y", "t").build();
    }
    PVector getVal(float x, float y, float t) {
        return new PVector(
            (float)equationX.setVariable("x", x).setVariable("y", y).setVariable("t", t).evaluate(),
            (float)equationY.setVariable("x", x).setVariable("y", y).setVariable("t", t).evaluate()
        );
    }
}
class EquationDifficultySorter implements Comparator<Equation> {
    @Override
    int compare(Equation a, Equation b) {
        return Float.compare(a.spawnProperties.difficulty, b.spawnProperties.difficulty);
    }
}

class PatternSpawner {
    ArrayList<Equation> locations;
    ArrayList<Equation2D> velocities;
    HashMap<String, Equation>   locIDMapping;
    HashMap<String, Equation2D> velIDMapping;
    HashMap<String, ArrayList<Equation2D>> locIDVelMapping;

    PatternSpawner(String filename) {
        ArrayList<Equation>   locations  = new ArrayList();
        ArrayList<Equation2D> velocities = new ArrayList();

        String jsonString = "";
        for(String s : loadStrings(filename)) {
            String t = trim(s);
            if(!(t.charAt(0) == '/' && t.charAt(1) == '/')) {
                jsonString += s + '\n';
            }
        }

        JSONObject json = parseJSONObject(jsonString);
        JSONObject locationPatterns = json.getJSONObject("location");
        JSONObject velocityPatterns = json.getJSONObject("velocity");

        for(Object key : locationPatterns.keys()) {
            try {
                String k = (String)key;
                locations .add(            parsePattern(locationPatterns.getJSONObject(k), k, false));
            } catch(Throwable t) {
                println("Failed to parse pattern:", t);
            }
        }
        for(Object key : velocityPatterns.keys()) {
            try {
                String k = (String)key;
                velocities.add((Equation2D)parsePattern(velocityPatterns.getJSONObject(k), k, true ));
            } catch(Throwable t) {
                println("Failed to parse pattern:", t);
            }
        }

        init(locations, velocities);
    }

    Equation parsePattern(JSONObject pattern, String ID, boolean isVelocityPattern) throws Exception {        
        int equationType;

        float difficulty = jsonVal(pattern, "difficulty", 0);
        String[] relatedEquationNames = null;
        if(!isVelocityPattern) relatedEquationNames = pattern.getJSONArray("velChoices").getStringArray();
        
        String equationImp = null, equationX = null, equationY = null;
        if(pattern.isNull("equation")) {
            equationType = Equation.PARAMETRIC;
            if(pattern.isNull("equationX") || pattern.isNull("equationY")) {
                throw new Exception("Pattern Parsing Error: Could not find equation");
            }
            equationX = pattern.getString("equationX");
            equationY = pattern.getString("equationY");
        }else{
            equationType = Equation.IMPLICIT;
            if(isVelocityPattern) {
                throw new Exception("Pattern Parsing Error: Implicit equation used for velocity");
            }
            equationImp = pattern.getString("equation");
        }

        ChainedTransformation transformations = new ChainedTransformation(new ArrayList());
        EnemyPatternProperties properties = new EnemyPatternProperties(difficulty, transformations);
        Equation equation;
        if(equationType == Equation.PARAMETRIC) {
            equation = new Equation2D(ID, relatedEquationNames, properties, equationX, equationY);
        }else{
            equation = new Equation1D(ID, relatedEquationNames, properties, equationImp);
        }

        properties. distBounds = defaultParse(pattern, "distBounds" , vec3(0));
        properties.scaleBounds = defaultParse(pattern, "scaleBounds", vec3(1));
        if(isVelocityPattern) {
            properties.speedBounds = defaultParse(pattern, "speedBounds", vec3(1));
            properties.angleSweep = defaultParse2D(pattern, "angleSweep", vec2(-PI, PI));
        }else{
            properties.countBounds = defaultParse(pattern, "countBounds", equationType == Equation.PARAMETRIC ? vec3(25) : vec3(5));
            properties.range = jsonVal(pattern, "range", 1);
        }

        if(!pattern.isNull("transform")) {
            JSONArray transformList = pattern.getJSONArray("transform");
            for(int i = 0; i < transformList.size(); i++) {
                JSONObject cur = transformList.getJSONObject(i);
                String transformationType = (String)cur.keys().iterator().next();
                String transformationValue = cur.getString(transformationType);
                switch(transformationType) {
                    case "scale": {
                        transformations.transformations.add(new Scale(parseBounds2D(transformationValue)));
                    } break;
                    case "rotate": {
                        transformations.transformations.add(new Rotate(float(transformationValue)));
                    } break;
                    case "translate": {
                        transformations.transformations.add(new Translate(parseBounds2D(transformationValue)));
                    } break;
                }
            }
        }
        if(!pattern.isNull("modifiers")) {
            for(String s : pattern.getJSONArray("modifiers").getStringArray()) {
                switch(s) {
                    case "disableRandomRotation": {
                        properties.disableRandomRotation = true;
                    } break;
                    case "disableRotationStacking": {
                        properties.disableRotationStacking = true; 
                    } break;
                }
            }
        }

        println(equation); //sadu8fgyhuidsfghs tostring aalso fix offset 

        return equation;
    }
    
    PVector defaultParse(JSONObject json, String s, PVector alternate) throws Exception {
        return json.isNull(s) ? alternate : parseBounds(json.getString(s));
    }
    PVector parseBounds(String s) throws Exception {
        String[] spl = split(s, ',');
        float[] vals = new float[spl.length];
        for(int i = 0; i < vals.length; i++) {
            vals[i] = float(trim(spl[i]));
        }
        if(vals.length == 1) return new PVector(vals[0], vals[0]                , vals[0]);
        if(vals.length == 2) return new PVector(vals[0], (vals[0] + vals[1]) / 2, vals[1]);
        if(vals.length >= 3) return new PVector(vals[0], vals[1]                , vals[2]);
        throw new Exception("Pattern Parsing Error: Couldn't parse bounds");
    }
    PVector defaultParse2D(JSONObject json, String s, PVector alternate) throws Exception {
        return json.isNull(s) ? alternate : parseBounds2D(json.getString(s));
    }
    PVector parseBounds2D(String s) throws Exception {
        String[] spl = split(s, ',');
        float[] vals = new float[spl.length];
        for(int i = 0; i < vals.length; i++) {
            vals[i] = float(trim(spl[i]).toLowerCase().replace("pi", str(PI)));
        }
        if(vals.length == 1) return new PVector(vals[0], vals[0]);
        if(vals.length == 2) return new PVector(vals[0], vals[1]);
        throw new Exception("Pattern Parsing Error: Couldn't parse bounds");
    }

    void init(ArrayList<Equation> locations, ArrayList<Equation2D> velocities) {
        this.locations = locations;
        this.velocities = velocities;

        locations.sort(new EquationDifficultySorter());

        velIDMapping = new HashMap<String, Equation2D>();
        locIDMapping = new HashMap<String, Equation  >();
        for(Equation2D velEquation : velocities) velIDMapping.put(velEquation.ID, velEquation);

        locIDVelMapping = new HashMap<String, ArrayList<Equation2D>>();
        for(Equation locEquation : locations) {
            locIDMapping.put(locEquation.ID, locEquation);
            ArrayList<Equation2D> complementVelocities = new ArrayList();
            for(String velName : locEquation.relatedEquationNames) complementVelocities.add(velIDMapping.get(velName));
            complementVelocities.sort(new EquationDifficultySorter());
            locIDVelMapping.put(locEquation.ID, complementVelocities);
        }
    }

    ArrayList<Enemy> spawnPattern(GameMap gameMap, RNG rng, float time, float intensity, float difficulty) {
        //intensity needs to range from 0 to around 1
        //difficulty ranges from 0.1 to 1.0; 0.1 = nearly zero chance of hard pattern; 1.0 = every pattern is the same 
        Equation spawnLocEq = locations.get(int(locations.size() * getWeighedRandom(rng, intensity, difficulty)));
        ArrayList<Equation2D> velEquationChoices = locIDVelMapping.get(spawnLocEq.ID);
        Equation2D spawnVelEq = velEquationChoices.get(int(velEquationChoices.size() * getWeighedRandom(rng, intensity, difficulty)));
        return generatePattern(spawnLocEq, spawnVelEq, gameMap, rng, time, getWeighedRandom(rng, intensity, difficulty));
    }
    ArrayList<Enemy> spawnPattern(GameMap gameMap, String locEqName, String velEqName, RNG rng, float time, float intensity, float difficulty) {
        return generatePattern(locIDMapping.get(locEqName), (Equation2D)locIDMapping.get(velEqName), gameMap, rng, time, getWeighedRandom(rng, intensity, difficulty));
    }

    float getWeighedRandom(RNG rng, float intensity, float difficulty) {
        return 1 - pow(rng.rand(), intensity * difficulty);
    }

    ArrayList<Enemy> generatePattern(Equation locEq, Equation2D velEq, GameMap gameMap, RNG rng, float time, float iLerp) {
        EnemyPatternProperties locationProps = locEq.spawnProperties;
        EnemyPatternProperties velocityProps = velEq.spawnProperties;
        ArrayList<PVector> locs = new ArrayList();
        ArrayList<PVector> vels = new ArrayList();
        
        int   count      = round(lerpCentered(locationProps.countBounds, iLerp)); //defaultCount
        float speed      =       lerpCentered(velocityProps.speedBounds, iLerp);  //defaultSpeed
        float locScale   =       lerpCentered(locationProps.scaleBounds, iLerp);  //defaultScale
        float velScale   =       lerpCentered(velocityProps.scaleBounds, iLerp);  //defaultScale
        float locDistAdj =       lerpCentered(locationProps.distBounds , rng.random()) * gameMap.gameDisplaySize.y;

        float locDistAdjRotation = rng.randCentered(PI);
        float locRotation = rng.randCentered(PI);
        float velRotation = rng.randCentered(PI);

        if(locEq.type == Equation.PARAMETRIC) {
            Equation2D parEq = (Equation2D)locEq;
            for(int i = 0; i < count; i++) {
                float t = map(i, 0, count - 1, locationProps.angleSweep);
                PVector loc = locationProps.defaultTransformation.apply(parEq.getVal(0, 0, t));
                locs.add(loc);
                vels.add(velocityProps.defaultTransformation.apply(velEq.getVal(loc.x, loc.y, t)));
            }
        }else if(locEq.type == Equation.IMPLICIT) {
            Equation1D impEq = (Equation1D)locEq;
            for(int i = 0; i < count; i++) {
                float x = map(i, 0, count - 1, -locationProps.range, locationProps.range);
                for(int o = 0; o < count; o++) {
                    float y = map(o, 0, count - 1, -locationProps.range, locationProps.range);
                    if(impEq.getVal(x, y, atan2(y, x)) > 0) continue;
                    PVector loc = locationProps.defaultTransformation.apply(new PVector(x, y));

                    locs.add(loc);
                    vels.add(velocityProps.defaultTransformation.apply(velEq.getVal(loc.x, loc.y, loc.heading()))); //im just gonna assume .heading will work
                }
            }
        }

        for(int i = 0; i < locs.size(); i++) {
            PVector loc = locs.get(i).mult(locScale);
            PVector vel = vels.get(i).mult(velScale);
            
            if(!locationProps.disableRandomRotation) {
                loc.rotate(locRotation);
                if(!velocityProps.disableRotationStacking) {
                    vel.rotate(locRotation);
                }
            }
            if(!velocityProps.disableRandomRotation) {
                vel.rotate(velRotation);
            }
            vel.mult(speed);
        }

        ArrayList<Enemy> enemies = new ArrayList();
        for(int i = 0; i < locs.size(); i++) {
            PVector loc = locs.get(i);
            PVector vel = vels.get(i);
            if(vel.mag() <= 0.01) {
                println(String.format("Enemy was excluded for having low or zero velocity: ([%s, %s], [%s, %s])", loc.x, loc.y, vel.x, vel.y));
                continue;
            }
            //todo: add field to songmap and have default location multiplier be min fieldsize / 3
            loc.mult(height / 6).add(gameMap.gameCenter).add(PVector.fromAngle(locDistAdjRotation).mult(locDistAdj));
            if(!velRectIntersection(loc, vel, gameMap.gameSize, gameMap.gameCenter)) {
                println(String.format("Enemy was excluded for having no intersection with play area: ([%s, %s], [%s, %s])", loc.x, loc.y, vel.x, vel.y));
                continue;
            }
            Enemy newEnemy = gameMap.createEnemy(loc, vel, time);
            if(newEnemy.spawnTime < 0) {
                println(String.format("Enemy was excluded for being on screen at song start: (%s)", newEnemy));
                continue;
            }
            enemies.add(newEnemy);
        }
        return enemies;
    }   
}
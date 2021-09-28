import java.util.Comparator;

class GameMap {
    int SPS, formCount, spawnIndex;
    float finalIntegralValue, songDuration, defaultSpeed, dt, marginSize, difficulty;
    String songName;
    PVector gameDisplaySize, gameSize, gameCenter;
    float[] velArr, integralArr, complexityArr;
    
    RNG rng;
    Music song;
    Field field;
    PatternSpawner spawner;
    ArrayList<Enemy> enemies;
    Enemy[] enemySpawns;

    class enemySpawnTimeSorter implements Comparator<Enemy> {
        @Override
        int compare(Enemy a, Enemy b) {
            return Float.compare(a.spawnTime, b.spawnTime);
        }
    }

    void init(PVector gameSize) {
        this.marginSize = GAME_MARGIN_SIZE;
        this.gameDisplaySize = gameSize.copy();
        this.gameSize = PVector.add(gameSize, vec2(marginSize * 2));
        this.gameCenter = PVector.mult(gameSize, 0.5);
        this.field = new Field(gameDisplaySize);
        
        SPS = SAMPLES_PER_SECOND;
        dt = 1.0 / SPS;
        defaultSpeed = DEFAULT_SPEED;
    }

    void prepareSong(AudioSample songRaw) {
        float[] leftSamples  = songRaw.getChannel(AudioSample.LEFT );
        float[] rightSamples = songRaw.getChannel(AudioSample.RIGHT);
        float[] samples = new float[rightSamples.length];
        for(int i = 0; i < leftSamples.length; i++) samples[i] = 0.5 * (leftSamples[i] + rightSamples[i]);

        formCount = samples.length / SAMPLES_PER_SECOND;
        songDuration = song.length() / 1000.0;

        complexityArr = new float[formCount];
        float[] buffer = new float[formCount];
        for(int i = 0; i < formCount - 1; i++) {
            for(int o = 0; o < buffer.length; o++) {
                int indx = i * SAMPLES_PER_SECOND + o;
                if(indx == samples.length) break;
                buffer[o] = samples[i * SAMPLES_PER_SECOND + o];
            }
            complexityArr[i] = findComplexity(buffer) * (1 + rootMeanSquare(buffer)) / 2;
        }
    }
    GameMap(String songName, String patternFileName, PVector gameSize, RNG rng, float difficulty) {
        init(gameSize);
        this.songName = songName;
        this.difficulty = difficulty;
        this.rng = rng;

        song = new Music(songName, -20.0);
        prepareSong(minim.loadSample(songName));
        spawner = new PatternSpawner(patternFileName);
        generateEnemies();
    }
    float[] generateVels() {
        float[] velArr = new float[SAMPLES_PER_SECOND * int(songDuration)];
        for(int i = 0; i < velArr.length; i++) {
            velArr[i] = defaultSpeed + 1000 * (complexityArr[int(map(i, 0, velArr.length, 0, complexityArr.length))]);
        }
        return velArr;
    }
    void createPattern(float time, float intensity, int intercept) {
        enemies.addAll(spawner.makePatternFromCategory(this, "default", rng, time, 1, difficulty, intercept));
    }
    void createPattern(String category, float time, float intensity, int intercept) {
        enemies.addAll(spawner.makePatternFromCategory(this, category , rng, time, 1, difficulty, intercept));
    }
    void createPatternFromLoc(String locEqName, float time, float intensity, int intercept) {
        enemies.addAll(spawner.makePatternFromLocation(this, locEqName, rng, time, 1, difficulty, intercept));
    }
    void addRecentEnemies(float time) {
        while(spawnIndex < enemySpawns.length && time >= enemySpawns[spawnIndex].spawnTime) {
            Enemy e = enemySpawns[spawnIndex];
            if(time < e.despawnTime) enemies.add(e);
            spawnIndex++;
        }
    }
    void removeExpiredEnemies(float time) {
        if(enemies.size() == 0) return;
        for(int i = enemies.size() - 1; i >= 0; i--) {
            if(time >= enemies.get(i).despawnTime) {
                enemies.remove(i);
            }
        }
    }
    void updateEnemies(float time) {
        removeExpiredEnemies(time);
        addRecentEnemies(time);
    }
    void resetEnemies() {
        spawnIndex = 0;
        enemies = new ArrayList<Enemy>();
    }
    int getIntensityIndex(float time) {
        return constrain(int(1000 * time * complexityArr.length / song.length()), 0, complexityArr.length - 1);
    }
    float getIntensity(float time) {
        return complexityArr[getIntensityIndex(time)];
    }
    void generateEnemies() {
        resetEnemies();

        float average = 0;
        for(int i = 0; i < complexityArr.length; i++) average += complexityArr[i];
        average /= complexityArr.length;
        for(int i = 0; i < complexityArr.length; i++) complexityArr[i] = pow(complexityArr[i] / (2.25 * average), 1.5);
        average = 0;
        for(int i = 0; i < complexityArr.length; i++) average += complexityArr[i];
        average /= complexityArr.length;

        float totalComplexity = findComplexity(complexityArr);

        int iSec = int(complexityArr.length / songDuration);       //seconds -> intTime
        float sampSecFactor = songDuration / complexityArr.length; //intTime -> seconds

        float boost = 0;
        for(int i = 0; i < complexityArr.length; i++) {
            float c = complexityArr[i] + boost;
            if(c < average) {
                boost = lerp(boost, average / 1.5, sampSecFactor / 20.0);
            }else if(c > average + 1.5 * totalComplexity) {
                boost = 0;
            }
            complexityArr[i] = c + boost;
        }

        generateIntegral(generateVels(), gameSize);

        float intensityScale = 1 / average + 2.25 * totalComplexity;
        { //Beat detection [AIDS WARNING]
            int minSeg = iSec / 3;
            int maxSeg = 5 * iSec;
            float spawnTimeDeltaRemoval = iSec / 8;
            int minConsecutiveBeats = 5;
            int maxBeatDrift = minSeg / 6;
            float thres0 = average + totalComplexity * 1; //Threshold for being a beat
            float thres1 = average + totalComplexity * 3.5; //Threshold for being a heavy beat

            IntList avoidTimings = new IntList();
            for(int i = 0; i < complexityArr.length; i++) {
                for(int o = minSeg; o < maxSeg; o++) {
                    IntList beats = new IntList();
                    int t = o;
                    int beatLength = o;
                    int overallOffset = 0;
                    while(i + t < complexityArr.length - beatLength * 2 && complexityArr[i + t] > thres0) {
                        beats.append(i + t);
                        int optimalLocOffset = findLocalMaxOffset(complexityArr, i + t + beatLength, maxBeatDrift);
                        overallOffset += optimalLocOffset;
                        if(overallOffset < maxBeatDrift && maxBeatDrift > -maxBeatDrift) {
                            beatLength += optimalLocOffset;
                        }
                        t += beatLength;
                    }
                    if(beats.size() < minConsecutiveBeats) continue;
                    for(int beatTime : beats) {
                        boolean invalidSpawn = false;
                        for(int avoidTime : avoidTimings) {
                            if(abs(beatTime - avoidTime) < spawnTimeDeltaRemoval) {
                                invalidSpawn = true;
                                break;
                            }
                        }
                        avoidTimings.append(beatTime);
                        if(invalidSpawn) continue;

                        if(complexityArr[beatTime] < thres1) {
                            createPattern("beat", beatTime * sampSecFactor, complexityArr[beatTime] * intensityScale, PatternSpawner.INTERCEPT_DEFAULT);
                        }else{
                            createPattern("heavyBeat", beatTime * sampSecFactor, complexityArr[beatTime] * intensityScale, PatternSpawner.INTERCEPT_DEFAULT);
                        }
                        enemies.add(createEnemy(vec2(gameSize.x, height / 2), vec2(1, 0), beatTime * sampSecFactor));
                    }
                    i += beatLength * 2;
                    break;
                }
            }
        }
        enemies.sort(new enemySpawnTimeSorter());
        enemySpawns = enemies.toArray(new Enemy[enemies.size()]);
        enemies = new ArrayList<Enemy>();

    }
    float findComplexity(float[] k) { //Variance calculation
        float adv = 0;
        for(int i = 0; i < k.length; i++) {
            adv += k[i];
        }
        adv /= k.length;
        float complexity = 0;
        for(int i = 0; i < k.length; i++) {
            complexity += abs(k[i] - adv);
        }
        complexity /= k.length;
        return complexity;
    }
    void generateIntegral(float[] velArr, PVector gameSize) {
        integralArr = new float[velArr.length];
        integralArr[0] = 0;
        for(int i = 1; i < integralArr.length; i++) {
            integralArr[i] = integralArr[i - 1] + velArr[i] * dt;
        }
        finalIntegralValue = integralArr[integralArr.length - 1];
    }
    float getIntegralVal(float val) {
        if(val >= integralArr.length) {
            return integralArr[integralArr.length - 1] + (val - integralArr[integralArr.length - 1]) * defaultSpeed * dt;
        }else if(val < 0) {
            return val * defaultSpeed * dt;
        }else{
            return integralArr[int(val)]; //lerp(integralArr[floor(val)], integralArr[ceil(val)], val - floor(val));
        }
    }
    float getIntegralTimeDelta(float checkDist, float checkLocation) {
        if(checkLocation > finalIntegralValue) {
            return integralArr.length + SPS * defaultSpeed;
        }else if(checkLocation < 0) {
            return SPS * checkLocation / defaultSpeed;
        }else{
            for(float i = 0; i < integralArr.length; i++) {
                if(getIntegralVal(i) >= checkLocation) return i;
            }
        }
        return -1;
    }
    Enemy createEnemy(Enemy e, float time) {
        return createEnemy(e.loc, e.vel, time);
    }
    Enemy createEnemy(PVector loc, PVector vel, float time) {
        float currentTime = time * SPS;
        float currentVal = getIntegralVal(currentTime);

        float startDist = distToRect(loc, PVector.mult(vel, -1), gameSize, gameCenter) / vel.mag();
        float startCheckLocation = currentVal - startDist;
        float startTime = getIntegralTimeDelta(startDist, startCheckLocation);
        float startVal = getIntegralVal(startTime);
        
        float finalDist = distToRect(loc, vel, gameSize, gameCenter) / vel.mag();
        float finalCheckLocation = currentVal + finalDist;
        float finalTime = getIntegralTimeDelta(finalDist, finalCheckLocation);

        float positionDelta = currentVal - startVal;
        PVector location = PVector.sub(loc, PVector.mult(vel, positionDelta));

        return new Enemy(this, location, vel, startTime / SPS, finalTime / SPS);
    }
    
    void updateField(PVector playerPos, float time, int mouseX, int mouseY) {
        field.update(playerPos, getIntensity(time), mouseX, mouseY);
    }
    void drawField(PGraphics base, PVector pos, int mouseX, int mouseY) {
        field.draw(base, pos, mouseX, mouseY);
    }
    void drawPlayer(PGraphics base, PVector pos, int mouseX, int mouseY) {
        field.drawPlayer(base, pos, mouseX, mouseY);
    }
    void drawEnemies(PGraphics base, float time, color enemyColor, boolean fancy) {
        base.noStroke();
        for(Enemy e : enemies) e.draw(base, time, enemyColor, fancy);
    }
}
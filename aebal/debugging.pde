class debugMessage {
    String msg;
    float decayTime, fadeOutDuration;
    int count = 1;
    debugMessage(String msg, float decayTime, float fadeOutDuration) {
        this.msg = msg;
        this.decayTime = decayTime;
        this.fadeOutDuration = fadeOutDuration;
    }
}

class debugList {
    ArrayList<debugMessage> messages;
    float x, y, decayTime, fadeOutDuration;
    debugList(float x, float y, float decayTime, float fadeOutDuration) {
        this.x = x;
        this.y = y;
        this.decayTime = decayTime;
        this.fadeOutDuration = fadeOutDuration;
        messages = new ArrayList();
    }
    void addMessage(String msg) {
        messages.add(new debugMessage(msg, adjMillis() + decayTime, fadeOutDuration));
    }
    void draw(PGraphics g) {
        g.textSize(14);
        g.textAlign(RIGHT, TOP);
        for(int i = messages.size() - 1; i >= 0; i--) {
            debugMessage msg = messages.get(i);
            g.fill(255, clampMap(adjMillis(), msg.decayTime - msg.fadeOutDuration, msg.decayTime, 255, 0));
            g.text((msg.count > 1 ? "[x"+msg.count+"] " : "") + msg.msg, x, y + (messages.size() - i) * 15);
            if(adjMillis() >= msg.decayTime) messages.remove(i);
        }
    }
}

void logmsg(String s) {
    println("["+millis()+"] " + s);
    s = s.replace("\n", "\\n");
    if(msgList.messages.size() > 0 && msgList.messages.get(msgList.messages.size() - 1).msg.equals(s)) {
        msgList.messages.get(msgList.messages.size() - 1).count++;
    }else{
        msgList.addMessage(s);
    }
}

String format(String s, Object... params) {
    return String.format(s, params);
}
void printf(String s, Object... params) {
    println(format(s, params));
}
void logf(String s, Object... params) {
    logmsg(format(s, params));
}

void TT(String ID) {
    if(TIMING_INFO.state && checkTimes) {
        if(timingList.containsKey(ID)) {
            float t = (float)(System.nanoTime() - timingList.get(ID)) / 1000000000;
            String v = timerFormat.format(100 * t * frameRate)+"%     (" + timerFormat.format(t) + "s)";
            timingDisplay.put(ID, v);
            timingList.remove(ID);
        }else{
            timingList.put(ID, System.nanoTime());
        }
    }
}
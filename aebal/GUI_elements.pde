int MOUSE_OVER    = 0;
int MOUSE_PRESS   = 1;
int MOUSE_RELEASE = 2;
class button {
    float x, y, w, h, r;
    boolean active, state;
    color norm_0, norm_1, over_0, over_1, down_0, down_1;
    String txt;
    PImage overlay;
    // keyword parameters don't exist in Java for """simplicity""" reasons
    void init(float x, float y, float w, float h, float r, PImage overlay, String txt, color norm_0, color over_0, color down_0, color norm_1, color over_1, color down_1) {
        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;
        this.r = r;
        if(overlay != null) {
            this.overlay = overlay.copy();
            this.overlay.resize(int(w / 1.15), int(h / 1.15));
        }
        this.txt = txt;
        this.norm_0 = norm_0;
        this.norm_1 = norm_1;
        this.over_0 = over_0;
        this.over_1 = over_1;
        this.down_0 = down_0;
        this.down_1 = down_1;
        state = true;
        active = false;
    }
    button(float x, float y, float w, float h, float r, PImage overlay, color norm_0, color over_0, color down_0) {
        init(x, y, w, h, r, overlay, null, norm_0, over_0, down_0, -1, -1, -1);
    }
    button(float x, float y, float w, float h, float r                , color norm_0, color over_0, color down_0) {
        init(x, y, w, h, r, null   , null, norm_0, over_0, down_0, -1, -1, -1);
    }
    button(float x, float y, float w, float h, float r, PImage overlay, color norm_0, color over_0, color down_0, color norm_1, color over_1, color down_1) {
        init(x, y, w, h, r, overlay, null, norm_0, over_0, down_0, norm_1, over_1, down_1);
    }
    button(float x, float y, float w, float h, float r                , color norm_0, color over_0, color down_0, color norm_1, color over_1, color down_1) {
        init(x, y, w, h, r, null   , null, norm_0, over_0, down_0, norm_1, over_1, down_1);
    }
    button(float x, float y, float w, float h, float r, PImage overlay, String txt, color norm_0, color over_0, color down_0) {
        init(x, y, w, h, r, overlay, txt , norm_0, over_0, down_0, -1, -1, -1);
    }
    button(float x, float y, float w, float h, float r, String txt                , color norm_0, color over_0, color down_0) {
        init(x, y, w, h, r, null   , txt , norm_0, over_0, down_0, -1, -1, -1);
    }
    button(float x, float y, float w, float h, float r, PImage overlay, String txt, color norm_0, color over_0, color down_0, color norm_1, color over_1, color down_1) {
        init(x, y, w, h, r, overlay, txt , norm_0, over_0, down_0, norm_1, over_1, down_1);
    }
    button(float x, float y, float w, float h, float r, String txt                , color norm_0, color over_0, color down_0, color norm_1, color over_1, color down_1) {
        init(x, y, w, h, r, null   , txt , norm_0, over_0, down_0, norm_1, over_1, down_1);
    }

    boolean checkMouse(int type) {
        boolean over = mouseX > x - w/2 && mouseX < x + w/2 && mouseY > y - h/2 && mouseY < y + h/2;
        if(over && active && type == MOUSE_RELEASE && over_1 != -1) state = !state;
        if(type > 0) {
            active = type == MOUSE_PRESS && over;
            if(over && type == MOUSE_RELEASE) buttonSFX.playR();
        }
        return over;
    }
    void draw() {
        rectMode(CENTER);
        imageMode(CENTER);
        boolean mouseOver = checkMouse(MOUSE_OVER);
        if(mouseOver) activeCursor = HAND; 
        
        fill(state ? (active ? down_0 : (mouseOver ? over_0 : norm_0)) : (active ? down_1 : (mouseOver ? over_1 : norm_1))); //lol
        rect(x, y, w, h, r);
        if(overlay != null) image(overlay, x, y);
        if(txt != null) text(txt, x + (w / 2.0 + g.textSize / 2.5) * (g.textAlign == LEFT ? 1 : -1), y - 4.5); //THIS STUPID LINE TOOK HOURS TO FIGURE OUT, NOWHERE ANYWHERE DOES IT MENTION 'g' AS A VARIABLE TO ACCESS THE PAPPLET's PGRAPHICS, I SCROLLED THROUGH SO MANY DOCS TO FIND THIS
    }
}

class slider {
    float x, y, w, h, val, val_min, val_max, ballHfactor;
    color clr_line, clr_ball, clr_line_hover, clr_ball_hover, clr_line_active, clr_ball_active;
    boolean active;
    String txt;
    void init(float x, float y, float w, float h, float val, float val_min, float val_max, String txt, color clr_line, color clr_ball, color clr_line_hover, color clr_ball_hover, color clr_line_active, color clr_ball_active) {
        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;
        this.val = val;
        this.val_min = val_min;
        this.val_max = val_max;
        this.txt = txt;
        this.clr_line = clr_line;
        this.clr_ball = clr_ball;
        this.clr_line_hover = clr_line_hover;
        this.clr_ball_hover = clr_ball_hover;
        this.clr_line_active = clr_line_active;
        this.clr_ball_active = clr_ball_active;
        this.ballHfactor = 1.3;
        active = false;
    }
    slider(float x, float y, float w, float h, float val, float val_min, float val_max, color clr_line, color clr_ball, color clr_line_hover, color clr_ball_hover, color clr_line_active, color clr_ball_active) {
        init(x, y, w, h, val, val_min, val_max, null, clr_line, clr_ball, clr_line_hover, clr_ball_hover, clr_line_active, clr_ball_active);
    }
    slider(float x, float y, float w, float h, float val, float val_min, float val_max, color clr, color clr_hover, color clr_active) {
        init(x, y, w, h, val, val_min, val_max, null, clr, clr, clr_hover, clr_hover, clr_hover, clr_active);
    }
    slider(float x, float y, float w, float h, float val, float val_min, float val_max, String txt, color clr_line, color clr_ball, color clr_line_hover, color clr_ball_hover, color clr_line_active, color clr_ball_active) {
        init(x, y, w, h, val, val_min, val_max, txt , clr_line, clr_ball, clr_line_hover, clr_ball_hover, clr_line_active, clr_ball_active);
    }
    slider(float x, float y, float w, float h, float val, float val_min, float val_max, String txt, color clr, color clr_hover, color clr_active) {
        init(x, y, w, h, val, val_min, val_max, txt , clr, clr, clr_hover, clr_hover, clr_hover, clr_active);
    }
    float getMappedVal() {
        return map(val, val_min, val_max, x - w / 2, x + w / 2);
    }
    boolean checkMouse(int type) {
        float offsetX = w / 2 - h / 2;
        boolean over = (mouseX > x - offsetX && mouseX < x + offsetX && mouseY > y - h / 2 && mouseY < y + h / 2) || dist(mouseX, mouseY, getMappedVal(), y) < h / 2 * ballHfactor || dist(mouseX, mouseY, x - offsetX, y) < h / 2 || dist(mouseX, mouseY, x + offsetX, y) < h / 2;
        boolean pre_active = active;
        if(type > 0) active = type == MOUSE_PRESS && over; //this line is sex
        if(pre_active && !active) {
            setGlobalVolume(volSlider.val);
            volChangeSFX.playR();
        }
        return over;
    }
    void draw() {
        if(active) val = constrain(map(mouseX, x - w / 2, x + w / 2, val_min, val_max), val_min, val_max);
        boolean mouseOver = checkMouse(MOUSE_OVER);
        if(mouseOver) activeCursor = HAND;
        rectMode(CENTER);
        fill(active ? clr_line_active : (mouseOver ? clr_line_hover : clr_line));
        rect(x, y, w, h, h / 2);
        fill(active ? clr_ball_active : (mouseOver ? clr_ball_hover : clr_ball));
        circle(getMappedVal(), y, h * ballHfactor);
        if(txt != null) {
            text(txt, x, y + g.textSize / 1.5 * (g.textAlignY == BOTTOM ? -1 : 1));
        } 
    }
}
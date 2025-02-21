/*
 * Copyright (c) 2024 Daniel Svensson <dsvensson@gmail.com>
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#define RSES_NOLERP   1
#define RSES_NOROTATE 2
#define RSES_NOTRAILS 4
#define RSES_NOLIGHTS 8

#define MASK_XRAY  (1<<3)
#define MASK_LOCAL (1<<4)

var float match_start_time = -1;
var int camera_index = -1;
var float camera_intro = 4.0;
var float camera_outro = 2.5;
var float camera_transition = 1.0;

#define CAMERA_START_RESET 9999999
#define CAMERA_END_RESET   9999999

var float camera_start = CAMERA_START_RESET;
var float camera_start_transition = CAMERA_START_RESET;

var float camera_end = CAMERA_END_RESET;
var float camera_end_transition = CAMERA_END_RESET;

var vector camera_bg_color = '1 1 1';
var string camera_item_name = "none";

var string team_shader = "";
var string enemy_shader = "";

var float autocvar_pip_debug = 0;
var float autocvar_pip_enabled = 1;
var float autocvar_pip_camera_intro = 5.0;
var float autocvar_pip_camera_outro = 3.5;
var float autocvar_pip_camera_transition = 0.8;
var vector autocvar_pip_bg_quad_color = '0.2 0.2 0.5';
var vector autocvar_pip_bg_pent_color = '0.5 0.2 0.2';

var float autocvar_pip_xray = 1;
var float autocvar_pip_xray_alpha = 0.3;
var float autocvar_pip_xray_distance = 512;
var vector autocvar_pip_xray_color_team = '0 1 0';
var vector autocvar_pip_xray_color_enemy = '1 0 0';

float(float x) easeInExpo =
{
    if (x == 0.0) {
        return 0.0;
    }
    return pow(2.0, 10.0 * x - 10.0);
};

void() ResetCamera =
{
    camera_start = CAMERA_START_RESET;
    camera_start_transition = CAMERA_START_RESET;
    camera_end = CAMERA_END_RESET;
    camera_end_transition = CAMERA_END_RESET;
    camera_index = -1;
};

void() SelectNextCamera =
{
    if (match_start_time == -1) {
        return;
    }

    if (time >= camera_start && time < camera_end) {
        return;
    }

    itemtimer_t *timers = PipGetTimers();

    itemtype_t candidate_type = IT_NONE;
    float candidate_respawn = CAMERA_START_RESET;
    int candidate_index = -1;

    for (int i = 0; i < MAX_POWERUPS; i++) {
        itemtimer_t *timer = &timers[i];
        item_t *item = timer->item;
        if (!item) {
            continue;
        }

        // deal with prioritization
        if (timer->respawn < candidate_respawn || (item->type == IT_PENT && timer->respawn == candidate_respawn)) {
            candidate_type = item->type;
            candidate_respawn = timer->respawn;
            candidate_index = i;
        }
    }
    if (candidate_index != -1) {
        // Reload any cvar changes
        camera_intro = autocvar_pip_camera_intro;
        camera_outro = autocvar_pip_camera_outro;
        camera_transition = autocvar_pip_camera_transition;

        camera_index = candidate_index;
        camera_start = max(match_start_time, candidate_respawn - camera_intro);
        camera_start_transition = camera_start + camera_transition;
        camera_end = CAMERA_END_RESET;
        camera_end_transition = CAMERA_END_RESET;

        switch (candidate_type) {
        case IT_QUAD:
            camera_bg_color = autocvar_pip_bg_quad_color;
            camera_item_name = "Quad";
            break;
        case IT_PENT:
            camera_bg_color = autocvar_pip_bg_pent_color;
            camera_item_name = "Pent";
            break;
        default:
            camera_bg_color = '1 1 1';
            break;
        }
    }
};


float() PipCmdActive =
{
    print("");

    println("PiP Camera State\n\n");
    println("Camera settings:");
    println("- index:      %3d", (float)camera_index);
    println("- intro:      %1.1f", camera_intro);
    println("- outro:      %1.1f", camera_outro);
    println("- transition: %1.1f", camera_transition);
    println("Camera schedule:");
    println("- start: %4.2f", camera_start);
    println("- intro: %4.2f", camera_start_transition);
    println("- outro: %4.2f", camera_end_transition);
    println("- end:   %4.2f", camera_end);
    println("Current Time: %4.2f", time);
    return 1;
};


float() PipCmdTimers =
{
    println("PiP Timer State\n");
    itemtimer_t *timers = PipGetTimers();
    for (int i = 0; i < MAX_POWERUPS; i++) {
        itemtimer_t *timer = &timers[i];
        if (!timer->item) {
            continue;
        }
        println("  index: %d", i);
        println(" entnum: %d", timer->entnum);
        println("   took: %.2f", timer->took);
        println("respawn: %.2f", timer->respawn);

        vector origin = getentity(timer->entnum, GE_ORIGIN);
        println("spawned: %s", origin == '0 0 0' ? "no" : "yes");

        if (timer->took > 0) {
            string name = getplayerkeyvalue(timer->playernum - 1, INFOKEY_P_NAME);
            println("     by: %s (num: %f)", name, timer->playernum);
        }

        print("   type: ");
        item_t *item = timer.item;
        switch (item.type) {
        case IT_QUAD:
            print("&c55fquad&r");
            break;
        case IT_PENT:
            print("&cf55pent&r");
            break;
        default:
            print("none");
            break;
        }
        print("\n\n");
    }
    println("Current time: %f", time);
    return 1;
};

float() PipCmdHelp =
{
    println("Picture-in-Picture Commands");
    println(" * active - Currently scheduled camera");
    println(" * timers - All tracked timers");
    return 1;
};

float(string cmd) CSQC_ConsoleCommand =
{
    tokenize_console(cmd);
    if (argv(0) != "pip") {
        return 0;
    }
    switch (argv(1)) {
    case "active":
        return PipCmdActive();
    case "timers":
        return PipCmdTimers();
    default:
        return PipCmdHelp();
    }
};

void(float apilevel, string enginename, float engineversion) CSQC_Init =
{
    registercommand("pip");
};

void(entity ent) PipResetPlayer =
{
    if (ent.entnum == player_localentnum) {
        ent.drawmask = MASK_LOCAL;
    } else {
        ent.drawmask = 0;
    }
    ent.effects = 0;
    ent.alpha = 0;
    ent.fatness = 0;
    ent.forceshader = 0;
};

float(float isnew) PipNewPlayer =
{
    if (self.entnum == player_localentnum || !autocvar_pip_xray) {
        PipResetPlayer(self);
        return isnew;
    }

    float pnum = self.entnum-1;
    float health = getplayerstat(pnum, STAT_HEALTH, EV_FLOAT);
    if (health <= 0) {
        PipResetPlayer(self);
        return isnew;
    }

    vector org = getviewprop(VF_ORIGIN);
    float cutoff = autocvar_pip_xray_distance;

    float distance = vlen(org - self.origin);
    if (distance > cutoff) {
        PipResetPlayer(self);
        return isnew;
    }

    traceline(org, self.origin, MOVE_NORMAL | MOVE_NOMONSTERS, self);
    if (trace_fraction == 1) {
        PipResetPlayer(self);
        return isnew;
    }

    float distanceFactor = 1 - easeInExpo(distance / cutoff);

    self.effects |= EF_NODEPTHTEST | EF_ADDITIVE;
    self.drawmask = (self.drawmask & ~MASK_ENGINE) | MASK_XRAY;
    self.alpha = autocvar_pip_xray_alpha * distanceFactor;
    self.fatness = 2;

    // Workaround for self.origin not being lerped, bug in FTE, remove once fixed.
    vector origin = getentity(self.entnum, GE_ORIGIN);
    setorigin(self, origin);

    string pov_team = getplayerkeyvalue(player_localentnum-1, "team");
    string ent_team = getplayerkeyvalue(pnum, "team");

    if (pov_team != ent_team) {
        self.forceshader = shaderforname("xray-enemy", enemy_shader);
    } else {
        self.forceshader = shaderforname("xray-team", team_shader);
    }

    return isnew;
};

void() CSQC_WorldLoaded =
{
    if (autocvar_pip_xray) {
        team_shader = sprintf(R"({
          {
            map $whiteimage
            rgbgen const %v
          }
        })", autocvar_pip_xray_color_team);

        enemy_shader = sprintf(R"({
          {
            map $whiteimage
            rgbgen const %v
          }
        })", autocvar_pip_xray_color_enemy);

        deltalisten("progs/player.mdl", PipNewPlayer, 0);
    }

    match_start_time = -1;

    ResetCamera();
    PipResetTimers(match_start_time);

    if (PipLoadItems()) {
        deltalisten("progs/quaddama.mdl", PipPowerupSpawnListener, RSES_NOLERP);
        deltalisten("progs/invulner.mdl", PipPowerupSpawnListener, RSES_NOLERP);
    }
};

void() CSQC_ServerInfoChanged =
{
    if (match_start_time >= 0.0f) {
        return;
    }

    string status = serverkey("status");
    if (!strcasecmp(status, "standby") || !strcasecmp(status, "countdown")) {
        return;
    }

    match_start_time = time;

    float argc = tokenize(status);
    if (argc == 3 && argv(1) == "min" && argv(2) == "left") {
        println("[%.0f] minutes remaining", stof(argv(0)));
    }

    PipResetTimers(match_start_time);
    SelectNextCamera();
};

void(float vwidth, float vheight, float notmenu) CSQC_UpdateView =
{
    clearscene();
    setviewprop(VF_VIEWENTITY, 0);
    addentities(MASK_ENGINE | MASK_VIEWMODEL);
    setviewprop(VF_DRAWENGINESBAR, 1);
    setviewprop(VF_DRAWCROSSHAIR, 1);
    renderscene();
    clearscene();

    addentities(MASK_XRAY);
    setviewprop(VF_DRAWWORLD, 0);
    renderscene();

    if (time < camera_start) {
        SelectNextCamera();
        return;
    }

    if (!autocvar_pip_enabled) {
        return;
    }

    vector font_size = '8 8 0';

    float aspect_ratio = vheight / vwidth;
    float width = vwidth / 4.0;
    float height = width * aspect_ratio;

    float margin = width / 10.0;
    float x_offset = vwidth - margin - width;

    float delta = 0.0;
    float slide_offset = 0;

    itemtimer_t *timer = PipGetTimer(camera_index);
    if (!timer) {
        return;
    }

    item_t *item = timer->item;

    if (camera_end == CAMERA_END_RESET && timer->took > camera_start) {
        camera_end = timer->took + camera_outro;
        camera_end_transition = camera_end - camera_transition;
    }

    if (time >= camera_start && time < camera_start_transition) {
        delta = easeInExpo((camera_start_transition - time) / camera_transition);
    }
    else if (time >= camera_end_transition) {
        delta = 1.0 - easeInExpo((camera_end - time) / camera_transition);
    }

    if (delta > 0.0) {
        slide_offset = (width + x_offset) * delta;
    }


    // Item type colored background
    float bg_offset_x = x_offset + slide_offset - margin / 4;
    float bg_offset_y = margin - margin / 4;
    float bg_width = width + margin / 2;
    float bg_height = height + margin / 2 + font_size.y;
    float bg_alpha = 0.5;
    drawfill([bg_offset_x, bg_offset_y], [bg_width, bg_height], camera_bg_color, bg_alpha);

    // Black contrasting inner border
    float border_offset_x = x_offset + slide_offset - margin / 16;
    float border_offset_y = margin - margin / 16;
    float border_width = width + margin / 8;
    float border_height = height + margin / 8;
    vector border_color = [0, 0, 0];
    float border_alpha = 0.4;
    drawfill([border_offset_x, border_offset_y], [border_width, border_height], border_color, border_alpha);

    // No-op to reset blending mode, bug in FTE
    drawfill([0, 0], [0, 0], [1, 1, 1], 1);

    clearscene();
    setviewprop(VF_DRAWWORLD, 1);
    setviewprop(VF_VIEWENTITY, 1);
    setviewprop(VF_DRAWENGINESBAR, 0);
    setviewprop(VF_DRAWCROSSHAIR, 0);
    setviewprop(VF_ORIGIN, item->camera->origin);
    setviewprop(VF_MIN_X, x_offset + slide_offset);
    setviewprop(VF_MIN_Y, margin);
    setviewprop(VF_SIZE_X, width);
    setviewprop(VF_SIZE_Y, height);
    setviewprop(VF_ANGLES, item->camera->angles);
    setviewprop(VF_FOV, '110 0 0');
    addentities(MASK_ENGINE | MASK_LOCAL);

    cvar_set("scr_autoid_armor", "0");
    cvar_set("scr_autoid_health", "0");
    cvar_set("scr_autoid_weapon", "0");

    renderscene();

    cvar_set("scr_autoid_armor", "1");
    cvar_set("scr_autoid_health", "1");
    cvar_set("scr_autoid_weapon", "1");

    string text;
    if (time < timer->respawn && time > (timer->respawn - camera_intro)) {
        text = sprintf("%s in %i sec", camera_item_name , (int)ceil(timer->respawn - time));
    } else if (time > timer->took && timer->took > camera_start) {
        string name = getplayerkeyvalue(timer->playernum - 1, INFOKEY_P_NAME);
        text = sprintf("%s's %s", name, camera_item_name);
    } else {
        text = sprintf("%s spawned!", camera_item_name);
    }

    float txt_offset_x = x_offset + slide_offset;
    float txt_offset_y = margin + height + margin / 8;
    vector txt_color = [0.7, 0.7, 0.7];
    float txt_alpha = 1;
    drawsetcliparea(txt_offset_x, txt_offset_y, width, font_size.y);
    drawstring([txt_offset_x, txt_offset_y], text, font_size, txt_color, txt_alpha, 0);
    drawresetcliparea();

    if (time > camera_end) {
        ResetCamera();
        SelectNextCamera();
    }
};

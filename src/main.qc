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

var float match_start_time = 0;
var int camera_index = -1;
var float camera_intro = 4.0;
var float camera_outro = 2.5;
var float camera_transition = 1.0;

#define CAMERA_START_RESET 9999
#define CAMERA_END_RESET   9999

var float camera_start = CAMERA_START_RESET;
var float camera_start_transition = CAMERA_START_RESET;

var float camera_end = CAMERA_END_RESET;
var float camera_end_transition = CAMERA_END_RESET;

var vector camera_bg_color = '1 1 1';
var string camera_item_name = "none";

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
    if (!match_start_time) {
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
        camera_intro = cvar("pip_camera_intro");
        camera_outro = cvar("pip_camera_outro");
        camera_transition = cvar("pip_camera_transition");

        camera_index = candidate_index;
        camera_start = max(match_start_time, candidate_respawn - camera_intro);
        camera_start_transition = camera_start + camera_transition;
        camera_end = CAMERA_END_RESET;
        camera_end_transition = CAMERA_END_RESET;

        switch (candidate_type) {
        case IT_QUAD:
            camera_bg_color = stov(cvar_string("pip_bg_quad_color"));
            camera_item_name = "Quad";
            break;
        case IT_PENT:
            camera_bg_color = stov(cvar_string("pip_bg_pent_color"));
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
    print("Picture-in-Picture Camera State\n\n");
    print("Camera settings:\n");
    print("- index:      ", itos(camera_index), "\n");
    print("- intro:      ", ftos(camera_intro), "\n");
    print("- outro:      ", ftos(camera_outro), "\n");
    print("- transition: ", ftos(camera_transition), "\n\n");
    print("Camera schedule:\n");
    print("- start: ", ftos(camera_start), "\n");
    print("- intro: ", ftos(camera_start_transition), "\n");
    print("- outro: ", ftos(camera_end_transition), "\n");
    print("- end:   ", ftos(camera_end), "\n\n");
    print("Current Time: ", ftos(time), "\n");
    return 1;
};


float() PipCmdTimers =
{
    print("Picture-in-Picture Timer State\n\n");
    itemtimer_t *timers = PipGetTimers();
    for (int i = 0; i < MAX_POWERUPS; i++) {
        itemtimer_t *timer = &timers[i];
        if (!timer->item) {
            continue;
        }
        print("  index: ", itos(i), "\n");
        print(" entnum: ", ftos(timer->entnum), "\n");
        print("   took: ", ftos(timer->took), "\n");
        print("respawn: ", ftos(timer->respawn), "\n");

        vector origin = getentity(timer->entnum, GE_ORIGIN);
        print("spawned: ", origin == '0 0 0' ? "no" : "yes", "\n");

        string name = getplayerkeyvalue(timer->playernum - 1, INFOKEY_P_NAME);
        print("     by: ", name, " (num: ", ftos(timer->playernum), ")\n");

        print("   type: ");
        item_t *item = timer.item;
        switch (item.type) {
        case IT_QUAD:
            print("quad");
            break;
        case IT_PENT:
            print("pent");
            break;
        default:
            print("none");
            break;
        }
        print("\n\n");
    }
    print("Current time: ", ftos(time), "\n");
    return 1;
};

float() PipCmdHelp =
{
    print("Picture-in-Picture Commands\n");
    print(" * active - Currently scheduled camera\n");
    print(" * timers - All tracked timers\n");
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
    // Toggle if cameras are enabled, the timing data will be recorded either way
    // to allow toggling it mid game
    registercvar("pip_enabled", "1");
    registercvar("pip_camera_intro", "5.0");
    registercvar("pip_camera_outro", "3.5");
    registercvar("pip_camera_transition", "0.8");
    registercvar("pip_bg_quad_color", "0.2 0.2 0.5");
    registercvar("pip_bg_pent_color", "0.5 0.2 0.2");
    registercommand("pip");
};

void() CSQC_WorldLoaded =
{
    if (!PipLoadItems()) {
        return;
    }

    camera_index = -1;
    camera_start = CAMERA_START_RESET;
    camera_start_transition = CAMERA_START_RESET;
    camera_end = CAMERA_END_RESET;
    camera_end_transition = CAMERA_END_RESET;

    deltalisten("progs/quaddama.mdl", PipPowerupSpawnListener, 1);
    deltalisten("progs/invulner.mdl", PipPowerupSpawnListener, 1);
};

void() CSQC_ServerInfoChanged =
{
    if (!PipGetCurrentItems() || match_start_time) {
        return;
    }

    string status = serverkey("status");
    if (!strcasecmp(status, "standby") || !strcasecmp(status, "countdown")) {
        return;
    }

    match_start_time = time;

    PipResetTimers(match_start_time);

    SelectNextCamera();
};

float(float x) easeInExpo =
{
    if (x == 0.0) {
        return 0.0;
    }
    return pow(2.0, 10.0 * x - 10.0);
};

void(float vwidth, float vheight, float notmenu) CSQC_UpdateView =
{
    clearscene();
    addentities(MASK_ENGINE | MASK_VIEWMODEL);
    setviewprop(VF_DRAWENGINESBAR, 1);
    setviewprop(VF_DRAWCROSSHAIR, 1);
    renderscene();

    if (time < camera_start) {
        SelectNextCamera();
        return;
    }

    if (!cvar("pip_enabled")) {
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

    setviewprop(VF_DRAWENGINESBAR, 0);
    setviewprop(VF_DRAWCROSSHAIR, 0);
    setviewprop(VF_VIEWENTITY, 0);
    setviewprop(VF_ORIGIN, item->camera->origin);
    setviewprop(VF_MIN_X, x_offset + slide_offset);
    setviewprop(VF_MIN_Y, margin);
    setviewprop(VF_SIZE_X, width);
    setviewprop(VF_SIZE_Y, height);
    setviewprop(VF_ANGLES, item->camera->angles);
    setviewprop(VF_FOV, '110 0 0');

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

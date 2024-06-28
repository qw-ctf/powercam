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

typedef struct {
    float entnum;
    float took;
    float respawn;
    float playernum;
    item_t *item;
} itemtimer_t;

itemtimer_t timers[MAX_POWERUPS];

itemtimer_t*() PipGetTimers =
{
    return timers;
};

itemtimer_t*(int index) PipGetTimer =
{
    itemtimer_t *timer = &timers[index];
    if (timer && !timer->item)
        return nil;
    return timer;
}

float(float isnew) PipPowerupSpawnListener =
{
    for (int i = 0; i < MAX_POWERUPS; i++) {
        itemtimer_t *timer = &timers[i];
        if (timer->entnum != self.entnum && timer->entnum > 0) {
            continue;
        }

        timer->entnum = self.entnum;

        if (!timer->item) {
            timer.item = PipFindItem(self.origin, self.modelindex);
            if (timer.item) {
                dprint("Associated timer via listener\n");
            }
        }

        break;
    }

    return isnew;
};

void(float timestamp) PipResetTimers =
{
    for (int i = 0; i < MAX_POWERUPS; i++) {
        itemtimer_t *timer = &timers[i];
        timer->respawn = timestamp;
    }
}

void(string msg) CSQC_Parse_StuffCmd =
{
    if (!PipGetCurrentItems())
        return;

    if (strncmp(msg, "//ktx took ", 10)) {
        return;
    }

    // //ktx took <entnum>(0) <delay>(1) <playernum>(2)
    msg = substring(msg, 11, -1);

    tokenize_console(msg);

    float delay = stof(argv(1));

    itemtype_t type = PipItemTypeByRespawnDelay(delay);

    // Lets assume standardized quad and pent respawn timers
    if (!(type == IT_QUAD || type == IT_PENT)) {
        return;
    }

    float entnum = stof(argv(0));
    float playernum = stof(argv(2));

    for (int i = 0; i < MAX_POWERUPS; i++) {
        itemtimer_t *timer = &timers[i];
        if (timer->entnum != 0 && entnum != timer->entnum) {
            continue;
        }

        if (!timer->item) {
            item_t *item = PipFindItemByEntity(entnum);
            if (!item) {
                dprint("ITEM NOT FOUND!\n");
                return;
            }
            timer->item = item;
            timer->entnum = entnum;
        }

        timer->respawn = time + delay;
        timer->took = time;
        timer->playernum = playernum;
        break;
    }
};

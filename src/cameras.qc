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

// Increase if any predefined map needs more.. "¯\_(ツ)_/¯"
#define MAX_POWERUPS 4

typedef struct {
        vector origin;
        vector angles;
} camera_t;

typedef struct {
    itemtype_t type;
    vector origin;
    camera_t camera;
} item_t;

// Defines to make the database somewhat of an embedded DSL.
#define origin(x) x
#define angles(x) x
#define camera(org, ang) { org, ang }
#define powerup(typ, org, cam) { typ, org, cam }
#define quad(org, cam) powerup(IT_QUAD, org, cam)
#define pent(org, cam) powerup(IT_PENT, org, cam)
#define map(name, ...) { name, { __VA_ARGS__ } }

struct {
    string name;
    item_t items[MAX_POWERUPS];
} database[] = {
    map("dm2",
        quad('1920 -704 184', camera(origin('1846 -585 355'), angles('71 0 0')))
    ),
    map("dm3",
        quad('952 296 56', camera(origin('986 316 91'), angles('27 225 0'))),
        pent('1008 800 -296', camera(origin('1239 664 113'), angles('51 139 0')))
    ),
    map("e1m2",
        quad('400 -1360 432', camera(origin('332 -1243 515'), angles('41 11 0')))
    ),
    map("e2m2",
        quad('-184 1512 144', camera(origin('-266 1582 172'), angles('23 322 0')))
    ),
    map("e2m5",
        quad('8 -416 -16', camera(origin('169 -210 100'), angles('27 227 0'))),
        quad('-32 2432 88', camera(origin('54 2432 191'), angles('22 180 0'))),
        pent('-320 1088 -423', camera(origin('-154 1005 -306'), angles('41 135 0')))
    ),
    map("e3m6",
        quad('32 -8 56', camera(origin('22 -131 93'), angles('33 40 0')))
    ),
    map("ctf5",
        quad('-672 1188 -496', camera(origin('-850 1188 -526'), angles('-22 360 0')))
    ),
    map("ctf8",
        quad('652 468 160', camera(origin('692 493 278'), angles('57 228 0')))
    ),
    map("ctf2m1",
        quad('160 -1584 -208', camera(origin('160 -1649 -33'), angles('69 90 0'))),
        pent('-296 -1584 -80', camera(origin('51 -1584 -118'), angles('-4 180 0')))
    ),
    map("ctf2m3",
        quad('803 -684 199', camera(origin('636 -684 271'), angles('28 360 0')))
    ),
    map("ztndm3",
        quad('-168 824 352', camera(origin('-200 856 411'), angles('45 253 0'))),
    ),
    map("schloss",
        quad('-216 -3344 456', camera(origin('-280 -3354 511'), angles('35 36 0'))),
        pent('352 -2152 264', camera(origin('453 -2170 361'), angles('42 228 0')))
    ),
    map("phantombase",
        quad('192 256 24', camera(origin('271 350 49'), angles('17 229 0'))),
        pent('-640 -256 24', camera(origin('-735 -333 58'), angles('23 39 0')))
    ),
    map("bravado",
        quad('752 24 288', camera(origin('820 -9 374'), angles('45 142 0')))
    ),
    map("shifter",
        quad('40 -24 168', camera(origin('81 -138 239'), angles('37 108 0')))
    ),
    map("catalyst",
        quad('836 14 235', camera(origin('748 -85 282'), angles('26 48 0')))
    ),
    map("ultrav",
        quad('608 -768 632', camera(origin('610 -772 716'), angles('90 1 0')))
    ),
};

#undef map
#undef pent
#undef quad
#undef powerup
#undef camera
#undef angles
#undef origin

var string mapname = "";
var item_t* active_items = nil;

float() PipLoadItems =
{
    for (int i = 0; i < database.length; i++) {
        if (database[i].name == mapname) {
            active_items = database[i].items;
            return 1;
        }
    }
    return 0;
};

item_t*() PipGetCurrentItems =
{
    if (!active_items)
        return nil;
    return active_items;
};

var int num_items = 0;

int() PipCountItems =
{
    if (!num_items) {
        item_t *items = PipGetCurrentItems();
        for (int i = 0; i < MAX_POWERUPS; i++) {
            item_t *item = &items[i];
            if (item.type == IT_NONE)
                break;
            num_items += 1;
        }
    }
    return num_items;
};

item_t*(vector origin, vector tolerance, itemtype_t expected_type) PipFindItemInternal =
{
    item_t *items = PipGetCurrentItems();
    if (!items)
        return nil;

    for (int i = 0; i < MAX_POWERUPS; i++) {
        item_t *item = &items[i];
        if (item.type == IT_NONE) {
            debug("Camera not found on map '%s'", mapname);
            break;
        }

        if (item.type != expected_type) {
            debug("Item model mismatch: %f != %f", item.type, expected_type);
            continue;
        }

        if (fabs(item.origin.x - origin.x) <= tolerance.x &&
            fabs(item.origin.y - origin.y) <= tolerance.y &&
            fabs(item.origin.z - origin.z) <= tolerance.z) {
            return item;
        } else {
            debug("x-delta: %f %f %f", item.origin.x, origin.x, fabs(item.origin.x - origin.x));
            debug("y-delta: %f %f %f", item.origin.y, origin.y, fabs(item.origin.y - origin.y));
            debug("z-delta: %f %f %f", item.origin.z, origin.z, fabs(item.origin.z - origin.z));
        }
    }

    // Fallback if map only has a single camera
    if (PipCountItems() == 1) {
        return &items[0];
    }

    return nil;
};

item_t*(vector org, float model_index) PipFindItem =
{
    if (org == '0 0 0') {
        debug("zero origin, skipping");
        return nil;
    }
    if (model_index == 0) {
        debug("zero type, skipping");
        return nil;
    }
    itemtype_t type = PipItemTypeByModelIndex(model_index);
    return PipFindItemInternal(org, '0 0 64', type);
};

item_t*(float entnum) PipFindItemByEntity =
{
    vector org = getentity(entnum, GE_ORIGIN);
    float model_index = getentity(entnum, GE_MODELINDEX);
    return PipFindItem(org, model_index);
};

item_t*(vector org, itemtype_t type) PipFindItemByPlayerOriginAndType =
{
    return PipFindItemInternal(org, '64 64 112', type);
}

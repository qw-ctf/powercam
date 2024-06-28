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

typedef enum {
    IT_NONE,
    IT_QUAD,
    IT_PENT,
} itemtype_t;

itemtype_t(float model_index) PipItemTypeByModelIndex =
{
    if (!model_index) {
        return IT_NONE;
    }

    string model_name = modelnameforindex(model_index);
    switch (model_name) {
    case "progs/quaddama.mdl":
        return IT_QUAD;
    case "progs/invulner.mdl":
        return IT_PENT;
    default:
        return IT_NONE;
    }
};

itemtype_t(string sound_name) PipItemTypeBySoundName =
{
    itemtype_t type = IT_NONE;
    switch (sound_name) {
    case "items/damage.wav":
        return IT_QUAD;
    case "items/protect.wav":
        return IT_PENT;
    default:
        return IT_NONE;
    }
};

itemtype_t(float respawn_delay) PipItemTypeByRespawnDelay =
{
    switch (respawn_delay) {
    case 60:
        return IT_QUAD;
    case 300:
        return IT_PENT;
    default:
        return IT_NONE;
    }
};

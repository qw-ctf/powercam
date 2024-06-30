Powerup Cameras CSQC Addon
==========================

This addon adds a picture-in-picture view for powerups based on KTX item
timers. If both a pentagram and quad artifact are close in spawn time, the
pentagram will be prioritized.

To match entities from both initial spawn origin, and entity number from
the `//ktx took` messages this project contains a database of common maps
keyed on origin. This origin is matched with some Z-tolerance as the items
are dropped to the ground on the map by the mod.

Contributing cameras
--------------------
The cameras are declared in `src/cameras.qc` via an eDSL to make it a bit
more accessible for non-programmers:

```
map("e2m5",
    quad('8 -416 -16', camera(origin('169 -210 100'), angles('27 227 0'))),
    quad('-32 2432 88', camera(origin('54 2432 191'), angles('22 180 0'))),
    pent('-320 1088 -423', camera(origin('-154 1005 -306'), angles('41 135 0')))
),
```

To contribute a new camera, the easiest way right now is to use a client
that supports `/viewpos`, for example [QSS-M](https://qssm.quakeone.com/).

Launch QSS-M, load the map, type `/noclip` and set `fov 110` as that's what
the camera uses. Then fly to the desired location and type `/viewpos copy`
to copy the position and angles into the clipboard which will look something
like this:

```
(610 -772 716) 90 1 0
```

The first triplet is camera position (origin), and the latter is camera angle.

To find the position of the powerup open up the .bsp in some editor and search
for `item_artifact_super_damage` (quad) and `item_artifact_invulnerability` (pent).

Alternatively run:
```bash
$ strings foo.bsp | grep -A 5 -B 5 item_artifact
```

In both cases there might be an origin field both above and below the so without
getting into technicals, just pick the one that looks closest to the origin of
your `/viewpos`.

If the powerup does not show up, then this is likely due to it being dropped
on the map. Try lowering the last value (Z) of the origin a bit and it ought
to pop up.

Configuration and commands
--------------------------

Configurations:
* `pip_enabled` - `0` or `1`.
* `pip_camera_intro` - Seconds before spawn to show camera.
* `pip_camera_outro` - Seconds until hide camera after pickup.
* `pip_camera_transition` - Seconds of camera transition, both in and out.
* `pip_bg_quad_color` - Background color if quad camera.
* `pip_bg_pent_color` - Background color if pent camera.

Commands:
* `pip` - Show available commands.
  * `active` - Current camera settings, and schedule.
  * `timers` - Tracked timers.

Compatibility
-------------
For the time being this addon only works with the
[hub.quakeworld.nu](https://hub.quakeworld.nu) fork of [FTE](https://www.fteqw.org).

The addon somewhat works when loaded in an official release of FTE, but due to
some bugs and limitations found during development there are currently some
issues with timers when seeking. Will work anywhere FTE runs later on.

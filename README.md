Powerup Cameras CSQC Addon
==========================

Here is a database of how to find items in the map. This dataset is keyed
on position, as the entity id is not known ahead of time.

Use for example QSS-M, load the map, type /noclip, set fov 110 as that's
what the camera uses. Then type /viewpos copy to copy the position into
the clipboard and paste into here.

You can find QSS-M here: https://qssm.quakeone.com/

To find the position of the powerup open up the .bsp in notepad and search
for "item_artifact" which will match both Quad and Pent.

Alternatively run:
```bash
$ strings foo.bsp | grep -A 5 -B 5 item_artifact"
```

In both cases there might be an origin field both above and below the so just
pick the one relevant one based on the camera origin you got from QSS-M.

As powerups are dropped to ground when spawned, the entity origin may have a
higher Z value than the actual in-game position if the mapper didn't place the
item exactly on the ground.

The code allows for some fuzz there, but if doesn't show up, then try lowering
the Z axis (last) value of the item origin.

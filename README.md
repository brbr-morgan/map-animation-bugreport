# Animated icons on a hidden map control make the main map stutter

A report for BYOND (Dream Seeker), found in ReiaMAX: an inventory's and a build palette's maps, hidden while another
tab was in front, made walking on the main map judder whenever they held an animated icon.

## The demo

Open `hidden_map_animation.dme` in Dream Maker, compile and run (1280 x 720; it can be maximised). Walk with the arrow
keys or WASD and watch the glide. It walks as ReiaMAX does: 50 fps, a view of 23 x 23 tiles of 16 pixels at 2x zoom,
`PIXEL_SCALE | LONG_GLIDE`, a step every 5 ticks with `glide_size` fitted to it, and held keys tried every tick from
`world.Tick()`. The small map in
the side panel (`map2`, a map control made at runtime) holds 100 screen objects with animated icons (`icons.dmi`: a
guard and a wizard, 2 frames each, 4 ticks apart).

1. With `map2` showing, walk: smooth.
2. **Hide map2** (`is-visible=false`), walk: the movement stutters and skips.
3. **Show map2**: smooth again. **+ 50 icons** / **- 50 icons** change how many it holds: the more animated icons on
   the hidden map, the worse the stutter.
4. **Use still icons** (1-frame crates), then hide map2 and walk: smooth.
5. **Remove map2** (the control deleted, the screen objects still on the client's screen, pointing at it): smooth.
6. **Remake map2** deletes and makes it again at once, to see the hitch making a map control costs. Remake and Make
   bring map2 back as it started: showing, full size, in its frame.
7. **Shrink to 1 px** and **Move out of sight** keep map2 switched on but out of view (1 x 1 pixel, or outside the
   window): whether a map that's on but unseen stutters too.

## The report

> **Animated icons on a hidden map control make the main map's movement stutter**
>
> A screen object with an animated icon state, on a secondary map control that's hidden (`is-visible=false`, or
> inside a child/pane that isn't showing), makes movement on the main map stutter: glides judder and skip frames
> for as long as the map is hidden. Showing the map again, removing the object from `client.screen`, deleting the
> map control, or giving the object a 1-frame icon state each stops it. A still icon on the hidden map doesn't do
> it. The more animated icons on the hidden map, the worse the stutter. Seen at 50 fps, `glide_size` fitted to a 5-tick step.
>
> It depends on the monitor's refresh rate: not noticeable at 60 Hz, faintly at 120–170 Hz, distracting at 360 Hz.
>
> Steps: run the attached demo, walk with the arrow keys, press Hide map2 and walk again.
>
> BYOND version: (yours) · Windows version: (yours) · GPU: (yours)

## What we saw first

In ReiaMAX the bag's and bank's maps (in a tab of a docked browser control, shown through child controls) and the
build palette's map stutter the main map while hidden, but only with a mob's animated icon on them; objects given a
mob's animated icon did it too. ReiaMAX works around it by keeping what's on a hidden map off the screen
(`docs/interface.md`, "No animated icons on a hidden map").

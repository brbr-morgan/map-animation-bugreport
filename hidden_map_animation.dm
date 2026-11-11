/*
	Animated icons on a hidden map control make the main map's movement stutter (Dream Seeker).

	Walk with the arrow keys or WASD and watch the glide. The small map in the side panel (map2) holds 100 animated icons.
	The panel's buttons:

	  Hide map2 / Show map2         map2's is-visible: walking stutters while it's hidden with an animated icon on it
	  Use a still icon / animated   the same with a still icon on map2: hiding it then makes no difference
	  Remove map2 / Make map2       deletes the control (the screen object stays, pointing at a map that isn't there)
	  Remake map2                   deletes and makes it again at once (the hitch of making a map), showing and full size
	  Shrink to 1 px                map2 switched on but 1 x 1 pixel: out of sight without being hidden
	  Move out of sight             map2 switched on but outside the window

	  - 50 icons / + 50 icons       how many icons map2 holds (100 to start): the stutter grows with them

	The icons (icons.dmi) are a few of ReiaMAX's demo art's: grass, a pine tree, the player, and on map2 a guard and
	a wizard (2 frames each, 4 ticks apart) or, still, a crate (1 frame).
*/

// Walking as ReiaMAX does it (its src/core/mob.dm and modules/keyboard): 50 fps, a step every move_delay (5 ticks)
// paced in whole ticks with the glide fitted to it. Held keys are stepped from world.Tick(), every tick.

world
	fps = 50
	icon_size = 16
	view = 11 // 23 x 23 tiles, at the map's 2x zoom
	maxx = 100
	maxy = 100
	turf = /turf/grass
	mob = /mob/walker
	movement_mode = TILE_MOVEMENT_MODE

atom
	appearance_flags = PIXEL_SCALE | LONG_GLIDE

turf/grass
	icon = 'icons.dmi'
	icon_state = "grass"

obj/scenery
	icon = 'icons.dmi'

// Trees to walk past, so the glide is easy to judge.
world/New()
	..()
	for(var/x in 1 to world.maxx)
		for(var/y in 1 to world.maxy)
			if(prob(12))
				var/obj/scenery/O = new(locate(x, y, 1))
				O.icon_state = "pinetree"

mob/walker
	icon = 'icons.dmi'
	icon_state = "player"
	pixel_y = 4
	var/move_delay = 1 // deciseconds: 5 ticks a step
	var/move_time      // the tick the next step is due

	Move()
		var/now = round(world.time / world.tick_lag, 1)
		var/ticks = max(1, -round(-move_delay / world.tick_lag + 0.01))
		if(now < move_time && move_time - now <= ticks) // a step not due yet
			return
		var/was = move_time
		if(now - move_time <= 1) // walking without a break
			move_time += ticks
		else
			move_time = now + ticks
		glide_size = world.icon_size / max(1, move_time - now)
		. = ..()
		if(!.)
			move_time = was

// Held keys: each movement key reports its press and release; while any is held, world.Tick() tries a step every tick.
var/list/walking_clients = list()

world/Tick()
	for(var/client/C as anything in walking_clients)
		C.StepHeld()

client
	var/move_keys = 0 // held: NORTH, SOUTH, EAST, WEST bits

	verb/move_key(dir as num, down as num)
		set name = "move-key"
		set instant = 1
		set hidden = 1
		if(!(dir in list(NORTH, SOUTH, EAST, WEST)))
			return
		if(down)
			move_keys |= dir
		else
			move_keys &= ~dir
		if(move_keys)
			walking_clients |= src
		else
			walking_clients -= src

	proc/StepHeld()
		var/d = move_keys
		if((d & NORTH) && (d & SOUTH))
			d &= ~(NORTH | SOUTH)
		if((d & EAST) && (d & WEST))
			d &= ~(EAST | WEST)
		if(d)
			Move(get_step(mob, d), d)

	Del()
		walking_clients -= src
		return ..()

obj/on_map2
	icon = 'icons.dmi'
	var/animated_state

var/list/animated_states = list("guard", "wizard")

client
	var/list/shown = list()
	var/still = FALSE
	var/map2_hidden = FALSE
	var/map2_removed = FALSE
	var/map2_parked // null, "tiny" (1 x 1 pixel) or "away" (outside the window): switched on, but out of sight

	New()
		. = ..()
		MakeMap2()
		SetIcons(100)
		mob.loc = locate(round(world.maxx / 2), round(world.maxy / 2), 1)
		Status("map2 showing, with [shown.len] animated icons.")

	// n icons on map2, 6 x 6 of them (the rest stacked on those).
	proc/SetIcons(n)
		n = clamp(n, 1, 1000)
		while(shown.len > n)
			screen -= shown[shown.len]
			shown.len--
		while(shown.len < n)
			var/obj/on_map2/O = new
			var/i = shown.len
			O.screen_loc = "map2:[i % 6 + 1],[round(i / 6) % 6 + 1]"
			O.animated_state = animated_states[i % animated_states.len + 1]
			O.icon_state = still ? "crate" : O.animated_state
			shown += O
			screen += O

	// Makes map2 if it isn't there, as it starts: showing, at full size, in its frame.
	proc/MakeMap2()
		map2_hidden = FALSE
		map2_parked = null
		map2_removed = FALSE
		Buttons()
		if(!winexists(src, "map2"))
			winset(src, "map2", "parent=mainwindow;type=map;anchor1=100,0;anchor2=100,0;zoom=1;background-color=#18181c")
		// Placed and shown every time, in case the old control was still there.
		winset(src, "map2", "[Map2Place()];is-visible=true")

	// Where map2 goes: inside its frame, wherever the frame is now (it keeps to the window's right edge), or parked.
	proc/Map2Place()
		var/list/at = splittext(winget(src, "map2_frame", "pos"), ",")
		var/x = at.len == 2 ? text2num(at[1]) + 4 : 1008
		var/y = at.len == 2 ? text2num(at[2]) + 4 : 44
		if(map2_parked == "tiny")
			return "pos=[x],[y];size=1x1"
		if(map2_parked == "away")
			return "pos=-2000,-2000;size=96x96"
		return "pos=[x],[y];size=96x96"

	proc/Park(how)
		map2_parked = map2_parked == how ? null : how
		if(winexists(src, "map2"))
			winset(src, "map2", Map2Place())
		Buttons()
		if(map2_parked == "tiny")
			Status("map2 shrunk to 1 pixel, still switched on. Walk: does it stutter?")
		else if(map2_parked == "away")
			Status("map2 moved outside the window, still switched on. Walk: does it stutter?")
		else
			Status("map2 back in its place.")

	proc/Buttons()
		winset(src, null, {"b_hide.text="[map2_hidden ? "Show map2" : "Hide map2"]";b_remove.text="[map2_removed ? "Make map2" : "Remove map2"]";b_tiny.text="[map2_parked == "tiny" ? "Full size" : "Shrink to 1 px"]";b_away.text="[map2_parked == "away" ? "Move back" : "Move out of sight"]""})

	proc/Status(text)
		winset(src, "status", "text=\"[text]\"")

	verb
		toggle_map2()
			set name = "toggle-map2"
			map2_hidden = !map2_hidden
			if(winexists(src, "map2"))
				winset(src, "map2", "is-visible=[map2_hidden ? "false" : "true"]")
			Buttons()
			Status(map2_hidden ? "map2 hidden. Walk: does it stutter?" : "map2 showing.")

		toggle_still()
			set name = "toggle-still"
			still = !still
			for(var/obj/on_map2/O in shown)
				O.icon_state = still ? "crate" : O.animated_state
			winset(src, "b_still", "text=\"[still ? "Use animated icons" : "Use still icons"]\"")
			Status("map2's [shown.len] icons: [still ? "crate" : "animated"].")

		more_icons()
			set name = "more-icons"
			SetIcons(shown.len == 1 ? 50 : shown.len + 50)
			Status("map2 holds [shown.len] [still ? "crate" : "animated"] icons.")

		fewer_icons()
			set name = "fewer-icons"
			SetIcons(shown.len - 50)
			Status("map2 holds [shown.len] [still ? "crate" : "animated"] icon[shown.len == 1 ? "" : "s"].")

		toggle_tiny()
			set name = "toggle-tiny"
			Park("tiny")

		toggle_away()
			set name = "toggle-away"
			Park("away")

		remake_map2()
			set name = "remake-map2"
			if(winexists(src, "map2"))
				winset(src, "map2", "parent=")
			MakeMap2()
			Status("map2 removed and made again at once, showing at full size. A hitch?")

		toggle_remove()
			set name = "toggle-remove"
			map2_removed = !map2_removed
			if(map2_removed)
				winset(src, "map2", "parent=")
				Buttons()
			else
				MakeMap2()
			Status(map2_removed ? "map2 removed (its screen objects kept)." : "map2 made again.")

/obj/effect/proc_holder/spell/targeted/projectile/magic_missile
	name = "Magic Missile"
	desc = "This spell fires several, slow moving, magic projectiles at nearby targets."

	school = "evocation"
	charge_max = 200
	clothes_req = TRUE
	invocation = "FORTI GY AMA"
	invocation_type = INVOCATION_SHOUT
	range = 7
	cooldown_min = 60 //35 deciseconds reduction per rank
	max_targets = 0
	proj_type = /obj/projectile/magic/spell/magic_missile
	action_icon_state = "magicm"
	sound = 'sound/magic/magic_missile.ogg'

/obj/projectile/magic/spell/magic_missile
	name = "magic missile"
	icon_state = "magicm"
	range = 20
	speed = 5
	trigger_range = 0
	linger = TRUE
	nodamage = FALSE
	paralyze = 60
	hitsound = 'sound/magic/mm_hit.ogg'

	trail = TRUE
	trail_lifespan = 5
	trail_icon_state = "magicmd"

/obj/projectile/magic/spell/magic_missile/on_hit(target)
	. = ..()
	if(ismob(target))
		var/mob/M = target
		if(M.anti_magic_check())
			M.visible_message(span_warning("[src] vanishes on contact with [target]!"))
			return BULLET_ACT_BLOCK

/obj/effect/proc_holder/spell/targeted/genetic/mutate
	name = "Mutate"
	desc = "This spell causes you to turn into a hulk and gain laser vision for a short while."

	school = "transmutation"
	charge_max = 400
	clothes_req = TRUE
	invocation = "BIRUZ BENNAR"
	invocation_type = INVOCATION_SHOUT
	range = -1
	include_user = TRUE

	mutations = list(LASEREYES, HULK)
	duration = 300
	cooldown_min = 300 //25 deciseconds reduction per rank

	action_icon_state = "mutate"
	sound = 'sound/magic/mutate.ogg'


/obj/effect/proc_holder/spell/targeted/smoke
	name = "Smoke"
	desc = "This spell spawns a cloud of choking smoke at your location."

	school = "conjuration"
	charge_max = 120
	clothes_req = FALSE
	invocation = "none"
	invocation_type = "none"
	range = -1
	include_user = TRUE
	cooldown_min = 20 //25 deciseconds reduction per rank

	smoke_spread = 2
	smoke_amt = 4

	action_icon_state = "smoke"


/obj/effect/proc_holder/spell/targeted/smoke/lesser //Chaplain smoke book
	name = "Smoke"
	desc = "This spell spawns a small cloud of choking smoke at your location."

	school = "conjuration"
	charge_max = 360
	clothes_req = FALSE
	invocation = "none"
	invocation_type = "none"
	range = -1
	include_user = TRUE

	smoke_spread = 1
	smoke_amt = 2

	action_icon_state = "smoke"

/obj/effect/proc_holder/spell/targeted/emplosion/disable_tech
	name = "Disable Tech"
	desc = "This spell disables all weapons, cameras and most other technology in range."
	charge_max = 400
	clothes_req = TRUE
	invocation = "NEC CANTIO"
	invocation_type = INVOCATION_SHOUT
	range = -1
	include_user = TRUE
	cooldown_min = 200 //50 deciseconds reduction per rank

	emp_heavy = 6
	emp_light = 10
	sound = 'sound/magic/disable_tech.ogg'

/obj/effect/proc_holder/spell/targeted/turf_teleport/blink
	name = "Blink"
	desc = "This spell randomly teleports you a short distance."

	school = "abjuration"
	charge_max = 20
	clothes_req = TRUE
	invocation = "none"
	invocation_type = "none"
	range = -1
	include_user = TRUE
	cooldown_min = 5 //4 deciseconds reduction per rank


	smoke_spread = 1
	smoke_amt = 0

	inner_tele_radius = 0
	outer_tele_radius = 6

	action_icon_state = "blink"
	sound1 = 'sound/magic/blink.ogg'
	sound2 = 'sound/magic/blink.ogg'

/obj/effect/proc_holder/spell/targeted/area_teleport/teleport
	name = "Teleport"
	desc = "This spell teleports you to an area of your selection."

	school = "abjuration"
	charge_max = 600
	clothes_req = TRUE
	invocation = "SCYAR NILA"
	invocation_type = INVOCATION_SHOUT
	range = -1
	include_user = TRUE
	cooldown_min = 200 //100 deciseconds reduction per rank
	action_icon_state = "teleport"

	smoke_spread = 1
	smoke_amt = 2
	sound1 = 'sound/magic/teleport_diss.ogg'
	sound2 = 'sound/magic/teleport_app.ogg'

/obj/effect/proc_holder/spell/targeted/area_teleport/teleport/santa
	name = "Santa Teleport"

	invocation = "HO HO HO"
	clothes_req = FALSE
	say_destination = FALSE // Santa moves in mysterious ways

/obj/effect/proc_holder/spell/aoe_turf/timestop
	name = "Stop Time"
	desc = "This spell stops time for everyone except for you, allowing you to move freely while your enemies and even projectiles are frozen."
	charge_max = 500
	clothes_req = TRUE
	invocation = "TOKI YO TOMARE"
	invocation_type = INVOCATION_SHOUT
	range = 0
	cooldown_min = 100
	action_icon_state = "time"
	var/timestop_range = 2
	var/timestop_duration = 100

/obj/effect/proc_holder/spell/aoe_turf/timestop/cast(list/targets, mob/user = usr)
	new /obj/effect/timestop/magic(get_turf(user), timestop_range, timestop_duration, list(user))

/obj/effect/proc_holder/spell/aoe_turf/conjure/carp
	name = "Summon Carp"
	desc = "This spell conjures a simple carp."

	school = "conjuration"
	charge_max = 1200
	clothes_req = TRUE
	invocation = "NOUK FHUNMM SACP RISSKA"
	invocation_type = INVOCATION_SHOUT
	range = 1

	summon_type = list(/mob/living/simple_animal/hostile/carp)
	cast_sound = 'sound/magic/summon_karp.ogg'

/obj/effect/proc_holder/spell/aoe_turf/conjure/creature
	name = "Summon Creature Swarm"
	desc = "This spell tears the fabric of reality, allowing horrific daemons to spill forth."

	school = "conjuration"
	charge_max = 1200
	clothes_req = FALSE
	invocation = "IA IA"
	invocation_type = INVOCATION_SHOUT
	summon_amt = 10
	range = 3

	summon_type = list(/mob/living/simple_animal/hostile/netherworld)
	cast_sound = 'sound/magic/summonitems_generic.ogg'

/obj/effect/proc_holder/spell/aoe_turf/repulse
	name = "Repulse"
	desc = "This spell throws everything around the user away."
	charge_max = 400
	clothes_req = TRUE
	invocation = "GITTAH WEIGH"
	invocation_type = INVOCATION_SHOUT
	range = 5
	cooldown_min = 150
	selection_type = "view"
	sound = 'sound/magic/repulse.ogg'
	var/maxthrow = 5
	var/sparkle_path = /obj/effect/temp_visual/gravpush
	var/repulse_force = MOVE_FORCE_EXTREMELY_STRONG
	var/stun_amt = 5
	action_icon_state = "repulse"

/obj/effect/proc_holder/spell/aoe_turf/repulse/cast(list/hit_turfs, mob/user = usr)
	var/list/thrownatoms = list()
	var/distfromcaster
	playMagSound()

	for(var/turf/T in hit_turfs)
		for(var/atom/movable/hit_target in T.contents)
			thrownatoms += hit_target

	for(var/thrown_atom in thrownatoms)
		if(!ismovable(thrown_atom))
			continue
		var/atom/movable/AM = thrown_atom
		if(AM == user || AM.anchored)
			continue
		var/atom/throwtarget = get_edge_target_turf(user, get_dir(user, get_step_away(AM, user)))
		new sparkle_path(get_turf(AM), get_dir(user, AM)) //created sparkles will disappear on their own
		if(isliving(AM))
			var/mob/living/M = AM
			shake_camera(AM, 2, 1)
			if(stun_amt)
				M.Paralyze(stun_amt)
			to_chat(M, span_userdanger("You're thrown back by [user]!"))
		AM.safe_throw_at(throwtarget, ((clamp((maxthrow - (clamp(distfromcaster - 2, 0, distfromcaster))), 3, maxthrow))), 1,user, force = repulse_force)//So stuff gets tossed around at the same time.

/obj/effect/proc_holder/spell/aoe_turf/repulse/xeno //i fixed conflicts only to find out that this is in the WIZARD file instead of the xeno file?!
	name = "Tail Sweep"
	desc = "Throw back attackers with a sweep of your tail."
	sound = 'sound/magic/tail_swing.ogg'
	charge_max = 150
	clothes_req = FALSE
	antimagic_allowed = TRUE
	range = 2
	cooldown_min = 150
	invocation_type = "none"
	sparkle_path = /obj/effect/temp_visual/dir_setting/tailsweep
	action_icon = 'icons/mob/actions/actions_xeno.dmi'
	action_icon_state = "tailsweep"
	action_background_icon_state = "bg_alien"
	stun_amt = 0

/obj/effect/proc_holder/spell/aoe_turf/repulse/xeno/cast(list/targets,mob/user = usr)
	if(iscarbon(user))
		var/mob/living/carbon/C = user
		playsound(C.loc, 'sound/voice/hiss5.ogg', 80, TRUE, TRUE)
		C.spin(6,1)
	..(targets, user, 60)

/obj/effect/proc_holder/spell/targeted/sacred_flame
	name = "Sacred Flame"
	desc = "Makes everyone around you more flammable, and lights yourself on fire."
	charge_max = 60
	clothes_req = FALSE
	invocation = "FI'RAN DADISKO"
	invocation_type = INVOCATION_SHOUT
	max_targets = 0
	range = 6
	include_user = TRUE
	selection_type = "view"
	action_icon_state = "sacredflame"
	sound = 'sound/magic/fireball.ogg'

/obj/effect/proc_holder/spell/targeted/sacred_flame/cast(list/targets, mob/user = usr)
	for(var/mob/living/L in targets)
		if(L.anti_magic_check(TRUE, TRUE))
			continue
		L.adjust_fire_stacks(20)
	if(isliving(user))
		var/mob/living/U = user
		if(!U.anti_magic_check(TRUE, TRUE))
			U.IgniteMob()

/obj/effect/proc_holder/spell/targeted/conjure_item/spellpacket
	name = "Thrown Lightning"
	desc = "Forged from eldrich energies, a packet of pure power, known as a spell packet will appear in your hand, that when thrown will stun the target."
	clothes_req = TRUE
	item_type = /obj/item/spellpacket/lightningbolt
	charge_max = 10
	action_icon_state = "thrownlightning"

/obj/effect/proc_holder/spell/targeted/conjure_item/spellpacket/cast(list/targets, mob/user = usr)
	..()
	for(var/mob/living/carbon/C in targets)
		C.throw_mode_on(THROW_MODE_TOGGLE)

/obj/item/spellpacket/lightningbolt
	name = "\improper Lightning bolt Spell Packet"
	desc = "Some birdseed wrapped in cloth that crackles with electricity."
	icon = 'icons/obj/toy.dmi'
	icon_state = "snappop"
	w_class = WEIGHT_CLASS_TINY

/obj/item/spellpacket/lightningbolt/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(!..())
		if(isliving(hit_atom))
			var/mob/living/M = hit_atom
			if(!M.anti_magic_check())
				M.electrocute_act(80, src, flags = SHOCK_ILLUSION)
		qdel(src)

/obj/item/spellpacket/lightningbolt/throw_at(atom/target, range, speed, mob/thrower, spin=TRUE, diagonals_first = FALSE, datum/callback/callback, force = INFINITY, quickstart = TRUE)
	. = ..()
	if(ishuman(thrower))
		var/mob/living/carbon/human/H = thrower
		H.say("LIGHTNINGBOLT!!", forced = "spell")

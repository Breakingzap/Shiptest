/*
	This component is responsible for handling individual instances of embedded objects. The embeddable element is what allows an item to be embeddable and stores its embedding stats,
	and when it impacts and meets the requirements to stick into something, it instantiates an embedded component. Once the item falls out, the component is destroyed, while the
	element survives to embed another day.

	There are 2 different things that can be embedded presently: carbons, and closed turfs (see: walls)

		- Carbon embedding has all the classical embedding behavior, and tracks more events and signals. The main behaviors and hooks to look for are:
			-- Every process tick, there is a chance to randomly proc pain, controlled by pain_chance. There may also be a chance for the object to fall out randomly, per fall_chance
			-- Every time the mob moves, there is a chance to proc jostling pain, controlled by jostle_chance (and only 50% as likely if the mob is walking or crawling)
			-- Various signals hooking into carbon topic() and the embed removal surgery in order to handle removals.

		- Turf embedding is much simpler. All we do here is draw an overlay of the item's inhand on the turf, hide the item, and create an HTML link in the turf's inspect
		that allows you to rip the item out. There's nothing dynamic about this, so far less checks.


	In addition, there are 2 cases of embedding: embedding, and sticking

		- Embedding involves harmful and dangerous embeds, whether they cause brute damage, stamina damage, or a mix. This is the default behavior for embeddings, for when something is "pointy"

		- Sticking occurs when an item should not cause any harm while embedding (imagine throwing a sticky ball of tape at someone, rather than a shuriken). An item is considered "sticky"
			when it has 0 for both pain multiplier and jostle pain multiplier. It's a bit arbitrary, but fairly straightforward.

		Stickables differ from embeds in the following ways:
			-- Text descriptors use phrasing like "X is stuck to Y" rather than "X is embedded in Y"
			-- There is no slicing sound on impact
			-- All damage checks and bloodloss are skipped for carbons
			-- Pointy objects create sparks when embedding into a turf

*/


/datum/component/embedded
	dupe_mode = COMPONENT_DUPE_ALLOWED
	var/obj/item/bodypart/limb
	var/obj/item/weapon

	// all of this stuff is explained in _DEFINES/combat.dm
	var/embed_chance // not like we really need it once we're already stuck in but hey
	var/fall_chance
	var/pain_chance
	var/pain_mult
	var/impact_pain_mult
	var/remove_pain_mult
	var/rip_time
	var/ignore_throwspeed_threshold
	var/jostle_chance
	var/jostle_pain_mult
	var/pain_stam_pct
	var/embed_chance_turf_mod

	///if both our pain multiplier and jostle pain multiplier are 0, we're harmless and can omit most of the damage related stuff
	var/harmful
	var/mutable_appearance/overlay

/datum/component/embedded/Initialize(obj/item/I,
			datum/thrownthing/throwingdatum,
			obj/item/bodypart/part,
			embed_chance = EMBED_CHANCE,
			fall_chance = EMBEDDED_ITEM_FALLOUT,
			pain_chance = EMBEDDED_PAIN_CHANCE,
			pain_mult = EMBEDDED_PAIN_MULTIPLIER,
			remove_pain_mult = EMBEDDED_UNSAFE_REMOVAL_PAIN_MULTIPLIER,
			impact_pain_mult = EMBEDDED_IMPACT_PAIN_MULTIPLIER,
			rip_time = EMBEDDED_UNSAFE_REMOVAL_TIME,
			ignore_throwspeed_threshold = FALSE,
			jostle_chance = EMBEDDED_JOSTLE_CHANCE,
			jostle_pain_mult = EMBEDDED_JOSTLE_PAIN_MULTIPLIER,
			pain_stam_pct = EMBEDDED_PAIN_STAM_PCT,
			embed_chance_turf_mod = EMBED_CHANCE_TURF_MOD)

	if((!iscarbon(parent) && !isclosedturf(parent)) || !isitem(I))
		return COMPONENT_INCOMPATIBLE

	if(part)
		limb = part
	src.embed_chance = embed_chance
	src.fall_chance = fall_chance
	src.pain_chance = pain_chance
	src.pain_mult = pain_mult
	src.remove_pain_mult = remove_pain_mult
	src.rip_time = rip_time
	src.impact_pain_mult = impact_pain_mult
	src.ignore_throwspeed_threshold = ignore_throwspeed_threshold
	src.jostle_chance = jostle_chance
	src.jostle_pain_mult = jostle_pain_mult
	src.pain_stam_pct = pain_stam_pct
	src.embed_chance_turf_mod = embed_chance_turf_mod

	src.weapon = I

	if(!weapon.isEmbedHarmless())
		harmful = TRUE

	if(iscarbon(parent))
		initCarbon()
	else if(isclosedturf(parent))
		initTurf(throwingdatum)

/datum/component/embedded/RegisterWithParent()
	if(iscarbon(parent))
		RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(jostleCheck))
		RegisterSignal(parent, COMSIG_CARBON_EMBED_RIP, PROC_REF(ripOutCarbon))
		RegisterSignal(parent, COMSIG_CARBON_EMBED_REMOVAL, PROC_REF(safeRemoveCarbon))
		RegisterSignal(parent, COMSIG_PARENT_ATTACKBY, PROC_REF(check_tweeze))
	else if(isclosedturf(parent))
		RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(examineTurf))
		RegisterSignal(parent, COMSIG_PARENT_QDELETING, PROC_REF(itemMoved))

/datum/component/embedded/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_MOVABLE_MOVED, COMSIG_CARBON_EMBED_RIP, COMSIG_CARBON_EMBED_REMOVAL, COMSIG_PARENT_EXAMINE, COMSIG_PARENT_ATTACKBY))

/datum/component/embedded/process(seconds_per_tick)
	if(iscarbon(parent))
		processCarbon(seconds_per_tick)

/datum/component/embedded/Destroy()
	if(weapon)
		UnregisterSignal(weapon, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))
	if(overlay)
		var/atom/A = parent
		UnregisterSignal(A,COMSIG_ATOM_UPDATE_OVERLAYS)
		qdel(overlay)

	return ..()

////////////////////////////////////////
/////////////HUMAN PROCS////////////////
////////////////////////////////////////

/// Set up an instance of embedding for a carbon. This is basically an extension of Initialize() so not much to say
/datum/component/embedded/proc/initCarbon()
	START_PROCESSING(SSdcs, src)
	var/mob/living/carbon/victim = parent
	if(!istype(limb))
		limb = pick(victim.bodyparts)

	limb.embedded_objects |= weapon // on the inside... on the inside...
	weapon.forceMove(victim)
	RegisterSignals(weapon, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING), PROC_REF(byeItemCarbon))

	if(harmful)
		victim.visible_message(span_danger("[weapon] embeds itself in [victim]'s [limb.name]!"),ignored_mobs=victim)
		to_chat(victim, span_userdanger("[weapon] embeds itself in your [limb.name]!"))
		victim.throw_alert("embeddedobject", /atom/movable/screen/alert/embeddedobject)
		playsound(victim,'sound/weapons/bladeslice.ogg', 40)
		weapon.add_mob_blood(victim)//it embedded itself in you, of course it's bloody!
		var/damage = weapon.w_class * impact_pain_mult
		limb.receive_damage(brute=(1-pain_stam_pct) * damage, stamina=pain_stam_pct * damage)
		SEND_SIGNAL(victim, COMSIG_ADD_MOOD_EVENT, "embedded", /datum/mood_event/embedded)
	else
		victim.visible_message(span_danger("[weapon] sticks itself to [victim]'s [limb.name]!"),ignored_mobs=victim)
		to_chat(victim, span_userdanger("[weapon] sticks itself to your [limb.name]!"))

/// Called every time a carbon with a harmful embed moves, rolling a chance for the item to cause pain. The chance is halved if the carbon is crawling or walking.
/datum/component/embedded/proc/jostleCheck()
	SIGNAL_HANDLER

	var/mob/living/carbon/victim = parent

	var/chance = jostle_chance
	if(victim.m_intent == MOVE_INTENT_WALK || victim.body_position == LYING_DOWN)
		chance *= 0.5

	if(harmful && prob(chance))
		var/damage = weapon.w_class * jostle_pain_mult
		limb.receive_damage(brute=(1-pain_stam_pct) * damage, stamina=pain_stam_pct * damage)
		if(HAS_TRAIT(victim, TRAIT_ANALGESIA))
			to_chat(victim, span_notice("[weapon] embedded in your [limb.name] shifts around."))
			return
		to_chat(victim, span_userdanger("[weapon] embedded in your [limb.name] jostles and stings!"))


/// Called when then item randomly falls out of a carbon. This handles the damage and descriptors, then calls safe_remove()
/datum/component/embedded/proc/fallOutCarbon()
	var/mob/living/carbon/victim = parent

	if(harmful)
		var/damage = weapon.w_class * remove_pain_mult
		limb.receive_damage(brute=(1-pain_stam_pct) * damage, stamina=pain_stam_pct * damage)
		victim.visible_message(span_danger("[weapon] falls out of [victim.name]'s [limb.name]!"), ignored_mobs=victim)
		to_chat(victim, span_userdanger("[weapon] falls out of your [limb.name]!"))
	else
		victim.visible_message(span_danger("[weapon] falls off of [victim.name]'s [limb.name]!"), ignored_mobs=victim)
		to_chat(victim, span_userdanger("[weapon] falls off of your [limb.name]!"))

	safeRemoveCarbon()


/// Called when a carbon with an object embedded/stuck to them inspects themselves and clicks the appropriate link to begin ripping the item out. This handles the ripping attempt, descriptors, and dealing damage, then calls safe_remove()
/datum/component/embedded/proc/ripOutCarbon(datum/source, obj/item/I, obj/item/bodypart/limb)
	SIGNAL_HANDLER

	if(I != weapon || src.limb != limb)
		return

	var/mob/living/carbon/victim = parent
	var/time_taken = rip_time * weapon.w_class
	INVOKE_ASYNC(src, PROC_REF(complete_rip_out), victim, I, limb, time_taken)

/// everything async that ripOut used to do
/datum/component/embedded/proc/complete_rip_out(mob/living/carbon/victim, obj/item/I, obj/item/bodypart/limb, time_taken)
	victim.visible_message(span_warning("[victim] attempts to remove [weapon] from [victim.p_their()] [limb.name]."),span_notice("You attempt to remove [weapon] from your [limb.name]... (It will take [DisplayTimeText(time_taken)].)"))
	if(do_after(victim, time_taken, target = victim))
		if(!weapon || !limb || weapon.loc != victim || !(weapon in limb.embedded_objects))
			qdel(src)
			return

		if(harmful)
			var/damage = weapon.w_class * remove_pain_mult
			limb.receive_damage(brute=(1-pain_stam_pct) * damage, stamina=pain_stam_pct * damage) //It hurts to rip it out, get surgery you dingus.
			victim.force_scream()
			victim.visible_message(span_notice("[victim] successfully rips [weapon] out of [victim.p_their()] [limb.name]!"), span_notice("You successfully remove [weapon] from your [limb.name]."))
		else
			victim.visible_message(span_notice("[victim] successfully rips [weapon] off of [victim.p_their()] [limb.name]!"), span_notice("You successfully remove [weapon] from your [limb.name]."))

		safeRemoveCarbon(TRUE)


/// This proc handles the final step and actual removal of an embedded/stuck item from a carbon, whether or not it was actually removed safely.
/// Pass TRUE for to_hands if we want it to go to the victim's hands when they pull it out
/datum/component/embedded/proc/safeRemoveCarbon(mob/to_hands)
	SIGNAL_HANDLER

	var/mob/living/carbon/victim = parent
	limb.embedded_objects -= weapon

	UnregisterSignal(weapon, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING)) // have to unhook these here so they don't also register as having disappeared

	if(!weapon)
		if(!victim.has_embedded_objects())
			victim.clear_alert("embeddedobject")
			SEND_SIGNAL(victim, COMSIG_CLEAR_MOOD_EVENT, "embedded")
		qdel(src)
		return

	if(weapon.unembedded()) // if it deleted itself
		weapon = null
		if(!victim.has_embedded_objects())
			victim.clear_alert("embeddedobject")
			SEND_SIGNAL(victim, COMSIG_CLEAR_MOOD_EVENT, "embedded")
		qdel(src)
		return

	if(to_hands)
		INVOKE_ASYNC(to_hands, TYPE_PROC_REF(/mob, put_in_hands), weapon)
	else
		weapon.forceMove(get_turf(victim))

	if(!victim.has_embedded_objects())
		victim.clear_alert("embeddedobject")
		SEND_SIGNAL(victim, COMSIG_CLEAR_MOOD_EVENT, "embedded")
	qdel(src)


/// Something deleted or moved our weapon while it was embedded, how rude!
/datum/component/embedded/proc/byeItemCarbon()
	SIGNAL_HANDLER

	var/mob/living/carbon/victim = parent
	limb.embedded_objects -= weapon
	UnregisterSignal(weapon, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))

	if(victim)
		to_chat(victim, span_userdanger("\The [weapon] that was embedded in your [limb.name] disappears!"))
		if(!victim.has_embedded_objects())
			victim.clear_alert("embeddedobject")
			SEND_SIGNAL(victim, COMSIG_CLEAR_MOOD_EVENT, "embedded")
	weapon = null
	qdel(src)


/// Items embedded/stuck to carbons both check whether they randomly fall out (if applicable), as well as if the target mob and limb still exists.
/// Items harmfully embedded in carbons have an additional check for random pain (if applicable)
/datum/component/embedded/proc/processCarbon(seconds_per_tick)
	var/mob/living/carbon/victim = parent

	if(!victim || !limb) // in case the victim and/or their limbs exploded (say, due to a sticky bomb)
		weapon.forceMove(get_turf(weapon))
		qdel(src)

	if(victim.stat == DEAD)
		return

	var/damage = weapon.w_class * pain_mult
	var/chance = SPT_PROB_RATE(pain_chance / 100, seconds_per_tick) * 100
	if(pain_stam_pct && HAS_TRAIT_FROM(victim, TRAIT_INCAPACITATED, STAMINA)) //if it's a less-lethal embed, give them a break if they're already stamcritted
		chance *= 0.3
		damage *= 0.7

	if(harmful && prob(chance))
		limb.receive_damage(brute=(1-pain_stam_pct) * damage, stamina=pain_stam_pct * damage)
		to_chat(victim, span_userdanger("[weapon] embedded in your [limb.name] hurts!"))

	var/fall_chance_current = SPT_PROB_RATE(fall_chance / 100, seconds_per_tick) * 100

	if(prob(fall_chance_current))
		fallOutCarbon()

/// The signal for listening to see if someone is using a hemostat on us to pluck out this object
/datum/component/embedded/proc/check_tweeze(mob/living/carbon/victim, obj/item/possible_tweezers, mob/user)
	SIGNAL_HANDLER

	if(!istype(victim) || possible_tweezers.tool_behaviour != TOOL_HEMOSTAT || user.zone_selected != limb.body_zone)
		return

	if(weapon != limb.embedded_objects[1]) // just pluck the first one, since we can't easily coordinate with other embedded components affecting this limb who is highest priority
		return

	if(ishuman(victim)) // check to see if the limb is actually exposed
		var/mob/living/carbon/human/victim_human = victim
		if(!victim_human.can_inject(user, TRUE, limb.body_zone))
			return TRUE

	INVOKE_ASYNC(src, PROC_REF(tweeze_pluck), possible_tweezers, user)
	return COMPONENT_NO_AFTERATTACK

/// The actual action for pulling out an embedded object with a hemostat
/datum/component/embedded/proc/tweeze_pluck(obj/item/possible_tweezers, mob/user)
	var/mob/living/carbon/victim = parent

	var/self_pluck = (user == victim)

	if(self_pluck)
		user.visible_message(
			span_warning("[user] begins plucking [weapon] from [user.p_their()] [limb.name]"),
			span_notice("You start plucking [weapon] from your [limb.name]..."),
			vision_distance=COMBAT_MESSAGE_RANGE,
			ignored_mobs=victim
			)
	else
		user.visible_message(
			span_warning("[user] begins plucking [weapon] from [victim]'s [limb.name]"),
			span_notice("You start plucking [weapon] from [victim]'s [limb.name]..."),
			vision_distance=COMBAT_MESSAGE_RANGE,
			ignored_mobs=victim
			)
		to_chat(victim, span_warning("[user] begins plucking [weapon] from your [limb.name]..."))

	var/pluck_time = 1.5 SECONDS * weapon.w_class * (self_pluck ? 2 : 1)
	if(!do_after(user, pluck_time, victim))
		if(self_pluck)
			to_chat(user, span_warning("You fail to pluck [weapon] from your [limb.name]."))
		else
			to_chat(user, span_warning("You fail to pluck [weapon] from [victim]'s [limb.name]."))
			to_chat(victim, span_warning("[user] fails to pluck [weapon] from your [limb.name]."))
		return

	to_chat(user, span_warning("You successfully pluck [weapon] from [victim]'s [limb.name]."))
	to_chat(victim, span_warning("[user] plucks [weapon] from your [limb.name]."))
	safeRemoveCarbon(user)

////////////////////////////////////////
//////////////TURF PROCS////////////////
////////////////////////////////////////

/// Turfs are much lower maintenance, since we don't care if they're in pain, but since they don't bleed or scream, we draw an overlay to show their status.
/// The only difference pointy/sticky items make here is text descriptors and pointy objects making a spark shower on impact.
/datum/component/embedded/proc/initTurf(datum/thrownthing/throwingdatum)
	var/turf/closed/hit = parent

	// we can't store the item IN the turf (cause turfs are just kinda... there), so we fake it by making the item invisible and bailing if it moves due to a blast
	weapon.forceMove(hit)
	weapon.invisibility = INVISIBILITY_ABSTRACT
	RegisterSignal(weapon, COMSIG_MOVABLE_MOVED, PROC_REF(itemMoved))

	var/pixelX = rand(-2, 2)
	var/pixelY = rand(-1, 3) // bias this upwards since in-hands are usually on the lower end of the sprite

	switch(throwingdatum.init_dir)
		if(NORTH)
			pixelY -= 2
		if(SOUTH)
			pixelY += 2
		if(WEST)
			pixelX += 2
		if(EAST)
			pixelX -= 2

	if(throwingdatum.init_dir in list(NORTH,  WEST, NORTHWEST, SOUTHWEST))
		overlay = mutable_appearance(icon=weapon.righthand_file,icon_state=weapon.item_state)
	else
		overlay = mutable_appearance(icon=weapon.lefthand_file,icon_state=weapon.item_state)

	var/matrix/M = matrix()
	M.Translate(pixelX, pixelY)
	overlay.transform = M
	RegisterSignal(hit,COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(apply_overlay))
	hit.update_appearance()

	if(harmful)
		hit.visible_message(span_danger("[weapon] embeds itself in [hit]!"))
		playsound(hit,'sound/weapons/bladeslice.ogg', 70)

		var/datum/effect_system/spark_spread/sparks = new
		sparks.set_up(1, 1, parent)
		sparks.attach(parent)
		sparks.start()
	else
		hit.visible_message(span_danger("[weapon] sticks itself to [hit]!"))

/datum/component/embedded/proc/apply_overlay(atom/source, list/overlay_list)
	overlay_list += overlay

/datum/component/embedded/proc/examineTurf(datum/source, mob/user, list/examine_list)
	if(harmful)
		examine_list += "\t <a href='byond://?src=[REF(src)];embedded_object=[REF(weapon)]' class='warning'>There is \a [weapon] embedded in [parent]!</a>"
	else
		examine_list += "\t <a href='byond://?src=[REF(src)];embedded_object=[REF(weapon)]' class='warning'>There is \a [weapon] stuck to [parent]!</a>"


/// Someone is ripping out the item from the turf by hand
/datum/component/embedded/Topic(datum/source, href_list)
	var/mob/living/us = usr
	if(in_range(us, parent) && locate(href_list["embedded_object"]) == weapon)
		if(harmful)
			us.visible_message(span_notice("[us] begins unwedging [weapon] from [parent]."), span_notice("You begin unwedging [weapon] from [parent]..."))
		else
			us.visible_message(span_notice("[us] begins unsticking [weapon] from [parent]."), span_notice("You begin unsticking [weapon] from [parent]..."))

		if(do_after(us, 30, target = parent))
			us.put_in_hands(weapon)
			weapon.unembedded()
			qdel(src)


/// This proc handles if something knocked the invisible item loose from the turf somehow (probably an explosion). Just make it visible and say it fell loose, then get outta here.
/datum/component/embedded/proc/itemMoved()
	weapon.invisibility = initial(weapon.invisibility)
	weapon.visible_message(span_notice("[weapon] falls loose from [parent]."))
	weapon.unembedded()
	qdel(src)

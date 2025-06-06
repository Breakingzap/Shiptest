/datum/component/plumbing
	///Index with "1" = /datum/ductnet/theductpointingnorth etc. "1" being the num2text from NORTH define
	var/list/datum/ductnet/ducts = list()
	///shortcut to our parents' reagent holder
	var/datum/reagents/reagents
	///TRUE if we wanna add proper pipe overlays under our parent object. this is pretty good if i may so so myself
	var/use_overlays = TRUE
	///Whether our tile is covered and we should hide our ducts
	var/tile_covered = FALSE
	///directions in wich we act as a supplier
	var/supply_connects
	///direction in wich we act as a demander
	var/demand_connects
	///FALSE to pretty much just not exist in the plumbing world so we can be moved, TRUE to go plumbo mode
	var/active = FALSE
	///if TRUE connects will spin with the parent object visually and codually, so you can have it work in any direction. FALSE if you want it to be static
	var/turn_connects = TRUE

/datum/component/plumbing/Initialize(start=TRUE, _turn_connects=TRUE) //turn_connects for wheter or not we spin with the object to change our pipes
	if(!ismovable(parent))
		return COMPONENT_INCOMPATIBLE

	var/atom/movable/AM = parent
	if(!AM.reagents)
		return COMPONENT_INCOMPATIBLE
	reagents = AM.reagents
	turn_connects = _turn_connects

	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_parent_moved))
	RegisterSignal(parent, COMSIG_PARENT_PREQDELETED, PROC_REF(disable))
	RegisterSignal(parent, COMSIG_OBJ_DEFAULT_UNFASTEN_WRENCH, PROC_REF(toggle_active))
	RegisterSignal(parent, COMSIG_OBJ_HIDE, PROC_REF(hide))
	RegisterSignal(parent, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(create_overlays)) //called by lateinit on startup

	if(start)
		//timer 0 so it can finish returning initialize, after which we're added to the parent.
		//Only then can we tell the duct next to us they can connect, because only then is the component really added. this was a fun one
		addtimer(CALLBACK(src, PROC_REF(enable)), 0)

/datum/component/plumbing/process(seconds_per_tick)
	if(!demand_connects || !reagents)
		STOP_PROCESSING(SSfluids, src)
		return
	if(reagents.total_volume < reagents.maximum_volume)
		for(var/D in GLOB.cardinals)
			if(D & demand_connects)
				send_request(D)

///Can we be added to the ductnet?
/datum/component/plumbing/proc/can_add(datum/ductnet/D, dir)
	if(!active)
		return
	if(!dir || !D)
		return FALSE
	if(num2text(dir) in ducts)
		return FALSE

	return TRUE

///called from in process(). only calls process_request(), but can be overwritten for children with special behaviour
/datum/component/plumbing/proc/send_request(dir)
	process_request(amount = MACHINE_REAGENT_TRANSFER, reagent = null, dir = dir)

///check who can give us what we want, and how many each of them will give us
/datum/component/plumbing/proc/process_request(amount, reagent, dir)
	var/list/valid_suppliers = list()
	var/datum/ductnet/net
	if(!ducts.Find(num2text(dir)))
		return
	net = ducts[num2text(dir)]
	for(var/A in net.suppliers)
		var/datum/component/plumbing/supplier = A
		if(supplier.can_give(amount, reagent, net))
			valid_suppliers += supplier
	for(var/A in valid_suppliers)
		var/datum/component/plumbing/give = A
		give.transfer_to(src, amount / valid_suppliers.len, reagent, net)

///returns TRUE when they can give the specified amount and reagent. called by process request
/datum/component/plumbing/proc/can_give(amount, reagent, datum/ductnet/net)
	if(amount <= 0)
		return

	if(reagent) //only asked for one type of reagent
		for(var/A in reagents.reagent_list)
			var/datum/reagent/R = A
			if(R.type == reagent)
				return TRUE
	else if(reagents.total_volume > 0) //take whatever
		return TRUE

///this is where the reagent is actually transferred and is thus the finish point of our process()
/datum/component/plumbing/proc/transfer_to(datum/component/plumbing/target, amount, reagent, datum/ductnet/net)
	if(!reagents || !target || !target.reagents)
		return FALSE
	if(reagent)
		reagents.trans_id_to(target.parent, reagent, amount)
	else
		reagents.trans_to(target.parent, amount, round_robin = TRUE)//we deal with alot of precise calculations so we round_robin=TRUE. Otherwise we get floating point errors, 1 != 1 and 2.5 + 2.5 = 6

///We create our luxurious piping overlays/underlays, to indicate where we do what. only called once if use_overlays = TRUE in Initialize()
/datum/component/plumbing/proc/create_overlays(atom/movable/AM, list/overlays)
	SIGNAL_HANDLER

	if(tile_covered || !use_overlays)
		return

	for(var/D in GLOB.cardinals)
		var/color
		var/direction
		if(D & initial(demand_connects))
			color = "red" //red because red is mean and it takes
		else if(D & initial(supply_connects))
			color = "blue" //blue is nice and gives
		else
			continue

		var/image/I
		if(turn_connects)
			switch(D)
				if(NORTH)
					direction = "north"
				if(SOUTH)
					direction = "south"
				if(EAST)
					direction = "east"
				if(WEST)
					direction = "west"
			I = image('icons/obj/plumbing/plumbers.dmi', "[direction]-[color]", layer = AM.layer - 1)

		else
			I = image('icons/obj/plumbing/plumbers.dmi', color,layer = AM.layer - 1) //color is not color as in the var, it's just the name of the icon_state
			I.dir = D
		overlays += I


/datum/component/plumbing/proc/on_parent_moved()
	SIGNAL_HANDLER

	var/atom/movable/AM = parent
	if (!AM.anchored)
		disable()


///we stop acting like a plumbing thing and disconnect if we are, so we can safely be moved and stuff
/datum/component/plumbing/proc/disable()
	SIGNAL_HANDLER

	if(!active)
		return

	STOP_PROCESSING(SSfluids, src)

	for(var/A in ducts)
		var/datum/ductnet/D = ducts[A]
		D.remove_plumber(src)

	active = FALSE

	for(var/D in GLOB.cardinals)
		if(D & (demand_connects | supply_connects))
			for(var/obj/machinery/duct/duct in get_step(parent, D))
				duct.remove_connects(turn(D, 180))
				duct.neighbours.Remove(parent)
				duct.update_appearance()

///settle wherever we are, and start behaving like a piece of plumbing
/datum/component/plumbing/proc/enable()
	if(active)
		return

	update_dir()
	active = TRUE

	var/atom/movable/AM = parent
	for(var/obj/machinery/duct/D in AM.loc)	//Destroy any ducts under us. Ducts also self destruct if placed under a plumbing machine. machines disable when they get moved
		if(D.anchored)								//that should cover everything
			D.disconnect_duct()

	if(demand_connects)
		START_PROCESSING(SSfluids, src)

	for(var/D in GLOB.cardinals)

		if(D & (demand_connects | supply_connects))
			for(var/atom/movable/A in get_step(parent, D))

				if(istype(A, /obj/machinery/duct))
					var/obj/machinery/duct/duct = A
					duct.attempt_connect()
				else
					var/datum/component/plumbing/P = A.GetComponent(/datum/component/plumbing)
					if(P)
						direct_connect(P, D)

/// Toggle our machinery on or off. This is called by a hook from default_unfasten_wrench with anchored as only param, so we dont have to copypaste this on every object that can move
/datum/component/plumbing/proc/toggle_active(obj/O, new_state)
	SIGNAL_HANDLER

	if(new_state)
		enable()
	else
		disable()

/** We update our connects only when we settle down by taking our current and original direction to find our new connects
* If someone wants it to fucking spin while connected to something go actually knock yourself out
*/
/datum/component/plumbing/proc/update_dir()
	if(!turn_connects)
		return

	var/atom/movable/AM = parent
	var/new_demand_connects
	var/new_supply_connects
	var/new_dir = AM.dir
	var/angle = 180 - dir2angle(new_dir)

	if(new_dir == SOUTH)
		demand_connects = initial(demand_connects)
		supply_connects = initial(supply_connects)
	else
		for(var/D in GLOB.cardinals)
			if(D & initial(demand_connects))
				new_demand_connects += turn(D, angle)
			if(D & initial(supply_connects))
				new_supply_connects += turn(D, angle)
		demand_connects = new_demand_connects
		supply_connects = new_supply_connects

///Give the direction of a pipe, and it'll return wich direction it originally was when it's object pointed SOUTH
/datum/component/plumbing/proc/get_original_direction(dir)
	var/atom/movable/AM = parent
	return turn(dir, dir2angle(AM.dir) - 180)

//special case in-case we want to connect directly with another machine without a duct
/datum/component/plumbing/proc/direct_connect(datum/component/plumbing/P, dir)
	if(!P.active)
		return
	var/opposite_dir = turn(dir, 180)
	if(P.demand_connects & opposite_dir && supply_connects & dir || P.supply_connects & opposite_dir && demand_connects & dir) //make sure we arent connecting two supplies or demands
		var/datum/ductnet/net = new()
		net.add_plumber(src, dir)
		net.add_plumber(P, opposite_dir)

/datum/component/plumbing/proc/hide(atom/movable/AM, intact)
	SIGNAL_HANDLER

	tile_covered = intact
	AM.update_appearance()

///has one pipe input that only takes, example is manual output pipe
/datum/component/plumbing/simple_demand
	demand_connects = NORTH

///has one pipe output that only supplies. example is liquid pump and manual input pipe
/datum/component/plumbing/simple_supply
	supply_connects = NORTH

///input and output, like a holding tank
/datum/component/plumbing/tank
	demand_connects = WEST
	supply_connects = EAST

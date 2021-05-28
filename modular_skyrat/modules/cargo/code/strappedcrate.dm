/*
Allows you to wrap crates with plastic straps that need to be cut before it can open
Why? Well, aside from an additional reinforcement, a silly way to trap people in crates (you cant weld them shut), and fluff.. they'll be used for cargo-based space ruins ok
*/

/obj/structure/closet/crate
	var/can_strap_shut = TRUE	//Lets me exclude the ones it looks ugly as sin on
	var/is_strapped = FALSE
/obj/structure/closet/crate/trashcart
	can_strap_shut = FALSE
/obj/structure/closet/crate/bin
	can_strap_shut = FALSE
/obj/structure/closet/crate/critter
	can_strap_shut = FALSE
/obj/structure/closet/crate/miningcar
	can_strap_shut = FALSE
/obj/structure/closet/crate/large
	can_strap_shut = FALSE //As much as I want it, I'd need to complicate shiz more

/obj/structure/closet/crate/attackby(obj/item/used_item, mob/user, params)
	. = ..()

/obj/structure/closet/crate/examine(mob/user)
	. = ..()
	if(is_strapped)
		. += "<span class='notice'>It's secured shut with plastic straps.</span>"

//This should, if not locked for another reason, do a final check to see if the crate is strapped. Otherwise, it'll return the original value (TRUE)
/obj/structure/closet/crate/can_open(mob/living/user, force = FALSE)
	. = ..()
	if(.)
		if(is_strapped)
			to_chat(user, "<span class='danger'>You can't open [src] while it's strapped shut!</span>")
			return FALSE

//This is here as a 'just in case I should add that'. Please clean it later. Please REMIND me to clean it later.
/*Test this code in place later:
/obj/structure/closet/crate/open(mob/living/user, force = FALSE)
	. = ..()
	is_strapped = FALSE
In theory it should work to just pin this on at the end, but idk if it'll update_appearance() and shiz right*/
/obj/structure/closet/crate/open(mob/living/user, force = FALSE)
	if(!can_open(user, force))
		return
	if(opened)
		return
	welded = FALSE
	locked = FALSE
	is_strapped = FALSE	//The only fucking change I added.
	playsound(loc, open_sound, open_sound_volume, TRUE, -3)
	opened = TRUE
	if(!dense_when_open)
		density = FALSE
	dump_contents()
	update_appearance()
	after_open(user, force)
	return TRUE
	//Also this is here because otherwise I'll overwrite it. Like I said - I need to fucking clean this later.
	if(. && manifest)
		to_chat(user, "<span class='notice'>The manifest is torn off [src].</span>")
		playsound(src, 'sound/items/poster_ripped.ogg', 75, TRUE)
		manifest.forceMove(get_turf(src))
		manifest = null
		update_appearance()

//(Original proc comment:) returns TRUE if attackBy call shouldn't be continued (because tool was used/closet was of wrong type), FALSE if otherwise
//This addition should do one final check - if it's strapped and attacked with the right tools, it'll remove the straps and return TRUE. Otherwise it'll still return FALSE.
/obj/structure/closet/crate/tool_interact(obj/item/W, mob/living/user)
	. = ..()
	if(!.)	//If the original output made it all the way to the bottom and output FALSE
		if(istype(W, cutting_tool) && is_strapped)	//Overall check, if it's not strapped they'll attack like normal
			if(W.tool_behaviour == TOOL_WIRECUTTER)
				to_chat(user, "<span class='notice'>You easily cut the straps off \the [src]!")
				is_strapped = FALSE
				//add plastic drop here
				update_appearance()	//Gotta actually remove the strap sprite
				log_game("[key_name(user)] cut the straps of crate [src] with [W] at [AREACOORD(src)]")	//Idk logging is important
				return TRUE
			else if(W.tool_behaviour == TOOL_KNIFE || W.tool_behaviour == TOOL_SAW)
				to_chat(user, "<span class='notice'>You begin using your [W] to saw through \the [src]'s straps...")
				if(!do_after(user, 20, target = user))
					to_chat(user, "<span class='notice'>Your [W] slips and you lose your groove!")	//I won't the only one who finds it funny that they not only lose the groove they saw into the strap with the knife, but also their metaphorical groove... right?
					return TRUE
				to_chat(user, "<span class='notice'>You saw the straps off \the [src]!")
				is_strapped = FALSE
				//add plastic drop here
				update_appearance()	//Gotta actually remove the strap sprite
				log_game("[key_name(user)] cut the straps of crate [src] with [W] at [AREACOORD(src)]")	//Idk logging is important
				return TRUE

//Makes sure you can resist out of a strapped locker/crate (Don't want people getting stuck, duh)
//-----Currently copy-paste and only adds the is_strapped to the 3rd if. Thats it.
//-----Please fix that to be cleaner. Someone remind me to do this if I havent.
/obj/structure/closet/crate/container_resist_act(mob/living/user)
	if(opened)
		return
	if(ismovable(loc))
		user.changeNext_move(CLICK_CD_BREAKOUT)
		user.last_special = world.time + CLICK_CD_BREAKOUT
		var/atom/movable/AM = loc
		AM.relay_container_resist_act(user, src)
		return
	if(!welded && !locked && !is_strapped)	//Added && !is_strapped check
		open()
		return

	//okay, so the closet is either welded or locked... resist!!!
	user.changeNext_move(CLICK_CD_BREAKOUT)
	user.last_special = world.time + CLICK_CD_BREAKOUT
	user.visible_message("<span class='warning'>[src] begins to shake violently!</span>", \
		"<span class='notice'>You lean on the back of [src] and start pushing the door open... (this will take about [DisplayTimeText(breakout_time)].)</span>", \
		"<span class='hear'>You hear banging from [src].</span>")
	if(do_after(user,(breakout_time), target = src))
		if(!user || user.stat != CONSCIOUS || user.loc != src || opened || (!locked && !welded) )
			return
		//we check after a while whether there is a point of resisting anymore and whether the user is capable of resisting
		user.visible_message("<span class='danger'>[user] successfully broke out of [src]!</span>",
							"<span class='notice'>You successfully break out of [src]!</span>")
		bust_open()
	else
		if(user.loc == src) //so we don't get the message if we resisted multiple times and succeeded.
			to_chat(user, "<span class='warning'>You fail to break out of [src]!</span>")

//This is literally just copied from the original closet/proc/bust_open(), but I've added the if(is_strapped) and its contents.
//Maybe I can do this cleaner?
/obj/structure/closet/crate/bust_open()
	welded = FALSE //applies to all lockers
	locked = FALSE //applies to critter crates and secure lockers only
	broken = TRUE //applies to secure lockers only
	if(is_strapped)	//This is in an if statement so we can get some plastic drops still
		is_strapped = FALSE	//applies to all crates
		//drop some plastic here
	open()

//THIS ALSO NEEDS CLEANING
//And big big thing, need to find a way to do a different overlay for crate and crate/big
/obj/structure/closet/crate/closet_update_overlays(list/new_overlays)
	. = new_overlays
	if(opened)
		. += "[icon_door_override ? icon_door : icon_state]_open"
		return

	. += "[icon_door || icon_state]_door"
	if(welded)
		. += icon_welded

	if(broken || !secure)
		return
	//Overlay is similar enough for both that we can use the same mask for both
	SSvis_overlays.add_vis_overlay(src, icon, "locked", EMISSIVE_LAYER, EMISSIVE_PLANE, dir, alpha)
	. += locked ? "locked" : "unlocked"

	if(is_strapped)
		//FUCK I NEED TO CHECK THE CRATE SIZE HERE
		. += crate_strap	//crate
		. += largecrate_strap //crate/big


//Now that we've established what a strapped crate is and how it works, we'll make it possible to actually strap one
/*
/obj/structure/closet/crate/attackby(obj/item/used_item, mob/user, params) //WIP
	. = ..()
	if(!opened)//Just to make sure we dont try to strap an open crate. Juuuuuust in case.
		if(istype(used_item, /obj/item/stack/sheet/plastic))
			if(can_strap_shut == FALSE)	//First, make sure we actually CAN strap it shut
				to_chat(user, "<span class='warning'>You cant find a way to strap this with plastic! Not a fun one, at least.</span>")
				return
			if(!do_after(user, 20, target = user))
				to_chat(user, "<span class='warning'>You need to stand still to strap the [src] shut!</span>")
				return
			//if(use(4))	should add a check to make sure we use 4 from the stack? that or add a craftable plastic strap item - TODO
			is_strapped = TRUE
			add_fingerprint(user)
			user.visible_message("<span class='notice'>[user] wraps [src].</span>")
			user.log_message("has used [name] on [key_name(src)]", LOG_ATTACK, color="blue")
	return
*/

/*
* WIP: Plastic Strapping will be a function of crates instead - - -
* EVERYTHING BELOW HERE IS THE ORIGINAL, NEW-OBJECT CODE
*/

/*
/obj/structure/big_delivery/strapped	//The following code is some horrific version of package wrappers. You've been warned.
	icon = 'modular_skyrat/modules/aesthetics/crates/icons/crates.dmi'
	name = "strapped crate"
	desc = "A crate secured shut and with thick plastic straps. You'll need to cut them off to open it."
	icon_state = "plasticcrate"
	overlays = list("crate_strap")	//This is cleared later when a new item is wrapped, dont worry.

/obj/structure/big_delivery/strapped/interact(mob/user)  //overwrites the original so that you cant tear off the straps by hand
	to_chat(user, "<span class='notice'>You tug at the plastic straps, but aren't strong enough to break them with your bare hands. You'll need to cut them.</span>")
	return

/obj/structure/big_delivery/strapped/wirecutter_act(mob/living/user, obj/item/I)
	. = ..()
	to_chat(user, "<span class='notice'>You start to cut off the plastic straps from the [src]!</span>")
	if(!do_after(user, 20, target = user))
		return
	playsound(src.loc, 'sound/weapons/slashmiss.ogg', 50, TRUE)
	user.visible_message("<span class='notice'>[user] cut \the [src]'s straps off.</span>", \
		"<span class='notice'>You cut off \the [src]'s straps.</span>", \
		"<span class='hear'>You hear a loud plastic snap!</span>")
	new /obj/item/stack/sheet/plastic (loc, 4)
	unwrap_contents()
	qdel(src)

/obj/structure/big_delivery/strapped/attackby(obj/item/used_item, mob/user, params) //rather than having sales tags, you can only attach paper to this
	if(istype(used_item, /obj/item/paper))
		if(note)
			to_chat(user, "<span class='warning'>This package already has a note attached!</span>")
			return
		if(!user.transferItemToLoc(used_item, src))
			to_chat(user, "<span class='warning'>For some reason, you can't attach [used_item]!</span>")
			return
		user.visible_message("<span class='notice'>[user] attaches [used_item] to [src].</span>", "<span class='notice'>You attach [used_item] to [src].</span>")
		note = used_item
		overlays += "manifest"

/obj/structure/big_delivery/strapped/relay_container_resist_act(mob/living/user, obj/strapped_object)
	if(ismovable(loc))
		var/atom/movable/AM = loc //can't unwrap the wrapped container if it's inside something.
		AM.relay_container_resist_act(user, strapped_object)
		return
	to_chat(user, "<span class='notice'>You lean on the back of [strapped_object] and start pushing to snap the straps off.</span>")
	if(do_after(user, 150, target = strapped_object))  //takes slightly longer to break plastic as opposed to paper
		if(!user || user.stat != CONSCIOUS || user.loc != strapped_object || strapped_object.loc != src )
			return
		to_chat(user, "<span class='notice'>You successfully broke [strapped_object]'s straps!</span>")
		strapped_object.forceMove(loc)
		playsound(src.loc, 'sound/items/poster_ripped.ogg', 50, TRUE)
		new /obj/item/stack/sheet/plastic (loc, 4)
		unwrap_contents()
		qdel(src)
	else
		if(user.loc == src) //so we don't get the message if we resisted multiple times and succeeded.
			to_chat(user, "<span class='warning'>You fail to remove [strapped_object]'s straps!</span>")

//Lets plastic wrap crates and only crates, then overlays the plastic straps/locks it shut
//Basically applies package wrapping code but for plastic onto crates
/obj/item/stack/sheet/plastic/afterattack(obj/target, mob/user, proximity)
	. = ..()
	if(!proximity)
		return
	if(!istype(target))
		return
	if(target.anchored)
		return

	if(istype (target, /obj/structure/closet))	//this extra IF check is basically so that hitting EVERY item doesnt say 'you cant wrap this', and only hitting invalid storage items does
		if(istype (target, /obj/structure/closet/crate))
			var/obj/structure/closet/crate/tcrate = target
			if(tcrate.opened)
				return
			if(!tcrate.delivery_icon) //no delivery icon means unwrappable crate
				to_chat(user, "<span class='warning'>You can't strap this shut!</span>")
				return
			if(istype(tcrate, /obj/structure/closet/crate/coffin) || istype(tcrate, /obj/structure/closet/crate/trashcart) || istype(tcrate, /obj/structure/closet/crate/bin) || istype(tcrate, /obj/structure/closet/crate/critter) || istype(tcrate, /obj/structure/closet/crate/necropolis) || istype(tcrate, /obj/structure/closet/crate/miningcar))	//for buggy-wuggy and ugly-wugly crates
				to_chat(user, "<span class='warning'>You can't strap this shut!</span>")
				return
			if(use(4))
				if(!do_after(user, 20, target = user))	//For some reason this still deletes stacks of exactly four, even if you fail?
					return
				var/obj/structure/big_delivery/strapped/new_strap = new /obj/structure/big_delivery/strapped(get_turf(tcrate.loc))
				new_strap.name = "strapped [tcrate.name]"	//you can still tell what crate is under the straps
				new_strap.icon_state = tcrate.icon_state	//inherits the sprite of the crate it was used on
				new_strap.overlays = tcrate.overlays //also inherits the overlays, for the sake of locks and papers. THIS OVERWRITES THE INITIAL CRATE-STRAP OVERLAY
				if(istype(tcrate, /obj/structure/closet/crate/large) || istype(tcrate, /obj/structure/closet/crate/big))	//if it was a large crate -
					new_strap.overlays += "largecrate_strap"	//overlays the large straps
				else
					new_strap.overlays += "crate_strap"	//otherwise just overlays the normal crate straps
				tcrate.forceMove(new_strap)
				new_strap.add_fingerprint(user)
				tcrate.add_fingerprint(user)
				user.visible_message("<span class='notice'>[user] wraps [target].</span>")
				user.log_message("has used [name] on [key_name(target)]", LOG_ATTACK, color="blue")
			else
				to_chat(user, "<span class='warning'>You need more plastic!</span>")
				return
		else
			to_chat(user, "<span class='warning'>You cant find a way to strap this with plastic! Not a fun one, at least.</span>")
			return
	else	//not a storage item, just use normal plastic attack code
		return
*/

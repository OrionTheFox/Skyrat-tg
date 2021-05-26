/*
Allows you to wrap crates with plastic straps that need to be cut before it can open
*/

//Adds the can_strap_shut variable
/obj/structure/closet/crate
	var/can_strap_shut = TRUE
	var/is_strapped = FALSE
/obj/structure/closet/crate/trashcart
	can_strap_shut = FALSE
/obj/structure/closet/crate/bin
	can_strap_shut = FALSE
/obj/structure/closet/crate/critter
	can_strap_shut = FALSE
/obj/structure/closet/crate/miningcar
	can_strap_shut = FALSE

/obj/structure/closet/crate/attackby(obj/item/used_item, mob/user, params)
	. = ..()
	if(!opened)//Just to make sure we dont try to strap an open crate. Juuuuuust in case.
		if(istype(used_item, /obj/item/stack/sheet/plastic))
			if(can_strap_shut == FALSE)	//First, make sure we actually CAN strap it shut
				to_chat(user, "<span class='warning'>You cant find a way to strap this with plastic! Not a fun one, at least.</span>")
				return
			if(!do_after(user, 20, target = user))
				to_chat(user, "<span class='warning'>You need to stand still to strap the [src] shut!</span>")
				return
//			if(use(4))
			is_strapped = TRUE
	return

//Re-define the can_open proc to block opening if is_strapped = TRUE, as well as posting to chat why
/obj/structure/closet/crate/can_open(mob/living/user, force = FALSE)
	if(force)
		return TRUE
	if(welded || locked)
		return FALSE
	if(is_strapped)
		to_chat(user,"<span class='notice'>[src] is strapped shut, preventing it from opening.</span>")
	var/turf/T = get_turf(src)
	for(var/mob/living/L in T)
		if(L.anchored || horizontal && L.mob_size > MOB_SIZE_TINY && L.density)
			if(user)
				to_chat(user, "<span class='danger'>There's something large on top of [src], preventing it from opening.</span>" )
			return FALSE
	return TRUE

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

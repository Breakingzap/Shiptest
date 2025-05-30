/datum/language/codespeak
	name = "Codespeak"
	desc = "Syndicate operatives can use a series of codewords to convey complex information, while sounding like random concepts and drinks to anyone listening in."
	key = "t"
	default_priority = 0
	flags = TONGUELESS_SPEECH | LANGUAGE_HIDE_ICON_IF_NOT_UNDERSTOOD
	icon_state = "codespeak"

/datum/language/codespeak/scramble_sentence(input, list/mutual_languages)
	var/sentence = read_word_cache(input)
	if(sentence)
		return sentence

	sentence = ""
	var/list/words = list()
	while(length_char(sentence) < length_char(input))
		words += generate_code_phrase(return_list=TRUE)
		sentence = jointext(words, ", ")

	sentence = capitalize(sentence)

	sentence += find_last_punctuation(input)

	write_word_cache(input, sentence)

	return sentence

/obj/item/codespeak_manual
	name = "codespeak manual"
	desc = "The book's cover reads: \"Codespeak(tm) - Secure your communication with metaphors so elaborate, they seem randomly generated!\""
	icon = 'icons/obj/library.dmi'
	icon_state = "book2"
	var/charges = 1

/obj/item/codespeak_manual/attack_self(mob/living/user)
	if(!isliving(user))
		return

	if(user.has_language(/datum/language/codespeak))
		to_chat(user, span_boldwarning("You start skimming through [src], but you already know Codespeak."))
		return

	to_chat(user, span_boldannounce("You start skimming through [src], and suddenly your mind is filled with codewords and responses."))
	user.grant_language(/datum/language/codespeak, TRUE, TRUE, LANGUAGE_MIND)

	use_charge(user)

/obj/item/codespeak_manual/attack(mob/living/M, mob/living/user)
	if(!istype(M) || !istype(user))
		return
	if(M == user)
		attack_self(user)
		return

	playsound(loc, "punch", 25, TRUE, -1)

	if(M.stat == DEAD)
		M.visible_message(span_danger("[user] smacks [M]'s lifeless corpse with [src]."), span_userdanger("[user] smacks your lifeless corpse with [src]."), span_hear("You hear smacking."))
	else if(M.has_language(/datum/language/codespeak))
		M.visible_message(span_danger("[user] beats [M] over the head with [src]!"), span_userdanger("[user] beats you over the head with [src]!"), span_hear("You hear smacking."))
	else
		M.visible_message(span_notice("[user] teaches [M] by beating [M.p_them()] over the head with [src]!"), span_boldnotice("As [user] hits you with [src], codewords and responses flow through your mind."), span_hear("You hear smacking."))
		M.grant_language(/datum/language/codespeak, TRUE, TRUE, LANGUAGE_MIND)
		use_charge(user)

/obj/item/codespeak_manual/proc/use_charge(mob/user)
	charges--
	if(!charges)
		var/turf/T = get_turf(src)
		T.visible_message(span_warning("The cover and contents of [src] start shifting and changing!"))

		qdel(src)
		var/obj/item/book/manual/random/book = new(T)
		user.put_in_active_hand(book)

/obj/item/codespeak_manual/unlimited
	name = "deluxe codespeak manual"
	charges = INFINITY

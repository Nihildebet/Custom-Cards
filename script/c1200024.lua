local s,id=GetID()

function s.initial_effect(c)

	--=========================================================
	-- LINK SUMMON
	-- Link 2
	-- 2 monsters including a Gemini monster
	--=========================================================

	c:EnableReviveLimit()

	Link.AddProcedure(
		c,
		s.linkfilter,
		2,
		2,
		s.linkcheck
	)


	--=========================================================
	-- EFFECT 1
	--
	-- Banish 1 Ritual Monster from Deck;
	-- send 1 Gemini Monster from Deck to GY;
	-- then you can add 1 Ritual Monster from banishment
	-- to your hand.
	--=========================================================

	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(
		CATEGORY_REMOVE
		+CATEGORY_TOGRAVE
		+CATEGORY_TOHAND
	)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,{id,0})
	e1:SetTarget(s.effect1tg)
	e1:SetOperation(s.effect1op)
	c:RegisterEffect(e1)


	--=========================================================
	-- EFFECT 2
	--
	-- During the Main Phase:
	-- Ritual Summon 1 Ritual Monster from your hand or GY,
	-- by shuffling Gemini monster(s) from your GY or
	-- banishment into the Deck whose total Levels equal
	-- or exceed that monster's Level.
	--=========================================================

	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(
		CATEGORY_SPECIAL_SUMMON
		+CATEGORY_TODECK
	)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.ritualtg)
	e2:SetOperation(s.ritualop)
	c:RegisterEffect(e2)

end


--=========================================================
-- LINK MATERIAL
-- 2 monsters including Gemini monster
--=========================================================

function s.linkfilter(c)
	return c:IsFaceup()
		and c:IsType(TYPE_MONSTER)
		and c:IsCanBeLinkMaterial()
end

function s.linkcheck(g,tp)
	return g:IsExists(
		Card.IsType,
		1,
		nil,
		TYPE_GEMINI
	)
end

--=========================================================
-- EFFECT 1
--
-- Banish 1 Ritual Monster from Deck
-- Send 1 Gemini Monster from Deck to GY
-- Then optionally add 1 banished Ritual Monster to hand
--=========================================================

function s.ritual_deck_filter(c)
	return c:IsType(TYPE_RITUAL)
		and c:IsMonster()
		and c:IsAbleToRemove()
end

function s.gem_deck_filter(c)
	return c:IsType(TYPE_GEMINI)
		and c:IsAbleToGrave()
end

function s.effect1tg(e,tp,eg,ep,ev,re,r,rp,chk)

	if chk==0 then

		if not Duel.IsExistingMatchingCard(
			s.ritual_deck_filter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil
		) then
			return false
		end

		return Duel.IsExistingMatchingCard(
			s.gem_deck_filter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil
		)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_REMOVE,
		nil,
		1,
		tp,
		LOCATION_DECK
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOGRAVE,
		nil,
		1,
		tp,
		LOCATION_DECK
	)
end

function s.effect1op(e,tp,eg,ep,ev,re,r,rp)

	--=====================================================
	-- Banish Ritual Monster
	--=====================================================

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_REMOVE
	)

	local rg=Duel.SelectMatchingCard(
		tp,
		s.ritual_deck_filter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil
	)

	if #rg==0 then
		return
	end

	if Duel.Remove(
		rg,
		POS_FACEUP,
		REASON_EFFECT
	)==0 then
		return
	end


	--=====================================================
	-- Send Gemini Monster from Deck to GY
	--=====================================================

	Duel.BreakEffect()

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_TOGRAVE
	)

	local gg=Duel.SelectMatchingCard(
		tp,
		s.gem_deck_filter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil
	)

	if #gg>0 then
		Duel.SendtoGrave(
			gg,
			REASON_EFFECT
		)
	end


	--=====================================================
	-- Optional: Add 1 banished Ritual Monster to hand
	--=====================================================

	local hg=Duel.GetMatchingGroup(
		function(c)
			return c:IsType(TYPE_RITUAL)
				and c:IsMonster()
				and c:IsFaceup()
				and c:IsAbleToHand()
		end,
		tp,
		LOCATION_REMOVED,
		0,
		nil
	)

	if #hg==0 then
		return
	end

	if not Duel.SelectYesNo(
		tp,
		aux.Stringid(id,2)
	) then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_ATOHAND
	)

	local sg=hg:Select(
		tp,
		1,
		1,
		nil
	)

	if #sg>0 then
		Duel.SendtoHand(
			sg,
			nil,
			REASON_EFFECT
		)

		Duel.ConfirmCards(
			1-tp,
			sg
		)
	end
end


--=========================================================
-- EFFECT 2
-- RITUAL SUMMON
--=========================================================

--=========================================================
-- Ritual Monster
-- From hand or GY
--=========================================================

function s.ritual_filter(c,e,tp)
	return c:IsType(TYPE_RITUAL)
		and c:IsMonster()
		and c:IsCanBeSpecialSummoned(
			e,
			SUMMON_TYPE_RITUAL,
			tp,
			false,
			true
		)
end


--=========================================================
-- Gemini Material
--
-- ONLY:
-- GY
-- Face-up banishment
--=========================================================

function s.material_filter(c)
	return c:IsType(TYPE_GEMINI)
		and c:IsAbleToDeck()
		and (
			c:IsLocation(LOCATION_GRAVE)
			or (
				c:IsLocation(LOCATION_REMOVED)
				and c:IsFaceup()
			)
		)
end


--=========================================================
-- Check whether enough Gemini Levels exist
--=========================================================

function s.has_material(tp,required_level)

	local g=Duel.GetMatchingGroup(
		s.material_filter,
		tp,
		LOCATION_GRAVE,
		0,
		nil
	)

	local bg=Duel.GetMatchingGroup(
		function(c)
			return s.material_filter(c)
		end,
		tp,
		LOCATION_REMOVED,
		0,
		nil
	)

	g:Merge(bg)

	local total_level=0

	for tc in aux.Next(g) do

		total_level=total_level+tc:GetLevel()

		if total_level>=required_level then
			return true
		end
	end

	return false
end


--=========================================================
-- Ritual Target
--=========================================================

function s.ritualtg(e,tp,eg,ep,ev,re,r,rp,chk)

	if chk==0 then

		local rg=Duel.GetMatchingGroup(
			s.ritual_filter,
			tp,
			LOCATION_HAND+LOCATION_GRAVE,
			0,
			nil,
			e,
			tp
		)

		if #rg==0 then
			return false
		end

		-- Check every available Ritual Monster
		-- to see whether enough Gemini Levels exist

		for rc in aux.Next(rg) do

			if s.has_material(
				tp,
				rc:GetLevel()
			) then

				return true

			end
		end

		return false
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,
		1,
		tp,
		LOCATION_HAND+LOCATION_GRAVE
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_TODECK,
		nil,
		1,
		tp,
		LOCATION_GRAVE+LOCATION_REMOVED
	)
end


--=========================================================
-- Ritual Operation
--=========================================================

function s.ritualop(e,tp,eg,ep,ev,re,r,rp)

	--=====================================================
	-- Select Ritual Monster
	--=====================================================

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_SPSUMMON
	)

	local rg=Duel.SelectMatchingCard(
		tp,
		s.ritual_filter,
		tp,
		LOCATION_HAND+LOCATION_GRAVE,
		0,
		1,
		1,
		nil,
		e,
		tp
	)

	if #rg==0 then
		return
	end

	local rc=rg:GetFirst()

	if not rc then
		return
	end

	local required_level=rc:GetLevel()


	--=====================================================
	-- Build available material pool
	--=====================================================

	local mg=Duel.GetMatchingGroup(
		s.material_filter,
		tp,
		LOCATION_GRAVE+LOCATION_REMOVED,
		0,
		nil
	)

	if #mg==0 then
		return
	end

	-- Ritual Monster itself cannot be material
	mg:RemoveCard(rc)


	--=====================================================
	-- Select materials
	--
	-- Continue until total Level >= Ritual Monster Level
	--=====================================================

	local selected=Group.CreateGroup()
	local total_level=0

	while total_level<required_level do

		if #mg==0 then
			return
		end

		-- Make a fresh available group
		local available=Group.CreateGroup()

		for tc in aux.Next(mg) do
			if tc:IsLocation(LOCATION_GRAVE)
				or (
					tc:IsLocation(LOCATION_REMOVED)
					and tc:IsFaceup()
				)
			then
				available:AddCard(tc)
			end
		end

		if #available==0 then
			return
		end


		-- Select one Gemini
		Duel.Hint(
			HINT_SELECTMSG,
			tp,
			HINTMSG_TODECK
		)

		local sg=available:Select(
			tp,
			1,
			1,
			nil
		)

		if #sg==0 then
			return
		end

		local mc=sg:GetFirst()

		selected:AddCard(mc)
		mg:RemoveCard(mc)

		total_level=total_level+mc:GetLevel()
	end


	--=====================================================
	-- Safety check
	--=====================================================

	if total_level<required_level then
		return
	end


	--=====================================================
	-- Set Ritual Materials
	--=====================================================

	rc:SetMaterial(selected)


	--=====================================================
	-- Shuffle materials into Deck
	--=====================================================

	if Duel.SendtoDeck(
		selected,
		nil,
		SEQ_DECKSHUFFLE,
		REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL
	)==0 then
		return
	end


	--=====================================================
	-- Ritual Summon
	--=====================================================

	Duel.BreakEffect()

	if Duel.SpecialSummon(
		rc,
		SUMMON_TYPE_RITUAL,
		tp,
		tp,
		false,
		true,
		POS_FACEUP
	)>0 then

		rc:CompleteProcedure()

	end
end
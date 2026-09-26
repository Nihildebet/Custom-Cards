
local s,id=GetID()

function s.initial_effect(c)
	-- Ritual Summon 1 Ritual Monster from hand or Deck
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_RELEASE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.ritualtg)
	e1:SetOperation(s.ritualop)
	c:RegisterEffect(e1)

	-- Add this card from GY to hand
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_LEAVE_FIELD)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

s.listed_card_types={TYPE_GEMINI}

--=========================================================
-- Ritual Monster Filter
--=========================================================

function s.ritfilter(c,e,tp)
	return c:IsType(TYPE_RITUAL)
		and c:IsMonster()
		and c:IsCanBeSpecialSummoned(
			e,
			SUMMON_TYPE_RITUAL,
			tp,
			true,
			false
		)
end

--=========================================================
-- Gemini Material Filter
--=========================================================

function s.matfilter(c)
	return c:IsMonster()
		and c:IsType(TYPE_GEMINI)
end

--=========================================================
-- Ritual Target
--=========================================================

function s.ritualtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.ritfilter,
			tp,
			LOCATION_HAND+LOCATION_DECK,
			0,
			1,
			nil,
			e,
			tp
		)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,
		1,
		tp,
		LOCATION_HAND+LOCATION_DECK
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
		s.ritfilter,
		tp,
		LOCATION_HAND+LOCATION_DECK,
		0,
		1,1,
		nil,
		e,
		tp
	)

	if #rg==0 then
		return
	end

	local rc=rg:GetFirst()
	local lv=rc:GetLevel()

	--=====================================================
	-- Get Gemini Materials
	-- Hand + Field + Deck
	--=====================================================

	local mg=Duel.GetMatchingGroup(
		s.matfilter,
		tp,
		LOCATION_HAND+LOCATION_MZONE+LOCATION_DECK,
		0,
		nil
	)

	if #mg==0 then
		return
	end

	--=====================================================
	-- Select Materials
	-- Total Levels must equal or exceed Ritual Level
	--=====================================================

	local selected=Group.CreateGroup()
	local total=0

	while total<lv do

		local available=mg:Filter(
			function(c,selected)
				return not selected:IsContains(c)
			end,
			nil,
			selected
		)

		if #available==0 then
			return
		end

		Duel.Hint(
			HINT_SELECTMSG,
			tp,
			HINTMSG_RELEASE
		)

		local sg=available:Select(
			tp,
			1,1,
			nil
		)

		if #sg==0 then
			return
		end

		local tc=sg:GetFirst()

		selected:AddCard(tc)
		total=total+tc:GetLevel()

		if total>=lv then
			break
		end
	end

	--=====================================================
	-- IMPORTANT:
	-- Register the selected cards as Ritual Materials.
	-- This allows the Ritual Monster to correctly remember
	-- which monsters were used for its Ritual Summon.
	--=====================================================

	rc:SetMaterial(selected)

	--=====================================================
	-- Separate materials by location
	--=====================================================

	local handfield=selected:Filter(
		Card.IsLocation,
		nil,
		LOCATION_HAND+LOCATION_MZONE
	)

	local deck=selected:Filter(
		Card.IsLocation,
		nil,
		LOCATION_DECK
	)

	--=====================================================
	-- Hand / Field materials are Tributed
	--=====================================================

	if #handfield>0 then
		Duel.Release(
			handfield,
			REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL
		)
	end

	--=====================================================
	-- Deck materials are sent to the GY
	--=====================================================

	if #deck>0 then
		Duel.SendtoGrave(
			deck,
			REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL
		)
	end

	--=====================================================
	-- Ritual Summon
	--=====================================================

	if Duel.SpecialSummon(
		rc,
		SUMMON_TYPE_RITUAL,
		tp,
		tp,
		true,
		false,
		POS_FACEUP
	)>0 then

		-- Mark as properly Ritual Summoned
		rc:CompleteProcedure()
	end
end

--=========================================================
-- Recovery Effect
-- Trigger when a Ritual or Gemini Monster you control
-- leaves the field while this card is in the GY
--=========================================================

function s.thfilter(c,tp)
	return c:IsPreviousControler(tp)
		and c:IsMonster()
		and (
			c:IsType(TYPE_RITUAL)
			or c:IsType(TYPE_GEMINI)
		)
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(
		s.thfilter,
		1,
		nil,
		tp
	)
end

function s.todeckfilter(c)
	return c:IsAbleToDeck()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)

	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.todeckfilter,
			tp,
			LOCATION_GRAVE+LOCATION_REMOVED,
			0,
			2,
			e:GetHandler()
		)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_TODECK,
		nil,
		2,
		tp,
		LOCATION_GRAVE+LOCATION_REMOVED
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOHAND,
		e:GetHandler(),
		1,
		tp,
		LOCATION_GRAVE
	)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)

	local c=e:GetHandler()

	-- This card must still be in the GY
	if not c:IsRelateToEffect(e) then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_TODECK
	)

	local g=Duel.SelectMatchingCard(
		tp,
		s.todeckfilter,
		tp,
		LOCATION_GRAVE+LOCATION_REMOVED,
		0,
		2,2,
		c
	)

	if #g~=2 then
		return
	end

	if Duel.SendtoDeck(
		g,
		nil,
		SEQ_DECKSHUFFLE,
		REASON_EFFECT
	)==2 then

		Duel.SendtoHand(
			c,
			nil,
			REASON_EFFECT
		)

		Duel.ConfirmCards(
			1-tp,
			c
		)
	end
end

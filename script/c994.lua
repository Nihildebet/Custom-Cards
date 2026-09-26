--Apostasia Malphoris
local s,id=GetID(994)

function s.initial_effect(c)
	-- Special Summon itself from hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id*100,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.spcon)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- If this card is Normal/Special Summoned:
	-- Add 1 "Apostasia" Spell/Trap
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,id*100+1,EFFECT_COUNT_CODE_OATH)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)

	-- If this card is banished:
	-- Ritual Summon by shuffling materials into the Deck
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_REMOVE)
	e4:SetCountLimit(1,id*100+2,EFFECT_COUNT_CODE_OATH)
	e4:SetTarget(s.rittg)
	e4:SetOperation(s.ritop)
	c:RegisterEffect(e4)
end

--------------------------------------------------
-- Special Summon from hand
--------------------------------------------------

function s.spcon(e,c)
	if c==nil then return true end

	local tp=c:GetControler()

	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=3
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	-- Banish top 3 cards from Deck
	local g=Duel.GetDecktopGroup(tp,3)
	if #g<3 then return end

	Duel.Remove(g,POS_FACEUP,REASON_COST)

	-- You cannot Special Summon monsters from the Extra Deck
	-- for the rest of this turn
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.exlimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

function s.exlimit(e,c)
	return c:IsLocation(LOCATION_EXTRA)
end

--------------------------------------------------
-- Search Apostasia Spell/Trap
--------------------------------------------------

function s.thfilter(c)
	return c:IsSetCard(0x4AA)
		and c:IsType(TYPE_SPELL+TYPE_TRAP)
		and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.thfilter,
			tp,
			LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,
			0,
			1,
			nil
		)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOHAND,
		nil,
		1,
		tp,
		LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED
	)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)

	local g=Duel.SelectMatchingCard(
		tp,
		s.thfilter,
		tp,
		LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,
		0,
		1,
		1,
		nil
	)

	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

--------------------------------------------------
-- Ritual Summon
--------------------------------------------------

function s.ritfilter(c,e,tp)
	return c:IsType(TYPE_MONSTER)
		and c:IsType(TYPE_RITUAL)
		and (
			c:IsLocation(LOCATION_HAND+LOCATION_GRAVE)
			or (
				c:IsLocation(LOCATION_REMOVED)
				and c:IsFaceup()
			)
		)
		and c:IsCanBeSpecialSummoned(
			e,
			SUMMON_TYPE_RITUAL,
			tp,
			false,
			true
		)
end

function s.matfilter(c)
	return c:IsType(TYPE_MONSTER)
		and (
			c:IsLocation(
				LOCATION_HAND+
				LOCATION_MZONE+
				LOCATION_GRAVE
			)
			or (
				c:IsLocation(LOCATION_REMOVED)
				and c:IsFaceup()
			)
		)
end

function s.rittg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.ritfilter,
			tp,
			LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED,
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
		LOCATION_HAND+
		LOCATION_GRAVE+
		LOCATION_REMOVED
	)
end

function s.ritop(e,tp,eg,ep,ev,re,r,rp)
	-- Select Ritual Monster
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local rg=Duel.SelectMatchingCard(
		tp,
		s.ritfilter,
		tp,
		LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED,
		0,
		1,
		1,
		nil,
		e,
		tp
	)

	if #rg==0 then return end

	local rc=rg:GetFirst()
	local required_level=rc:GetLevel()

	-- Select possible materials
	local mg=Duel.GetMatchingGroup(
		s.matfilter,
		tp,
		LOCATION_HAND+
		LOCATION_MZONE+
		LOCATION_GRAVE+
		LOCATION_REMOVED,
		0,
		nil
	)

	-- Ritual Monster cannot be used as material
	mg:RemoveCard(rc)

	if #mg==0 then return end

	local selected=Group.CreateGroup()
	local total_level=0

	-- If Monster Zone is full, prioritize
	-- materials from the field
	local prioritize_field=
		Duel.GetLocationCount(tp,LOCATION_MZONE)==0

	while total_level<required_level and #mg>0 do
		local available=mg

		if prioritize_field then
			local field_materials=mg:Filter(
				function(c)
					return c:IsLocation(LOCATION_MZONE)
				end,
				nil
			)

			if #field_materials>0 then
				available=field_materials
			end
		end

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)

		local sg=available:Select(tp,1,1,nil)

		if #sg==0 then return end

		local mc=sg:GetFirst()

		-- Selected material cannot be selected again
		selected:AddCard(mc)
		mg:RemoveCard(mc)

		total_level=total_level+mc:GetLevel()

		-- A field material frees a Monster Zone
		if mc:IsLocation(LOCATION_MZONE) then
			prioritize_field=false
		end
	end

	if total_level<required_level then
		return
	end

	-- All materials are shuffled into the Deck
	if Duel.SendtoDeck(
		selected,
		nil,
		SEQ_DECKSHUFFLE,
		REASON_EFFECT+
		REASON_MATERIAL+
		REASON_RITUAL
	)==0 then
		return
	end
rc:SetMaterial(selected)
	Duel.BreakEffect()

	-- Ritual Summon
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
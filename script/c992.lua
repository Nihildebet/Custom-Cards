local s,id=GetID(992)

function s.initial_effect(c)

	-- If this card is banished:
	-- Ritual Summon 1 Ritual Monster
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_REMOVE)
	e1:SetCountLimit(1,id*100+2,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.rittg)
	e1:SetOperation(s.ritop)
	c:RegisterEffect(e1)


	-- Special Summon itself from the hand
	-- Banish the top 3 cards of your Deck
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_SPSUMMON_PROC)
	e2:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e2:SetCountLimit(1,id*100,EFFECT_COUNT_CODE_OATH)
	e2:SetRange(LOCATION_HAND)
	e2:SetCondition(s.spcon)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)


	-- If this card is Normal/Special Summoned:
	-- Banish 2 cards from your hand and/or field,
	-- then draw 2 cards
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_REMOVE+CATEGORY_DRAW)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetCountLimit(1,id*100+1,EFFECT_COUNT_CODE_OATH)
	e3:SetTarget(s.bntg)
	e3:SetOperation(s.bnop)
	c:RegisterEffect(e3)

	local e4=e3:Clone()
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e4)

end


--------------------------------------------------
-- SPECIAL SUMMON PROCEDURE
--------------------------------------------------

function s.spcon(e,c)
	if c==nil then return true end

	local tp=c:GetControler()

	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=3
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)

	-- Banish the top 3 cards face-up
	local g=Duel.GetDecktopGroup(tp,3)

	Duel.Remove(
		g,
		POS_FACEUP,
		REASON_COST
	)

	-- Cannot Special Summon from the Extra Deck
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
-- RITUAL SUMMON
--------------------------------------------------

-- Ritual Monster only
function s.ritfilter(c,e,tp)
	return c:IsType(TYPE_MONSTER)
		and c:IsType(TYPE_RITUAL)
		and (
			c:IsLocation(LOCATION_HAND+LOCATION_GRAVE)
			or (c:IsLocation(LOCATION_REMOVED) and c:IsFaceup())
		)
		and c:IsCanBeSpecialSummoned(
			e,SUMMON_TYPE_RITUAL,tp,false,true
		)
end


-- Possible Ritual Materials
function s.matfilter(c)
	return c:IsType(TYPE_MONSTER)
		and (
			c:IsLocation(
				LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE
			)
			or (
				c:IsLocation(LOCATION_REMOVED)
				and c:IsFaceup()
			)
		)
end


-- Material cannot be the selected Ritual Monster
function s.matcheck(c,rc)
	return c~=rc
		and c:IsType(TYPE_MONSTER)
		and c:IsAbleToDeck()
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
		LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED
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
		LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE+LOCATION_REMOVED,
		0,
		nil
	)

	-- The selected Ritual Monster cannot be used as material
	mg:RemoveCard(rc)

	if #mg==0 then return end

	local selected=Group.CreateGroup()
	local total_level=0

	-- If Monster Zone is full, prioritize field materials
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
		if #sg==0 then break end

		local mc=sg:GetFirst()

		-- Add the selected material
		selected:AddCard(mc)

		-- Remove it from the candidate group
		-- so it cannot be selected again
		mg:RemoveCard(mc)

		total_level=total_level+mc:GetLevel()

		-- Once a field monster is selected, a zone is freed
		if mc:IsLocation(LOCATION_MZONE) then
			prioritize_field=false
		end
	end

	-- The selected materials must fulfill the required Level
	if total_level<required_level then
		return
	end

	-- All selected materials are shuffled into the Deck
	if Duel.SendtoDeck(
		selected,
		nil,
		SEQ_DECKSHUFFLE,
		REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL
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


--------------------------------------------------
-- BANISH 2, THEN DRAW 2
--------------------------------------------------

-- Cards that can be banished
function s.bnfilter(c)
	return c:IsAbleToRemove()
end


function s.bntg(e,tp,eg,ep,ev,re,r,rp,chk)

	if chk==0 then

		return Duel.IsExistingMatchingCard(
			s.bnfilter,
			tp,
			LOCATION_HAND+LOCATION_MZONE,
			0,
			2,
			nil
		)
		and Duel.IsPlayerCanDraw(tp,2)

	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_REMOVE,
		nil,
		2,
		tp,
		LOCATION_HAND+LOCATION_MZONE
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_DRAW,
		nil,
		2,
		tp,
		2
	)

end


function s.bnop(e,tp,eg,ep,ev,re,r,rp)

	local g=Duel.SelectMatchingCard(
		tp,
		s.bnfilter,
		tp,
		LOCATION_HAND+LOCATION_MZONE,
		0,
		2,
		2,
		nil
	)

	if #g<2 then return end

	if Duel.Remove(
		g,
		POS_FACEUP,
		REASON_EFFECT
	)==2 then

		Duel.Draw(
			tp,
			2,
			REASON_EFFECT
		)

	end

end
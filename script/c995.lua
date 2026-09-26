--Apostasia Sacred Altar
local s,id=GetID(995)
local SET_APOSTASIA=0x4AA
function s.initial_effect(c)
	-- Ritual Summon
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE+CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.ritual_target)
	e1:SetOperation(s.ritual_operation)
	c:RegisterEffect(e1)

	-- If this card is banished
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_REMOVE+CATEGORY_LEAVE_GRAVE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_REMOVE)
	e2:SetCountLimit(1,id*100,EFFECT_COUNT_CODE_OATH)
	e2:SetTarget(s.set_target)
	e2:SetOperation(s.set_operation)
	c:RegisterEffect(e2)
end

-- Ritual Monster from hand, Graveyard, or face-up banishment
function s.ritual_filter(c,e,tp)
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

-- Normal materials from hand, field, or Graveyard
function s.material_filter(c)
	return c:IsType(TYPE_MONSTER)
		and c:IsLocation(
			LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE
		)
end

-- Face-up banished materials
function s.banished_material_filter(c)
	return c:IsType(TYPE_MONSTER)
		and c:IsLocation(LOCATION_REMOVED)
		and c:IsFaceup()
end

function s.ritual_target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.ritual_filter,
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

function s.ritual_operation(e,tp,eg,ep,ev,re,r,rp)
	-- Select Ritual Monster
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local rg=Duel.SelectMatchingCard(
		tp,
		s.ritual_filter,
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

	-- Determine whether banished materials are allowed
	local allow_banish_material=
		not Duel.IsExistingMatchingCard(
			function(c)
				return c:IsFaceup()
					and c:IsSummonLocation(LOCATION_EXTRA)
			end,
			tp,
			LOCATION_MZONE,
			0,
			1,
			nil
		)

	local material_location=
		LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE

	if allow_banish_material then
		material_location=material_location+LOCATION_REMOVED
	end

	local mg=Duel.GetMatchingGroup(
		function(c)
			if not c:IsType(TYPE_MONSTER) then
				return false
			end

			if c:IsLocation(LOCATION_REMOVED) then
				return allow_banish_material and c:IsFaceup()
			end

			return c:IsLocation(
				LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE
			)
		end,
		tp,
		material_location,
		0,
		nil
	)

	-- Ritual Monster itself cannot be used as material
	mg:RemoveCard(rc)

	if #mg==0 then return end

	-- Select materials manually
	local selected=Group.CreateGroup()
	local total_level=0

	while total_level<required_level and #mg>0 do
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

		local sg=mg:Select(tp,1,1,nil)
		if #sg==0 then break end

		local mc=sg:GetFirst()
		selected:AddCard(mc)
		mg:RemoveCard(mc)
		total_level=total_level+mc:GetLevel()
	end

	if total_level<required_level then
		return
	end

	-- Banish materials from hand, field, and Graveyard
	-- Shuffle face-up banished materials into the Deck
	local banished_materials=Group.CreateGroup()
	local normal_materials=Group.CreateGroup()

	local tc=selected:GetFirst()
	while tc do
		if tc:IsLocation(LOCATION_REMOVED) then
			banished_materials:AddCard(tc)
		else
			normal_materials:AddCard(tc)
		end
		tc=selected:GetNext()
	end

	if #normal_materials>0 then
		Duel.Remove(
			normal_materials,
			POS_FACEUP,
			REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL
		)
	end

	if #banished_materials>0 then
		Duel.SendtoDeck(
			banished_materials,
			nil,
			SEQ_DECKSHUFFLE,
			REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL
		)
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

-- This card can be Set from banishment
function s.set_target(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsLocation(LOCATION_REMOVED)
			and c:IsSSetable()
			and Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=3
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_REMOVE,
		nil,
		3,
		tp,
		LOCATION_DECK
	)
end

function s.set_operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsLocation(LOCATION_REMOVED) then
		return
	end

	-- Banish top 3 cards as cost-like effect
	local top=Duel.GetDecktopGroup(tp,3)
	if #top<3 then return end

	Duel.Remove(top,POS_FACEUP,REASON_EFFECT)

	-- Set this card
	if not Duel.SSet(tp,c) then
		return
	end

	-- Extra Deck lock
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.extra_deck_limit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

function s.extra_deck_limit(e,c)
	return c:IsLocation(LOCATION_EXTRA)
end
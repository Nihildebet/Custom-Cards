--Ritual Monster: Gemini synergy boss
local s,id=GetID()

function s.initial_effect(c)

	--============================================================
	-- (1) IMMUNE TO OTHER CARD EFFECTS
	--
	-- This card that was Ritual Summoned using only Gemini
	-- monsters is unaffected by other card effects.
	--============================================================

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetCondition(s.immunecon)
	e1:SetValue(s.immunefilter)
	c:RegisterEffect(e1)


		  --============================================================
		-- (2) QUICK EFFECT:
		-- When your opponent activates a card or effect:
		-- Special Summon 1 Gemini monster from Deck.
		--
		-- You cannot Special Summon Gemini monsters with an
		-- Attribute already used by this effect this turn.
		--============================================================

		local e2=Effect.CreateEffect(c)
		e2:SetDescription(aux.Stringid(id,0))
		e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
		e2:SetType(EFFECT_TYPE_QUICK_O)
		e2:SetCode(EVENT_CHAINING)
		e2:SetRange(LOCATION_MZONE)
		e2:SetCondition(s.spcon)
		e2:SetTarget(s.sptg)
		e2:SetOperation(s.spop)
		c:RegisterEffect(e2)


	--============================================================
	-- (3) GEMINI EFFECT ACTIVATION
	--
	-- Each time a Gemini monster you control activates its effect:
	--
	-- Look at opponent's Extra Deck,
	-- banish 1 card from it face-down,
	-- then all monsters you currently control gain
	-- 500 ATK/DEF.
	--============================================================

	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(
		CATEGORY_REMOVE
		+CATEGORY_ATKCHANGE
		+CATEGORY_DEFCHANGE
	)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(s.gemactcon)
	e3:SetTarget(s.gemacttg)
	e3:SetOperation(s.gemactop)
	c:RegisterEffect(e3)

end


--============================================================
-- (1) IMMUNITY CONDITION
--============================================================

function s.immunecon(e)

	local c=e:GetHandler()

	-- Must have been Ritual Summoned
	if not c:IsSummonType(SUMMON_TYPE_RITUAL) then
		return false
	end

	local mg=c:GetMaterial()

	if not mg or mg:GetCount()==0 then
		return false
	end

	-- Every Ritual Material must be a Gemini monster
	return not mg:IsExists(
		function(mc)
			return not mc:IsType(TYPE_GEMINI)
		end,
		1,
		nil
	)
end


function s.immunefilter(e,re)

	return re:GetOwner()~=e:GetHandler()

end


--============================================================
-- (2) QUICK EFFECT CONDITION
--============================================================

function s.spcon(e,tp,eg,ep,ev,re,r,rp)

	-- Opponent activated the card/effect
	return rp==1-tp

end


--============================================================
-- Gemini Deck Filter
--============================================================

function s.gemdeckfilter(c,e,tp,att)

	return c:IsType(TYPE_GEMINI)
		and c:IsAttribute(att)
		and c:IsCanBeSpecialSummoned(
			e,
			0,
			tp,
			false,
			false
		)

end


--============================================================
-- QUICK EFFECT TARGET
--============================================================

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)

	if chk==0 then

		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
			return false
		end

		-- Check whether there is at least 1 Gemini
		-- with an Attribute that has not been used this turn
		local g=Duel.GetMatchingGroup(
			function(c,e,tp)
				if not c:IsType(TYPE_GEMINI) then
					return false
				end

				if not c:IsCanBeSpecialSummoned(
					e,
					0,
					tp,
					false,
					false
				) then
					return false
				end

				local att=c:GetAttribute()

				if att==0 then
					return false
				end

				return Duel.GetFlagEffect(tp,id+att)==0
			end,
			tp,
			LOCATION_DECK,
			0,
			nil,
			e,
			tp
		)

		return #g>0
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,
		1,
		tp,
		LOCATION_DECK
	)
end


function s.spop(e,tp,eg,ep,ev,re,r,rp)

	-- Build available Gemini monsters
	-- whose Attribute has not been used this turn
	local g=Duel.GetMatchingGroup(
		function(c,e,tp)
			if not c:IsType(TYPE_GEMINI) then
				return false
			end

			if not c:IsCanBeSpecialSummoned(
				e,
				0,
				tp,
				false,
				false
			) then
				return false
			end

			local att=c:GetAttribute()

			if att==0 then
				return false
			end

			return Duel.GetFlagEffect(tp,id+att)==0
		end,
		tp,
		LOCATION_DECK,
		0,
		nil,
		e,
		tp
	)

	if #g==0 then
		return
	end

	-- Select Gemini
	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_SPSUMMON
	)

	local sg=g:Select(tp,1,1,nil)

	if #sg==0 then
		return
	end

	local tc=sg:GetFirst()
	local att=tc:GetAttribute()

	--=========================================================
	-- Mark this Attribute as used for this turn
	--
	-- The flag automatically resets at End Phase.
	--=========================================================

	Duel.RegisterFlagEffect(
		tp,
		id+att,
		RESET_PHASE+PHASE_END,
		0,
		1
	)

	-- Special Summon
	Duel.SpecialSummon(
		tc,
		0,
		tp,
		tp,
		false,
		false,
		POS_FACEUP
	)
end




--============================================================
-- (3) GEMINI EFFECT ACTIVATION CONDITION
--============================================================

function s.gemactcon(e,tp,eg,ep,ev,re,r,rp)

	local rc=re:GetHandler()

	return rc
		and rc:IsControler(tp)
		and rc:IsType(TYPE_GEMINI)
		and rc:IsGeminiStatus()

end


--============================================================
-- EXTRA DECK FILTER
--============================================================

function s.anycard(c)

	return c:IsAbleToRemove()

end


--============================================================
-- EXTRA DECK TARGET
--============================================================

function s.gemacttg(e,tp,eg,ep,ev,re,r,rp,chk)

	if chk==0 then

		return Duel.GetFieldGroupCount(
			1-tp,
			LOCATION_EXTRA,
			0
		)>0

	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_REMOVE,
		nil,
		1,
		1-tp,
		LOCATION_EXTRA
	)

end


--============================================================
-- EXTRA DECK OPERATION
--============================================================

function s.gemactop(e,tp,eg,ep,ev,re,r,rp)

	-- Get opponent's Extra Deck
	local g=Duel.GetMatchingGroup(
		s.anycard,
		1-tp,
		LOCATION_EXTRA,
		0,
		nil
	)

	if #g==0 then
		return
	end


	-- Look at opponent's Extra Deck
	Duel.ConfirmCards(
		tp,
		g
	)


	-- Banish 1 face-down
	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_REMOVE
	)

	local sg=g:Select(
		tp,
		1,
		1,
		nil
	)

	if #sg>0 then

		Duel.Remove(
			sg,
			POS_FACEDOWN,
			REASON_EFFECT
		)

	end


	--=========================================================
	-- All monsters currently controlled
	-- gain 500 ATK/DEF
	--=========================================================

	local atkbuff=Effect.CreateEffect(
		e:GetHandler()
	)

	atkbuff:SetType(EFFECT_TYPE_FIELD)
	atkbuff:SetCode(EFFECT_UPDATE_ATTACK)
	atkbuff:SetTargetRange(
		LOCATION_MZONE,
		0
	)
	atkbuff:SetValue(500)

	Duel.RegisterEffect(
		atkbuff,
		tp
	)


	local defbuff=atkbuff:Clone()

	defbuff:SetCode(
		EFFECT_UPDATE_DEFENSE
	)

	Duel.RegisterEffect(
		defbuff,
		tp
	)

end
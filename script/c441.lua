local s,id=GetID()

function s.initial_effect(c)
	-- Special Summon itself from hand
	-- by banishing 1 non-DARK Gemini Monster from hand or Deck
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetRange(LOCATION_HAND)
	e1:SetCondition(s.spcon)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Gemini Effect
	Gemini.AddProcedure(c)

	-- Quick Effect
	-- Once per chain, when your opponent activates:
	-- 1. a card/effect that targets your card in the
	--	field, Graveyard, or banishment
	-- OR
	-- 2. a card/effect as Chain Link 2 or higher
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.condition)
	e2:SetTarget(s.target)
	e2:SetOperation(s.operation)
	c:RegisterEffect(e2)
end


--=========================================================
-- Special Summon Procedure
-- "by banishing 1 non-DARK Gemini Monster from your
-- hand or Deck"
--=========================================================

function s.banfilter(c)
	return c:IsType(TYPE_GEMINI)
		and not c:IsAttribute(ATTRIBUTE_DARK)
		and c:IsAbleToRemove()
end

function s.spcon(e,c)
	if c==nil then return true end

	local tp=c:GetControler()

	return Duel.IsExistingMatchingCard(
		s.banfilter,
		tp,
		LOCATION_HAND+LOCATION_DECK,
		0,
		1,
		c
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_REMOVE
	)

	local g=Duel.SelectMatchingCard(
		tp,
		s.banfilter,
		tp,
		LOCATION_HAND+LOCATION_DECK,
		0,
		1,1,
		c
	)

	if #g>0 then
		Duel.Remove(
			g,
			POS_FACEUP,
			REASON_COST
		)
	end
end


--=========================================================
-- Quick Effect Condition
--
-- Opponent activates:
-- A) an effect that targets your card in:
--	- Field
--	- Graveyard
--	- Banishment
--
-- OR
--
-- B) an effect at Chain Link 2 or higher
--=========================================================

function s.tgfilter(c,tp)
	return c:IsControler(tp)
		and c:IsLocation(
			LOCATION_ONFIELD
			|LOCATION_GRAVE
		)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	 -- Must already be a Gemini Effect Monster
	if not e:GetHandler():IsGeminiStatus() then
		return false
	end

	-- Must be opponent's activation
	if rp==tp then
		return false
	end

	-- Chain Link 2 or higher
	if ev>=2 then
		return true
	end

	-- Chain Link 1:
	-- Check whether the activated effect targets
	-- your card in the field, Graveyard, or banishment
	local tg=Duel.GetChainInfo(
		ev,
		CHAININFO_TARGET_CARDS
	)

	return tg
		and tg:IsExists(
			s.tgfilter,
			1,
			nil,
			tp
		)
end


--=========================================================
-- Gemini Monster Special Summon Filter
--=========================================================

function s.spfilter(c,e,tp)
	return c:IsType(TYPE_GEMINI)
		and c:IsCanBeSpecialSummoned(
			e,
			0,
			tp,
			false,
			false
		)
end


--=========================================================
-- Quick Effect Target
--=========================================================

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.spfilter,
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


--=========================================================
-- Quick Effect Operation
--=========================================================

function s.operation(e,tp,eg,ep,ev,re,r,rp)

	-- Special Summon 1 Gemini Monster
	local g=Duel.SelectMatchingCard(
		tp,
		s.spfilter,
		tp,
		LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED,
		0,
		1,1,
		nil,
		e,
		tp
	)

	if #g==0 then
		return
	end

	local tc=g:GetFirst()

	if Duel.SpecialSummon(
		tc,
		0,
		tp,
		tp,
		false,
		false,
		POS_FACEUP
	)>0 then

		-- You can banish 1 card on the field face-down
		local fg=Duel.GetFieldGroup(
			tp,
			LOCATION_ONFIELD,
			LOCATION_ONFIELD
		)

		if #fg>0 then

			if Duel.SelectYesNo(
				tp,
				aux.Stringid(id,2)
			) then

				Duel.Hint(
					HINT_SELECTMSG,
					tp,
					HINTMSG_REMOVE
				)

				local sg=fg:Select(
					tp,
					1,1,
					nil
				)

				local fc=sg:GetFirst()

				if fc then
					Duel.Remove(
						fc,
						POS_FACEDOWN,
						REASON_EFFECT
					)
				end
			end
		end
	end
end
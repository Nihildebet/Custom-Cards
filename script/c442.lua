local s,id=GetID()

function s.initial_effect(c)

	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

		   -- Each time a monster is Special Summoned:
		-- You can immediately Normal Summon 1 Gemini monster
		local e2=Effect.CreateEffect(c)
		e2:SetDescription(aux.Stringid(id,1))
		e2:SetCategory(CATEGORY_SUMMON)
		e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
		e2:SetProperty(EFFECT_FLAG_DELAY)
		e2:SetCode(EVENT_SPSUMMON_SUCCESS)
		e2:SetRange(LOCATION_FZONE)
		e2:SetTarget(s.nstg)
		e2:SetOperation(s.nsop)
		c:RegisterEffect(e2)

end

s.listed_card_types={TYPE_GEMINI}


--========================================
-- Place 1 Continuous Trap
--========================================

function s.plfilter(c,tp)
	return c:IsContinuousTrap()
		and c:ListsCardType(TYPE_GEMINI)
		and not c:IsForbidden()
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)

	local c=e:GetHandler()

	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end

	if not Duel.IsExistingMatchingCard(
		s.plfilter,
		tp,
		LOCATION_DECK+LOCATION_GRAVE,
		0,
		1,nil,tp
	) then return end

	if not Duel.SelectYesNo(tp,aux.Stringid(id,0)) then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)

	local tc=Duel.SelectMatchingCard(
		tp,
		s.plfilter,
		tp,
		LOCATION_DECK+LOCATION_GRAVE,
		0,
		1,1,
		nil,tp
	):GetFirst()

	if tc then
		Duel.MoveToField(
			tc,
			tp,
			tp,
			LOCATION_SZONE,
			POS_FACEUP,
			true
		)
	end

end


--========================================
-- Immediately Normal Summon 1 Gemini
--========================================

function s.nsfilter(c)
	return c:IsType(TYPE_GEMINI)
		and c:IsSummonable(true,nil)
end

function s.nstg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.nsfilter,
			tp,
			LOCATION_HAND|LOCATION_MZONE,
			0,
			1,
			nil
		)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SUMMON,
		nil,
		1,
		0,
		0
	)
end

function s.nsop(e,tp,eg,ep,ev,re,r,rp)

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_SUMMON
	)

	local g=Duel.SelectMatchingCard(
		tp,
		s.nsfilter,
		tp,
		LOCATION_HAND|LOCATION_MZONE,
		0,
		1,1,
		nil
	)

	local tc=g:GetFirst()

	if tc then
		Duel.Summon(
			tp,
			tc,
			true,
			nil
		)
	end

end
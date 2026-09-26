local s,id=GetID()

function s.initial_effect(c)
	-- Gemini Procedure
	Gemini.AddProcedure(c)

	--=====================================================
	-- Special Summon from hand or banishment
	--
	-- Target 1 Gemini monster you control that became
	-- an Effect Monster and 1 card your opponent controls;
	-- banish them, then Special Summon this card.
	--=====================================================

	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND+LOCATION_REMOVED)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--=====================================================
	-- Become an Effect Monster
	--=====================================================

	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_ADD_TYPE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(Gemini.EffectStatusCondition)
	e2:SetValue(TYPE_EFFECT)
	c:RegisterEffect(e2)

	--=====================================================
	-- Quick Effect
	--
	-- Once per chain:
	-- Shuffle 1 Gemini monster you control and
	-- 1 card on the field into the Deck, then draw 1 card.
	--=====================================================

	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id,EFFECT_COUNT_CODE_CHAIN)
	e3:SetCondition(Gemini.EffectStatusCondition)
	e3:SetTarget(s.tdtg)
	e3:SetOperation(s.tdop)
	c:RegisterEffect(e3)
end


--=========================================================
-- First Effect
--=========================================================

-- Gemini monster you control that became an Effect Monster
function s.gemfilter(c,tp)
	return c:IsType(TYPE_GEMINI)
		and c:IsGeminiStatus()
		and c:IsFaceup()
		and c:IsControler(tp)
end

-- Opponent's card
function s.opfilter(c,tp)
	return c:IsOnField()
		and c:IsControler(1-tp)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(
				s.gemfilter,
				tp,
				LOCATION_MZONE,
				0,
				1,
				nil,
				tp
			)
			and Duel.IsExistingMatchingCard(
				s.opfilter,
				tp,
				0,
				LOCATION_ONFIELD,
				1,
				nil,
				tp
			)
			and e:GetHandler():IsCanBeSpecialSummoned(
				e,
				0,
				tp,
				false,
				false
			)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_REMOVE,
		nil,
		2,
		PLAYER_ALL,
		LOCATION_MZONE+LOCATION_ONFIELD
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		e:GetHandler(),
		1,
		tp,
		LOCATION_HAND+LOCATION_REMOVED
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	-- Select your Gemini Effect Monster
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

	local g1=Duel.SelectMatchingCard(
		tp,
		s.gemfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,1,
		nil,
		tp
	)

	if #g1==0 then
		return
	end

	-- Select opponent's card
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

	local g2=Duel.SelectMatchingCard(
		tp,
		s.opfilter,
		tp,
		0,
		LOCATION_ONFIELD,
		1,1,
		nil,
		tp
	)

	if #g2==0 then
		return
	end

	local g=Group.CreateGroup()
	g:Merge(g1)
	g:Merge(g2)

	-- Banish both
	if Duel.Remove(g,POS_FACEUP,REASON_EFFECT)~=2 then
		return
	end

	-- Special Summon this card
	if c:IsLocation(LOCATION_HAND+LOCATION_REMOVED)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) then

		Duel.SpecialSummon(
			c,
			0,
			tp,
			tp,
			false,
			false,
			POS_FACEUP
		)
	end
end


--=========================================================
-- Second Effect
--
-- Shuffle 1 Gemini monster you control
-- and 1 other card on the field into the Deck,
-- then draw 1 card.
--=========================================================

function s.gemtdfilter(c,tp)
	return c:IsFaceup()
		and c:IsType(TYPE_GEMINI)
		and c:IsControler(tp)
		and c:IsAbleToDeck()
end

function s.fieldfilter(c,excluded)
	return c:IsOnField()
		and c:IsAbleToDeck()
		and c~=excluded
end

function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		if not Duel.IsPlayerCanDraw(tp,1) then
			return false
		end

		if not Duel.IsExistingMatchingCard(
			s.gemtdfilter,
			tp,
			LOCATION_MZONE,
			0,
			1,
			nil,
			tp
		) then
			return false
		end

		local g=Duel.GetMatchingGroup(
			s.gemtdfilter,
			tp,
			LOCATION_MZONE,
			0,
			nil,
			tp
		)

		for tc in aux.Next(g) do
			if Duel.IsExistingMatchingCard(
				s.fieldfilter,
				tp,
				LOCATION_ONFIELD,
				LOCATION_ONFIELD,
				1,
				tc
			) then
				return true
			end
		end

		return false
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_TODECK,
		nil,
		2,
		PLAYER_ALL,
		LOCATION_ONFIELD
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_DRAW,
		nil,
		0,
		tp,
		1
	)
end

function s.tdop(e,tp,eg,ep,ev,re,r,rp)
	-- Select Gemini monster
	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_TODECK
	)

	local g1=Duel.SelectMatchingCard(
		tp,
		s.gemtdfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,1,
		nil,
		tp
	)

	if #g1==0 then
		return
	end

	local tc=g1:GetFirst()

	-- Select another card on the field
	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_TODECK
	)

	local g2=Duel.SelectMatchingCard(
		tp,
		s.fieldfilter,
		tp,
		LOCATION_ONFIELD,
		LOCATION_ONFIELD,
		1,1,
		tc
	)

	if #g2==0 then
		return
	end

	local g=Group.CreateGroup()
	g:Merge(g1)
	g:Merge(g2)

	if Duel.SendtoDeck(
		g,
		nil,
		SEQ_DECKSHUFFLE,
		REASON_EFFECT
	)==0 then
		return
	end

	Duel.ShuffleDeck(tp)

	Duel.Draw(tp,1,REASON_EFFECT)
end
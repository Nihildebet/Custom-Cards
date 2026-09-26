local s,id=GetID()

function s.initial_effect(c)

	--=========================================================
	-- Special Summon from hand
	--
	-- Tribute 2 non-LIGHT monsters from your Deck,
	-- including at least 1 Gemini monster.
	--=========================================================

	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_RELEASE)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetRange(LOCATION_HAND)
	e1:SetCondition(s.spcon)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)


	--=========================================================
	-- Gemini Procedure
	--=========================================================

	Gemini.AddProcedure(c)


	--=========================================================
	-- Gemini Effect 1
	--
	-- Once per turn:
	-- Set 1 Spell that mentions "Gemini monster"
	-- from your Deck or GY,
	-- then you can shuffle 2 cards from your GY
	-- or banishment into the Deck.
	--=========================================================

	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_LEAVE_GRAVE+CATEGORY_TODECK+CATEGORY_SET)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(Gemini.EffectStatusCondition)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)


		--=========================================================
	-- Gemini Effect 2
	--
	-- Once per turn, when your opponent activates
	-- a monster effect:
	-- Send the top 3 cards of your Deck to the GY,
	-- then draw 1 card.
	--=========================================================

  -- Gemini Effect 2
local e3=Effect.CreateEffect(c)
e3:SetDescription(aux.Stringid(id,2))
e3:SetCategory(CATEGORY_TOGRAVE+CATEGORY_DRAW)
e3:SetType(EFFECT_TYPE_QUICK_O)
e3:SetCode(EVENT_CHAINING)
e3:SetRange(LOCATION_MZONE)
e3:SetCountLimit(1,{id,2})
e3:SetCondition(s.drawcon)
e3:SetCost(s.drawcost)
e3:SetTarget(s.drawtg)
e3:SetOperation(s.drawop)
c:RegisterEffect(e3)

end


--=========================================================
-- Special Summon from Hand
--=========================================================

function s.matfilter(c)
	return c:IsMonster()
		and not c:IsAttribute(ATTRIBUTE_LIGHT)
		and not c:IsAttribute(ATTRIBUTE_DARK)
		and c:IsAbleToGrave()
end

function s.gemmatfilter(c)
	return s.matfilter(c)
		and c:IsType(TYPE_GEMINI)
end


function s.spcon(e,c)

	if c==nil then
		return true
	end

	local tp=c:GetControler()

	-- Need 2 non-LIGHT monsters in Deck
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return false
	end

	if not Duel.IsExistingMatchingCard(
		s.gemmatfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		c
	) then
		return false
	end

	return Duel.IsExistingMatchingCard(
		s.matfilter,
		tp,
		LOCATION_DECK,
		0,
		2,
		c
	)
end


function s.spop(e,tp,eg,ep,ev,re,r,rp)

	--=========================================================
	-- Select 1 Gemini monster first
	--=========================================================

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_RELEASE
	)

	local g=Duel.SelectMatchingCard(
		tp,
		s.gemmatfilter,
		tp,
		LOCATION_DECK,
		0,
		1,1,
		e:GetHandler()
	)

	if #g==0 then
		return
	end

	--=========================================================
	-- Select the second non-LIGHT monster
	--=========================================================

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_RELEASE
	)

	local g2=Duel.SelectMatchingCard(
		tp,
		s.matfilter,
		tp,
		LOCATION_DECK,
		0,
		1,1,
		g:GetFirst(),
		e:GetHandler()
	)

	if #g2==0 then
		return
	end

	g:Merge(g2)

	--=========================================================
	-- Send both to GY as Tribute
	--=========================================================

	if Duel.SendtoGrave(
		g,
		REASON_COST+REASON_RELEASE
	)~=2 then
		return
	end

end


--=========================================================
-- Gemini Effect 1
-- Set 1 Spell that mentions "Gemini monster"
-- from Deck or GY
--=========================================================

function s.setfilter(c)
	return c:IsSpell()
		and c:ListsCardType(TYPE_GEMINI)
		and c:IsSSetable()
end


function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)

	if chk==0 then

		if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then
			return false
		end

		return Duel.IsExistingMatchingCard(
			s.setfilter,
			tp,
			LOCATION_DECK+LOCATION_GRAVE,
			0,
			1,
			nil
		)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_LEAVE_GRAVE,
		nil,
		1,
		tp,
		LOCATION_DECK+LOCATION_GRAVE
	)

end


function s.setop(e,tp,eg,ep,ev,re,r,rp)

	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_SET
	)

	local g=Duel.SelectMatchingCard(
		tp,
		s.setfilter,
		tp,
		LOCATION_DECK+LOCATION_GRAVE,
		0,
		1,1,
		nil
	)

	local tc=g:GetFirst()

	if not tc then
		return
	end

	Duel.SSet(tp,tc)

	--=========================================================
	-- Optional: shuffle 2 cards from GY or banishment
	-- into the Deck
	--=========================================================

	local rg=Duel.GetMatchingGroup(
		s.todeckfilter,
		tp,
		LOCATION_GRAVE+LOCATION_REMOVED,
		0,
		nil
	)

	if #rg<2 then
		return
	end

	if not Duel.SelectYesNo(
		tp,
		aux.Stringid(id,3)
	) then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_TODECK
	)

	local sg=rg:Select(tp,2,2,nil)

	if #sg==2 then
		Duel.SendtoDeck(
			sg,
			nil,
			SEQ_DECKSHUFFLE,
			REASON_EFFECT
		)
	end
end


function s.todeckfilter(c)
	return c:IsAbleToDeck()
end


--=========================================================
-- Gemini Effect 2
-- Opponent activates a monster effect
--=========================================================

function s.drawcon(e,tp,eg,ep,ev,re,r,rp)
	if not Gemini.EffectStatusCondition(e,tp,eg,ep,ev,re,r,rp) then
		return false
	end
	return rp==1-tp
		and re:IsActiveType(TYPE_MONSTER)
end

function s.drawtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsPlayerCanDraw(tp,1)
	end
	Duel.SetOperationInfo(
		0,CATEGORY_DRAW,nil,1,tp,0
	)
end


function s.drawcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsPlayerCanDiscardDeckAsCost(tp,3)
	end
	Duel.DiscardDeck(tp,3,REASON_COST)
end




function s.drawop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Draw(tp,1,REASON_EFFECT)
end
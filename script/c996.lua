--Apostasia Azarithiel
local s,id=GetID()

function s.initial_effect(c)
	
	--If a Ritual Monster you control would be destroyed: shuffle 3 cards
	--from your GY and/or banishment to the Deck instead.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EFFECT_DESTROY_REPLACE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTarget(s.reptg)
	e1:SetValue(s.repval)
	e1:SetOperation(s.repop)
	c:RegisterEffect(e1)

	--If this card is Ritual Summoned: add card(s) from GY/banishment to hand,
	--up to the number of material used for this card's Ritual Summon.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCountLimit(1,id*100+1)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	--If card(s) is shuffled from your Graveyard or banishment to the Deck:
	--you can banish 1 card from your Deck and 1 card on the field. (HOPT)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,3))
	e3:SetCategory(CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_TO_DECK)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id*100+3)
	e3:SetCondition(s.shufflecon)
	e3:SetTarget(s.shuffletg)
	e3:SetOperation(s.shuffleop)
	c:RegisterEffect(e3)
end

--============================================================
-- (1) REPLACE DESTRUCTION OF YOUR RITUAL MONSTERS
--============================================================
function s.repfilter(c,tp)
	return c:IsFaceup() and c:IsType(TYPE_RITUAL) and c:IsType(TYPE_MONSTER) and c:IsControler(tp)
end

function s.repval(e,c)
	return s.repfilter(c,e:GetHandlerPlayer())
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetMatchingGroupCount(Card.IsAbleToDeck,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)>=3
			and eg:IsExists(s.repfilter,1,nil,tp)
	end
	return Duel.SelectEffectYesNo(tp,e:GetHandler(),aux.Stringid(id,0))
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,Card.IsAbleToDeck,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,3,3,nil)
	if g:GetCount()==3 then
		Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT+REASON_REPLACE)
	end
end

--============================================================
-- (2) IF RITUAL SUMMONED: ADD CARD(S) FROM GY/BANISHMENT TO HAND
--   jumlahnya = jumlah material yang dipakai untuk Ritual Summon ini
--============================================================
function s.thfilter(c)
	return true
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_RITUAL)
end

--Ambil jumlah material Ritual Summon dari kartu ini.
--Kalau Ritual Spell yang dipakai tidak mencatat material (c:SetMaterial),
--nilainya di-fallback ke 1 supaya efek tetap bisa jalan (bukan 0/gagal total).
function s.getmatcount(c)
	local mg=c:GetMaterial()
	local mc=mg and mg:GetCount() or 0
	if mc<=0 then mc=1 end
	return mc
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil)
	end
	local mc=s.getmatcount(e:GetHandler())
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,mc,tp,LOCATION_GRAVE+LOCATION_REMOVED)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil) then return end
	local mc=s.getmatcount(e:GetHandler())
	local ct=math.min(mc,Duel.GetMatchingGroupCount(s.thfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil))
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,ct,nil)
	if g:GetCount()>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end


--============================================================
-- (4) IF CARD(S) IS SHUFFLED FROM YOUR GY/BANISHMENT TO THE DECK:
--   Banish 1 card from your Deck and 1 card on the field.
--============================================================

function s.shufflefilter(c,tp)
	return c:IsPreviousLocation(LOCATION_GRAVE+LOCATION_REMOVED)
end

function s.shufflecon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.shufflefilter,1,nil,tp)
end

function s.fieldfilter(c)
	return c:IsOnField() and c:IsAbleToRemove()
end

function s.deckfilter(c)
	return c:IsAbleToRemove()
end

function s.shuffletg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.fieldfilter,tp,
			LOCATION_ONFIELD,LOCATION_ONFIELD,
			1,nil
		)
		and Duel.IsExistingMatchingCard(
			s.deckfilter,tp,
			LOCATION_DECK,0,
			1,nil
		)
	end

	Duel.SetOperationInfo(
		0,CATEGORY_REMOVE,nil,1,tp,
		LOCATION_ONFIELD
	)
	Duel.SetOperationInfo(
		0,CATEGORY_REMOVE,nil,1,tp,
		LOCATION_DECK
	)
end

function s.shuffleop(e,tp,eg,ep,ev,re,r,rp)
	-- Banish 1 card from the field
	if not Duel.IsExistingMatchingCard(
		s.fieldfilter,tp,
		LOCATION_ONFIELD,LOCATION_ONFIELD,
		1,nil
	) then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local fg=Duel.SelectMatchingCard(
		tp,s.fieldfilter,tp,
		LOCATION_ONFIELD,LOCATION_ONFIELD,
		1,1,nil
	)

	if #fg>0 then
		Duel.Remove(fg,POS_FACEUP,REASON_EFFECT)
	end

	-- Banish 1 card from your Deck
	if Duel.IsExistingMatchingCard(
		s.deckfilter,tp,
		LOCATION_DECK,0,
		1,nil
	) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local dg=Duel.SelectMatchingCard(
			tp,s.deckfilter,tp,
			LOCATION_DECK,0,
			1,1,nil
		)

		if #dg>0 then
			Duel.Remove(dg,POS_FACEUP,REASON_EFFECT)
		end
	end
end
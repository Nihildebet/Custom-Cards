--Apostasia Commandment
local s,id=GetID()
local SET_APOSTASIA=0x4AA
function s.initial_effect(c)
	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id*100,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	e1:SetCost(s.cost)
	c:RegisterEffect(e1)

	-- If this card is banished: Set this card, then shuffle up to 3 banished cards
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_LEAVE_GRAVE+CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_REMOVE)
	e2:SetCountLimit(1,id*100+1,EFFECT_COUNT_CODE_OATH)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
end

-- You control no monster Summoned from the Extra Deck
function s.exmonster(c)
	return c:IsFaceup() and c:IsSummonLocation(LOCATION_EXTRA)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return not Duel.IsExistingMatchingCard(
		s.exmonster,tp,LOCATION_MZONE,0,1,nil
	)
end

-- Own monster from hand or field
function s.ownmonster(c)
	return c:IsType(TYPE_MONSTER) and c:IsAbleToRemove()
end

-- Opponent's monster
function s.opmonster(c)
	return c:IsType(TYPE_MONSTER) and c:IsAbleToRemove()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=4
			and Duel.IsExistingMatchingCard(
				s.ownmonster,tp,LOCATION_HAND+LOCATION_MZONE,0,1,nil
			)
			and Duel.IsExistingMatchingCard(
				s.opmonster,tp,0,LOCATION_MZONE,1,nil
			)
	end

	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,4,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_HAND+LOCATION_MZONE)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_MZONE)
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=4
	end

	local g=Duel.GetDecktopGroup(tp,4)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end


function s.activate(e,tp,eg,ep,ev,re,r,rp)
	-- Banish the top 4 cards of your Deck
  

	-- Banish 1 monster from your hand or field
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g1=Duel.SelectMatchingCard(
		tp,s.ownmonster,tp,LOCATION_HAND+LOCATION_MZONE,0,1,1,nil
	)
	if #g1==0 then return end

	Duel.Remove(g1,POS_FACEUP,REASON_EFFECT)

	-- Banish 1 monster your opponent controls
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g2=Duel.SelectMatchingCard(
		tp,s.opmonster,tp,0,LOCATION_MZONE,1,1,nil
	)
	if #g2==0 then return end

	Duel.Remove(g2,POS_FACEUP,REASON_EFFECT)

	-- You cannot Special Summon from the Extra Deck for the rest of this turn
	local e1=Effect.CreateEffect(e:GetHandler())
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

-- Set this card from banishment
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return c:IsLocation(LOCATION_REMOVED)
			and c:IsSSetable()
	end
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsLocation(LOCATION_REMOVED) then return end
	if not Duel.SSet(tp,c) then return end

	-- Shuffle up to 3 of your banished cards into the Deck
	local g=Duel.GetMatchingGroup(
		Card.IsAbleToDeck,tp,LOCATION_REMOVED,0,nil
	)

	if #g==0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local sg=g:Select(tp,0,math.min(3,#g),nil)

	if #sg>0 then
		Duel.SendtoDeck(
			sg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT
		)
	end
end
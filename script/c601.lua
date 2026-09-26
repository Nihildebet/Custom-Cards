local s,id=GetID()

function s.initial_effect(c)
	-- Special Summon from hand + draw
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_BATTLE_DAMAGE)
	e1:SetRange(LOCATION_HAND)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)

	-- Cannot be destroyed by battle
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e2:SetValue(1)
	e2:SetCondition(s.handspcon)
	c:RegisterEffect(e2)

	-- Battle Damage involving this card becomes LP gain
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_REVERSE_DAMAGE)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(1,0)
	e3:SetValue(s.dmgval)
	e3:SetCondition(s.handspcon)
	c:RegisterEffect(e3)
end

-- If you take Battle Damage
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return ep==tp
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
	end

	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)

	local ct=math.floor(ev/600)
	if ct>0 then
		Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,ct,tp,ct)
	end
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsRelateToEffect(e) then return end

	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then

		-- Mark this card as Special Summoned from the hand
		c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)

		-- Draw 1 card for every 1000 damage
		local ct=math.floor(ev/1000)
		if ct>0 then
			Duel.Draw(tp,ct,REASON_EFFECT)
		end
	end
end

-- This card was Special Summoned from the hand
function s.handspcon(e)
	return e:GetHandler():GetFlagEffect(id)>0
end

-- Reverse only Battle Damage from a battle involving this card
function s.dmgval(e,re,r,rp,rc)
	if (r&REASON_BATTLE)==0 then
		return false
	end

	local c=e:GetHandler()
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()

	return a==c or d==c
end
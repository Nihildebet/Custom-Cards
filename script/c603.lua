local s,id=GetID()

function s.initial_effect(c)
	-- Spell/Trap you control cannot be targeted by opponent
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_SZONE,0)
	e1:SetCondition(s.lpcon)
	e1:SetValue(s.tgvalue)
	c:RegisterEffect(e1)

	-- Spell/Trap you control cannot be destroyed by opponent's effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_SZONE,0)
	e2:SetCondition(s.lpcon)
	e2:SetValue(s.desvalue)
	c:RegisterEffect(e2)

	-- Special Summon from hand + inflict damage
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DAMAGE)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_BATTLE_DAMAGE)
	e3:SetRange(LOCATION_HAND)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCondition(s.condition)
	e3:SetTarget(s.target)
	e3:SetOperation(s.operation)
	c:RegisterEffect(e3)

	-- Cannot be destroyed by battle
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e4:SetValue(1)
	e4:SetCondition(s.handspcon)
	c:RegisterEffect(e4)

	-- Battle Damage involving this card becomes LP gain
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD)
	e5:SetCode(EFFECT_REVERSE_DAMAGE)
	e5:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e5:SetRange(LOCATION_MZONE)
	e5:SetTargetRange(1,0)
	e5:SetValue(s.dmgval)
	e5:SetCondition(s.handspcon)
	c:RegisterEffect(e5)
end

-- Your LP must be higher than your opponent's
function s.lpcon(e)
	local tp=e:GetHandlerPlayer()
	return Duel.GetLP(tp)>Duel.GetLP(1-tp)
end

-- Only opponent's card effects cannot target
function s.tgvalue(e,re,rp)
	return rp~=e:GetHandlerPlayer()
end

-- Only opponent's card effects cannot destroy
function s.desvalue(e,re,rp)
	return rp~=e:GetHandlerPlayer()
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

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		e:GetHandler(),
		1,
		0,
		0
	)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsRelateToEffect(e) then return end

	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then

		-- Mark this card as Special Summoned from the hand
		c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)

		-- Count opponent's cards on the field and in their hand
		local ct=Duel.GetFieldGroupCount(
			tp,
			0,
			LOCATION_ONFIELD+LOCATION_HAND
		)

		local dam=ct*500

		if dam>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
			Duel.Damage(1-tp,dam,REASON_EFFECT)
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
local s,id=GetID()

function s.initial_effect(c)
	-- Special Summon from hand
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DISABLE)
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
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsRelateToEffect(e) then return end

	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then

		-- Mark this card as Special Summoned from the hand
		c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)

		-- Number of cards that can have their effects negated
		local ct=math.floor(ev/1000)

		if ct>0 then
			local g=Duel.GetMatchingGroup(
				Card.IsFaceup,
				tp,
				LOCATION_ONFIELD,
				LOCATION_ONFIELD,
				nil
			)

			if #g>0 then
				local max_count=math.min(ct,#g)

				-- Non-targeting selection
				local sg=Duel.SelectMatchingCard(
					tp,
					Card.IsFaceup,
					tp,
					LOCATION_ONFIELD,
					LOCATION_ONFIELD,
					1,
					max_count,
					nil
				)

				-- Negate all selected cards
				for tc in aux.Next(sg) do
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_DISABLE)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1)

	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_DISABLE_EFFECT)
	e2:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e2)

	-- Remove the negation at the End Phase of your turn
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_PHASE+PHASE_END)
	e3:SetLabel(tp)
	e3:SetLabelObject(e1)
	e3:SetOperation(s.resetnegate)
	Duel.RegisterEffect(e3,tp)

	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_PHASE+PHASE_END)
	e4:SetLabel(tp)
	e4:SetLabelObject(e2)
	e4:SetOperation(s.resetnegate)
	Duel.RegisterEffect(e4,tp)
end
			end
		end
	end
end

function s.resetnegate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetTurnPlayer()==e:GetLabel() then
		local ce=e:GetLabelObject()

		if ce then
			ce:Reset()
		end

		e:Reset()
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
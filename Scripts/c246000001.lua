-- Recharge Dinomorphia
local s, id = GetID()

s.listed_series = {0x173}

function s.initial_effect(c)
	-- Activation le tour où elle est Posée (en payant la moitié des LP)
	local e0 = Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
	e0:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	c:RegisterEffect(e0)

	-- Effet 1 : Poser 1 M/P Dinomorphia depuis le Deck
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1, id) -- Limite partagée (1 seul effet par tour)
	e1:SetCost(s.actcost)
	e1:SetTarget(s.settg)
	e1:SetOperation(s.setop)
	c:RegisterEffect(e1)

	-- Effet 2 : Bannir depuis le Cimetière à l'attaque adverse -> Détruire l'attaquant
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_ATTACK_ANNOUNCE)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1, id) -- Limite partagée (1 seul effet par tour)
	e2:SetCondition(s.descon)
	e2:SetCost(s.descost)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
end

function s.actcost(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then
		if c:IsStatus(STATUS_SET_TURN) then
			return Duel.CheckLPCost(tp, 1)
		end
		return true
	end
	if c:IsStatus(STATUS_SET_TURN) then
		Duel.PayLPCost(tp, math.floor(Duel.GetLP(tp) / 2))
	end
end

function s.setfilter(c)
	return (c:IsSetCard(0x173) or c:IsOriginalSetCard(0x173))
		and (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP))
		and not c:IsCode(id)
		and c:IsSSetable()
end

function s.settg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.IsExistingMatchingCard(s.setfilter, tp, LOCATION_DECK, 0, 1, nil)
	end
end

function s.setop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SET)
	local g = Duel.SelectMatchingCard(tp, s.setfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
	if #g > 0 then
		local tc = g:GetFirst()
		if Duel.SSet(tp, tc) > 0 and Duel.GetTurnPlayer() ~= tp then
			-- Rendre la carte activable ce tour si c'est le tour adverse
			local e1 = Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
			e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
			e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
			tc:RegisterEffect(e1)
			local e2 = e1:Clone()
			e2:SetCode(EFFECT_QP_ACT_IN_SET_TURN)
			tc:RegisterEffect(e2)
		end
	end
end

function s.descon(e, tp, eg, ep, ev, re, r, rp)
	local ac = Duel.GetAttacker()
	local tc = Duel.GetAttackTarget()
	return ac and ac:IsControler(1 - tp) and tc and tc:IsFaceup()
		and (tc:IsSetCard(0x173) or tc:IsOriginalSetCard(0x173))
		and tc:IsControler(tp)
end

function s.descost(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then return c:IsAbleToRemoveAsCost() end
	Duel.Remove(c, POS_FACEUP, REASON_COST)
end

function s.destg(e, tp, eg, ep, ev, re, r, rp, chk)
	local ac = Duel.GetAttacker()
	if chk == 0 then return ac and ac:IsRelateToBattle() and ac:IsDestructable() end
	Duel.SetTargetCard(ac)
	Duel.SetOperationInfo(0, CATEGORY_DESTROY, ac, 1, 0, 0)
end

function s.desop(e, tp, eg, ep, ev, re, r, rp)
	local ac = Duel.GetFirstTarget()
	if ac and ac:IsRelateToBattle() and ac:IsRelateToEffect(e) then
		Duel.Destroy(ac, REASON_EFFECT)
	end
end
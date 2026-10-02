-- Relique Égyptienne - Titanium de Crystal
local s, id = GetID()

s.listed_series = {0xdd7}

function s.initial_effect(c)
	-- Effet 1 : Envoyer des cartes du Deck au Cimetière à l'Invocation
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1, id)
	e1:SetTarget(s.tgtg)
	e1:SetOperation(s.tgop)
	c:RegisterEffect(e1)
	local e2 = e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)

	-- Effet 2 : (Effet Rapide) Annuler et détruire l'activation adverse
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 1))
	e3:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
	e3:SetRange(LOCATION_MZONE + LOCATION_GRAVE)
	e3:SetCountLimit(1, id + 100)
	e3:SetCondition(s.negcon)
	e3:SetCost(s.negcost)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)
end

function s.tgfilter(c)
	return c:IsSetCard(0xdd7) and c:IsAbleToGrave()
end

function s.tgtg(e, tp, eg, ep, ev, re, r, rp, chk)
	local max_ct = Duel.GetFieldGroupCount(1 - tp, LOCATION_HAND, 0)
	if chk == 0 then
		return max_ct > 0 and Duel.IsExistingMatchingCard(s.tgfilter, tp, LOCATION_DECK, 0, 1, nil)
	end
	Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, nil, 1, tp, LOCATION_DECK)
end

function s.tgop(e, tp, eg, ep, ev, re, r, rp)
	local max_ct = Duel.GetFieldGroupCount(1 - tp, LOCATION_HAND, 0)
	if max_ct <= 0 then return end
	local g = Duel.GetMatchingGroup(s.tgfilter, tp, LOCATION_DECK, 0, nil)
	if #g == 0 then return end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
	local sg = g:SelectSubGroup(tp, aux.dncheck, false, 1, max_ct)
	if sg and #sg > 0 then
		Duel.SendtoGrave(sg, REASON_EFFECT)
	end
end

function s.negcon(e, tp, eg, ep, ev, re, r, rp)
	return ep == 1 - tp and Duel.IsChainNegatable(ev)
end

function s.cfilter(c)
	return c:IsSetCard(0xdd7) and c:IsAbleToRemoveAsCost()
end

function s.negcost(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	local g = Duel.GetMatchingGroup(s.cfilter, tp, LOCATION_HAND + LOCATION_GRAVE + LOCATION_ONFIELD, 0, c)
	if chk == 0 then
		return c:IsAbleToRemoveAsCost() and g:CheckSubGroup(aux.dncheck, 2, 2)
	end
	Duel.Remove(c, POS_FACEUP, REASON_COST)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
	local sg = g:SelectSubGroup(tp, aux.dncheck, false, 2, 2)
	Duel.Remove(sg, POS_FACEUP, REASON_COST)
end

function s.negtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return true end
	Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
	if re:GetHandler():IsRelateToEffect(re) and re:GetHandler():IsDestructable() then
		Duel.SetOperationInfo(0, CATEGORY_DESTROY, eg, 1, 0, 0)
	end
end

function s.negop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg, REASON_EFFECT)
	end
end
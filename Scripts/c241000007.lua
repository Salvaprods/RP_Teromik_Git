-- Promotion - Echec Divin
local s, id = GetID()
function s.initial_effect(c)
	-- Activer la carte (Piège Continue standard)
	local e0 = Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-- Effet 1 : Envoyer cette carte + une autre carte "Echec Divin" au Cimetière pour détruire une carte (Effet Rapide)
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_SZONE)
	e1:SetHintTiming(0, TIMINGS_CHECK_MONSTER)
	e1:SetCountLimit(1, id)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)

	-- Effet 2 : Bannir depuis le Cimetière pour déplacer un monstre "Echec Divin" vers une autre zone
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1, id + 100)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.mvtg)
	e2:SetOperation(s.mvop)
	c:RegisterEffect(e2)
end

s.listed_series = {0xe7a} -- Echec Divin

-- ==========================================
-- EFFET 1 : COÛT, CIBLE ET OPÉRATION (DESTRUCTION)
-- ==========================================
function s.cfilter(c)
	return c:IsSetCard(0xe7a) and c:IsAbleToGraveAsCost()
end

function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then 
		return c:IsAbleToGraveAsCost() 
			and Duel.IsExistingMatchingCard(s.cfilter, tp, LOCATION_ONFIELD, 0, 1, c) 
	end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
	local g = Duel.SelectMatchingCard(tp, s.cfilter, tp, LOCATION_ONFIELD, 0, 1, 1, c)
	g:AddCard(c)
	Duel.SendtoGrave(g, REASON_COST)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsControler(1 - tp) and chkc:IsOnField() and chkc:IsDestructable() end
	if chk == 0 then return Duel.IsExistingTarget(Card.IsDestructable, tp, 0, LOCATION_ONFIELD, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
	local g = Duel.SelectTarget(tp, Card.IsDestructable, tp, 0, LOCATION_ONFIELD, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, 1, 0, 0)
end

function s.operation(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc, REASON_EFFECT)
	end
end

-- ==========================================
-- EFFET 2 : DÉPLACEMENT DE ZONE DEPUIS LE CIMETIÈRE
-- ==========================================
function s.mvfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xe7a)
end

function s.mvtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.mvfilter(chkc) end
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and Duel.IsExistingTarget(s.mvfilter, tp, LOCATION_MZONE, 0, 1, nil)
	end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
	Duel.SelectTarget(tp, s.mvfilter, tp, LOCATION_MZONE, 0, 1, 1, nil)
end

function s.mvop(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) or not tc:IsFaceup() then return end
	
	local flag = 0
	for i = 0, 4 do
		if Duel.CheckLocation(tp, LOCATION_MZONE, i) then
			flag = flag | (1 << i)
		end
	end
	if flag == 0 then return end
	
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOZONE)
	local zone = Duel.SelectField(tp, 1, LOCATION_MZONE, 0, ~flag)
	local seq = 0
	for i = 0, 4 do
		if (zone & (1 << i)) ~= 0 then
			seq = i
			break
		end
	end
	
	if seq ~= tc:GetSequence() then
		Duel.MoveSequence(tc, seq)
	end
end
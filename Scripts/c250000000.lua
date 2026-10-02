-- Cure Profonde - Âme Du Chasseur
local s, id = GetID()

function s.initial_effect(c)
	-- 1. Effet d'activation : Chercher une carte "Âme Du Chasseur" ou la placer en Zone Pendule
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1, id) -- HOPT pour l'effet 1
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- 2. Effet Rapide (Cimetière) : Si l'adversaire Invoque Spécialement depuis l'Extra Deck
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 2))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_SPSUMMON)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1, id + 100) -- HOPT pour l'effet 2
	e2:SetCondition(s.condition)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.target)
	e2:SetOperation(s.operation)
	c:RegisterEffect(e2)
end

-- ==========================================
-- EFFET 1 : RECHERCHE / ZONE PENDULE
-- ==========================================
function s.thfilter(c, tp)
	-- Doit appartenir à l'archétype 0xc92 et exclure la carte elle-même
	if not (c:IsSetCard(0xc92) and c:IsCode(id) == false) then return false end
	local b1 = c:IsAbleToHand()
	local b2 = c:IsType(TYPE_PENDULUM) and (Duel.CheckLocation(tp, LOCATION_PZONE, 0) or Duel.CheckLocation(tp, LOCATION_PZONE, 1))
	return b1 or b2
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then 
		return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil, tp) 
	end
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end

function s.thop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_OPERATECARD)
	local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK, 0, 1, 1, nil, tp)
	local tc = g:GetFirst()
	if tc then
		local b1 = tc:IsAbleToHand()
		local b2 = tc:IsType(TYPE_PENDULUM) and (Duel.CheckLocation(tp, LOCATION_PZONE, 0) or Duel.CheckLocation(tp, LOCATION_PZONE, 1))
		local op = 0
		if b1 and b2 then
			op = Duel.SelectOption(tp, aux.Stringid(id, 0), aux.Stringid(id, 1))
		elseif b1 then
			op = 0
		else
			op = 1
		end
		
		if op == 0 then
			Duel.SendtoHand(tc, nil, REASON_EFFECT)
			Duel.ConfirmCards(1 - tp, tc)
		else
			Duel.MoveToField(tc, tp, tp, LOCATION_PZONE, POS_FACEUP, true)
		end
	end
end

-- ==========================================
-- EFFET 2 : INTERACTION CIMETIÈRE CONTRE EXTRA DECK
-- ==========================================
function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xc92)
end

function s.exspfilter(c, tp)
	return c:IsControler(1 - tp) and c:IsSummonLocation(LOCATION_EXTRA)
end

function s.condition(e, tp, eg, ep, ev, re, r, rp)
	-- Contrôler au moins un monstre "Âme Du Chasseur" ET l'adversaire invoque depuis l'Extra Deck
	return Duel.IsExistingMatchingCard(s.cfilter, tp, LOCATION_MZONE, 0, 1, nil)
		and eg:IsExists(s.exspfilter, 1, nil, tp)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return eg:IsContains(chkc) and s.exspfilter(chkc, tp) and chkc:IsCanBeEffectTarget(e) end
	if chk == 0 then return eg:IsExists(s.exspfilter, 1, nil, tp) end
	
	local g = eg:Filter(s.exspfilter, nil, tp)
	local tc = nil
	if #g == 1 then
		tc = g:GetFirst()
	else
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
		local sg = g:Select(tp, 1, 1, nil)
		tc = sg:GetFirst()
	end
	
	Duel.SetTargetCard(tc)
	Duel.SetOperationInfo(0, CATEGORY_DESTROY, tc, 1, 0, 0)
end

function s.operation(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc, REASON_EFFECT)
	end
end
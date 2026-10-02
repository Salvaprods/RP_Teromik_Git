-- Café du Coin Devcutie
local s, id = GetID()

s.listed_series = {0xb8e}
local COUNTER_DEV = 0x1b8e

function s.initial_effect(c)
	-- Activer la carte & Autoriser les compteurs
	c:EnableCounterPermit(COUNTER_DEV)

	-- Effet 1 : Lorsque cette carte est activée -> Recherche 1 "Devcutie"
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1, id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Effet 2 : Main Phase -> Détruit 1 carte "Devcutie" (main/terrain) pour Spécialement 1 monstre depuis le Deck
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_FZONE)
	e2:SetCountLimit(1, id + 100)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	-- Effet 3 : Annuler activation en retirant 3 Compteurs "Dev"
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 2))
	e3:SetCategory(CATEGORY_NEGATE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCountLimit(1, id + 200)
	e3:SetCondition(s.negcon)
	e3:SetCost(s.negcost)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)

	-- Effet Inhérent : Placement automatique d'un Compteur "Dev" (sans chaîne ni déclaration)
	local e4 = Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_DESTROYED)
	e4:SetRange(LOCATION_FZONE)
	e4:SetCondition(s.ctcon)
	e4:SetOperation(s.ctop)
	c:RegisterEffect(e4)
end

-- ==========================================
-- EFFET 1 : RECHERCHE SUR ACTIVATION
-- ==========================================
function s.thfilter(c)
	return c:IsSetCard(0xb8e) and not c:IsCode(id) and c:IsAbleToHand()
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return true end
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 0, tp, LOCATION_DECK)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
	local g = Duel.GetMatchingGroup(s.thfilter, tp, LOCATION_DECK, 0, nil)
	if #g > 0 and Duel.SelectYesNo(tp, aux.Stringid(id, 3)) then
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
		local sg = g:Select(tp, 1, 1, nil)
		Duel.SendtoHand(sg, nil, REASON_EFFECT)
		Duel.ConfirmCards(1 - tp, sg)
	end
end

-- ==========================================
-- EFFET 2 : INVOCATION SPÉCIALE DEPUIS LE DECK
-- ==========================================
function s.costfilter(c, e, tp)
	if not (c:IsSetCard(0xb8e) and (c:IsLocation(LOCATION_HAND) or (c:IsLocation(LOCATION_ONFIELD) and c:IsFaceup()))) then return false end
	local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
	if c:IsLocation(LOCATION_MZONE) then ft = ft + 1 end
	if ft <= 0 then return false end
	return Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_DECK, 0, 1, nil, e, tp, c:GetCode())
end

function s.spfilter(c, e, tp, code)
	return c:IsSetCard(0xb8e) and c:IsType(TYPE_MONSTER) and not c:IsCode(code) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.IsExistingMatchingCard(s.costfilter, tp, LOCATION_HAND + LOCATION_ONFIELD, 0, 1, nil, e, tp)
	end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
	local g = Duel.SelectMatchingCard(tp, s.costfilter, tp, LOCATION_HAND + LOCATION_ONFIELD, 0, 1, 1, nil, e, tp)
	local code = g:GetFirst():GetCode()
	Duel.Destroy(g, REASON_COST + REASON_EFFECT)
	e:SetLabel(code)
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_DECK)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
	local code = e:GetLabel()
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local g = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_DECK, 0, 1, 1, nil, e, tp, code)
	if #g > 0 then
		Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
	end
end

-- ==========================================
-- EFFET 3 : ANNULATION D'ACTIVATION
-- ==========================================
function s.cfilter(c)
	return c:IsSetCard(0xb8e) and c:IsFaceup()
end

function s.negcon(e, tp, eg, ep, ev, re, r, rp)
	return ep == 1 - tp and Duel.IsChainNegatable(ev)
		and Duel.IsExistingMatchingCard(s.cfilter, tp, LOCATION_ONFIELD, 0, 1, nil)
end

function s.negcost(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then return c:IsCanRemoveCounter(tp, COUNTER_DEV, 3, REASON_COST) end
	c:RemoveCounter(tp, COUNTER_DEV, 3, REASON_COST)
end

function s.negtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return true end
	Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
end

function s.negop(e, tp, eg, ep, ev, re, r, rp)
	Duel.NegateActivation(ev)
end

-- ==========================================
-- EFFET INHÉRENT : GAIN DE COMPTEUR AUTOMATIQUE
-- ==========================================
function s.ctfilter(c)
	return (c:IsSetCard(0xb8e) or c:IsPreviousSetCard(0xb8e))
		and (c:IsReason(REASON_EFFECT) or c:IsReason(REASON_COST))
end

function s.ctcon(e, tp, eg, ep, ev, re, r, rp)
	return eg:IsExists(s.ctfilter, 1, nil)
end

function s.ctop(e, tp, eg, ep, ev, re, r, rp)
	e:GetHandler():AddCounter(COUNTER_DEV, 1)
end
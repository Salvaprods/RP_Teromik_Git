-- Devcutie - Leyla
local s, id = GetID()

s.listed_series = {0xb8e}

function s.initial_effect(c)
	-- Invocable par Fusion (2 monstres "Devcutie")
	c:EnableReviveLimit()
	aux.AddFusionProcMixRep(c, true, true, aux.FilterBoolFunction(Card.IsSetCard, 0xb8e), 2, 2)

	-- Effet Continu : L'adversaire doit payer 1000 LP pour Invoquer depuis l'Extra Deck
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_COST)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(0, 1)
	e1:SetCost(s.splpcost)
	e1:SetOperation(s.splpop)
	c:RegisterEffect(e1)

	-- Effet Rapide (Main Phase) : Détruit 1 carte (Main/Terrain) pour détruire 1 carte adverse (+1 si Lien/Fusion Devcutie)
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 0))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0, TIMING_MAIN_END + TIMINGS_CHECK_MONSTER)
	e2:SetCountLimit(1, id)
	e2:SetCondition(s.descon)
	e2:SetCost(s.descost)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)

	-- Effet Déclencheur (Cimetière) : Détruite par un effet durant le tour adverse -> Se Spécialise et détruit 1 carte
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetCountLimit(1, id + 100)
	e3:SetCondition(s.spcon)
	e3:SetCost(s.spcost)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

-- ==========================================
-- EFFET 1 : TAXE LP EXTRA DECK
-- ==========================================
function s.splpcost(e, c, tp, st)
	if c:IsLocation(LOCATION_EXTRA) then
		return Duel.CheckLPCost(tp, 1000)
	end
	return true
end

function s.splpop(e, tp, eg, ep, ev, re, r, rp)
	Duel.PayLPCost(tp, 1000)
end

-- ==========================================
-- EFFET 2 : DESTRUCTION EN MAIN PHASE
-- ==========================================
function s.descon(e, tp, eg, ep, ev, re, r, rp)
	return Duel.IsMainPhase()
end

function s.descost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(nil, tp, LOCATION_HAND + LOCATION_ONFIELD, 0, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
	local g = Duel.SelectMatchingCard(tp, nil, tp, LOCATION_HAND + LOCATION_ONFIELD, 0, 1, 1, nil)
	local tc = g:GetFirst()
	local is_special = tc:IsSetCard(0xb8e) and (tc:IsType(TYPE_LINK) or (tc:IsType(TYPE_FUSION) and tc:IsType(TYPE_MONSTER)))
	e:SetLabel(is_special and 1 or 0)
	Duel.Destroy(g, REASON_COST + REASON_EFFECT)
end

function s.destg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(nil, tp, 0, LOCATION_ONFIELD, 1, nil) end
	Duel.SetOperationInfo(0, CATEGORY_DESTROY, nil, 1, 1 - tp, LOCATION_ONFIELD)
end

function s.desop(e, tp, eg, ep, ev, re, r, rp)
	local g = Duel.GetMatchingGroup(nil, tp, 0, LOCATION_ONFIELD, nil)
	if #g == 0 then return end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
	local sg = g:Select(tp, 1, 1, nil)
	if Duel.Destroy(sg, REASON_EFFECT) ~= 0 and e:GetLabel() == 1 then
		local g2 = Duel.GetMatchingGroup(nil, tp, 0, LOCATION_ONFIELD, nil)
		if #g2 > 0 and Duel.SelectYesNo(tp, aux.Stringid(id, 2)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
			local sg2 = g2:Select(tp, 1, 1, nil)
			Duel.Destroy(sg2, REASON_EFFECT)
		end
	end
end

-- ==========================================
-- EFFET 3 : RENAISSANCE ET DESTRUCTION
-- ==========================================
function s.spcon(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	return c:IsReason(REASON_EFFECT) and c:IsPreviousLocation(LOCATION_ONFIELD) and Duel.GetTurnPlayer() == 1 - tp
end

function s.banfilter(c)
	return c:IsSetCard(0xb8e) and c:IsType(TYPE_MONSTER) and c:IsAbleToRemoveAsCost()
end

function s.spcost(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then return Duel.IsExistingMatchingCard(s.banfilter, tp, LOCATION_GRAVE, 0, 2, c) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
	local g = Duel.SelectMatchingCard(tp, s.banfilter, tp, LOCATION_GRAVE, 0, 2, 2, c)
	Duel.Remove(g, POS_FACEUP, REASON_COST)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, 0, 0)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP) ~= 0 then
		local g = Duel.GetMatchingGroup(nil, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, nil)
		if #g > 0 and Duel.SelectYesNo(tp, aux.Stringid(id, 3)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
			local sg = g:Select(tp, 1, 1, nil)
			Duel.Destroy(sg, REASON_EFFECT)
		end
	end
end
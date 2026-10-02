-- Devcuties et le Pégase
local s, id = GetID()

s.listed_series = {0xb8e}

function s.initial_effect(c)
	-- Invocable par Synchronisation (1 Syntoniseur "Devcutie" + 1 monstre non-Syntoniseur)
	c:EnableReviveLimit()
	aux.AddSynchroProcedure(c, aux.FilterBoolFunction(Card.IsSetCard, 0xb8e), nil, 1, 1)

	-- Effet 1 : Invoqué par Synchronisation -> Réanime 1 monstre "Devcutie" depuis le Cimetière
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1, id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Effet 2 (Effet Rapide, Votre Main Phase) : Se bannit temporairement -> Tuto ou Invoque en Défense
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH + CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0, TIMING_MAIN_END)
	e2:SetCountLimit(1, id + 100)
	e2:SetCondition(s.bancon)
	e2:SetCost(s.bancost)
	e2:SetTarget(s.bantg)
	e2:SetOperation(s.banop)
	c:RegisterEffect(e2)
end

-- ==========================================
-- EFFET 1 : REANIMATION D'UN MONSTRE DEVCUTIE
-- ==========================================
function s.spcon(e, tp, eg, ep, ev, re, r, rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end

function s.spfilter(c, e, tp)
	return c:IsSetCard(0xb8e) and c:IsType(TYPE_MONSTER) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.spfilter(chkc, e, tp) end
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and Duel.IsExistingTarget(s.spfilter, tp, LOCATION_GRAVE, 0, 1, nil, e, tp)
	end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local g = Duel.SelectTarget(tp, s.spfilter, tp, LOCATION_GRAVE, 0, 1, 1, nil, e, tp)
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, g, 1, 0, 0)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SpecialSummon(tc, 0, tp, tp, false, false, POS_FACEUP)
	end
end

-- ==========================================
-- EFFET 2 : BANISSEMENT TEMPORAIRE & TUTO/SPECIAL
-- ==========================================
function s.bancon(e, tp, eg, ep, ev, re, r, rp)
	return Duel.IsMainPhase() and Duel.GetTurnPlayer() == tp
end

function s.bancost(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then return c:IsAbleToRemoveAsCost() end
	if Duel.Remove(c, POS_FACEUP, REASON_COST + REASON_TEMPORARY) ~= 0 then
		local e1 = Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(EVENT_PHASE + PHASE_END)
		e1:SetReset(RESET_PHASE + PHASE_END)
		e1:SetLabelObject(c)
		e1:SetCountLimit(1)
		e1:SetOperation(s.retop)
		Duel.RegisterEffect(e1, tp)
	end
end

function s.retop(e, tp, eg, ep, ev, re, r, rp)
	Duel.ReturnToField(e:GetLabelObject())
end

function s.thspfilter(c, e, tp, ft)
	return c:IsSetCard(0xb8e) and c:IsType(TYPE_MONSTER)
		and (c:IsAbleToHand() or (ft > 0 and c:IsCanBeSpecialSummoned(e, 0, tp, false, false, POS_DEFENSE)))
end

function s.bantg(e, tp, eg, ep, ev, re, r, rp, chk)
	local ft = Duel.GetMZoneCount(tp, e:GetHandler())
	if chk == 0 then
		return Duel.IsExistingMatchingCard(s.thspfilter, tp, LOCATION_DECK, 0, 1, nil, e, tp, ft)
	end
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_DECK)
end

function s.banop(e, tp, eg, ep, ev, re, r, rp)
	local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_OPERATECARD)
	local g = Duel.SelectMatchingCard(tp, s.thspfilter, tp, LOCATION_DECK, 0, 1, 1, nil, e, tp, ft)
	local tc = g:GetFirst()
	if tc then
		local b1 = tc:IsAbleToHand()
		local b2 = ft > 0 and tc:IsCanBeSpecialSummoned(e, 0, tp, false, false, POS_DEFENSE)
		local op = 0
		if b1 and b2 then
			op = Duel.SelectOption(tp, aux.Stringid(id, 2), aux.Stringid(id, 3))
		elseif b1 then
			op = 0
		else
			op = 1
		end
		if op == 0 then
			Duel.SendtoHand(tc, nil, REASON_EFFECT)
			Duel.ConfirmCards(1 - tp, tc)
		else
			Duel.SpecialSummon(tc, 0, tp, tp, false, false, POS_DEFENSE)
		end
	end
end
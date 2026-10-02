-- Devcutie - Keupsy
local s, id = GetID()

s.listed_series = {0xb8e}

function s.initial_effect(c)
	-- Invoc Spéciale inhérente : Détruire 1 carte "Devcutie" depuis la main ou le Terrain (1 fois par tour)
	local e0 = Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e0:SetRange(LOCATION_HAND)
	e0:SetCountLimit(1, id)
	e0:SetCondition(s.spcon)
	e0:SetTarget(s.sptg)
	e0:SetOperation(s.spop)
	c:RegisterEffect(e0)

	-- Effet 1 : Si Invoqué Normalement ou Spécialement -> Recherche monstre "Devcutie" (1 fois par tour)
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1, id + 100)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	local e1_bis = e1:Clone()
	e1_bis:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e1_bis)

	-- Effet 2 : Envoyé du Terrain au Cimetière -> Invoc Spéciale Monstre Pendule "Devcutie" (1 fois par tour)
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1, id + 200)
	e2:SetCondition(s.spcon2)
	e2:SetTarget(s.sptg2)
	e2:SetOperation(s.spop2)
	c:RegisterEffect(e2)
end

-- ==========================================
-- INVOCATION SPÉCIALE INHÉRENTE
-- ==========================================
function s.spfilter(c, e)
	return c:IsSetCard(0xb8e) and (c:IsLocation(LOCATION_HAND) or (c:IsLocation(LOCATION_ONFIELD) and c:IsFaceup())) and c:IsDestructable(e)
end

function s.spcon(e, c)
	if c == nil then return true end
	local tp = c:GetControler()
	return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
		and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_ONFIELD, 0, 1, c, e)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk, c)
	local g = Duel.GetMatchingGroup(s.spfilter, tp, LOCATION_HAND + LOCATION_ONFIELD, 0, c, e)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
	local sg = g:Select(tp, 1, 1, nil)
	if sg and #sg > 0 then
		sg:KeepAlive()
		e:SetLabelObject(sg)
		return true
	end
	return false
end

function s.spop(e, tp, eg, ep, ev, re, r, rp, c)
	local sg = e:GetLabelObject()
	if sg then
		Duel.Destroy(sg, REASON_EFFECT + REASON_COST)
		sg:DeleteGroup()
	end
end

-- ==========================================
-- EFFET 1 : RECHERCHE MONSTRE
-- ==========================================
function s.thfilter(c)
	return c:IsSetCard(0xb8e) and c:IsType(TYPE_MONSTER) and not c:IsCode(id) and c:IsAbleToHand()
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil)
	end
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end

function s.thop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
	local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
	if #g > 0 then
		Duel.SendtoHand(g, nil, REASON_EFFECT)
		Duel.ConfirmCards(1 - tp, g)
	end
end

-- ==========================================
-- EFFET 2 : INVOCATION SPÉCIALE DEPUIS PZONE/EXTRA
-- ==========================================
function s.spcon2(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	return c:IsPreviousLocation(LOCATION_FIELD)
end

function s.spfilter2(c, e, tp)
	return c:IsSetCard(0xb8e) and c:IsType(TYPE_PENDULUM) 
		and (c:IsLocation(LOCATION_PZONE) or (c:IsLocation(LOCATION_EXTRA) and c:IsFaceup()))
		and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.sptg2(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and Duel.IsExistingMatchingCard(s.spfilter2, tp, LOCATION_PZONE + LOCATION_EXTRA, 0, 1, nil, e, tp)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_PZONE + LOCATION_EXTRA)
end

function s.spop2(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local g = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.spfilter2), tp, LOCATION_PZONE + LOCATION_EXTRA, 0, 1, 1, nil, e, tp)
	if #g > 0 then
		if Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP) ~= 0 then
			local e1 = Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_FIELD)
			e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
			e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
			e1:SetTargetRange(1, 0)
			e1:SetTarget(s.splimit)
			e1:SetReset(RESET_PHASE + PHASE_END)
			Duel.RegisterEffect(e1, tp)
		end
	end
end

function s.splimit(e, c, sump, sumtype, sumpos, targetp, se)
	return not c:IsSetCard(0xb8e)
end
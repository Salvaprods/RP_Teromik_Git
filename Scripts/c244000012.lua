-- Téléportation des Devcuties
local s, id = GetID()

s.listed_series = {0xb8e}

function s.initial_effect(c)
	-- Activer
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1, id, EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- ==========================================
-- FILTRES ET CONDITIONS
-- ==========================================
function s.gyfilter(c)
	return c:IsSetCard(0xb8e) and c:IsType(TYPE_MONSTER)
end

function s.spfilter(c, e, tp, g_gy)
	return c:IsSetCard(0xb8e) and c:IsType(TYPE_MONSTER)
		and not g_gy:IsExists(Card.IsCode, 1, nil, c:GetCode())
		and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
	local g_gy = Duel.GetMatchingGroup(s.gyfilter, tp, LOCATION_GRAVE, 0, nil)
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp, g_gy)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_DECK)
	Duel.SetOperationInfo(0, CATEGORY_DESTROY, nil, 1, tp, LOCATION_MZONE)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
	local g_gy = Duel.GetMatchingGroup(s.gyfilter, tp, LOCATION_GRAVE, 0, nil)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local g = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, e, tp, g_gy)
	if #g > 0 and Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP) ~= 0 then
		local dg = Duel.GetMatchingGroup(nil, tp, LOCATION_MZONE, 0, nil)
		if #dg > 0 then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
			local sg = dg:Select(tp, 1, 1, nil)
			Duel.Destroy(sg, REASON_EFFECT)
		end
	end
end
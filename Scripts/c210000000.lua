-- Force Ultimate - Roi Des Crânes Serviteurs
local s, id = GetID()
function s.initial_effect(c)
	-- Activate
	local e1 = Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0, TIMINGS_CHECK_MONSTER)
	e1:SetCountLimit(1, id, EFFECT_COUNT_CODE_OATH)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end

function s.cfilter(c)
	return c:IsFaceup() and c:IsCode(36021814)
end

function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.CheckReleaseGroup(tp, s.cfilter, 1, false, 1, true, nil, tp, nil, false, nil) end
	local g = Duel.SelectReleaseGroup(tp, s.cfilter, 1, 1, false, 1, true, nil, tp, nil, false, nil)
	Duel.Release(g, REASON_COST)
end

function s.filter(c, e, tp)
	-- true en 4e argument pour contourner la restriction Nomi du monstre
	return c:IsCode(210000001) and c:IsCanBeSpecialSummoned(e, 0, tp, true, false)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > -1
		and Duel.IsExistingMatchingCard(s.filter, tp, LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE, 0, 1, nil, e, tp) end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE)
	if e:IsHasType(EFFECT_TYPE_ACTIVATE) then
		Duel.SetChainLimit(s.chainlimit)
	end
end

function s.chainlimit(e, ep, tp)
	return not e:IsActiveType(TYPE_MONSTER)
end

function s.operation(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local g = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.filter), tp, LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE, 0, 1, 1, nil, e, tp)
	if #g > 0 then
		-- true en 5e argument pour forcer l'invocation Nomi
		Duel.SpecialSummon(g, 0, tp, tp, true, false, POS_FACEUP)
	end
end
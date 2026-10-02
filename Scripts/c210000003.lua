-- Reunions De Famille
local s, id = GetID()

-- Indispensable pour que les autres cartes sachent qu'elle mentionne "Crâne Serviteur"
s.listed_names = {32274490}

function s.initial_effect(c)
	-- Effet 1 : Bannir jusqu'à 5 monstres du Cimetière, puis envoyer autant de cartes de l'adversaire au Cimetière sans cibler
	local e1 = Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_REMOVE + CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0, TIMINGS_CHECK_MONSTER + TIMING_MAIN_END)
	e1:SetCountLimit(1, id, EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Effet 2 : Si un monstre mentionnant "Crâne Serviteur" est détruit et envoyé au Cimetière, bannir cette carte du Cimetière pour Invoquer Spécialement 3 monstres du bannissement
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1, id + 100)
	e2:SetCondition(s.spcon)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

-- Filtre pour les monstres de l'archétype / mention
function s.filter(c)
	return c:IsType(TYPE_MONSTER) and (c:IsCode(32274490) or aux.IsCodeListed(c, 32274490) or c:IsSetCard(0x159)) and c:IsAbleToRemove()
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.IsExistingMatchingCard(s.filter, tp, LOCATION_GRAVE, 0, 1, nil)
			and Duel.IsExistingMatchingCard(nil, tp, 0, LOCATION_ONFIELD, 1, nil)
	end
	Duel.SetOperationInfo(0, CATEGORY_REMOVE, nil, 1, tp, LOCATION_GRAVE)
	Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, nil, 1, 0, LOCATION_ONFIELD)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
	local g = Duel.SelectMatchingCard(tp, s.filter, tp, LOCATION_GRAVE, 0, 1, 5, nil)
	if #g > 0 then
		local ct = Duel.Remove(g, POS_FACEUP, REASON_EFFECT)
		if ct > 0 then
			Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
			local og = Duel.SelectMatchingCard(tp, nil, tp, 0, LOCATION_ONFIELD, ct, ct, nil)
			if #og > 0 then
				Duel.SendtoGrave(og, REASON_EFFECT)
			end
		end
	end
end

-- Condition Effet Cimetière
function s.cfilter(c, tp)
	return c:IsControler(tp) and c:IsPreviousLocation(LOCATION_MZONE) and c:IsReason(REASON_BATTLE | REASON_EFFECT)
		and (c:IsCode(32274490) or aux.IsCodeListed(c, 32274490) or c:IsSetCard(0x159))
end

function s.spcon(e, tp, eg, ep, ev, re, r, rp)
	return eg:IsExists(s.cfilter, 1, nil, tp)
end

-- Filtre pour l'invocation spéciale depuis le bannissement
function s.spsfilter(c, e, tp)
	return (c:IsCode(32274490) or aux.IsCodeListed(c, 32274490) or c:IsSetCard(0x159)) 
		and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) >= 3
			and not Duel.IsPlayerAffectedByEffect(tp, CARD_BLUEEYES_SPIRIT)
			and Duel.IsExistingMatchingCard(s.spsfilter, tp, LOCATION_REMOVED, 0, 3, nil, e, tp)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 3, tp, LOCATION_REMOVED)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetLocationCount(tp, LOCATION_MZONE) < 3 then return end
	local g = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.spsfilter), tp, LOCATION_REMOVED, 0, 3, 3, nil, e, tp)
	if #g == 3 then
		Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
	end
end
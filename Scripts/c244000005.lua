-- L'Assaut des Devcuties
local s, id = GetID()

s.listed_series = {0xb8e}

function s.initial_effect(c)
	-- Activation (Magie Rapide)
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0, TIMING_MAIN_END + TIMINGS_CHECK_MONSTER)
	e1:SetCountLimit(1, id, EFFECT_COUNT_CODE_OATH)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.spfilter(c, e, tp)
	return c:IsSetCard(0xb8e) and c:IsLevel(3) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.costfilter(c, e, tp)
	if not (c:IsSetCard(0xb8e) and (c:IsLocation(LOCATION_HAND) or (c:IsLocation(LOCATION_ONFIELD) and c:IsFaceup()))) then return false end
	local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
	if c:IsLocation(LOCATION_MZONE) then ft = ft + 1 end
	return ft > 0
end

function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	local can_pay = Duel.IsExistingMatchingCard(s.costfilter, tp, LOCATION_HAND + LOCATION_ONFIELD, 0, 1, c, e, tp)
	if chk == 0 then return true end
	
	-- Le joueur choisit à l'activation s'il détruit une carte pour appliquer l'effet
	if can_pay and Duel.SelectYesNo(tp, aux.Stringid(id, 0)) then
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
		local g = Duel.SelectMatchingCard(tp, s.costfilter, tp, LOCATION_HAND + LOCATION_ONFIELD, 0, 1, 1, c, e, tp)
		Duel.Destroy(g, REASON_COST)
		e:SetLabel(1)
	else
		e:SetLabel(0)
	end
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		-- Vérification obligatoire : au moins 1 monstre Devcutie Niv 3 dans le Cimetière
		return Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_GRAVE, 0, 1, nil, e, tp)
	end
	if e:GetLabel() == 1 then
		Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_GRAVE)
	end
end

function s.lkfilter(c, tp)
	return c:IsSetCard(0xb8e) and c:IsType(TYPE_LINK) and c:IsLinkSummonable(nil)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
	-- Si la destruction n'a pas été effectuée, la carte s'active sans effet
	if e:GetLabel() ~= 1 then return end
	if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
	
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local g = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.spfilter), tp, LOCATION_GRAVE, 0, 1, 1, nil, e, tp)
	if #g > 0 and Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP) ~= 0 then
		local lkg = Duel.GetMatchingGroup(s.lkfilter, tp, LOCATION_EXTRA, 0, nil, tp)
		if #lkg > 0 and Duel.SelectYesNo(tp, aux.Stringid(id, 1)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
			local sg = lkg:Select(tp, 1, 1, nil)
			Duel.LinkSummon(tp, sg:GetFirst(), nil)
		end
	end
end
-- Danse Programmée Devcutie
local s, id = GetID()

s.listed_series = {0xb8e}

function s.initial_effect(c)
	-- Activer 1 "Danse Programmée Devcutie" par tour
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1, id, EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.filter(c)
	return c:IsSetCard(0xb8e) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

function s.filter2(c, code)
	return c:IsSetCard(0xb8e) and c:IsType(TYPE_MONSTER) and not c:IsCode(code) and c:IsAbleToHand()
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.IsExistingMatchingCard(s.filter, tp, LOCATION_DECK, 0, 1, nil)
	end
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
	local g = Duel.SelectMatchingCard(tp, s.filter, tp, LOCATION_DECK, 0, 1, 1, nil)
	if #g > 0 then
		local tc = g:GetFirst()
		local b2 = Duel.GetFieldGroupCount(tp, 0, LOCATION_MZONE) >= 2
		if b2 then
			local g2 = Duel.GetMatchingGroup(s.filter2, tp, LOCATION_DECK, 0, nil, tc:GetCode())
			if #g2 > 0 and Duel.SelectYesNo(tp, aux.Stringid(id, 1)) then
				Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
				local sg2 = g2:Select(tp, 1, 1, nil)
				g:Merge(sg2)
			end
		end
		Duel.SendtoHand(g, nil, REASON_EFFECT)
		Duel.ConfirmCards(1 - tp, g)
	end
end
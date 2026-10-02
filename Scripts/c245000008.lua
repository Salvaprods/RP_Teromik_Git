-- Relique Égyptienne - Kuriboh du Pot
local s, id = GetID()

s.listed_series = {0xdd7}
s.listed_names = {id}

function s.initial_effect(c)
	-- Effet Rapide : Défausser pour activer 1 des effets
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1, id)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end

function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then return c:IsDiscardable() end
	Duel.SendtoGrave(c, REASON_COST + REASON_DISCARD)
end

function s.thfilter(c)
	return c:IsSetCard(0xdd7) and not c:IsCode(id) and c:IsAbleToHand()
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
	local b1 = true
	local b2 = Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil)
	if chk == 0 then return b1 or b2 end
	local op = 0
	if b1 and b2 then
		op = Duel.SelectOption(tp, aux.Stringid(id, 1), aux.Stringid(id, 2))
	elseif b1 then
		op = Duel.SelectOption(tp, aux.Stringid(id, 1))
	else
		op = Duel.SelectOption(tp, aux.Stringid(id, 2)) + 1
	end
	e:SetLabel(op)
	if op == 1 then
		e:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
		Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
	else
		e:SetCategory(0)
	end
end

function s.operation(e, tp, eg, ep, ev, re, r, rp)
	local op = e:GetLabel()
	if op == 0 then
		-- Aucun dommage de combat ce tour
		local e1 = Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_AVOID_BATTLE_DAMAGE)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e1:SetTargetRange(1, 0)
		e1:SetValue(1)
		e1:SetReset(RESET_PHASE + PHASE_END)
		Duel.RegisterEffect(e1, tp)
	elseif op == 1 then
		-- Ajouter 1 carte Relique Égyptienne depuis le Deck
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
		local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
		if #g > 0 then
			Duel.SendtoHand(g, nil, REASON_EFFECT)
			Duel.ConfirmCards(1 - tp, g)
		end
	end
end
-- Relique Égyptienne - Échange de Bon Procédé
local s, id = GetID()

s.listed_series = {0xdd7}

function s.initial_effect(c)
	-- Activer 1 de ces effets
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1, id, EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end

function s.cfilter(c)
	return c:IsSetCard(0xdd7) and c:IsAbleToGraveAsCost()
end

function s.lvl12filter(c)
	return c:IsFaceup() and c:IsLevel(12)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsOnField() and chkc:IsControler(1 - tp) and chkc:IsCanBeEffectTarget(e) end
	local b1 = Duel.IsExistingMatchingCard(s.cfilter, tp, LOCATION_HAND, 0, 1, e:GetHandler()) and Duel.IsPlayerCanDraw(tp, 2)
	local b2 = Duel.IsExistingMatchingCard(s.lvl12filter, tp, LOCATION_MZONE, 0, 1, nil) and Duel.IsExistingTarget(nil, tp, 0, LOCATION_ONFIELD, 1, nil)
	if chk == 0 then return b1 or b2 end
	local op = 0
	if b1 and b2 then
		op = Duel.SelectOption(tp, aux.Stringid(id, 0), aux.Stringid(id, 1))
	elseif b1 then
		op = Duel.SelectOption(tp, aux.Stringid(id, 0))
	else
		Duel.SelectOption(tp, aux.Stringid(id, 1))
		op = 1
	end
	e:SetLabel(op)
	if op == 0 then
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
		local g = Duel.SelectMatchingCard(tp, s.cfilter, tp, LOCATION_HAND, 0, 1, 1, e:GetHandler())
		Duel.SendtoGrave(g, REASON_COST)
		Duel.SetOperationInfo(0, CATEGORY_DRAW, nil, 0, tp, 2)
	else
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
		local g = Duel.SelectTarget(tp, nil, tp, 0, LOCATION_ONFIELD, 1, 1, nil)
		Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, 1, 0, 0)
	end
end

function s.operation(e, tp, eg, ep, ev, re, r, rp)
	local op = e:GetLabel()
	if op == 0 then
		Duel.Draw(tp, 2, REASON_EFFECT)
	else
		local tc = Duel.GetFirstTarget()
		if tc and tc:IsRelateToEffect(e) then
			Duel.Destroy(tc, REASON_EFFECT)
		end
	end
end
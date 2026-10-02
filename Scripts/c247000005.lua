-- Queentwins - Rose Lance
local s, id = GetID()

s.listed_series = {0xd44}

function s.initial_effect(c)
	-- Activation et Ciblage d'équipement
	local e0 = Effect.CreateEffect(c)
	e0:SetCategory(CATEGORY_EQUIP)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	e0:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e0:SetCountLimit(1, id, EFFECT_COUNT_CODE_OATH)
	e0:SetTarget(s.eqtg)
	e0:SetOperation(s.eqop)
	c:RegisterEffect(e0)

	-- Condition d'Équipement (Peut équiper n'importe quel monstre face recto)
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_EQUIP_LIMIT)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- Effet 1 : Gain de 300 ATK par monstre « Queentwins » sur le terrain de nom différent
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_EQUIP)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)

	-- Effet 2 : Envoyée au Cimetière -> Bannir 1 carte aléatoire de la main adverse jusqu'à la End Phase
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 0))
	e3:SetCategory(CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetTarget(s.rmtg)
	e3:SetOperation(s.rmop)
	c:RegisterEffect(e3)
end

-- ==========================================
-- ACTIVATION & ÉQUIPEMENT
-- ==========================================
function s.eqtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsFaceup() end
	if chk == 0 then return Duel.IsExistingTarget(Card.IsFaceup, tp, LOCATION_MZONE, LOCATION_MZONE, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_EQUIP)
	Duel.SelectTarget(tp, Card.IsFaceup, tp, LOCATION_MZONE, LOCATION_MZONE, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_EQUIP, e:GetHandler(), 1, 0, 0)
end

function s.eqop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	local tc = Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		Duel.Equip(tp, c, tc)
	end
end

-- ==========================================
-- EFFET 1 : GAIN D'ATK
-- ==========================================
function s.atkfilter(c)
	return c:IsFaceup() and (c:IsSetCard(0xd44) or c:IsOriginalSetCard(0xd44))
end

function s.atkval(e, c)
	local g = Duel.GetMatchingGroup(s.atkfilter, e:GetHandlerPlayer(), LOCATION_MZONE, LOCATION_MZONE, nil)
	return g:GetClassCount(Card.GetCode) * 300
end

-- ==========================================
-- EFFET 2 : BANNISSEMENT TEMPORAIRE DE LA MAIN
-- ==========================================
function s.rmtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsAbleToRemove, tp, 0, LOCATION_HAND, 1, nil) end
	Duel.SetOperationInfo(0, CATEGORY_REMOVE, nil, 1, 1 - tp, LOCATION_HAND)
end

function s.rmop(e, tp, eg, ep, ev, re, r, rp)
	local g = Duel.GetMatchingGroup(Card.IsAbleToRemove, tp, 0, LOCATION_HAND, 1, nil)
	if #g > 0 then
		local sg = g:RandomSelect(tp, 1)
		local tc = sg:GetFirst()
		if tc and Duel.Remove(tc, POS_FACEUP, REASON_EFFECT + REASON_TEMPORARY) > 0 then
			local e1 = Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
			e1:SetCode(EVENT_PHASE + PHASE_END)
			e1:SetReset(RESET_PHASE + PHASE_END)
			e1:SetCountLimit(1)
			e1:SetLabelObject(tc)
			e1:SetOperation(s.retop)
			Duel.RegisterEffect(e1, tp)
		end
	end
end

function s.retop(e, tp, eg, ep, ev, re, r, rp)
	local tc = e:GetLabelObject()
	if tc then
		Duel.SendtoHand(tc, nil, REASON_EFFECT)
	end
end
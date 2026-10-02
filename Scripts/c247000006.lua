-- Queentwins - Sharp Robe
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

	-- Condition d'Équipement
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_EQUIP_LIMIT)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- Effet 1 : Le monstre équipé ne peut pas activer ses effets
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_EQUIP)
	e2:SetCode(EFFECT_CANNOT_ACTIVATE)
	e2:SetValue(s.actval)
	c:RegisterEffect(e2)

	-- Effet 2 : Envoyée au Cimetière -> Regarder le dessus du Deck adverse et tuto 1 monstre Queentwins
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 0))
	e3:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
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
-- EFFET 1 : RESTRICTION D'ACTIVATION DU MONSTRE ÉQUIPÉ
-- ==========================================
function s.actval(e, re, tp)
	return re:GetHandler() == e:GetHandler():GetEquippedTarget()
end

-- ==========================================
-- EFFET 2 : DECKTOP ADVERSE & TUTORISATION
-- ==========================================
function s.thfilter(c)
	return (c:IsSetCard(0xd44) or c:IsOriginalSetCard(0xd44))
		and c:IsType(TYPE_MONSTER)
		and c:IsAbleToHand()
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.GetFieldGroupCount(tp, 0, LOCATION_DECK) > 0
			and Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil)
	end
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end

function s.thop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetFieldGroupCount(tp, 0, LOCATION_DECK) > 0 then
		local g = Duel.GetDecktopGroup(1 - tp, 1)
		if #g > 0 then
			Duel.ConfirmCards(tp, g)
			Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
			local sg = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
			if #sg > 0 then
				Duel.SendtoHand(sg, nil, REASON_EFFECT)
				Duel.ConfirmCards(1 - tp, sg)
			end
		end
	end
end
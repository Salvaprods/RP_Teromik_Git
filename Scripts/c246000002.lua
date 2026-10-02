-- Sécurisation Dinomorphia
local s, id = GetID()

s.listed_series = {0x173}

function s.initial_effect(c)
	-- Effet 1 : Ajouter 1 carte « Dinomorphia » (sauf Sécurisation Dinomorphia) depuis le Deck à la main
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1, id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- Effet 2 : Bannir depuis le Cimetière -> L'adversaire ne peut pas répondre à la prochaine Carte Piège Dinomorphia
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1, id + 100)
	e2:SetCost(aux.bfgcost)
	e2:SetOperation(s.protop)
	c:RegisterEffect(e2)
end

function s.thfilter(c)
	return (c:IsSetCard(0x173) or c:IsOriginalSetCard(0x173))
		and not c:IsCode(id) and c:IsAbleToHand()
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

function s.protop(e, tp, eg, ep, ev, re, r, rp)
	local e1 = Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_CHAINING)
	e1:SetOwnerPlayer(tp)
	e1:SetOperation(s.chainop)
	Duel.RegisterEffect(e1, tp)
end

function s.chainop(e, tp, eg, ep, ev, re, r, rp)
	local rc = re:GetHandler()
	if ep == tp and re:IsHasType(EFFECT_TYPE_ACTIVATE) and rc:IsType(TYPE_TRAP)
		and (rc:IsSetCard(0x173) or rc:IsOriginalSetCard(0x173)) then
		Duel.SetChainLimit(s.chainlm)
		e:Reset()
	end
end

function s.chainlm(e, rp, tp)
	return tp == rp
end
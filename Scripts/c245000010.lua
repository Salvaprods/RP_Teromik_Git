-- Relique Égyptienne - Mur Ancien
local s, id = GetID()

s.listed_series = {0xdd7}

function s.initial_effect(c)
	-- Activation du Terrain
	local e0 = Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-- Effet 1 : Placer jusqu'à 2 cartes dans le Deck puis piocher
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_TODECK + CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_FZONE)
	e1:SetCountLimit(1, id)
	e1:SetTarget(s.drtg)
	e1:SetOperation(s.drop)
	c:RegisterEffect(e1)

	-- Effet 2 : L'adversaire ne peut pas répondre aux activations "Relique Égyptienne"
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_FZONE)
	e2:SetOperation(s.chainop)
	c:RegisterEffect(e2)

	-- Effet 3 : Détruit par un effet de carte adverse -> Ajouter à la main
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 1))
	e3:SetCategory(CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetCountLimit(1, id + 100)
	e3:SetCondition(s.thcon)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
end

function s.tdfilter(c)
	return c:IsSetCard(0xdd7) and c:IsAbleToDeck()
end

function s.drtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.IsPlayerCanDraw(tp, 1)
			and Duel.IsExistingMatchingCard(s.tdfilter, tp, LOCATION_HAND, 0, 1, nil)
	end
	Duel.SetOperationInfo(0, CATEGORY_TODECK, nil, 1, tp, LOCATION_HAND)
	Duel.SetOperationInfo(0, CATEGORY_DRAW, nil, 0, tp, 1)
end

function s.drop(e, tp, eg, ep, ev, re, r, rp)
	local g = Duel.GetMatchingGroup(s.tdfilter, tp, LOCATION_HAND, 0, nil)
	if #g == 0 then return end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TODECK)
	local sg = g:Select(tp, 1, 2, nil)
	if #sg > 0 then
		Duel.ConfirmCards(1 - tp, sg)
		local ct = Duel.SendtoDeck(sg, nil, SEQ_DECKSHUFFLE, REASON_EFFECT)
		if ct > 0 then
			Duel.ShuffleDeck(tp)
			Duel.BreakEffect()
			Duel.Draw(tp, ct, REASON_EFFECT)
		end
	end
end

function s.chainop(e, tp, eg, ep, ev, re, r, rp)
	if re:GetHandler():IsSetCard(0xdd7) and ep == tp then
		Duel.SetChainLimit(s.chainlm)
	end
end

function s.chainlm(e, rp, tp)
	return tp == rp
end

function s.thcon(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	return c:IsReason(REASON_DESTROY) and c:IsReason(REASON_EFFECT)
		and c:IsPreviousControler(tp) and rp == 1 - tp
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then return c:IsAbleToHand() end
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, c, 1, 0, 0)
end

function s.thop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c, nil, REASON_EFFECT)
	end
end
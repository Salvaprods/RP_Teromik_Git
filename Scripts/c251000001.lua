-- Démarrage Purrely
local s, id = GetID()

function s.initial_effect(c)
	-- ==========================================
	-- EFFET 1 : Coût (1000 LP) -> Effet (Défausse + Recherche Deck)
	-- ==========================================
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_HANDES + CATEGORY_TOHAND + CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1, id)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- ==========================================
	-- EFFET 2 : Bannissement du Cimetière -> Annulation d'effet adverse
	-- ==========================================
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_LEAVE_FIELD)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1, id + 100)
	e2:SetCondition(s.effcon)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.efftg)
	e2:SetOperation(s.effop)
	c:RegisterEffect(e2)
end

-- ==========================================
-- FILTRES ET EFFET 1
-- ==========================================
function s.mfilter(c)
	return c:IsSetCard(0x18c) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

function s.stfilter(c, code)
	return c:IsSetCard(0x18c) and c:IsType(TYPE_SPELL + TYPE_TRAP) and not c:IsCode(code) and c:IsAbleToHand()
end

function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.CheckLPCost(tp, 1000) end
	Duel.PayLPCost(tp, 1000)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.IsExistingMatchingCard(Card.IsDiscardable, tp, LOCATION_HAND, 0, 1, e:GetHandler())
			and Duel.IsExistingMatchingCard(s.mfilter, tp, LOCATION_DECK, 0, 1, nil)
			and Duel.IsExistingMatchingCard(s.stfilter, tp, LOCATION_DECK, 0, 1, nil, id)
	end
	Duel.SetOperationInfo(0, CATEGORY_HANDES, nil, 0, tp, 1)
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 2, tp, LOCATION_DECK)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
	-- Défausse 1 carte
	local ct = Duel.DiscardHand(tp, Card.IsDiscardable, 1, 1, REASON_EFFECT + REASON_DISCARD, nil)
	if ct > 0 then
		-- Et si vous le faites, ajoutez 1 monstre et 1 Magie/Piège depuis le Deck
		if Duel.IsExistingMatchingCard(s.mfilter, tp, LOCATION_DECK, 0, 1, nil)
			and Duel.IsExistingMatchingCard(s.stfilter, tp, LOCATION_DECK, 0, 1, nil, id) then
			
			Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
			local g1 = Duel.SelectMatchingCard(tp, s.mfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
			Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
			local g2 = Duel.SelectMatchingCard(tp, s.stfilter, tp, LOCATION_DECK, 0, 1, 1, nil, id)
			if #g1 > 0 and #g2 > 0 then
				g1:Merge(g2)
				Duel.SendtoHand(g1, nil, REASON_EFFECT)
				Duel.ConfirmCards(1 - tp, g1)
			end
		end
	end
end

-- ==========================================
-- EFFET 2 : Condition et Cible depuis le Cimetière
-- ==========================================
function s.cfilter(c, tp)
	return c:IsPreviousControler(tp) and c:IsSetCard(0x18c) and c:IsType(TYPE_MONSTER)
		and c:IsReason(REASON_EFFECT) and c:GetReasonPlayer() == 1 - tp
end

function s.effcon(e, tp, eg, ep, ev, re, r, rp)
	return eg:IsExists(s.cfilter, 1, nil, tp)
end

function s.efftg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1 - tp) and chkc:IsFaceup() end
	if chk == 0 then return Duel.IsExistingTarget(Card.IsFaceup, tp, 0, LOCATION_MZONE, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DISABLE)
	local g = Duel.SelectTarget(tp, Card.IsFaceup, tp, 0, LOCATION_MZONE, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_DISABLE, g, 1, 0, 0)
end

function s.effop(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() and not tc:IsDisabled() then
		Duel.NegateRelatedChain(tc, RESET_TURN_SET)
		local e1 = Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT + RESETS_STANDARD)
		tc:RegisterEffect(e1)
		local e2 = Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetReset(RESET_EVENT + RESETS_STANDARD)
		tc:RegisterEffect(e2)
	end
end
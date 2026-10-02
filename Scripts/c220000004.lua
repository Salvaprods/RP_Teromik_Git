-- Lana l'Esprit, Seigneur Lumière
local s, id = GetID()
function s.initial_effect(c)
	-- Invocation Xyz : 3 monstres de Niveau 8
	c:EnableReviveLimit()
	aux.AddXyzProcedure(c, nil, 8, 3, s.ovfilter, aux.Stringid(id, 0), 3, s.xyzop)

	-- Effet : Lorsque l'adversaire Invoque Spécialement depuis Deck/Extra Deck
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 1))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1, id)
	e1:SetCondition(s.spcon)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
end

s.listed_names = {}
s.listed_series = {0x38} -- Seigneur Lumière / Lightsworn

-- ==========================================
-- INVOCATION XYZ ALTERNATIVE
-- ==========================================

function s.ovfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:IsSetCard(0x38)
end

function s.xyzop(e, tp, chk)
	if chk == 0 then return Duel.GetFlagEffect(tp, id + 100) == 0 end
	Duel.RegisterFlagEffect(tp, id + 100, RESET_PHASE + PHASE_END, 0, 1)
	return true
end

-- ==========================================
-- EFFET : ENVOI AU CIMETIÈRE (NON-CIBLANT)
-- ==========================================

function s.cfilter(c, tp)
	return c:IsSummonPlayer(1 - tp) and (c:IsSummonLocation(LOCATION_DECK) or c:IsSummonLocation(LOCATION_EXTRA))
end

function s.spcon(e, tp, eg, ep, ev, re, r, rp)
	return eg:IsExists(s.cfilter, 1, nil, tp)
end

function s.costfilter(c)
	return c:IsSetCard(0x38) and c:IsAbleToRemoveAsCost()
end

function s.spcost(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then
		return c:CheckRemoveOverlayCard(tp, 1, REASON_COST)
			and Duel.IsExistingMatchingCard(s.costfilter, tp, LOCATION_GRAVE, 0, 3, nil)
	end
	-- Détache 1 matériel
	c:RemoveOverlayCard(tp, 1, 1, REASON_COST)
	-- Bannit 3 cartes "Seigneur Lumière"
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
	local g = Duel.SelectMatchingCard(tp, s.costfilter, tp, LOCATION_GRAVE, 0, 3, 3, nil)
	Duel.Remove(g, POS_FACEUP, REASON_COST)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return true end
	local g = eg:Filter(s.cfilter, nil, tp)
	Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, g, #g, 0, 0)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	local g = eg:Filter(s.cfilter, nil, tp)
	local tg = g:Filter(Card.IsLocation, nil, LOCATION_MZONE)
	if #tg > 0 then
		Duel.SendtoGrave(tg, REASON_EFFECT)
	end
end
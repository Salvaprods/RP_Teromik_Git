-- Création des Devcuties
local s, id = GetID()

s.listed_series = {0xb8e}

function s.initial_effect(c)
	-- Effet 1 : Contrôle 2+ "Devcutie" diff. -> Détruit 1 carte sur le Terrain
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetHintTiming(0, TIMING_END_PHASE + TIMINGS_CHECK_MONSTER)
	e1:SetCountLimit(1, id)
	e1:SetCondition(s.descon)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)

	-- Effet 2 : Une carte contrôlée est détruite par un effet -> Pose cette carte depuis le Cimetière
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_DESTROYED)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1, id + 100)
	e2:SetCondition(s.setcon)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
end

-- ==========================================
-- EFFET 1 : DESTRUCTION
-- ==========================================
function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xb8e)
end

function s.descon(e, tp, eg, ep, ev, re, r, rp)
	local g = Duel.GetMatchingGroup(s.cfilter, tp, LOCATION_MZONE, 0, nil)
	return g:GetClassCount(Card.GetCode) >= 2
end

function s.destg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsOnField() end
	if chk == 0 then return Duel.IsExistingTarget(nil, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
	local g = Duel.SelectTarget(tp, nil, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, 1, 0, 0)
end

function s.desop(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc, REASON_EFFECT)
	end
end

-- ==========================================
-- EFFET 2 : POSE DEPUIS LE CIMETIÈRE
-- ==========================================
function s.setfilter(c, tp)
	return c:IsPreviousControler(tp) and c:IsPreviousLocation(LOCATION_ONFIELD) and c:IsReason(REASON_EFFECT)
end

function s.setcon(e, tp, eg, ep, ev, re, r, rp)
	return eg:IsExists(s.setfilter, 1, nil, tp)
end

function s.settg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then return c:IsSSetable() end
	Duel.SetOperationInfo(0, CATEGORY_LEAVE_GRAVE, c, 1, 0, 0)
end

function s.setop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsSSetable() then
		Duel.SSet(tp, c)
	end
end
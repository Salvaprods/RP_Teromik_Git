-- Fou - Echec Divin
local s, id = GetID()
function s.initial_effect(c)
	-- Effet 1 : Placer depuis la main dans la zone M&P comme Magie Continue face recto
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1, id)
	e1:SetTarget(s.plstg)
	e1:SetOperation(s.plsop)
	c:RegisterEffect(e1)

	-- Effet 2A : Protection contre la destruction par des effets de l'adversaire
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_SZONE, 0)
	e2:SetTarget(s.indtg)
	e2:SetValue(s.indval)
	c:RegisterEffect(e2)

	-- Effet 2B : Protection contre le bannissement par des effets de l'adversaire
	local e3 = Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_REMOVE)
	e3:SetRange(LOCATION_SZONE)
	e3:SetTargetRange(LOCATION_SZONE, 0)
	e3:SetTarget(s.indtg)
	e3:SetValue(s.indval)
	c:RegisterEffect(e3)

	-- Effet 3 : Invocation Spéciale si une carte "Echec Divin" est détruite
	local e4 = Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id, 1))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_DESTROYED)
	e4:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_DAMAGE_STEP)
	e4:SetRange(LOCATION_SZONE)
	e4:SetCountLimit(1, id + 100)
	e4:SetCondition(s.descon)
	e4:SetTarget(s.destg)
	e4:SetOperation(s.desop)
	c:RegisterEffect(e4)

	-- Effet 4 : Durant la Main Phase de l'adversaire (Effet Rapide) : Placer dans la S-Zone et bannir
	local e5 = Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id, 2))
	e5:SetCategory(CATEGORY_REMOVE)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_FREE_CHAIN)
	e5:SetRange(LOCATION_MZONE)
	e5:SetHintTiming(0, TIMINGS_CHECK_MONSTER)
	e5:SetCountLimit(1, id + 200)
	e5:SetCondition(s.fieldcon)
	e5:SetTarget(s.fieldtg)
	e5:SetOperation(s.fieldop)
	c:RegisterEffect(e5)
end

s.listed_series = {0xe7a} -- Echec Divin

-- ==========================================
-- EFFET 1 : PLACER DEPUIS LA MAIN COMME MAGIE CONTINUE
-- ==========================================
function s.plstg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_SZONE) > 0 end
end

function s.plsop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp, LOCATION_SZONE) <= 0 then return end
	Duel.MoveToField(c, tp, tp, LOCATION_SZONE, POS_FACEUP, true)
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CHANGE_TYPE)
	e1:SetValue(TYPE_SPELL + TYPE_CONTINUOUS)
	e1:SetReset(RESET_EVENT + RESETS_STANDARD - RESET_TURN_SET)
	c:RegisterEffect(e1)
end

-- ==========================================
-- EFFET 2 : PROTECTION DES AUTRES CARTES
-- ==========================================
function s.indtg(e, c)
	return c ~= e:GetHandler() and c:IsSetCard(0xe7a) and c:IsFaceup() and c:IsType(TYPE_SPELL + TYPE_TRAP)
end

function s.indval(e, re, rp)
	return rp ~= e:GetHandlerPlayer()
end

-- ==========================================
-- EFFET 3 : INVOCATION SPÉCIALESUR DESTRUCTION
-- ==========================================
function s.cfilter(c, tp)
	return c:IsSetCard(0xe7a) and (c:IsReason(REASON_BATTLE) or c:IsReason(REASON_EFFECT))
end

function s.descon(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	return c:IsFaceup() and c:IsType(TYPE_CONTINUOUS) and eg:IsExists(s.cfilter, 1, nil, tp)
end

function s.destg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then 
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and c:IsCanBeSpecialSummoned(e, 0, tp, false, false) 
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, tp, 0)
end

function s.desop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP)
	end
end

-- ==========================================
-- EFFET 4 : PLACEMENT EN ZONE S-ZONE DURANT TOUR ADVERSAIRE & BANNISSEMENT
-- ==========================================
function s.fieldcon(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	return Duel.IsMainPhase() and Duel.GetTurnPlayer() ~= tp and c:IsFaceup()
end

function s.stfilter(c)
	return c:IsSetCard(0xe7a) and c:IsType(TYPE_SPELL + TYPE_TRAP) and c:IsFaceup()
end

function s.fieldtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_SZONE) > 0
			and Duel.IsExistingMatchingCard(Card.IsAbleToRemove, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, nil)
	end
	Duel.SetOperationInfo(0, CATEGORY_REMOVE, nil, 1, PLAYER_ALL, LOCATION_ONFIELD)
end

function s.fieldop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if not c:IsRelateToEffect(e) or not c:IsLocation(LOCATION_MZONE) then return end
	if Duel.GetLocationCount(tp, LOCATION_SZONE) <= 0 then return end
	
	-- Place cette carte dans la zone M&P comme Magie Continue
	Duel.MoveToField(c, tp, tp, LOCATION_SZONE, POS_FACEUP, true)
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CHANGE_TYPE)
	e1:SetValue(TYPE_SPELL + TYPE_CONTINUOUS)
	e1:SetReset(RESET_EVENT + RESETS_STANDARD - RESET_TURN_SET)
	c:RegisterEffect(e1)

	-- Compte les cartes Magie & Piège "Echec Divin" contrôlées (incluant celle-ci)
	local ct = Duel.GetMatchingGroupCount(s.stfilter, tp, LOCATION_SZONE, 0, nil)
	if ct > 0 and Duel.IsExistingMatchingCard(Card.IsAbleToRemove, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, nil) then
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
		local g = Duel.SelectMatchingCard(tp, Card.IsAbleToRemove, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, ct, nil)
		if #g > 0 then
			Duel.BreakEffect()
			Duel.Remove(g, POS_FACEUP, REASON_EFFECT)
		end
	end
end
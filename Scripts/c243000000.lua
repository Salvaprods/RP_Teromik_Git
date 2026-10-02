-- Fuvagabonbrise et le Repos
local s, id = GetID()

s.listed_series = {0x16d}

function s.initial_effect(c)
	-- Effet 1 : Invocation Normale depuis le Deck & Restriction d'Invocation Spéciale
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1, id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Effet 2 : Remplacement de destruction depuis le Cimetière
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EFFECT_DESTROY_REPLACE)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1, id + 100)
	e2:SetCondition(s.repcon)
	e2:SetTarget(s.reptg)
	e2:SetValue(s.repval)
	e2:SetOperation(s.repop)
	c:RegisterEffect(e2)
end

-- ==========================================
-- EFFET 1 : INVOCATION NORMALE DEPUIS LE DECK
-- ==========================================
function s.filter(c)
	return c:IsSetCard(0x16d) and c:IsLevel(1) and c:IsSummonable(true, nil)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.IsExistingMatchingCard(s.filter, tp, LOCATION_DECK, 0, 1, nil)
	end
	Duel.SetOperationInfo(0, CATEGORY_SUMMON, nil, 1, tp, LOCATION_DECK)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
	-- Restriction : Ne peut pas Invoquer Spécialement le tour où cet effet est activé
	local e1 = Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1, 0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE + PHASE_END)
	Duel.RegisterEffect(e1, tp)

	-- Invocation Normale
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SUMMON)
	local g = Duel.SelectMatchingCard(tp, s.filter, tp, LOCATION_DECK, 0, 1, 1, nil)
	if #g > 0 then
		Duel.Summon(tp, g:GetFirst(), true, nil)
	end
end

function s.splimit(e, c, sump, sumtype, sumpos, targetp, se)
	return true
end

-- ==========================================
-- EFFET 2 : PROTECTION DESTRUCTION GY
-- ==========================================
function s.repfilter(c, tp)
	return c:IsControler(tp) and c:IsLocation(LOCATION_MZONE)
		and c:IsSetCard(0x16d) and c:IsReason(REASON_EFFECT) and c:GetReasonPlayer() == 1 - tp
		and not c:IsReason(REASON_REPLACE)
end

function s.repcon(e, tp, eg, ep, ev, re, r, rp)
	return eg:IsExists(s.repfilter, 1, nil, tp)
end

function s.reptg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then
		return c:IsAbleToRemove() and eg:IsExists(s.repfilter, 1, nil, tp)
	end
	return Duel.SelectYesNo(tp, aux.Stringid(id, 1))
end

function s.repval(e, c)
	return s.repfilter(c, e:GetHandlerPlayer())
end

function s.repop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Remove(e:GetHandler(), POS_FACEUP, REASON_EFFECT)
end
-- Laqueus Explosion
local s, id = GetID()

function s.initial_effect(c)
	-- Compteur global d'Invocations par tour
	if not s.global_check then
		s.global_check = true
		s.summon_count = {[0] = 0, [1] = 0}

		local ge1 = Effect.GlobalEffect()
		ge1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_SUMMON_SUCCESS)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1, 0)

		local ge2 = ge1:Clone()
		ge2:SetCode(EVENT_SPSUMMON_SUCCESS)
		Duel.RegisterEffect(ge2, 0)

		local ge3 = ge1:Clone()
		ge3:SetCode(EVENT_FLIP_SUMMON_SUCCESS)
		Duel.RegisterEffect(ge3, 0)

		local ge4 = Effect.GlobalEffect()
		ge4:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
		ge4:SetCode(EVENT_PREDRAW)
		ge4:SetOperation(s.resetop)
		Duel.RegisterEffect(ge4, 0)
	end

	-- Activation de la carte
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1, id, EFFECT_COUNT_CODE_OATH)
	e1:SetHintTiming(0, TIMING_END_PHASE)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Activation depuis la main si aucune carte sur votre Terrain
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	e2:SetCondition(s.handcon)
	c:RegisterEffect(e2)
end

-- ==========================================
-- SUIVI DU NOMBRE D'INVOCATIONS
-- ==========================================
function s.checkop(e, tp, eg, ep, ev, re, r, rp)
	local tc = eg:GetFirst()
	while tc do
		local p = tc:GetSummonPlayer()
		s.summon_count[p] = s.summon_count[p] + 1
		tc = eg:GetNext()
	end
end

function s.resetop(e, tp, eg, ep, ev, re, r, rp)
	s.summon_count[0] = 0
	s.summon_count[1] = 0
end

-- ==========================================
-- CONDITIONS ET ACTIVATION
-- ==========================================
function s.condition(e, tp, eg, ep, ev, re, r, rp)
	return s.summon_count[1 - tp] >= 5
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return true end
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
	-- Sélection de 2 zones sur le Terrain adverse
	local z = Duel.SelectFieldZone(tp, 2, 0, LOCATION_ONFIELD, 0)
	if z == 0 then return end

	-- Enregistre l'effet pour la End Phase
	local e1 = Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PHASE + PHASE_END)
	e1:SetCountLimit(1)
	e1:SetReset(RESET_PHASE + PHASE_END)
	e1:SetLabel(z)
	e1:SetOperation(s.endop)
	Duel.RegisterEffect(e1, tp)
end

-- ==========================================
-- EFFET DE LA END PHASE
-- ==========================================
function s.endop(e, tp, eg, ep, ev, re, r, rp)
	local z = e:GetLabel()
	local g = Duel.GetMatchingGroup(nil, tp, 0, LOCATION_ONFIELD, nil)

	-- Vérifie si au moins une des zones ciblées contient une carte
	local has_card = g:IsExists(function(c) return (c:GetZone(tp) & z) ~= 0 end, 1, nil)

	if has_card and Duel.SelectYesNo(tp, aux.Stringid(id, 1)) then
		Duel.Hint(HINT_CARD, 0, id)
		local destroy_g = g:Filter(function(c) return (c:GetZone(tp) & z) == 0 end, nil)
		if #destroy_g > 0 then
			Duel.Destroy(destroy_g, REASON_EFFECT)
		end
	end
end

-- ==========================================
-- ACTIVATION DEPUIS LA MAIN
-- ==========================================
function s.handcon(e)
	return Duel.GetFieldGroupCount(e:GetHandlerPlayer(), LOCATION_ONFIELD, 0) == 0
end
-- Laqueus Sifflante
local s, id = GetID()

function s.initial_effect(c)
	-- Activation principale
	local e1 = Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1, id, EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Activation depuis la main si aucune carte sur le Terrain
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	e2:SetCondition(s.handcon)
	c:RegisterEffect(e2)
end

-- ==========================================
-- FILTRE & CONDITION
-- ==========================================
function s.filter(c, tp)
	return c:IsSummonPlayer(1 - tp) 
		and c:IsSummonLocation(LOCATION_EXTRA) 
		and c:IsFaceup() 
		and c:IsAttackBelow(2000)
end

function s.condition(e, tp, eg, ep, ev, re, r, rp)
	return eg:IsExists(s.filter, 1, nil, tp)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return eg:IsExists(s.filter, 1, nil, tp) end
	local g = eg:Filter(s.filter, nil, tp)
	Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, #g, 0, 0)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
	local g = eg:Filter(s.filter, nil, tp)
	if #g > 0 then
		Duel.Destroy(g, REASON_EFFECT)
	end
end

-- ==========================================
-- ACTIVATION DEPUIS LA MAIN
-- ==========================================
function s.handcon(e)
	return Duel.GetFieldGroupCount(e:GetHandlerPlayer(), LOCATION_ONFIELD, 0) == 0
end
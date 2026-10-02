-- Pendule Du Chasseur - Âme Du Chasseur
local s, id = GetID()

function s.initial_effect(c)
	-- ==========================================
	-- EFFET : Activer -> Placer 1 Monstre Pendule depuis le Deck dans la Zone Pendule
	-- ==========================================
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_TOFIELD)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1, id, EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- ==========================================
-- FILTRE ET CIBLE
-- ==========================================
function s.filter(c, tp)
	return c:IsSetCard(0xc92) and c:IsType(TYPE_PENDULUM) and not c:IsForbidden(tp)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		-- Vérifie si au moins une Zone Pendule est libre de manière fiable
		return (Duel.CheckLocation(tp, LOCATION_PZONE, 0) or Duel.CheckLocation(tp, LOCATION_PZONE, 1))
			and Duel.IsExistingMatchingCard(s.filter, tp, LOCATION_DECK, 0, 1, nil, tp)
	end
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
	if not (Duel.CheckLocation(tp, LOCATION_PZONE, 0) or Duel.CheckLocation(tp, LOCATION_PZONE, 1)) then return end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOFIELD)
	local g = Duel.SelectMatchingCard(tp, s.filter, tp, LOCATION_DECK, 0, 1, 1, nil, tp)
	local tc = g:GetFirst()
	if tc then
		Duel.MoveToField(tc, tp, tp, LOCATION_PZONE, POS_FACEUP, true)
	end
end
-- Universo - Charge Spatiale
local s, id = GetID()

function s.initial_effect(c)
	-- Activation
	local e1 = Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DISABLE + CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	-- OATH lie la limite de 1 par tour au nom de la carte au moment de l'activation
	e1:SetCountLimit(1, id, EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end

-- ==========================================
-- CONDITION, CIBLE ET RÉSOLUTION
-- ==========================================
function s.condition(e, tp, eg, ep, ev, re, r, rp)
	-- L'effet adverse doit être au minimum le Maillon 2 (puisqu'il répond à ta carte)
	if ev < 2 then return false end
	-- L'effet doit être activé par l'adversaire
	if rp == tp then return false end
	
	-- On récupère les informations du Maillon précédent (ev - 1)
	local pre_te, pre_tp = Duel.GetChainInfo(ev - 1, CHAININFO_TRIGGERING_EFFECT, CHAININFO_TRIGGERING_PLAYER)
	
	-- Le Maillon précédent doit t'appartenir, être une carte "Universo", et l'effet actuel doit pouvoir être annulé
	return pre_tp == tp and pre_te and pre_te:GetHandler():IsSetCard(0xc17) 
		and Duel.IsChainDisablable(ev)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return true end
	Duel.SetOperationInfo(0, CATEGORY_DISABLE, eg, 1, 0, 0)
	
	local rc = re:GetHandler()
	if rc:IsRelateToEffect(re) and rc:IsAbleToDeck() then
		Duel.SetOperationInfo(0, CATEGORY_TODECK, eg, 1, 0, 0)
	end
end

function s.operation(e, tp, eg, ep, ev, re, r, rp)
	local rc = re:GetHandler()
	-- Si on parvient à annuler l'effet adverse
	if Duel.NegateEffect(ev) and rc:IsRelateToEffect(re) then
		-- Indispensable : Empêche la carte d'être envoyée au Cimetière (si c'est une Magie/Piège Normal ou Rapide)
		rc:CancelToGrave()
		-- Et on la mélange dans le Deck
		Duel.SendtoDeck(rc, nil, SEQ_DECKSHUFFLE, REASON_EFFECT)
	end
end
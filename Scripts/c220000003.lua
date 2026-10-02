-- Ody le Puissant, Seigneur Lumière
local s, id = GetID()
function s.initial_effect(c)
	-- Procédure de Synchro : 1 Syntoniseur + 1+ monstre non-Syntoniseur "Seigneur Lumière"
	aux.AddSynchroProcedure(c, nil, aux.NonTuner(Card.IsSetCard, 0x38), 1, 99)
	c:EnableReviveLimit()

	-- Effet 1 : Les monstres "Seigneur Lumière" contrôlés ne peuvent pas être ciblés
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_MZONE, 0)
	e1:SetTarget(s.indtg) -- LA CORRECTION EST ICI !
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- Effet 2 : Gain d'ATK (200 par nom différent dans le Cimetière et bannissement)
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)

	-- Effet 3 : Si quitte le Terrain par un effet de l'adversaire (Envoie tous les monstres adverses au GY + anti-réponse monstre)
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 0))
	e3:SetCategory(CATEGORY_TOGRAVE)
	e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_DAMAGE_STEP)
	e3:SetCode(EVENT_LEAVE_FIELD)
	e3:SetCountLimit(1, id)
	e3:SetCondition(s.leavecon)
	e3:SetTarget(s.leavetg)
	e3:SetOperation(s.leaveop)
	c:RegisterEffect(e3)

	-- Effet 4 : Effet Rapide (Bannir 3 cartes "Seigneur Lumière" du GY pour cibler et annuler une carte face recto)
	local e4 = Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id, 1))
	e4:SetCategory(CATEGORY_DISABLE)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_MZONE)
	e4:SetHintTiming(0, TIMINGS_CHECK_MONSTER + TIMING_MAIN_END)
	e4:SetCountLimit(1, id + 1)
	e4:SetCost(s.cost)
	e4:SetTarget(s.target4)
	e4:SetOperation(s.op4)
	c:RegisterEffect(e4)
end

s.listed_names = {}

-- Cible pour l'Effet 1 (Le correctif)
function s.indtg(e, c)
	return c:IsSetCard(0x38)
end

-- Effet 2 : Calcul ATK
function s.atkfilter(c)
	return c:IsType(TYPE_MONSTER) and c:IsSetCard(0x38)
end

function s.atkval(e, c)
	local g = Duel.GetMatchingGroup(s.atkfilter, e:GetHandler():GetControler(), LOCATION_GRAVE + LOCATION_REMOVED, 0, nil)
	local codes = {}
	for tc in aux.Next(g) do
		codes[tc:GetCode()] = true
	end
	local count = 0
	for k, v in pairs(codes) do
		count = count + 1
	end
	return count * 200
end

-- Effet 3 : Quitte le Terrain par un effet de l'adversaire
function s.leavecon(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	return c:IsReason(REASON_EFFECT) and rp ~= tp and c:IsPreviousControler(tp)
end

function s.leavetg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.IsExistingMatchingCard(Card.IsAbleToGrave, tp, 0, LOCATION_MZONE, 1, nil)
	end
	Duel.SetChainLimit(s.chainlm)
	local g = Duel.GetMatchingGroup(Card.IsAbleToGrave, tp, 0, LOCATION_MZONE, nil)
	Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, g, #g, 0, 0)
end

function s.chainlm(e, rp, tp)
	return not (rp ~= tp and re:IsActiveType(TYPE_MONSTER))
end

function s.leaveop(e, tp, eg, ep, ev, re, r, rp)
	local g = Duel.GetMatchingGroup(Card.IsAbleToGrave, tp, 0, LOCATION_MZONE, nil)
	if #g > 0 then
		Duel.SendToGrave(g, REASON_EFFECT)
	end
end

-- Effet 4 : Coût & Cible pour l'Effet Rapide
function s.costfilter(c)
	return c:IsSetCard(0x38) and c:IsAbleToRemoveAsCost()
end

function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(s.costfilter, tp, LOCATION_GRAVE, 0, 3, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
	local g = Duel.SelectMatchingCard(tp, s.costfilter, tp, LOCATION_GRAVE, 0, 3, 3, nil)
	Duel.Remove(g, POS_FACEUP, REASON_COST)
end

function s.target4(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsOnField() and chkc:IsFaceup() end
	if chk == 0 then return Duel.IsExistingTarget(Card.IsFaceup, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DISABLE)
	local g = Duel.SelectTarget(tp, Card.IsFaceup, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_DISABLE, g, 1, 0, 0)
end

function s.op4(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		Duel.NegateRelatedChain(tc, RESET_TURN_SET)
		local le1 = Effect.CreateEffect(e:GetHandler())
		le1:SetType(EFFECT_TYPE_SINGLE)
		le1:SetCode(EFFECT_DISABLE)
		le1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
		tc:RegisterEffect(le1)
		local le2 = Effect.CreateEffect(e:GetHandler())
		le2:SetType(EFFECT_TYPE_SINGLE)
		le2:SetCode(EFFECT_DISABLE_EFFECT)
		le2:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
		tc:RegisterEffect(le2)
		if tc:IsType(TYPE_TRAPMONSTER) then
			local le3 = Effect.CreateEffect(e:GetHandler())
			le3:SetType(EFFECT_TYPE_SINGLE)
			le3:SetCode(EFFECT_DISABLE_TRAPMONSTER)
			le3:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
			tc:RegisterEffect(le3)
		end
	end
end
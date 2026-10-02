-- Le Faux Créateur
local s, id = GetID()

s.listed_series = {0xdd7}

function s.initial_effect(c)
	c:EnableReviveLimit()
	-- Matériels de Fusion : 5 monstres « Relique Égyptienne » de noms différents
	aux.AddFusionProcMixRep(c, true, true, s.ffilter, 5, 5)

	-- Toujours traitée comme une carte « Relique Égyptienne »
	local e0 = Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
	e0:SetValue(0xdd7)
	c:RegisterEffect(e0)

	-- Unicité sur le Terrain (Vous ne pouvez contrôler qu'1 "Le Faux Créateur")
	c:SetUniqueOnField(1, 0, id)

	-- Invocable Spécialement en bannissant les Matériels depuis le Cimetière
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Non affectée par les effets activés de l'adversaire
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetValue(s.efilter)
	c:RegisterEffect(e2)

	-- Gagne 500 ATK pour chaque carte bannie
	local e3 = Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetValue(s.atkval)
	c:RegisterEffect(e3)

	-- (Effet Rapide) : Cibler 1 carte -> Détruire + bannir M/P adverse si main vide
	local e4 = Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id, 0))
	e4:SetCategory(CATEGORY_DESTROY + CATEGORY_REMOVE)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1, id)
	e4:SetTarget(s.destg)
	e4:SetOperation(s.desop)
	c:RegisterEffect(e4)
end

function s.ffilter(c, fc, sumtype, tp)
	return (c:IsSetCard(0xdd7, fc, sumtype, tp) or c:IsOriginalSetCard(0xdd7)) and c:IsType(TYPE_MONSTER, fc, sumtype, tp)
end

function s.spfilter(c)
	return (c:IsSetCard(0xdd7) or c:IsOriginalSetCard(0xdd7)) and c:IsType(TYPE_MONSTER) and c:IsAbleToRemoveAsCost()
end

function s.spcon(e, c)
	if c == nil then return true end
	local tp = c:GetControler()
	local g = Duel.GetMatchingGroup(s.spfilter, tp, LOCATION_GRAVE, 0, nil)
	return Duel.GetLocationCountFromEx(tp, tp, nil, c) > 0
		and g:CheckSubGroup(aux.dncheck, 5, 5)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk, c)
	local g = Duel.GetMatchingGroup(s.spfilter, tp, LOCATION_GRAVE, 0, nil)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
	local sg = g:SelectSubGroup(tp, aux.dncheck, true, 5, 5)
	if sg then
		sg:KeepAlive()
		e:SetLabelObject(sg)
		return true
	end
	return false
end

function s.spop(e, tp, eg, ep, ev, re, r, rp, c)
	local sg = e:GetLabelObject()
	if not sg then return end
	Duel.Remove(sg, POS_FACEUP, REASON_COST)
	sg:DeleteGroup()
end

function s.efilter(e, te)
	return te:GetOwnerPlayer() ~= e:GetHandlerPlayer() and te:IsActivated()
end

function s.atkval(e, c)
	return Duel.GetMatchingGroupCount(nil, c:GetControler(), LOCATION_REMOVED, LOCATION_REMOVED, nil) * 500
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
	if tc and tc:IsRelateToEffect(e) and Duel.Destroy(tc, REASON_EFFECT) > 0 then
		if Duel.GetFieldGroupCount(tp, LOCATION_HAND, 0) == 0 then
			local g = Duel.GetMatchingGroup(Card.IsType, tp, 0, LOCATION_ONFIELD, nil, TYPE_SPELL + TYPE_TRAP)
			if #g > 0 and Duel.SelectYesNo(tp, aux.Stringid(id, 1)) then
				Duel.BreakEffect()
				Duel.Remove(g, POS_FACEUP, REASON_EFFECT)
			end
		end
	end
end
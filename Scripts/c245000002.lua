-- Script pour Omega (Monstre Boss)
local s, id = GetID()

function s.initial_effect(c)
	-- Ne peut pas être Invoqué Normalement / Posé
	c:EnableReviveLimit()
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_CANNOT_SUMMON)
	c:RegisterEffect(e1)
	local e2 = e1:Clone()
	e2:SetCode(EFFECT_CANNOT_SET)
	c:RegisterEffect(e2)

	-- Condition d'Invocation Spéciale globale
	local e3 = Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
	e3:SetCode(EFFECT_SPSUMMON_CONDITION)
	e3:SetValue(aux.FALSE)
	c:RegisterEffect(e3)

	-- Effet pour l'Invoquer Spécialement depuis la Main ou le Cimetière
	local e_sp = Effect.CreateEffect(c)
	e_sp:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e_sp:SetType(EFFECT_TYPE_IGNITION)
	e_sp:SetRange(LOCATION_HAND + LOCATION_GRAVE)
	e_sp:SetCondition(s.spcon)
	e_sp:SetTarget(s.sptg)
	e_sp:SetOperation(s.spop)
	c:RegisterEffect(e_sp)

	-- Non affectée par les effets de carte
	local e4 = Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCode(EFFECT_IMMUNE_EFFECT)
	e4:SetValue(s.efilter)
	c:RegisterEffect(e4)

	-- Indestructible au combat
	local e5 = Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e5:SetValue(1)
	c:RegisterEffect(e5)

	-- Effet Actif (Une fois par tour) : Bannir 1 monstre Bête-Divine du GY pour copier ses effets
	local e6 = Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id, 0))
	e6:SetCategory(CATEGORY_REMOVE)
	e6:SetType(EFFECT_TYPE_IGNITION)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCountLimit(1)
	e6:SetCost(s.cost)
	e6:SetOperation(s.op)
	c:RegisterEffect(e6)
end

-- Listes des IDs pour les trois Dieux égyptiens (variantes comprises)
s.obelisk_ids = { 10000000, 10000001, 10000002, 10000003, 10000004 }
s.slifer_ids   = { 10000020, 10000021, 10000022, 10000023, 10000024 }
s.ra_ids	   = { 10000010, 10000011, 10000012, 10000013, 10000014 }

function s.id_filter(c, id_list)
	for _, target_code in ipairs(id_list) do
		if c:IsCode(target_code) then return true end
	end
	return false
end

function s.check_gods(tp)
	local g = Duel.GetFieldGroup(tp, LOCATION_GRAVE, 0)
	local has_obelisk = g:IsExists(s.id_filter, 1, nil, s.obelisk_ids)
	local has_slifer  = g:IsExists(s.id_filter, 1, nil, s.slifer_ids)
	local has_ra	  = g:IsExists(s.id_filter, 1, nil, s.ra_ids)
	return has_obelisk and has_slifer and has_ra
end

function s.spcon(e, tp, eg, ep, ev, re, r, rp)
	return s.check_gods(tp)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and c:IsCanBeSpecialSummoned(e, 0, tp, true, false)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, tp, c:GetLocation())
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c, 0, tp, tp, true, false, POS_FACEUP)
	end
end

function s.efilter(e, te)
	return te:GetOwner() ~= e:GetHandler()
end

function s.costfilter(c)
	return c:IsType(TYPE_MONSTER) and c:IsRace(RACE_DIVINE) and c:IsAbleToRemove()
end

function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(s.costfilter, tp, LOCATION_GRAVE, 0, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
	local g = Duel.SelectMatchingCard(tp, s.costfilter, tp, LOCATION_GRAVE, 0, 1, 1, nil)
	Duel.Remove(g, POS_FACEUP, REASON_COST)
	e:SetLabel(g:GetFirst():GetCode())
end

function s.op(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	local code = e:GetLabel()
	if c:IsRelateToEffect(e) and c:IsFaceup() then
		local cid = c:CopyEffect(code, RESET_EVENT + RESETS_STANDARD, 1)
		
		local e_reset = Effect.CreateEffect(c)
		e_reset:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
		e_reset:SetCode(EVENT_PHASE + PHASE_END)
		e_reset:SetCountLimit(1)
		e_reset:SetCondition(function(e)
			return Duel.GetTurnCount() == e:GetLabel()
		end)
		e_reset:SetOperation(function(e)
			c:ResetEffect(cid, RESET_COPY)
			e:Reset()
		end)
		e_reset:SetLabel(Duel.GetTurnCount() + 1)
		Duel.RegisterEffect(e_reset, tp)
	end
end
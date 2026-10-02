-- Spectre de Couleur, Monde Ténébreux
local s, id = GetID()
function s.initial_effect(c)
	-- Invocation Lien : 2 monstres non-Lien "Monde Ténébreux"
	c:EnableReviveLimit()
	aux.AddLinkProcedure(c, s.matfilter, 2, 2)

	-- Restriction : Invoqué par Lien qu'une fois par tour
	local e0 = Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e0:SetProperty(EFFECT_FLAG_PLAYER_TARGET + EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_CANNOT_NEGATE)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetTargetRange(1, 0)
	e0:SetTarget(s.splimit)
	c:RegisterEffect(e0)

	local e_reg = Effect.CreateEffect(c)
	e_reg:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_CONTINUOUS)
	e_reg:SetCode(EVENT_SPSUMMON_SUCCESS)
	e_reg:SetOperation(s.regop)
	c:RegisterEffect(e_reg)

	-- Effet 1 : Si une ou plusieurs cartes sont défaussées (max. 3 fois par tour) -> Piocher 1 carte
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_DISCARD)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(3, id)
	e1:SetCondition(s.drcon)
	e1:SetTarget(s.drtg)
	e1:SetOperation(s.drop)
	c:RegisterEffect(e1)

	-- Effet 2 : Protection anti-ciblage pour les autres cartes "Monde Ténébreux"
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_ONFIELD, 0)
	e2:SetTarget(s.tgtg)
	e2:SetValue(aux.tgoval)
	c:RegisterEffect(e2)

	-- Effet 3 : Payer 1000 LP ; Invocation Fusion (en bannissant des monstres Main/Terrain)
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1, id + 100)
	e3:SetCost(s.fuscost)
	e3:SetTarget(s.fustg)
	e3:SetOperation(s.fusop)
	c:RegisterEffect(e3)
end

s.listed_names = {}
s.listed_series = {0x6} -- Monde Ténébreux

-- ==========================================
-- RESTRICTION LINK SUMMON ONCE PER TURN
-- ==========================================
function s.regop(e, tp, eg, ep, ev, re, r, rp)
	if e:GetHandler():IsSummonType(SUMMON_TYPE_LINK) then
		Duel.RegisterFlagEffect(tp, id + 200, RESET_PHASE + PHASE_END, 0, 1)
	end
end

function s.splimit(e, c, sump, sumtype, sumpos, targetp, se)
	return c:IsCode(id) and (sumtype & SUMMON_TYPE_LINK) == SUMMON_TYPE_LINK and Duel.GetFlagEffect(sump, id + 200) > 0
end

-- ==========================================
-- MATÉRIAUX DE LIEN (2 non-Lien "Monde Ténébreux")
-- ==========================================
function s.matfilter(c, scard, sumtype, tp)
	return not c:IsType(TYPE_LINK, scard, sumtype, tp) and c:IsSetCard(0x6, scard, sumtype, tp)
end

-- ==========================================
-- EFFET 1 : PIOCHE SUR DÉFAUSSE
-- ==========================================
function s.drcon(e, tp, eg, ep, ev, re, r, rp)
	return eg:IsExists(Card.IsControler, 1, nil, tp)
end

function s.drtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsPlayerCanDraw(tp, 1) end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(1)
	Duel.SetOperationInfo(0, CATEGORY_DRAW, nil, 0, tp, 1)
end

function s.drop(e, tp, eg, ep, ev, re, r, rp)
	local p, d = Duel.GetChainInfo(0, CHAININFO_TARGET_PLAYER, CHAININFO_TARGET_PARAM)
	Duel.Draw(p, d, REASON_EFFECT)
end

-- ==========================================
-- EFFET 2 : PROTECTION ANTI-CIBLAGE
-- ==========================================
function s.tgtg(e, c)
	return c ~= e:GetHandler() and c:IsSetCard(0x6)
end

-- ==========================================
-- EFFET 3 : INVOCATION FUSION (BANISSEMENT)
-- ==========================================
function s.ffilter(c, e, tp, mg, chkf)
	return c:IsSetCard(0x6) and c:IsType(TYPE_FUSION)
		and c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_FUSION, tp, false, false)
		and c:CheckFusionMaterial(mg, nil, chkf)
end

function s.fuscost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.CheckLPCost(tp, 1000) end
	Duel.PayLPCost(tp, 1000)
end

function s.fustg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		local chkf = tp
		local mg = Duel.GetMatchingGroup(Card.IsAbleToRemove, tp, LOCATION_HAND + LOCATION_MZONE, 0, nil)
		return Duel.IsExistingMatchingCard(s.ffilter, tp, LOCATION_EXTRA, 0, 1, nil, e, tp, mg, chkf)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_EXTRA)
	Duel.SetOperationInfo(0, CATEGORY_REMOVE, nil, 1, tp, LOCATION_HAND + LOCATION_MZONE)
end

function s.fusop(e, tp, eg, ep, ev, re, r, rp)
	local chkf = tp
	local mg = Duel.GetMatchingGroup(Card.IsAbleToRemove, tp, LOCATION_HAND + LOCATION_MZONE, 0, nil)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local g = Duel.SelectMatchingCard(tp, s.ffilter, tp, LOCATION_EXTRA, 0, 1, 1, nil, e, tp, mg, chkf)
	local tc = g:GetFirst()
	if tc then
		local mat = Duel.SelectFusionMaterial(tp, tc, mg, nil, chkf)
		tc:SetMaterial(mat)
		Duel.Remove(mat, POS_FACEUP, REASON_EFFECT + REASON_MATERIAL + REASON_FUSION)
		Duel.BreakEffect()
		Duel.SpecialSummon(tc, SUMMON_TYPE_FUSION, tp, tp, false, false, POS_FACEUP)
		tc:CompleteProcedure()
	end
end
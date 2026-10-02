-- Devcutie - Misaka
local s, id = GetID()

s.listed_series = {0xb8e}
local COUNTER_DEV = 0x1b8e

function s.initial_effect(c)
	-- Invocable par Lien (2 monstres non-Lien "Devcutie")
	c:EnableReviveLimit()
	aux.AddLinkProcedure(c, s.mfilter, 2, 2)

	-- Effet Continu : Gagne une ATK égale à l'ATK totale des monstres pointés
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)

	-- Effet Rapide (Main Phase Adversaire) : Invoque Spécialement du Deck puis Fusion
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_FUSION_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0, TIMING_MAIN_END + TIMINGS_CHECK_MONSTER)
	e2:SetCountLimit(1, id)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	-- Effet Rapide : Adversaire active une carte/effet sur le Terrain -> Retire 1 Compteur "Dev" et détruit 1 carte
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 1))
	e3:SetCategory(CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1, id + 100)
	e3:SetCondition(s.descon)
	e3:SetCost(s.descost)
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)
end

-- ==========================================
-- MATÉRIEL LIEN
-- ==========================================
function s.mfilter(c, lc, sumtype, tp)
	return c:IsSetCard(0xb8e, lc, sumtype, tp) and not c:IsType(TYPE_LINK, lc, sumtype, tp)
end

-- ==========================================
-- EFFET 1 : ATK DU MONSTRE
-- ==========================================
function s.atkval(e, c)
	local g = c:GetLinkedGroup():Filter(Card.IsFaceup, nil)
	return g:GetSum(Card.GetAttack)
end

-- ==========================================
-- EFFET 2 : INVOCATION SPÉCIALE DEPUIS LE DECK + FUSION (MAIN PHASE ADVERSAIRE)
-- ==========================================
function s.spcon(e, tp, eg, ep, ev, re, r, rp)
	return Duel.IsMainPhase() and Duel.GetTurnPlayer() == 1 - tp
end

function s.spfilter(c, e, tp)
	return c:IsSetCard(0xb8e) and c:IsType(TYPE_MONSTER) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.fusfilter(c, e, tp, mg)
	return c:IsSetCard(0xb8e) and c:IsType(TYPE_FUSION) and c:CheckFusionMaterial(mg, nil, tp)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_DECK, 0, 1, nil, e, tp)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_DECK)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local g = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_DECK, 0, 1, 1, nil, e, tp)
	if #g > 0 and Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP) ~= 0 then
		local mg1 = Duel.GetFusionMaterial(tp)
		local sg1 = Duel.GetMatchingGroup(s.fusfilter, tp, LOCATION_EXTRA, 0, nil, e, tp, mg1)
		if #sg1 > 0 and Duel.SelectYesNo(tp, aux.Stringid(id, 2)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
			local tc = sg1:Select(tp, 1, 1, nil):GetFirst()
			local mat1 = Duel.SelectFusionMaterial(tp, tc, mg1, nil, tp)
			tc:SetMaterial(mat1)
			Duel.SendtoGrave(mat1, REASON_EFFECT + REASON_MATERIAL + REASON_FUSION)
			Duel.SpecialSummon(tc, SUMMON_TYPE_FUSION, tp, tp, false, false, POS_FACEUP)
			tc:CompleteProcedure()
		end
	end
end

-- ==========================================
-- EFFET 3 : DESTRUCTION SUR ACTIVATION ADVERSE
-- ==========================================
function s.descon(e, tp, eg, ep, ev, re, r, rp)
	local loc = Duel.GetChainInfo(ev, CHAININFO_TRIGGERING_LOCATION)
	return ep == 1 - tp and (loc & LOCATION_ONFIELD) ~= 0
end

function s.descost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsCanRemoveCounter(tp, 1, 0, COUNTER_DEV, 1, REASON_COST) end
	Duel.RemoveCounter(tp, 1, 0, COUNTER_DEV, 1, REASON_COST)
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
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc, REASON_EFFECT)
	end
end
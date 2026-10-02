-- Œil De Gokvelgr - Âme Du Chasseur
local s, id = GetID()

function s.initial_effect(c)
	-- ==========================================
	-- EFFET 1 : Activation (Recherche Deck ou Extra Deck face recto)
	-- ==========================================
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1, id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- ==========================================
	-- EFFET 2 : Main Phase (Détruire 1 monstre -> Invocation Spéciale Niv +1 ou -1)
	-- ==========================================
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_DESTROY + CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1, id + 100)
	e2:SetTarget(s.sptg2)
	e2:SetOperation(s.spop2)
	c:RegisterEffect(e2)

	-- ==========================================
	-- EFFET 3 : Boost ATK/DEF continus
	-- ==========================================
	local e3 = Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetRange(LOCATION_SZONE)
	e3:SetTargetRange(LOCATION_MZONE, 0)
	e3:SetTarget(s.valtg)
	e3:SetValue(s.val)
	c:RegisterEffect(e3)
	local e4 = e3:Clone()
	e4:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e4)
end

-- ==========================================
-- EFFET 1 : Recherche
-- ==========================================
function s.thfilter(c)
	return c:IsSetCard(0xc92) and c:IsType(TYPE_MONSTER) 
		and (c:IsLocation(LOCATION_DECK) or (c:IsLocation(LOCATION_EXTRA) and c:IsFaceup())) 
		and c:IsAbleToHand()
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then 
		return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK + LOCATION_EXTRA, 0, 1, nil) 
	end
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK + LOCATION_EXTRA)
end

function s.thop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
	local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK + LOCATION_EXTRA, 0, 1, 1, nil)
	if #g > 0 then
		Duel.SendtoHand(g, nil, REASON_EFFECT)
		Duel.ConfirmCards(1 - tp, g)
	end
end

-- ==========================================
-- EFFET 2 : Destruction + Invocation Spéciale (Niveau +/- 1)
-- ==========================================
function s.spfilter2(c, e, tp, lv)
	return c:IsSetCard(0xc92) and (c:GetLevel() == lv + 1 or c:GetLevel() == lv - 1)
		and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
		and (c:IsLocation(LOCATION_DECK) or (c:IsLocation(LOCATION_EXTRA) and c:IsFaceup()))
end

function s.desfilter(c, e, tp)
	if not (c:IsFaceup() and c:IsLevelAbove(1)) then return false end
	local lv = c:GetLevel()
	return Duel.IsExistingMatchingCard(s.spfilter2, tp, LOCATION_DECK + LOCATION_EXTRA, 0, 1, nil, e, tp, lv)
end

function s.sptg2(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > -1
			and Duel.IsExistingMatchingCard(s.desfilter, tp, LOCATION_MZONE, 0, 1, nil, e, tp)
	end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
	local g = Duel.SelectMatchingCard(tp, s.desfilter, tp, LOCATION_MZONE, 0, 1, 1, nil, e, tp)
	Duel.SetTargetCard(g)
	Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, 1, 0, 0)
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_DECK + LOCATION_EXTRA)
end

function s.spop2(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and Duel.Destroy(tc, REASON_EFFECT) ~= 0 then
		local lv = tc:GetLevel()
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
		local g = Duel.SelectMatchingCard(tp, s.spfilter2, tp, LOCATION_DECK + LOCATION_EXTRA, 0, 1, 1, nil, e, tp, lv)
		if #g > 0 then
			Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
		end
	end
end

-- ==========================================
-- EFFET 3 : Bonus ATK/DEF
-- ==========================================
function s.valtg(e, c)
	return c:IsSetCard(0xc92)
end

function s.extcounter(c)
	return c:IsFaceup() and c:IsSetCard(0xc92) and c:IsType(TYPE_MONSTER)
end

function s.val(e, c)
	local ct = Duel.GetMatchingGroupCount(s.extcounter, e:GetHandlerPlayer(), LOCATION_EXTRA, 0, nil)
	return ct * 200
end
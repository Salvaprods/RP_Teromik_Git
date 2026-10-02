-- Devcutie - Camille
local s, id = GetID()

s.listed_series = {0xb8e}

function s.initial_effect(c)
	-- Effet 1a : Ajouté du Deck à la main par un effet "Devcutie"
	local e1a = Effect.CreateEffect(c)
	e1a:SetDescription(aux.Stringid(id, 0))
	e1a:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_DESTROY)
	e1a:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e1a:SetProperty(EFFECT_FLAG_DELAY)
	e1a:SetCode(EVENT_TO_HAND)
	e1a:SetRange(LOCATION_HAND)
	e1a:SetCountLimit(1, id)
	e1a:SetCondition(s.spcon1)
	e1a:SetTarget(s.sptg1)
	e1a:SetOperation(s.spop1)
	c:RegisterEffect(e1a)

	-- Effet 1b : Détruit par un effet de carte
	local e1b = Effect.CreateEffect(c)
	e1b:SetDescription(aux.Stringid(id, 0))
	e1b:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_DESTROY)
	e1b:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e1b:SetProperty(EFFECT_FLAG_DELAY)
	e1b:SetCode(EVENT_DESTROYED)
	e1b:SetCountLimit(1, id)
	e1b:SetCondition(s.spcon2)
	e1b:SetTarget(s.sptg1)
	e1b:SetOperation(s.spop1)
	c:RegisterEffect(e1b)

	-- Effet 2 : Si Invoqué Normalement ou Spécialement -> Poser 1 M/P Devcutie depuis le Deck
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1, id + 100)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
	local e2_bis = e2:Clone()
	e2_bis:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2_bis)
end

-- ==========================================
-- EFFET 1 : INVOCATION SPÉCIALE & DESTRUCTION
-- ==========================================
function s.spcon1(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	return c:IsPreviousLocation(LOCATION_DECK) and re and re:GetHandler():IsSetCard(0xb8e)
end

function s.spcon2(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	return c:IsReason(REASON_EFFECT)
end

function s.pzfilter(c)
	return c:IsSetCard(0xb8e) and c:IsType(TYPE_PENDULUM)
end

function s.sptg1(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, 0, 0)
end

function s.spop1(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP) ~= 0 then
		local has_pzone = Duel.IsExistingMatchingCard(s.pzfilter, tp, LOCATION_PZONE, 0, 1, nil)
		local g = Duel.GetMatchingGroup(nil, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, nil)
		if has_pzone and #g > 0 and Duel.SelectYesNo(tp, aux.Stringid(id, 2)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
			local sg = g:Select(tp, 1, 1, nil)
			Duel.HintSelection(sg)
			Duel.Destroy(sg, REASON_EFFECT)
		end
	end
end

-- ==========================================
-- EFFET 2 : POSER MAGIE/PIÈGE DEPUIS LE DECK
-- ==========================================
function s.setfilter(c)
	return c:IsSetCard(0xb8e) and c:IsType(TYPE_SPELL + TYPE_TRAP) and c:IsSSetable()
end

function s.settg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.IsExistingMatchingCard(s.setfilter, tp, LOCATION_DECK, 0, 1, nil)
	end
end

function s.setop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SET)
	local g = Duel.SelectMatchingCard(tp, s.setfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
	if #g > 0 then
		Duel.SSet(tp, g:GetFirst())
	end
end
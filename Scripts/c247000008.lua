-- Queentwins - Lucy Pink
local s, id = GetID()

s.listed_series = {0xd44}

function s.initial_effect(c)
	-- Invocation Xyz : 2 monstres « Queentwins » de Niveau 4
	c:EnableReviveLimit()
	aux.AddXyzProcedure(c, s.mfilter, 4, 2)

	-- Effet 1 : Invoquée par Xyz -> Spécialement 1 monstre Queentwins du Deck de nom différent des matériels
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1, id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Effet 2 : Détacher 1 matériel -> Poser 1 Magie/Piège Queentwins depuis le Deck
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1, id + 100)
	e2:SetCost(s.setcost)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
end

function s.mfilter(c, sc, sumtype, tp)
	return c:IsSetCard(0xd44, sc, sumtype, tp) or c:IsOriginalSetCard(0xd44)
end

-- ==========================================
-- EFFET 1 : INVOCATION SPÉCIALE DEPUIS LE DECK
-- ==========================================
function s.spcon(e, tp, eg, ep, ev, re, r, rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end

function s.spfilter(c, e, tp, og)
	return (c:IsSetCard(0xd44) or c:IsOriginalSetCard(0xd44))
		and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
		and not (og and og:IsExists(Card.IsCode, 1, nil, c:GetCode()))
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	local og = e:GetHandler():GetOverlayGroup()
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_DECK, 0, 1, nil, e, tp, og)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_DECK)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
	local og = e:GetHandler():GetOverlayGroup()
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local g = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_DECK, 0, 1, 1, nil, e, tp, og)
	if #g > 0 then
		Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
	end
end

-- ==========================================
-- EFFET 2 : POSER MAGIE/PIÈGE DEPUIS LE DECK
-- ==========================================
function s.setcost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return e:GetHandler():CheckRemoveOverlayCard(tp, 1, REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp, 1, 1, REASON_COST)
end

function s.setfilter(c)
	return (c:IsSetCard(0xd44) or c:IsOriginalSetCard(0xd44))
		and (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP))
		and c:IsSSetable()
end

function s.settg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_SZONE) > 0
			and Duel.IsExistingMatchingCard(s.setfilter, tp, LOCATION_DECK, 0, 1, nil)
	end
end

function s.setop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetLocationCount(tp, LOCATION_SZONE) <= 0 then return end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SET)
	local g = Duel.SelectMatchingCard(tp, s.setfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
	if #g > 0 then
		Duel.SSet(tp, g:GetFirst())
	end
end
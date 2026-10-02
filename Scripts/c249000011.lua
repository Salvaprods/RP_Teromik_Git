-- Universo - Exdragon Plasma
local s, id = GetID()

function s.initial_effect(c)
	-- 1. Effet d'Ignition : Révéler pour Invoquer Spécialement et Bannir 1 autre monstre "Universo"
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1, id) -- HOPT 1
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- 2. Effet Déclencheur : Si cette carte est bannie, Invoquez-la Spécialement
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_REMOVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1, id + 100) -- HOPT 2
	e2:SetTarget(s.rmtg)
	e2:SetOperation(s.rmop)
	c:RegisterEffect(e2)
end

-- ==========================================
-- EFFET 1 (Main : Révéler, Invoquer & Bannir)
-- ==========================================
function s.spcost(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then return not c:IsPublic() end
	Duel.ConfirmCards(1 - tp, c)
end

function s.spfilter(c, e, tp)
	return c:IsSetCard(0xc17) and c:IsType(TYPE_MONSTER)
		and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

-- Modifié : Doit être un autre monstre "Universo"
function s.rmfilter(c, ec)
	return c:IsSetCard(0xc17) and c:IsType(TYPE_MONSTER) and c:IsAbleToRemove() and c ~= ec
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND, 0, 1, nil, e, tp)
			and Duel.IsExistingMatchingCard(s.rmfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, c, c)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND)
	Duel.SetOperationInfo(0, CATEGORY_REMOVE, nil, 1, tp, LOCATION_HAND + LOCATION_DECK)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
	
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local g = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND, 0, 1, 1, nil, e, tp)
	
	if #g > 0 and Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP) > 0 then
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
		local rg = Duel.SelectMatchingCard(tp, s.rmfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, c)
		
		if #rg > 0 then
			Duel.BreakEffect()
			Duel.Remove(rg, POS_FACEUP, REASON_EFFECT)
		end
	end
end

-- ==========================================
-- EFFET 2 (Bannie : S'Invoquer)
-- ==========================================
function s.rmtg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then 
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, 0, 0)
end

function s.rmop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP)
	end
end
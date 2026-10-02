-- Hictia l'Hibou, Seigneur Lumière
local s, id = GetID()
function s.initial_effect(c)
	-- Effet 1 : Coût (Placer 1 "Seigneur Lumière" Main/Deck au-dessus du Deck) + Invocation Spéciale + Meule 3
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_DECKDES)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1, id)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)

	-- Effet 2 : Si envoyée depuis le Deck au Cimetière
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1, id + 100)
	e2:SetCondition(s.spcon2)
	e2:SetTarget(s.sptg2)
	e2:SetOperation(s.spop2)
	c:RegisterEffect(e2)

	-- Effet 3 : Si utilisée comme Matériel Synchro ou Lien pour un monstre "Seigneur Lumière"
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 2))
	e3:SetCategory(CATEGORY_SSET)
	e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetRange(LOCATION_GY)
	e3:SetCountLimit(1, id + 200)
	e3:SetCondition(s.setcon)
	e3:SetTarget(s.settg)
	e3:SetOperation(s.setop)
	c:RegisterEffect(e3)
end

s.listed_names = {}

-- Effet 1 : Coût (Placer 1 "Seigneur Lumière" de la Main ou du Deck au-dessus du Deck)
function s.costfilter(c, e)
	return c:IsSetCard(0x38) and c ~= e:GetHandler() and (c:IsAbleToDeckAsCost() or c:IsLocation(LOCATION_DECK))
end

function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then return Duel.IsExistingMatchingCard(s.costfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, c, e) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TODECK)
	local g = Duel.SelectMatchingCard(tp, s.costfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, c, e)
	local tc = g:GetFirst()
	if tc:IsLocation(LOCATION_DECK) then
		Duel.MoveSequence(tc, SEQ_DECKTOP)
	else
		Duel.SendtoDeck(tc, nil, SEQ_DECKTOP, REASON_COST)
	end
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then 
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
			and Duel.IsPlayerCanDiscardDeck(tp, 3) 
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, tp, LOCATION_HAND)
	Duel.SetOperationInfo(0, CATEGORY_DECKDES, nil, 0, tp, 3)
end

function s.operation(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP) > 0 then
		Duel.DiscardDeck(tp, 3, REASON_EFFECT)
	end
end

-- Effet 2 : Si envoyée depuis le Deck au Cimetière
function s.spcon2(e, tp, eg, ep, ev, re, r, rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_DECK)
end

function s.sptg2(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then 
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and c:IsCanBeSpecialSummoned(e, 0, tp, false, false) 
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, tp, LOCATION_GRAVE)
end

function s.spop2(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP)
	end
end

-- Effet 3 : Si utilisée comme Matériel Synchro ou Lien pour un monstre "Seigneur Lumière"
function s.setcon(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	local rc = c:GetReasonCard()
	return c:IsReason(REASON_SYNCHRO | REASON_LINK) and rc and rc:IsSetCard(0x38)
end

function s.stfilter(c)
	return (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP)) and c:IsSetCard(0x38) and c:IsSSetable()
end

function s.settg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then 
		return Duel.IsExistingMatchingCard(aux.NecroValleyFilter(s.stfilter), tp, LOCATION_DECK + LOCATION_GRAVE, 0, 1, nil) 
	end
	Duel.SetOperationInfo(0, CATEGORY_SSET, nil, 1, tp, LOCATION_DECK + LOCATION_GRAVE)
end

function s.setop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SET)
	local g = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.stfilter), tp, LOCATION_DECK + LOCATION_GRAVE, 0, 1, 1, nil)
	if #g > 0 then
		Duel.SSet(tp, g:GetFirst())
	end
end
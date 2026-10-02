-- Celine la Prêtresse, Seigneur Lumière
local s, id = GetID()
function s.initial_effect(c)
	-- Effet 1 : Inocation Spéciale depuis la Main ou le Cimetière en envoyant un autre "Seigneur Lumière" du Deck (pas une autre copie d'elle-même)
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND + LOCATION_GRAVE)
	e1:SetCountLimit(1, id)
	e1:SetCost(s.spcost1)
	e1:SetTarget(s.sptg1)
	e1:SetOperation(s.spop1)
	c:RegisterEffect(e1)

	-- Effet 2 : Si envoyée du Deck au Cimetière
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

	-- Effet 3 : Meule selon le nombre de cartes en main (Invocation Normale ou Spéciale)
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 2))
	e3:SetCategory(CATEGORY_DECKDES)
	e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetCountLimit(1, id + 200)
	e3:SetTarget(s.milltg)
	e3:SetOperation(s.millop)
	c:RegisterEffect(e3)
	local e3b = e3:Clone()
	e3b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3b)

	-- Effet 4 : Remplacement de destruction depuis le Cimetière ou le Bannissement (Une fois par tour)
	local e4 = Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EFFECT_DESTROY_REPLACE)
	e4:SetRange(LOCATION_GRAVE + LOCATION_REMOVED)
	e4:SetTarget(s.reptg)
	e4:SetValue(s.repval)
	e4:SetOperation(s.repop)
	c:RegisterEffect(e4)
end

s.listed_names = {}

-- Effet 1 : Coût (envoie un autre "Seigneur Lumière" du Deck, excluant son propre nom pour empêcher d'envoyer une autre Céline)
function s.costfilter(c)
	return c:IsSetCard(0x38) and not c:IsCode(id) and c:IsAbleToGraveAsCost()
end

function s.spcost1(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(s.costfilter, tp, LOCATION_DECK, 0, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
	local g = Duel.SelectMatchingCard(tp, s.costfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
	Duel.SendtoGrave(g, REASON_COST)
end

function s.sptg1(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, tp, c:GetLocation())
end

function s.spop1(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP)
	end
end

-- Effet 2
function s.spcon2(e, tp, eg, ep, ev, re, r, rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_DECK)
end

function s.sptg2(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, tp, c:GetLocation())
end

function s.spop2(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP)
	end
end

-- Effet 3 (Meule dynamique)
function s.milltg(e, tp, eg, ep, ev, re, r, rp, chk)
	local ct = Duel.GetFieldGroupCount(tp, LOCATION_HAND, 0)
	if chk == 0 then return ct > 0 and Duel.IsPlayerCanDiscardDeck(tp, ct) end
	Duel.SetOperationInfo(0, CATEGORY_DECKDES, nil, 0, tp, ct)
end

function s.millop(e, tp, eg, ep, ev, re, r, rp)
	local ct = Duel.GetFieldGroupCount(tp, LOCATION_HAND, 0)
	if ct > 0 then
		Duel.DiscardDeck(tp, ct, REASON_EFFECT)
	end
end

-- Effet 4 (Protection par remplacement avec Opt)
function s.repfilter(c, tp)
	return c:IsControler(tp) and c:IsOnField() and c:IsSetCard(0x38)
		and c:IsReason(REASON_BATTLE | REASON_EFFECT) and not c:IsReason(REASON_REPLACE)
end

function s.reptg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then 
		return c:IsAbleToDeck() 
			and eg:IsExists(s.repfilter, 1, nil, tp)
			and c:GetFlagEffect(id + 300) == 0
	end
	if Duel.SelectEffectYesNo(tp, c, aux.Stringid(id, 3)) then
		c:RegisterFlagEffect(id + 300, RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END, 0, 1)
		return true
	end
	return false
end

function s.repval(e, c)
	return s.repfilter(c, e:GetHandlerPlayer())
end

function s.repop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	Duel.SendtoDeck(c, nil, SEQ_DECKSHUFFLE, REASON_EFFECT)
end
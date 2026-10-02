-- Cavalier - Echec Divin
local s, id = GetID()
function s.initial_effect(c)
	-- Effet 1 : Placer depuis la main dans la zone M&P comme Magie Continue face recto
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1, id)
	e1:SetTarget(s.plstg)
	e1:SetOperation(s.plsop)
	c:RegisterEffect(e1)

	-- Effet 2 : Invocation Spéciale depuis la zone M&P (Effet Rapide) et bannissement optionnel
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1, id + 100)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	-- Effet 3 : Durant la Main Phase de l'adversaire (Effet Rapide) : Placer cette carte (depuis la zone monstre) et une autre depuis le Deck
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 2))
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE) -- Uniquement lorsqu'il est un monstre sur le terrain
	e3:SetHintTiming(0, TIMINGS_CHECK_MONSTER)
	e3:SetCountLimit(1, id + 200)
	e3:SetCondition(s.fieldcon)
	e3:SetTarget(s.fieldtg)
	e3:SetOperation(s.fieldop)
	c:RegisterEffect(e3)
end

s.listed_series = {0xe7a} -- Echec Divin

-- ==========================================
-- EFFET 1 : PLACER DEPUIS LA MAIN COMME MAGIE CONTINUE
-- ==========================================
function s.plstg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_SZONE) > 0 end
end

function s.plsop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp, LOCATION_SZONE) <= 0 then return end
	Duel.MoveToField(c, tp, tp, LOCATION_SZONE, POS_FACEUP, true)
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CHANGE_TYPE)
	e1:SetValue(TYPE_SPELL + TYPE_CONTINUOUS)
	e1:SetReset(RESET_EVENT + RESETS_STANDARD - RESET_TURN_SET)
	c:RegisterEffect(e1)
end

-- ==========================================
-- EFFET 2 : INVOCATION SPÉCIALE & BANNISSEMENT
-- ==========================================
function s.spcon(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	return c:IsFaceup() and c:IsType(TYPE_CONTINUOUS)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	local seq = c:GetSequence()
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and Duel.CheckLocation(tp, LOCATION_MZONE, seq)
			and c:IsCanBeSpecialSummoned(e, 0, tp, false, false, POS_FACEUP, tp, 1 << seq)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, tp, 0)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local seq = c:GetSequence()
	if Duel.CheckLocation(tp, LOCATION_MZONE, seq) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false, POS_FACEUP, tp, 1 << seq) then
		if Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP, 1 << seq) ~= 0 then
			if Duel.IsExistingMatchingCard(Card.IsAbleToRemove, tp, LOCATION_MZONE, LOCATION_MZONE, 1, nil)
				and Duel.SelectYesNo(tp, aux.Stringid(id, 3)) then
				Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
				local g = Duel.SelectMatchingCard(tp, Card.IsAbleToRemove, tp, LOCATION_MZONE, LOCATION_MZONE, 1, 1, nil)
				if #g > 0 then
					Duel.BreakEffect()
					Duel.Remove(g, POS_FACEUP, REASON_EFFECT)
				end
			end
		end
	end
end

-- ==========================================
-- EFFET 3 : DURANT LA MAIN PHASE DE L'ADVERSAIRE (PLACEMENT DEPUIS LE DECK)
-- ==========================================
function s.fieldcon(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	return Duel.IsMainPhase() and Duel.GetTurnPlayer() ~= tp and c:IsFaceup()
end

function s.fieldfilter(c)
	return c:IsSetCard(0xe7a) and c:IsType(TYPE_MONSTER) and not c:IsCode(id)
end

function s.fieldtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		-- Il faut au moins 2 emplacements libres dans la zone M&P (un pour cette carte, un pour celle du Deck)
		return Duel.GetLocationCount(tp, LOCATION_SZONE) >= 2
			and Duel.IsExistingMatchingCard(s.fieldfilter, tp, LOCATION_DECK, 0, 1, nil)
	end
end

function s.fieldop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if not c:IsRelateToEffect(e) or not c:IsLocation(LOCATION_MZONE) then return end
	if Duel.GetLocationCount(tp, LOCATION_SZONE) < 2 then return end
	
	-- Place cette carte dans la zone M&P comme Magie Continue
	Duel.MoveToField(c, tp, tp, LOCATION_SZONE, POS_FACEUP, true)
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CHANGE_TYPE)
	e1:SetValue(TYPE_SPELL + TYPE_CONTINUOUS)
	e1:SetReset(RESET_EVENT + RESETS_STANDARD - RESET_TURN_SET)
	c:RegisterEffect(e1)

	-- Place un autre monstre "Echec Divin" depuis le Deck
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOFIELD)
	local g = Duel.SelectMatchingCard(tp, s.fieldfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
	local tc = g:GetFirst()
	if tc then
		Duel.MoveToField(tc, tp, tp, LOCATION_SZONE, POS_FACEUP, true)
		local e2 = Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_CHANGE_TYPE)
		e2:SetValue(TYPE_SPELL + TYPE_CONTINUOUS)
		e2:SetReset(RESET_EVENT + RESETS_STANDARD - RESET_TURN_SET)
		tc:RegisterEffect(e2)
	end
end
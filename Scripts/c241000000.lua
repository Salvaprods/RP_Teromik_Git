-- Pion - Echec Divin
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

	-- Effet 2 : Invocation Spéciale depuis la zone M&P (Effet Rapide) et placement d'un autre monstre "Echec Divin"
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1, id + 100)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
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
-- EFFET 2 : INVOCATION SPÉCIALE & PLACEMENT DEPUIS LE DECK
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

function s.deckfilter(c)
	return c:IsSetCard(0xe7a) and c:IsType(TYPE_MONSTER) and not c:IsCode(id)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local seq = c:GetSequence()
	if Duel.CheckLocation(tp, LOCATION_MZONE, seq) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false, POS_FACEUP, tp, 1 << seq) then
		if Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP, 1 << seq) ~= 0 then
			if Duel.GetLocationCount(tp, LOCATION_SZONE) > 0 and Duel.IsExistingMatchingCard(s.deckfilter, tp, LOCATION_DECK, 0, 1, nil) then
				if Duel.SelectYesNo(tp, aux.Stringid(id, 2)) then
					Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOFIELD)
					local g = Duel.SelectMatchingCard(tp, s.deckfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
					local tc = g:GetFirst()
					if tc then
						Duel.MoveToField(tc, tp, tp, LOCATION_SZONE, POS_FACEUP, true)
						local e1 = Effect.CreateEffect(c)
						e1:SetType(EFFECT_TYPE_SINGLE)
						e1:SetCode(EFFECT_CHANGE_TYPE)
						e1:SetValue(TYPE_SPELL + TYPE_CONTINUOUS)
						e1:SetReset(RESET_EVENT + RESETS_STANDARD - RESET_TURN_SET)
						tc:RegisterEffect(e1)
					end
				end
			end
		end
	end
end
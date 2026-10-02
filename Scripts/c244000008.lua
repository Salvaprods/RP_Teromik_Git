-- Devcutie - Boretta
local s, id = GetID()

s.listed_series = {0xb8e}
s.listed_names = {id}

function s.initial_effect(c)
	-- Invocable par Lien (2+ monstres "Devcutie")
	c:EnableReviveLimit()
	aux.AddLinkProcedure(c, aux.FilterBoolFunction(Card.IsSetCard, 0xb8e), 2, 3)

	-- Effet 1 : Invoqué par Lien -> Spécialise 1 "Devcutie" du Cimetière pointé + annulation optionnelle
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1, id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Effet 2 : Détruit au combat ou par effet -> Recycle 3 "Devcutie" diff. + destruction optionnelle
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_TODECK + CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_DESTROYED)
	e2:SetCountLimit(1, id + 100)
	e2:SetCondition(s.descon)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
end

-- ==========================================
-- EFFET 1 : INVOCATION DEPUIS LE CIMETIÈRE ET ANNULATION
-- ==========================================
function s.spcon(e, tp, eg, ep, ev, re, r, rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

function s.spfilter(c, e, tp, zone)
	return c:IsSetCard(0xb8e) and not c:IsCode(id) and c:IsType(TYPE_MONSTER)
		and c:IsCanBeSpecialSummoned(e, 0, tp, false, false, POS_FACEUP, tp, zone)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	local zone = e:GetHandler():GetLinkedZone(tp)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.spfilter(chkc, e, tp, zone) end
	if chk == 0 then
		return zone ~= 0 and Duel.IsExistingTarget(s.spfilter, tp, LOCATION_GRAVE, 0, 1, nil, e, tp, zone)
	end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local g = Duel.SelectTarget(tp, s.spfilter, tp, LOCATION_GRAVE, 0, 1, 1, nil, e, tp, zone)
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, g, 1, 0, 0)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	local tc = Duel.GetFirstTarget()
	local zone = c:IsRelateToEffect(e) and c:GetLinkedZone(tp) or 0
	if tc and tc:IsRelateToEffect(e) and zone ~= 0 then
		if Duel.SpecialSummon(tc, 0, tp, tp, false, false, POS_FACEUP, zone) ~= 0 and c:IsRelateToEffect(e) then
			local og = c:GetLinkedGroup():Filter(Card.IsControler, nil, 1 - tp):Filter(Card.IsFaceup, nil):Filter(aux.NOT(Card.IsDisabled), nil)
			if #og > 0 and Duel.SelectYesNo(tp, aux.Stringid(id, 2)) then
				Duel.BreakEffect()
				for oc in aux.Next(og) do
					local e1 = Effect.CreateEffect(c)
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetCode(EFFECT_DISABLE)
					e1:SetReset(RESET_EVENT + RESETS_STANDARD)
					oc:RegisterEffect(e1)
					local e2 = Effect.CreateEffect(c)
					e2:SetType(EFFECT_TYPE_SINGLE)
					e2:SetCode(EFFECT_DISABLE_EFFECT)
					e2:SetReset(RESET_EVENT + RESETS_STANDARD)
					oc:RegisterEffect(e2)
				end
			end
		end
	end
end

-- ==========================================
-- EFFET 2 : RECYCLAGE ET DESTRUCTION
-- ==========================================
function s.descon(e, tp, eg, ep, ev, re, r, rp)
	return e:GetHandler():IsReason(REASON_BATTLE + REASON_EFFECT)
end

function s.tdfilter(c)
	return c:IsSetCard(0xb8e) and c:IsAbleToDeck()
end

function s.destg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return false end
	local g = Duel.GetMatchingGroup(s.tdfilter, tp, LOCATION_GRAVE, 0, nil)
	if chk == 0 then
		return g:SelectSubGroup(tp, aux.dncheck, false, 3, 3) ~= nil
	end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TODECK)
	local sg = g:SelectSubGroup(tp, aux.dncheck, false, 3, 3)
	Duel.SetTargetCard(sg)
	Duel.SetOperationInfo(0, CATEGORY_TODECK, sg, 3, 0, 0)
end

function s.desop(e, tp, eg, ep, ev, re, r, rp)
	local g = Duel.GetTargetCards(e)
	if #g == 3 and Duel.SendtoDeck(g, nil, SEQ_DECKSHUFFLE, REASON_EFFECT) > 0 then
		local dg = Duel.GetMatchingGroup(nil, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, nil)
		if #dg > 0 and Duel.SelectYesNo(tp, aux.Stringid(id, 3)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
			local sg = dg:Select(tp, 1, 1, nil)
			Duel.Destroy(sg, REASON_EFFECT)
		end
	end
end
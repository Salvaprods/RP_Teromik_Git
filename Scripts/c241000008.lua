-- Reine - Echec Divin
local s, id = GetID()

s.listed_series = {0xe7a}

function s.initial_effect(c)
	c:EnableReviveLimit()
	
	-- Invoc Spéciale inhérente : Envoyer 3 cartes monstre "Echec Divin" depuis la main et/ou le terrain (MZONE ou SZONE) au Cimetière
	local e0 = Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.spcon)
	e0:SetTarget(s.sptg)
	e0:SetOperation(s.spop)
	c:RegisterEffect(e0)

	-- Effet 1 : déplacement de zone (Effet Rapide)
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetHintTiming(0, TIMINGS_CHECK_MONSTER)
	e1:SetCountLimit(1, id)
	e1:SetCondition(s.mvcon)
	e1:SetTarget(s.mvtg)
	e1:SetOperation(s.mvop)
	c:RegisterEffect(e1)

	-- Effet 2 : annulation Magie/Piège
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_NEGATE + CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1, id + 100)
	e2:SetCondition(s.negcon)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)
end

-- ==========================================
-- INVOCATION SPÉCIALE INHÉRENTE
-- ==========================================
function s.spfilter(c)
	return c:IsSetCard(0xe7a) 
		and (c:IsType(TYPE_MONSTER) or (c:GetOriginalType() & TYPE_MONSTER) ~= 0) 
		and c:IsAbleToGraveAsCost()
end

function s.spcon(e, c)
	if c == nil then return true end
	local tp = c:GetControler()
	local g = Duel.GetMatchingGroup(s.spfilter, tp, LOCATION_HAND + LOCATION_ONFIELD, 0, nil)
	return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 and #g >= 3
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk, c)
	local g = Duel.GetMatchingGroup(s.spfilter, tp, LOCATION_HAND + LOCATION_ONFIELD, 0, nil)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
	local sg = g:Select(tp, 3, 3, nil)
	if sg and #sg == 3 then
		sg:KeepAlive()
		e:SetLabelObject(sg)
		return true
	end
	return false
end

function s.spop(e, tp, eg, ep, ev, re, r, rp, c)
	local sg = e:GetLabelObject()
	if sg then
		Duel.SendtoGrave(sg, REASON_COST)
		sg:DeleteGroup()
	end
end

-- ==========================================
-- EFFET 1 : DÉPLACEMENT & COLONNE
-- ==========================================
function s.mvcon(e, tp, eg, ep, ev, re, r, rp)
	return Duel.IsMainPhase()
end

function s.mvfilter(c, tp)
	if not (c:IsFaceup() and c:IsSetCard(0xe7a)) then return false end
	local seq = c:GetSequence()
	for i = 0, 4 do
		if i ~= seq and Duel.CheckLocation(tp, LOCATION_MZONE, i) then
			return true
		end
	end
	return false
end

function s.mvtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.mvfilter(chkc, tp) end
	if chk == 0 then
		return Duel.IsExistingTarget(s.mvfilter, tp, LOCATION_MZONE, 0, 1, nil, tp)
	end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
	Duel.SelectTarget(tp, s.mvfilter, tp, LOCATION_MZONE, 0, 1, 1, nil, tp)
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 0, 1 - tp, LOCATION_ONFIELD)
end

function s.mvop(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) or not tc:IsFaceup() then return end
	
	local flag = 0
	local seq = tc:GetSequence()
	for i = 0, 4 do
		if i ~= seq and Duel.CheckLocation(tp, LOCATION_MZONE, i) then
			flag = flag | (1 << i)
		end
	end
	if flag == 0 then return end
	
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOZONE)
	local zone = Duel.SelectField(tp, 1, LOCATION_MZONE, 0, ~flag)
	local new_seq = 0
	for i = 0, 4 do
		if (zone & (1 << i)) ~= 0 then
			new_seq = i
			break
		end
	end
	
	if new_seq ~= seq and Duel.MoveSequence(tc, new_seq) ~= 0 then
		local g = tc:GetColumnGroup()
		local og = g:Filter(Card.IsControler, nil, 1 - tp)
		og = og:Filter(Card.IsAbleToHand, nil)
		if #og > 0 and Duel.SelectYesNo(tp, aux.Stringid(id, 2)) then
			Duel.BreakEffect()
			Duel.SendtoHand(og, nil, REASON_EFFECT)
		end
	end
end

-- ==========================================
-- EFFET 2 : ANNULATION MAGIE/PIÈGE
-- ==========================================
function s.negcon(e, tp, eg, ep, ev, re, r, rp)
	return rp ~= tp and re:IsActiveType(TYPE_SPELL + TYPE_TRAP) and Duel.IsChainNegatable(ev)
end

function s.negfilter(c)
	return c:IsSetCard(0xe7a) and c:IsAbleToGrave()
end

function s.negtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.IsExistingMatchingCard(s.negfilter, tp, LOCATION_ONFIELD, 0, 1, nil)
	end
	Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
	Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, nil, 1, tp, LOCATION_ONFIELD)
end

function s.negop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.NegateActivation(ev) then
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
		local g = Duel.SelectMatchingCard(tp, s.negfilter, tp, LOCATION_ONFIELD, 0, 1, 1, nil)
		if #g > 0 then
			Duel.SendtoGrave(g, REASON_EFFECT)
		end
	end
end
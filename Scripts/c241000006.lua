-- Adorable Joueuse D'Echec - Echec Divin
local s, id = GetID()
function s.initial_effect(c)
	-- Effet 1 : Ajouter 1 monstre "Echec Divin" du Deck à la main + restriction d'invocation
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1, id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Effet 2 : Bannir depuis le Cimetière pour déplacer un monstre "Echec Divin" vers une autre zone
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1, id + 100)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.mvtg)
	e2:SetOperation(s.mvop)
	c:RegisterEffect(e2)
end

s.listed_series = {0xe7a} -- Echec Divin

-- ==========================================
-- EFFET 1 : RECHERCHE + RESTRICTION
-- ==========================================
function s.filter(c)
	return c:IsSetCard(0xe7a) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(s.filter, tp, LOCATION_DECK, 0, 1, nil) end
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
	local g = Duel.SelectMatchingCard(tp, s.filter, tp, LOCATION_DECK, 0, 1, 1, nil)
	if #g > 0 then
		if Duel.SendtoHand(g, nil, REASON_EFFECT) ~= 0 then
			Duel.ConfirmCards(1 - tp, g)
			-- Restriction d'invocation (Normale et Spéciale)
			local e1 = Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_FIELD)
			e1:SetCode(EFFECT_CANNOT_SUMMON)
			e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET + EFFECT_FLAG_CLIENT_HINT)
			e1:SetTargetRange(1, 0)
			e1:SetDescription(aux.Stringid(id, 2))
			e1:SetTarget(s.sumlimit)
			e1:SetReset(RESET_PHASE + PHASE_END)
			Duel.RegisterEffect(e1, tp)
			local e2 = e1:Clone()
			e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
			Duel.RegisterEffect(e2, tp)
		end
	end
end

function s.sumlimit(e, c, sump, sumtype, sumpos, targetp, se)
	return not c:IsSetCard(0xe7a)
end

-- ==========================================
-- EFFET 2 : DÉPLACEMENT DE ZONE DEPUIS LE CIMETIÈRE
-- ==========================================
function s.mvfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xe7a)
end

function s.mvtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.mvfilter(chkc) end
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and Duel.IsExistingTarget(s.mvfilter, tp, LOCATION_MZONE, 0, 1, nil)
	end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
	Duel.SelectTarget(tp, s.mvfilter, tp, LOCATION_MZONE, 0, 1, 1, nil)
end

function s.mvop(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) or not tc:IsFaceup() then return end
	
	local flag = 0
	for i = 0, 4 do
		if Duel.CheckLocation(tp, LOCATION_MZONE, i) then
			flag = flag | (1 << i)
		end
	end
	if flag == 0 then return end
	
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOZONE)
	local zone = Duel.SelectField(tp, 1, LOCATION_MZONE, 0, ~flag)
	local seq = 0
	for i = 0, 4 do
		if (zone & (1 << i)) ~= 0 then
			seq = i
			break
		end
	end
	
	if seq ~= tc:GetSequence() then
		Duel.MoveSequence(tc, seq)
	end
end
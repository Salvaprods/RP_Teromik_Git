-- Bjorn - Âme Du Chasseur
local s, id = GetID()

function s.initial_effect(c)
	-- ==========================================
	-- MÉCANIQUE PENDULE
	-- ==========================================
	aux.EnablePendulumAttribute(c)

	-- ==========================================
	-- EFFET PENDULE (P)
	-- ==========================================
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_TOEXTRA)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_PZONE)
	e1:SetCountLimit(1, id)
	e1:SetCost(s.pencost)
	e1:SetTarget(s.pentg)
	e1:SetOperation(s.penop)
	c:RegisterEffect(e1)
	
	-- ==========================================
	-- EFFETS DE MONSTRE (E)
	-- ==========================================
	-- Effet 1 : Arrivé face recto à l'Extra Deck -> S'Invoquer (Condition stricte de zone Extra)
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_LEAVE_FIELD)
	e2:SetRange(LOCATION_EXTRA)
	e2:SetCountLimit(1, id + 100)
	e2:SetCondition(s.pzcon)
	e2:SetTarget(s.extg)
	e2:SetOperation(s.exop)
	c:RegisterEffect(e2)

	-- Effet 2 : Invoqué Normalement ou Spécialement -> Top 5 Deck
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 2))
	e3:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH + CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetCountLimit(1, id + 200)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
	
	local e3_bis = e3:Clone()
	e3_bis:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3_bis)
end

function s.hunter_filter(c)
	return c:IsSetCard(0xc92)
end

-- ==========================================
-- EFFET PENDULE (Placer dans l'Extra Deck)
-- ==========================================
function s.pencost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return e:GetHandler():IsDestructable() end
	Duel.Destroy(e:GetHandler(), REASON_COST)
end

function s.penfilter(c)
	return c:IsSetCard(0xc92) and c:IsType(TYPE_PENDULUM) and c:IsLevelBelow(6) and not c:IsForbidden()
end

function s.pentg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(s.penfilter, tp, LOCATION_DECK, 0, 1, nil) end
	Duel.SetOperationInfo(0, CATEGORY_TOEXTRA, nil, 1, tp, LOCATION_DECK)
end

function s.penop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOEXTRA)
	local g = Duel.SelectMatchingCard(tp, s.penfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
	if #g > 0 then
		Duel.SendtoExtraP(g, tp, REASON_EFFECT)
	end
end

-- ==========================================
-- EFFET MONSTRE 1 : Arrivée Extra Deck
-- ==========================================
function s.pzcon(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	return c:IsLocation(LOCATION_EXTRA) and c:IsFaceup() and c:IsPreviousLocation(LOCATION_ONFIELD)
end

function s.extg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then 
		-- EMPÊCHE L'ACTIVATION S'IL N'Y A PAS DE PLACE VALIDE DEPUIS L'EXTRA DECK
		return Duel.GetLocationCountFromEx(tp, tp, nil, c) > 0 
			and c:IsCanBeSpecialSummoned(e, 0, tp, false, false) 
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, 0, 0)
end

function s.exop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP)
	end
end

-- ==========================================
-- EFFET MONSTRE 2 : Top 5 Deck -> Ajouter -> Destruction optionnelle
-- ==========================================
function s.thfilter(c)
	return s.hunter_filter(c) and c:IsAbleToHand()
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.GetFieldGroupCount(tp, LOCATION_DECK, 0) >= 5 end
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end

function s.thop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetFieldGroupCount(tp, LOCATION_DECK, 0) < 5 then return end
	Duel.ConfirmDecktop(tp, 5)
	local g = Duel.GetDecktopGroup(tp, 5)
	if #g > 0 then
		local sg = g:Filter(s.thfilter, nil)
		if #sg > 0 and Duel.SelectYesNo(tp, aux.Stringid(id, 3)) then
			Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
			local tg = sg:Select(tp, 1, 1, nil)
			Duel.SendtoHand(tg, nil, REASON_EFFECT)
			Duel.ConfirmCards(1 - tp, tg)
		end
		Duel.ShuffleDeck(tp)
	end
	
	if Duel.GetFieldGroupCount(tp, 0, LOCATION_MZONE) > 0 
		and Duel.IsExistingMatchingCard(Card.IsFaceup, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, nil) 
		and Duel.SelectYesNo(tp, aux.Stringid(id, 4)) then
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
		local dg = Duel.SelectMatchingCard(tp, Card.IsFaceup, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, 1, nil)
		if #dg > 0 then
			Duel.BreakEffect()
			Duel.Destroy(dg, REASON_EFFECT)
		end
	end
end
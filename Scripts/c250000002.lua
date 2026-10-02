-- Gokvelgr - Âme Du Chasseur
local s, id = GetID()

function s.initial_effect(c)
	-- ==========================================
	-- MÉCANIQUE PENDULE
	-- ==========================================
	aux.EnablePendulumAttribute(c)

	-- ==========================================
	-- EFFET PENDULE (P)
	-- ==========================================
	-- Détruire -> Chercher
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SEARCH + CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_PZONE)
	e1:SetCountLimit(1, id)
	e1:SetCost(s.thcost)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	
	-- ==========================================
	-- EFFETS DE MONSTRE (E)
	-- ==========================================
	-- Effet 1 : Ajouté face recto à l'Extra Deck
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_LEAVE_FIELD)
	e2:SetRange(LOCATION_EXTRA)
	e2:SetCountLimit(1, id + 100)
	e2:SetCondition(s.pzcon)
	e2:SetTarget(s.pztg)
	e2:SetOperation(s.pzop)
	c:RegisterEffect(e2)

	-- Effet 2 : Invoquée Spécialement -> Raigeki
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 2))
	e3:SetCategory(CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetCountLimit(1, id + 200)
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)

	-- Effet 3 : Monstre quitte l'Extra Deck adverse -> Invoquer Spécialement
	local function create_ed_leave_effect(event_code)
		local e = Effect.CreateEffect(c)
		e:SetDescription(aux.Stringid(id, 3))
		e:SetCategory(CATEGORY_SPECIAL_SUMMON)
		e:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
		e:SetProperty(EFFECT_FLAG_DELAY)
		e:SetCode(event_code)
		e:SetRange(LOCATION_EXTRA)
		e:SetCountLimit(1, id + 300)
		e:SetCondition(s.spcon)
		e:SetCost(s.spcost)
		e:SetTarget(s.sptg)
		e:SetOperation(s.spop)
		c:RegisterEffect(e)
	end
	create_ed_leave_effect(EVENT_SPSUMMON_SUCCESS)
	create_ed_leave_effect(EVENT_TO_GRAVE)
	create_ed_leave_effect(EVENT_REMOVE)
	create_ed_leave_effect(EVENT_TO_HAND)
end

-- Pendule : Chercher
function s.thcost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return e:GetHandler():IsDestructable() end
	Duel.Destroy(e:GetHandler(), REASON_COST)
end
function s.thfilter(c)
	return c:IsSetCard(0xc92) and c:IsAbleToHand()
end
function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil) end
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end
function s.thop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
	local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
	if #g > 0 then
		Duel.SendtoHand(g, nil, REASON_EFFECT)
		Duel.ConfirmCards(1 - tp, g)
	end
end

-- Monstre 1 : Placement Pendule depuis Deck/Main
function s.pzcon(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	return c:IsLocation(LOCATION_EXTRA) and c:IsFaceup() and c:IsPreviousLocation(LOCATION_ONFIELD)
end
function s.pzfilter(c)
	return c:IsSetCard(0xc92) and c:IsType(TYPE_PENDULUM) and not c:IsCode(id) and not c:IsForbidden()
end
function s.pztg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then 
		return (Duel.CheckLocation(tp, LOCATION_PZONE, 0) or Duel.CheckLocation(tp, LOCATION_PZONE, 1))
			and Duel.IsExistingMatchingCard(s.pzfilter, tp, LOCATION_DECK + LOCATION_HAND, 0, 1, nil) 
	end
end
function s.pzop(e, tp, eg, ep, ev, re, r, rp)
	if not Duel.CheckLocation(tp, LOCATION_PZONE, 0) and not Duel.CheckLocation(tp, LOCATION_PZONE, 1) then return end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOFIELD)
	local g = Duel.SelectMatchingCard(tp, s.pzfilter, tp, LOCATION_DECK + LOCATION_HAND, 0, 1, 1, nil)
	if #g > 0 then
		Duel.MoveToField(g:GetFirst(), tp, tp, LOCATION_PZONE, POS_FACEUP, true)
	end
end

-- Monstre 2 : Détruire monstres adverses
function s.destg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.GetFieldGroupCount(tp, 0, LOCATION_MZONE) > 0 end
	local g = Duel.GetFieldGroup(tp, 0, LOCATION_MZONE)
	Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, #g, 0, 0)
end
function s.desop(e, tp, eg, ep, ev, re, r, rp)
	local g = Duel.GetFieldGroup(tp, 0, LOCATION_MZONE)
	if #g > 0 then
		Duel.Destroy(g, REASON_EFFECT)
	end
end

-- Monstre 3 : S'invoquer depuis Extra
function s.exfilter(c, tp)
	return c:IsPreviousLocation(LOCATION_EXTRA) and c:GetPreviousControler() == 1 - tp
end
function s.spcon(e, tp, eg, ep, ev, re, r, rp)
	return e:GetHandler():IsFaceup() and eg:IsExists(s.exfilter, 1, nil, tp)
end
function s.revfilter(c)
	return c:IsSetCard(0xc92) and not c:IsPublic()
end
function s.spcost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(s.revfilter, tp, LOCATION_HAND, 0, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_CONFIRM)
	local g = Duel.SelectMatchingCard(tp, s.revfilter, tp, LOCATION_HAND, 0, 1, 1, nil)
	Duel.ConfirmCards(1 - tp, g)
	Duel.ShuffleHand(tp)
end
function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then 
		return Duel.GetLocationCountFromEx(tp, tp, nil, c) > 0
			and c:IsCanBeSpecialSummoned(e, 0, tp, false, false) 
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, 0, 0)
end
function s.spop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP)
	end
end
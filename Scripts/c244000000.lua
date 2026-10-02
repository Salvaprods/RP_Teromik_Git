-- Devcutie - Louise
local s, id = GetID()

s.listed_series = {0xb8e}

function s.initial_effect(c)
	-- Pendulum Summon
	aux.EnablePendulumAttribute(c)

	-- ==========================================
	-- EFFET PENDULE
	-- ==========================================
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetRange(LOCATION_PZONE)
	e1:SetTargetRange(LOCATION_MZONE, 0)
	e1:SetTarget(aux.TargetBoolFunction(Card.IsSetCard, 0xb8e))
	e1:SetValue(aux.tgoval)
	c:RegisterEffect(e1)

	-- ==========================================
	-- EFFET MONSTRE 1 : INVOCATION & COÛT DE DESTRUCTION + RECHERCHE M/P (1 fois par tour)
	-- ==========================================
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 0))
	e2:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH + CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1, id)
	e2:SetCost(s.thcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	local e2_bis = e2:Clone()
	e2_bis:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2_bis)

	-- ==========================================
	-- EFFET MONSTRE 2 : AJOUTÉ À L'EXTRA DECK -> ZONE PENDULE (Sans limite par tour)
	-- ==========================================
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 1))
	e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_LEAVE_FIELD)
	e3:SetRange(LOCATION_EXTRA)
	e3:SetCondition(s.pzcon)
	e3:SetTarget(s.pztg)
	e3:SetOperation(s.pzop)
	c:RegisterEffect(e3)
end

-- ==========================================
-- FONCTIONS : EFFET MONSTRE 1
-- ==========================================
function s.thcost(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then return c:IsDestructable(e) end
	Duel.Destroy(c, REASON_COST)
end

function s.thfilter(c)
	return c:IsSetCard(0xb8e) and c:IsType(TYPE_SPELL + TYPE_TRAP) and c:IsAbleToHand()
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil)
	end
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end

function s.thop(e, tp, eg, ep, ev, re, r, rp)
	-- Restriction : Ne peut pas Invoquer de monstres excepté "Devcutie" le reste du tour
	local e1 = Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_SUMMON)
	e1:SetTargetRange(1, 0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE + PHASE_END)
	Duel.RegisterEffect(e1, tp)
	local e2 = e1:Clone()
	e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	Duel.RegisterEffect(e2, tp)

	-- Recherche
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
	local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
	if #g > 0 then
		Duel.SendtoHand(g, nil, REASON_EFFECT)
		Duel.ConfirmCards(1 - tp, g)
	end
end

function s.splimit(e, c, sump, sumtype, sumpos, targetp, se)
	return not c:IsSetCard(0xb8e)
end

-- ==========================================
-- FONCTIONS : EFFET MONSTRE 2
-- ==========================================
function s.pzcon(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	return c:IsLocation(LOCATION_EXTRA) and c:IsFaceup() and c:IsPreviousLocation(LOCATION_ONFIELD)
end

function s.pztg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then
		return (Duel.CheckLocation(tp, LOCATION_PZONE, 0) or Duel.CheckLocation(tp, LOCATION_PZONE, 1))
			and not c:IsForbidden()
	end
end

function s.pzop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if not (Duel.CheckLocation(tp, LOCATION_PZONE, 0) or Duel.CheckLocation(tp, LOCATION_PZONE, 1)) then return end
	if c:IsRelateToEffect(e) then
		Duel.MoveToField(c, tp, tp, LOCATION_PZONE, POS_FACEUP, true)
	end
end
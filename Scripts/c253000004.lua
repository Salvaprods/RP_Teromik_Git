-- Arrivée Des Bulles Des Slime☺
local s,id=GetID()

local SET_SLIME=0xc2a

function s.initial_effect(c)
	-- Activation : ajouter 1 carte Slime☺ au nom différent
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
end

s.listed_series={SET_SLIME}

-- =========================================
-- NOMS SLIME☺ DÉJÀ CONTRÔLÉS / DANS LE GY
-- =========================================
function s.namefilter(c)
	return c:IsSetCard(SET_SLIME)
end

function s.thfilter(c,tp)
	if not c:IsSetCard(SET_SLIME)
		or c:IsCode(id)
		or not c:IsAbleToHand() then
		return false
	end

	local code=c:GetCode()

	return not Duel.IsExistingMatchingCard(
		function(tc)
			return tc:IsSetCard(SET_SLIME)
				and tc:IsCode(code)
		end,
		tp,
		LOCATION_ONFIELD+LOCATION_GRAVE,
		0,
		1,
		nil
	)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.thfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil,
			tp
		)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOHAND,
		nil,
		1,
		tp,
		LOCATION_DECK
	)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)

	local g=Duel.SelectMatchingCard(
		tp,
		s.thfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil,
		tp
	)

	local tc=g:GetFirst()

	if tc then
		Duel.SendtoHand(
			tc,
			nil,
			REASON_EFFECT
		)
		Duel.ConfirmCards(1-tp,tc)
	end
end
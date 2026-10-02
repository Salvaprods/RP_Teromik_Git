-- Ravitaillement Kuriboh
local s,id=GetID()

local CREPUSCULE=6309986
local MULTIPLICATEUR=40703222
local LIENKURIBOH=41999284

function s.initial_effect(c)
	-- Envoyer 1 Kuriboh depuis la main ;
	-- ajouter 1 Kuriboh de nom différent,
	-- puis optionnellement payer 1000 LP pour ajouter une M/P
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SEARCH+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

s.listed_series={0xa4}
s.listed_names={CREPUSCULE,MULTIPLICATEUR,LIENKURIBOH}

-- =========================================
-- MONSTRE KURIBOH
-- Lienkuriboh forcé comme Kuriboh
-- =========================================
function s.iskuriboh(c)
	return c:IsSetCard(0xa4)
		or c:IsCode(LIENKURIBOH)
end

function s.thfilter(c,code)
	return s.iskuriboh(c)
		and c:IsType(TYPE_MONSTER)
		and not c:IsCode(code)
		and c:IsAbleToHand()
end

-- =========================================
-- COÛT : KURIBOH DEPUIS LA MAIN
-- =========================================
function s.costfilter(c,tp)
	return s.iskuriboh(c)
		and c:IsType(TYPE_MONSTER)
		and c:IsAbleToGraveAsCost()
		and Duel.IsExistingMatchingCard(
			s.thfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil,
			c:GetCode()
		)
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.costfilter,
			tp,
			LOCATION_HAND,
			0,
			1,
			nil,
			tp
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)

	local g=Duel.SelectMatchingCard(
		tp,
		s.costfilter,
		tp,
		LOCATION_HAND,
		0,
		1,
		1,
		nil,
		tp
	)

	local tc=g:GetFirst()
	if not tc then return end

	e:SetLabel(tc:GetCode())
	Duel.SendtoGrave(tc,REASON_COST)
end

-- =========================================
-- M/P À AJOUTER
-- Kuriboh OU Crépuscule OU Multiplicateur
-- =========================================
function s.stfilter(c)
	return c:IsType(TYPE_SPELL+TYPE_TRAP)
		and (
			c:IsSetCard(0xa4)
			or c:IsCode(CREPUSCULE)
			or c:IsCode(MULTIPLICATEUR)
		)
		and not c:IsCode(id)
		and c:IsAbleToHand()
end

-- =========================================
-- TARGET
-- =========================================
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local code=e:GetLabel()

	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.thfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil,
			code
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

-- =========================================
-- RÉSOLUTION
-- =========================================
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local code=e:GetLabel()

	-- Ajoute 1 Kuriboh de nom différent
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
		code
	)

	local tc=g:GetFirst()
	if not tc then return end

	if Duel.SendtoHand(tc,nil,REASON_EFFECT)==0 then
		return
	end

	Duel.ConfirmCards(1-tp,tc)

	-- Puis possibilité de payer 1000 LP
	if not Duel.CheckLPCost(tp,1000) then
		return
	end

	if not Duel.IsExistingMatchingCard(
		s.stfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		nil
	) then
		return
	end

	if not Duel.SelectYesNo(
		tp,
		aux.Stringid(id,0)
	) then
		return
	end

	Duel.PayLPCost(tp,1000)

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)

	local sg=Duel.SelectMatchingCard(
		tp,
		s.stfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil
	)

	local sc=sg:GetFirst()

	if sc then
		Duel.SendtoHand(sc,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,sc)
	end
end
-- Royaume des Slime☺
local s,id=GetID()

local SET_SLIME=0xc2a
local TOKEN_ID=253000007 -- Remplace par l'ID de "Jeton Slime☺"

function s.initial_effect(c)
	-- Activation
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-- Tous les Slime☺ gagnent 500 ATK/DEF par Slime☺ contrôlé
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetRange(LOCATION_FZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.atktg)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)

	local e2=e1:Clone()
	e2:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e2)

	-- Main Phase : défausser 1 -> ajouter 1 Slime☺
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCountLimit(1,id+100)
	e3:SetCost(s.thcost)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)

	-- Slime☺ invoqué -> Token
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_SUMMON_SUCCESS)
	e4:SetRange(LOCATION_FZONE)
	e4:SetCountLimit(1,id+200)
	e4:SetCondition(s.tkcon)
	e4:SetTarget(s.tktg)
	e4:SetOperation(s.tkop)
	c:RegisterEffect(e4)

	local e5=e4:Clone()
	e5:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e5)

	local e6=e4:Clone()
	e6:SetCode(EVENT_FLIP_SUMMON_SUCCESS)
	c:RegisterEffect(e6)
end

s.listed_series={SET_SLIME}

-- =========================================
-- BOOST ATK / DEF
-- =========================================
function s.slimefilter(c)
	return c:IsFaceup()
		and c:IsSetCard(SET_SLIME)
		and c:IsType(TYPE_MONSTER)
end

function s.atktg(e,c)
	return s.slimefilter(c)
end

function s.atkval(e,c)
	return Duel.GetMatchingGroupCount(
		s.slimefilter,
		e:GetHandlerPlayer(),
		LOCATION_MZONE,
		0,
		nil
	)*500
end

-- =========================================
-- SEARCH
-- =========================================
function s.disfilter(c)
	return c:IsDiscardable()
end

function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.disfilter,
			tp,
			LOCATION_HAND,
			0,
			1,
			nil
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)

	local g=Duel.SelectMatchingCard(
		tp,
		s.disfilter,
		tp,
		LOCATION_HAND,
		0,
		1,
		1,
		nil
	)

	Duel.SendtoGrave(
		g,
		REASON_COST+REASON_DISCARD
	)
end

function s.thfilter(c)
	return c:IsSetCard(SET_SLIME)
		and c:IsType(TYPE_MONSTER)
		and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.thfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil
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
		nil
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

-- =========================================
-- TOKEN
-- =========================================
function s.tkfilter(c,tp)
	return c:IsControler(tp)
		and c:IsSetCard(SET_SLIME)
		and c:IsType(TYPE_MONSTER)
		and not c:IsType(TYPE_TOKEN)
end

function s.tkcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(
		s.tkfilter,
		1,
		nil,
		tp
	)
end

function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(
			tp,
			LOCATION_MZONE
		)>0
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,
		1,
		tp,
		0
	)
end

function s.tkop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(
		tp,
		LOCATION_MZONE
	)<=0 then
		return
	end

	local token=Duel.CreateToken(
		tp,
		TOKEN_ID
	)

	Duel.SpecialSummon(
		token,
		0,
		tp,
		tp,
		false,
		false,
		POS_FACEUP_DEFENSE
	)
end
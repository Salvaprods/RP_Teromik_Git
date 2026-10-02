-- ♪DIABLORCHESTRE♪ - Rocks
local s,id=GetID()

function s.initial_effect(c)
	-- Défausser cette carte ; bannir 1 DIABLORCHESTRE Niveau 3 du Deck
	-- sauf Rocks, puis ajouter 1 DIABLORCHESTRE banni à la main
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.cost)
	e1:SetTarget(s.rmtg)
	e1:SetOperation(s.rmop)
	c:RegisterEffect(e1)

	-- Si un ou plusieurs DIABLORCHESTRE sont Invoqués sur votre Terrain
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetRange(LOCATION_GRAVE+LOCATION_REMOVED)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)

	local e4=e2:Clone()
	e4:SetCode(EVENT_FLIP_SUMMON_SUCCESS)
	c:RegisterEffect(e4)
end

-- =========================================
-- EFFET 1
-- =========================================
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsDiscardable()
	end

	Duel.SendtoGrave(
		c,
		REASON_COST+REASON_DISCARD
	)
end

-- Niveau 3 DIABLORCHESTRE, Rocks exclu
function s.rmfilter(c)
	return c:IsSetCard(0xd1f)
		and c:IsType(TYPE_MONSTER)
		and c:IsLevel(3)
		and not c:IsCode(id)
		and c:IsAbleToRemove()
end

function s.thfilter(c)
	return c:IsSetCard(0xd1f)
		and c:IsType(TYPE_MONSTER)
		and c:IsFaceup()
		and c:IsAbleToHand()
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.rmfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil
		)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_REMOVE,
		nil,
		1,
		tp,
		LOCATION_DECK
	)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

	local g=Duel.SelectMatchingCard(
		tp,
		s.rmfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil
	)

	local tc=g:GetFirst()
	if not tc then return end

	if Duel.Remove(
		tc,
		POS_FACEUP,
		REASON_EFFECT
	)==0 then
		return
	end

	-- "et si vous le faites"
	local bg=Duel.GetMatchingGroup(
		s.thfilter,
		tp,
		LOCATION_REMOVED,
		0,
		nil
	)

	if bg:GetCount()==0 then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)

	local sg=bg:Select(tp,1,1,nil)
	local ac=sg:GetFirst()

	if ac
		and Duel.SendtoHand(ac,nil,REASON_EFFECT)>0 then
		Duel.ConfirmCards(1-tp,ac)
	end
end

-- =========================================
-- EFFET 2
-- =========================================
function s.spfilter(c,tp)
	return c:IsControler(tp)
		and c:IsSetCard(0xd1f)
		and c:IsType(TYPE_MONSTER)
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if c:IsLocation(LOCATION_REMOVED)
		and not c:IsFaceup() then
		return false
	end

	return eg:IsExists(
		s.spfilter,
		1,
		nil,
		tp
	)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(
				e,
				0,
				tp,
				false,
				false
			)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		c,
		1,
		tp,
		c:GetLocation()
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsRelateToEffect(e)
		or Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return
	end

	if Duel.SpecialSummon(
		c,
		0,
		tp,
		tp,
		false,
		false,
		POS_FACEUP
	)>0 then

		-- Mélangez-la dans le Deck lorsqu'elle quitte le Terrain
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_REDIRECT)
		e1:SetValue(LOCATION_DECK)
		c:RegisterEffect(e1,true)
	end
end
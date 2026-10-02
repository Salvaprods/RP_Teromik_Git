-- ♪DIABLORCHESTRE♪ - Triplourd
local s,id=GetID()

function s.initial_effect(c)
	-- Si envoyée au GY ou bannie par un effet DIABLORCHESTRE : Special Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_TO_GRAVE)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	local e2=e1:Clone()
	e2:SetCode(EVENT_REMOVE)
	c:RegisterEffect(e2)

	-- Main Phase : si Niveau/Rang 7 DIABLORCHESTRE -> pioche 1
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_DRAW)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+100)
	e3:SetCondition(s.drcon)
	e3:SetTarget(s.drtg)
	e3:SetOperation(s.drop)
	c:RegisterEffect(e3)

	-- Si Special Summon depuis GY ou bannissement : bannir 1 M/P
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_REMOVE)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	e4:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e4:SetCountLimit(1,id+200)
	e4:SetCondition(s.rmcon)
	e4:SetTarget(s.rmtg)
	e4:SetOperation(s.rmop)
	c:RegisterEffect(e4)
end

-- =========================================
-- EFFET 1
-- =========================================
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return re
		and bit.band(r,REASON_EFFECT)~=0
		and re:GetHandler()
		and re:GetHandler():IsSetCard(0xd1f)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
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

	if c:IsRelateToEffect(e)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then

		Duel.SpecialSummon(
			c,
			0,
			tp,
			tp,
			false,
			false,
			POS_FACEUP
		)
	end
end

-- =========================================
-- EFFET 2
-- =========================================
function s.lv7filter(c)
	return c:IsFaceup()
		and c:IsSetCard(0xd1f)
		and (
			c:IsLevel(7)
			or c:IsRank(7)
		)
end

function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()

	return Duel.GetTurnPlayer()==tp
		and (ph==PHASE_MAIN1 or ph==PHASE_MAIN2)
		and Duel.IsExistingMatchingCard(
			s.lv7filter,
			tp,
			LOCATION_MZONE,
			0,
			1,
			nil
		)
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsPlayerCanDraw(tp,1)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_DRAW,
		nil,
		0,
		tp,
		1
	)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Draw(tp,1,REASON_EFFECT)
end

-- =========================================
-- EFFET 3
-- =========================================
function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	return c:IsPreviousLocation(LOCATION_GRAVE)
		or c:IsPreviousLocation(LOCATION_REMOVED)
end

function s.rmfilter(c)
	return c:IsType(TYPE_SPELL+TYPE_TRAP)
		and c:IsAbleToRemove()
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_ONFIELD)
			and s.rmfilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.rmfilter,
			tp,
			LOCATION_ONFIELD,
			LOCATION_ONFIELD,
			1,
			nil
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

	local g=Duel.SelectTarget(
		tp,
		s.rmfilter,
		tp,
		LOCATION_ONFIELD,
		LOCATION_ONFIELD,
		1,
		1,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_REMOVE,
		g,
		1,
		0,
		0
	)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if tc
		and tc:IsRelateToEffect(e) then

		Duel.Remove(
			tc,
			POS_FACEUP,
			REASON_EFFECT
		)
	end
end
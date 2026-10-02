-- ♪DIABLORCHESTRE♪ - Guitaros
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

	-- Défausser cette carte ; ajouter 1 monstre DIABLORCHESTRE
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_HAND)
	e3:SetCountLimit(1,id+100)
	e3:SetCost(s.thcost)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)

	-- Normal/Special Summon :
	-- 1 monstre devient immunisé aux effets de Magie adverses
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_SUMMON_SUCCESS)
	e4:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e4:SetCountLimit(1,id+200)
	e4:SetTarget(s.imtg)
	e4:SetOperation(s.imop)
	c:RegisterEffect(e4)

	local e5=e4:Clone()
	e5:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e5)
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
		0,CATEGORY_SPECIAL_SUMMON,c,1,tp,c:GetLocation()
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if c:IsRelateToEffect(e)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then

		Duel.SpecialSummon(
			c,0,tp,tp,false,false,POS_FACEUP
		)
	end
end

-- =========================================
-- EFFET 2
-- =========================================
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsDiscardable()
	end

	Duel.SendtoGrave(
		c,
		REASON_COST+REASON_DISCARD
	)
end

function s.thfilter(c)
	return c:IsSetCard(0xd1f)
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
		0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK
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

	if tc
		and Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 then
		Duel.ConfirmCards(1-tp,tc)
	end
end

-- =========================================
-- EFFET 3
-- IMMUNITÉ AUX MAGIES ADVERSES
-- =========================================
function s.imtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_MZONE)
			and chkc:IsFaceup()
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			Card.IsFaceup,
			tp,
			LOCATION_MZONE,
			0,
			1,
			nil
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)

	Duel.SelectTarget(
		tp,
		Card.IsFaceup,
		tp,
		LOCATION_MZONE,
		0,
		1,
		1,
		nil
	)
end

function s.immval(e,te)
	return te:IsActiveType(TYPE_SPELL)
		and te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

function s.imop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if not tc
		or not tc:IsRelateToEffect(e)
		or not tc:IsFaceup() then
		return
	end

	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetValue(s.immval)
	e1:SetReset(
		RESET_EVENT+RESETS_STANDARD+
		RESET_PHASE+PHASE_END,
		2
	)
	tc:RegisterEffect(e1)
end
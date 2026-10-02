-- Cure Profonde - Âme Du Chasseur
local s,id=GetID()

function s.initial_effect(c)
	-- Ajouter 1 carte Âme Du Chasseur,
	-- ou la placer en Zone Pendule si c'est un Monstre Pendule
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
end

s.listed_series={0xc92}

function s.thfilter(c,tp)
	if not c:IsSetCard(0xc92)
		or c:IsCode(id) then
		return false
	end

	local b1=c:IsAbleToHand()
	local b2=c:IsType(TYPE_MONSTER)
		and c:IsType(TYPE_PENDULUM)
		and not c:IsForbidden()
		and (
			Duel.CheckLocation(tp,LOCATION_PZONE,0)
			or Duel.CheckLocation(tp,LOCATION_PZONE,1)
		)

	return b1 or b2
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
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_OPERATECARD)

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
	if not tc then return end

	local b1=tc:IsAbleToHand()
	local b2=tc:IsType(TYPE_MONSTER)
		and tc:IsType(TYPE_PENDULUM)
		and not tc:IsForbidden()
		and (
			Duel.CheckLocation(tp,LOCATION_PZONE,0)
			or Duel.CheckLocation(tp,LOCATION_PZONE,1)
		)

	local op=0

	if b1 and b2 then
		op=Duel.SelectOption(
			tp,
			aux.Stringid(id,0),
			aux.Stringid(id,1)
		)
	elseif b2 then
		op=1
	end

	if op==0 then
		if Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 then
			Duel.ConfirmCards(1-tp,tc)
		end
	else
		Duel.MoveToField(
			tc,
			tp,
			tp,
			LOCATION_PZONE,
			POS_FACEUP,
			true
		)
	end
end
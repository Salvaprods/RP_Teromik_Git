-- Solfachord Jacia
local s,id=GetID()
local sid=120000001

function s.initial_effect(c)
	aux.EnablePendulumAttribute(c)

	-- Effet Pendule
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(sid,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_PZONE)
	e1:SetCountLimit(1,id+100)
	e1:SetCost(s.pencost)
	e1:SetTarget(s.pentg)
	e1:SetOperation(s.penop)
	c:RegisterEffect(e1)

	-- Si envoyée face recto à l'Extra Deck
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(sid,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_LEAVE_FIELD)
	e2:SetCountLimit(1,id+200)
	e2:SetCondition(s.pzcon)
	e2:SetTarget(s.pztg)
	e2:SetOperation(s.pzop)
	c:RegisterEffect(e2)

	-- Normal / Special Summon
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(sid,2))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetCountLimit(1,id+300)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)

	local e4=e3:Clone()
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e4)
end

s.listed_series={0x162}

function s.pencost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsDestructable() end
	Duel.Destroy(c,REASON_COST)
end

function s.penfilter(c)
	return c:IsSetCard(0x162)
		and not c:IsCode(id)
		and c:IsAbleToHand()
end

function s.pentg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.penfilter,tp,LOCATION_DECK,0,1,nil
		)
	end
	Duel.SetOperationInfo(
		0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK
	)
end

function s.penop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)

	local g=Duel.SelectMatchingCard(
		tp,s.penfilter,tp,LOCATION_DECK,0,1,1,nil
	)

	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

function s.pzcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsLocation(LOCATION_EXTRA)
		and c:IsFaceup()
		and c:IsPreviousLocation(LOCATION_ONFIELD)
end

function s.pzfilter(c)
	return c:IsType(TYPE_PENDULUM)
		and not c:IsCode(id)
		and not c:IsForbidden()
end

function s.pztg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return (
			Duel.CheckLocation(tp,LOCATION_PZONE,0)
			or Duel.CheckLocation(tp,LOCATION_PZONE,1)
		)
		and Duel.IsExistingMatchingCard(
			s.pzfilter,
			tp,
			LOCATION_DECK+LOCATION_HAND+LOCATION_EXTRA,
			0,1,nil
		)
	end

	Duel.SetOperationInfo(
		0,CATEGORY_TOFIELD,nil,1,tp,
		LOCATION_DECK+LOCATION_HAND+LOCATION_EXTRA
	)
end

function s.pzop(e,tp,eg,ep,ev,re,r,rp)
	if not (
		Duel.CheckLocation(tp,LOCATION_PZONE,0)
		or Duel.CheckLocation(tp,LOCATION_PZONE,1)
	) then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)

	local g=Duel.SelectMatchingCard(
		tp,s.pzfilter,tp,
		LOCATION_DECK+LOCATION_HAND+LOCATION_EXTRA,
		0,1,1,nil
	)

	local tc=g:GetFirst()

	if tc then
		Duel.MoveToField(
			tc,tp,tp,
			LOCATION_PZONE,
			POS_FACEUP,
			true
		)
	end
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetFieldGroupCount(
			tp,LOCATION_DECK,0
		)>=3
	end
end

function s.thfilter(c)
	return c:IsSetCard(0x162)
		and c:IsAbleToHand()
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFieldGroupCount(
		tp,LOCATION_DECK,0
	)<3 then return end

	Duel.ConfirmDecktop(tp,3)

	local g=Duel.GetDecktopGroup(tp,3)
	local sg=g:Filter(s.thfilter,nil)

	if #sg>0
		and Duel.SelectYesNo(
			tp,
			aux.Stringid(sid,3)
		) then

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)

		local tg=sg:Select(tp,1,1,nil)

		Duel.SendtoHand(
			tg,nil,REASON_EFFECT
		)

		Duel.ConfirmCards(
			1-tp,tg
		)
	end

	Duel.ShuffleDeck(tp)
end
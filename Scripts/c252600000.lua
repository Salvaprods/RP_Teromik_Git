-- Lettre Pour K9
local s,id=GetID()

function s.initial_effect(c)
	-- Envoyer 1 K9 au GY ; ajouter 1 K9 de nom différent
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+100)
	e1:SetCost(s.thcost)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- GY : bannir cette carte ; Set 1 M/P K9 depuis le Deck
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_LEAVE_GRAVE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+200)
	e2:SetCondition(s.setcon)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
end

s.listed_series={0x1cb}

-- =========================================
-- EFFET 1
-- =========================================
function s.thfilter(c,code)
	return c:IsSetCard(0x1cb)
		and c:IsType(TYPE_MONSTER)
		and not c:IsCode(code)
		and c:IsAbleToHand()
end

function s.costfilter(c,tp)
	return c:IsSetCard(0x1cb)
		and c:IsType(TYPE_MONSTER)
		and c:IsAbleToGraveAsCost()
		and Duel.IsExistingMatchingCard(
			s.thfilter,tp,LOCATION_DECK,0,1,nil,c:GetCode()
		)
end

function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.costfilter,tp,LOCATION_DECK,0,1,nil,tp
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)

	local g=Duel.SelectMatchingCard(
		tp,s.costfilter,tp,LOCATION_DECK,0,1,1,nil,tp
	)

	local tc=g:GetFirst()
	if not tc then return end

	e:SetLabel(tc:GetCode())
	Duel.SendtoGrave(tc,REASON_COST)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end

	Duel.SetOperationInfo(
		0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK
	)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local code=e:GetLabel()

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)

	local g=Duel.SelectMatchingCard(
		tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil,code
	)

	if g:GetCount()>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- =========================================
-- EFFET 2
-- =========================================
function s.xyzfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(0x1cb)
		and c:IsType(TYPE_XYZ)
end

function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(
		s.xyzfilter,tp,LOCATION_MZONE,0,1,nil
	)
end

function s.setfilter(c)
	return c:IsSetCard(0x1cb)
		and c:IsType(TYPE_SPELL+TYPE_TRAP)
		and c:IsSSetable()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.setfilter,tp,LOCATION_DECK,0,1,nil
		)
	end
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)

	local g=Duel.SelectMatchingCard(
		tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil
	)

	local tc=g:GetFirst()

	if tc then
		Duel.SSet(tp,tc)
	end
end
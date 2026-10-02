-- ♪DIABLORCHESTRE♪ - Groupies De Backstage
local s,id=GetID()

function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.thfilter(c)
	return c:IsSetCard(0xd1f)
		and c:IsType(TYPE_MONSTER)
		and c:IsAbleToHand()
end

function s.desfilter(c)
	return c:IsType(TYPE_MONSTER)
		and c:IsDestructable()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.thfilter,tp,LOCATION_DECK,0,1,nil
		)
	end

	Duel.SetOperationInfo(
		0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK
	)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	-- Ajouter 1 monstre DIABLORCHESTRE
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(
		tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil
	)

	local tc=g:GetFirst()
	if not tc then return end

	if Duel.SendtoHand(tc,nil,REASON_EFFECT)==0 then
		return
	end

	Duel.ConfirmCards(1-tp,tc)

	-- Puis, si l'adversaire contrôle plus de monstres
	if Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)
		<=Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0) then
		return
	end

	if not Duel.CheckLPCost(tp,1000) then
		return
	end

	if not Duel.IsExistingMatchingCard(
		s.desfilter,tp,0,LOCATION_MZONE,1,nil
	) then
		return
	end

	-- Effet optionnel
	if not Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		return
	end

	Duel.PayLPCost(tp,1000)

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local dg=Duel.SelectMatchingCard(
		tp,s.desfilter,tp,0,LOCATION_MZONE,1,1,nil
	)

	if dg:GetCount()>0 then
		Duel.Destroy(dg,REASON_EFFECT)
	end
end
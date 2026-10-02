-- Appel Orcustré
local s,id=GetID()

function s.initial_effect(c)
	-- Envoyez 1 monstre "Orcust" depuis le Deck au Cimetière ;
	-- ajoutez 1 carte "Orcust" de nom différent depuis le Deck à la main
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

-- Carte "Orcust" à ajouter
-- Nom différent du monstre envoyé
-- "Appel Orcustré" exclu
function s.thfilter(c,code)
	return c:IsSetCard(0x11b)
		and not c:IsCode(id)
		and c:GetCode()~=code
		and c:IsAbleToHand()
end

-- Monstre "Orcust" à envoyer au Cimetière
function s.tgfilter(c,tp)
	return c:IsSetCard(0x11b)
		and c:IsType(TYPE_MONSTER)
		and c:IsAbleToGraveAsCost()
		and Duel.IsExistingMatchingCard(
			s.thfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			c,
			c:GetCode()
		)
end

-- ==========================================
-- COÛT
-- ==========================================
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.tgfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil,
			tp
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)

	local g=Duel.SelectMatchingCard(
		tp,
		s.tgfilter,
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
		e:SetLabel(tc:GetCode())
		Duel.SendtoGrave(tc,REASON_COST)
	end
end

-- ==========================================
-- CIBLE
-- ==========================================
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return true
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

-- ==========================================
-- RÉSOLUTION
-- ==========================================
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local code=e:GetLabel()

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

	if tc then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,tc)
	end
end
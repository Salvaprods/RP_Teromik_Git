-- Appel Orcustré
local s,id=GetID()

function s.initial_effect(c)
	-- Envoyer 1 carte "Orcust" depuis la main au GY,
	-- puis ajouter 1 "Orcust" de nom différent depuis le Deck
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

s.listed_series={0x11b}

-- =========================================
-- CARTE À AJOUTER
-- =========================================
function s.thfilter(c,code)
	return c:IsSetCard(0x11b)
		and not c:IsCode(id)
		and not c:IsCode(code)
		and c:IsAbleToHand()
end

-- =========================================
-- CARTE ORCUST À ENVOYER DEPUIS LA MAIN
-- Il faut qu'un autre nom existe dans le Deck
-- =========================================
function s.tgfilter(c,tp)
	return c:IsSetCard(0x11b)
		and c:IsAbleToGrave()
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

-- =========================================
-- TARGET
-- =========================================
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.tgfilter,
			tp,
			LOCATION_HAND,
			0,
			1,
			nil,
			tp
		)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOGRAVE,
		nil,
		1,
		tp,
		LOCATION_HAND
	)

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
	-- Sélectionner 1 Orcust de la main
	local hg=Duel.GetMatchingGroup(
		s.tgfilter,
		tp,
		LOCATION_HAND,
		0,
		nil,
		tp
	)

	if hg:GetCount()==0 then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)

	local sg=hg:Select(tp,1,1,nil)
	local tc=sg:GetFirst()

	if not tc then
		return
	end

	local code=tc:GetCode()

	-- L'envoi est un EFFET, pas un coût
	if Duel.SendtoGrave(
		tc,
		REASON_EFFECT
	)==0 then
		return
	end

	-- "et si vous le faites"
	if not tc:IsLocation(LOCATION_GRAVE) then
		return
	end

	-- Ajouter un Orcust de nom différent
	if not Duel.IsExistingMatchingCard(
		s.thfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		nil,
		code
	) then
		return
	end

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

	if g:GetCount()>0 then
		Duel.SendtoHand(
			g,
			nil,
			REASON_EFFECT
		)
		Duel.ConfirmCards(1-tp,g)
	end
end
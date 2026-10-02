-- Dragonirène Bienvenue
local s,id=GetID()

function s.initial_effect(c)
	-- Envoyez 1 monstre "Dragonirène" du Deck au Cimetière ;
	-- ajoutez 1 monstre "Dragonirène" d'un Attribut différent,
	-- puis possibilité d'en Invoquer Spécialement 1 depuis la main
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SEARCH+CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- Monstre à ajouter : Attribut différent
function s.thfilter(c,att)
	return c:IsSetCard(0x133)
		and c:IsType(TYPE_MONSTER)
		and not c:IsAttribute(att)
		and c:IsAbleToHand()
end

-- Monstre à envoyer au Cimetière
function s.costfilter(c,tp)
	return c:IsSetCard(0x133)
		and c:IsType(TYPE_MONSTER)
		and c:IsAbleToGraveAsCost()
		and Duel.IsExistingMatchingCard(
			s.thfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			c,
			c:GetAttribute()
		)
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.costfilter,
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
		s.costfilter,
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
		e:SetLabel(tc:GetAttribute())
		Duel.SendtoGrave(tc,REASON_COST)
	end
end

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

function s.spfilter(c,e,tp)
	return c:IsSetCard(0x133)
		and c:IsType(TYPE_MONSTER)
		and c:IsCanBeSpecialSummoned(
			e,
			0,
			tp,
			false,
			false
		)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local att=e:GetLabel()

	-- Ajoute 1 Dragonirène d'un Attribut différent
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
		att
	)

	local tc=g:GetFirst()

	if not tc then
		return
	end

	if Duel.SendtoHand(tc,nil,REASON_EFFECT)==0 then
		return
	end

	Duel.ConfirmCards(1-tp,tc)

	-- Puis, si l'adversaire contrôle un monstre,
	-- vous pouvez Invoquer Spécialement 1 "Dragonirène" depuis votre main
	if Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)==0 then
		return
	end

	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return
	end

	if not Duel.IsExistingMatchingCard(
		s.spfilter,
		tp,
		LOCATION_HAND,
		0,
		1,
		nil,
		e,
		tp
	) then
		return
	end

	if not Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local sg=Duel.SelectMatchingCard(
		tp,
		s.spfilter,
		tp,
		LOCATION_HAND,
		0,
		1,
		1,
		nil,
		e,
		tp
	)

	local sc=sg:GetFirst()

	if sc then
		Duel.SpecialSummon(
			sc,
			0,
			tp,
			tp,
			false,
			false,
			POS_FACEUP
		)
	end
end
-- Pleine Lunalight
local s,id=GetID()

function s.initial_effect(c)
	-- Ajouter 1 monstre "Lunalight" depuis le Deck à la main
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+100)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- End Phase : récupérer cette carte depuis le GY
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_PHASE+PHASE_END)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+200)
	e2:SetCondition(s.reccon)
	e2:SetTarget(s.rectg)
	e2:SetOperation(s.recop)
	c:RegisterEffect(e2)
end

s.listed_series={0xdf}

-- =========================================
-- EFFET 1 : SEARCH
-- =========================================
function s.thfilter(c)
	return c:IsSetCard(0xdf)
		and c:IsType(TYPE_MONSTER)
		and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.thfilter,tp,LOCATION_DECK,0,1,nil
		)
	end

	Duel.SetOperationInfo(
		0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK
	)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)

	local g=Duel.SelectMatchingCard(
		tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil
	)

	if g:GetCount()>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- =========================================
-- EFFET 2 : END PHASE
-- =========================================
function s.fusfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(0xdf)
		and c:IsType(TYPE_FUSION)
end

function s.reccon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(
		s.fusfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		nil
	)
end

function s.rectg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsAbleToHand()
	end

	Duel.SetOperationInfo(
		0,CATEGORY_TOHAND,c,1,tp,LOCATION_GRAVE
	)
end

function s.recop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if c:IsRelateToEffect(e)
		and c:IsAbleToHand() then

		Duel.SendtoHand(c,nil,REASON_EFFECT)
	end
end
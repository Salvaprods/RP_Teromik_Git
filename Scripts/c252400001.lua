-- Débridage Gobelin
local s,id=GetID()

local ENTREPOT=252400000 -- ID de "Entrepôt Des Gobelins Motards"

function s.initial_effect(c)
	-- Révéler 1 Gobelin ; chercher un nom différent
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+100)
	e1:SetCost(s.thcost)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- GY : bannir cette carte ; cibler 1 Gobelin ; SS un nom différent
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+200)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

s.listed_series={0xac}
s.listed_names={ENTREPOT}

-- =========================================
-- EFFET 1 : RÉVÉLER + SEARCH
-- =========================================
function s.thfilter(c,code)
	return c:IsSetCard(0xac)
		and c:IsType(TYPE_MONSTER)
		and not c:IsCode(code)
		and c:IsAbleToHand()
end

function s.revealfilter(c,tp)
	return c:IsSetCard(0xac)
		and c:IsType(TYPE_MONSTER)
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

function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.revealfilter,
			tp,
			LOCATION_HAND,
			0,
			1,
			nil,
			tp
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)

	local g=Duel.SelectMatchingCard(
		tp,
		s.revealfilter,
		tp,
		LOCATION_HAND,
		0,
		1,
		1,
		nil,
		tp
	)

	local tc=g:GetFirst()
	if not tc then return end

	e:SetLabel(tc:GetCode())
	Duel.ConfirmCards(1-tp,tc)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
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

function s.fieldfilter(c)
	return c:IsCode(ENTREPOT)
		and not c:IsForbidden()
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
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
	if not tc then return end

	if Duel.SendtoHand(tc,nil,REASON_EFFECT)==0 then
		return
	end

	Duel.ConfirmCards(1-tp,tc)

	-- Puis possibilité de placer Entrepôt
	if not Duel.IsExistingMatchingCard(
		s.fieldfilter,
		tp,
		LOCATION_DECK+LOCATION_GRAVE,
		0,
		1,
		nil
	) then
		return
	end

	if not Duel.SelectYesNo(
		tp,
		aux.Stringid(id,1)
	) then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)

	local fg=Duel.SelectMatchingCard(
		tp,
		s.fieldfilter,
		tp,
		LOCATION_DECK+LOCATION_GRAVE,
		0,
		1,
		1,
		nil
	)

	local fc=fg:GetFirst()

	if fc then
		Duel.MoveToField(
			fc,
			tp,
			tp,
			LOCATION_FZONE,
			POS_FACEUP,
			true
		)
	end
end

-- =========================================
-- EFFET 2 : GY
-- =========================================
function s.spfilter(c,e,tp,code)
	return c:IsSetCard(0xac)
		and c:IsType(TYPE_MONSTER)
		and not c:IsCode(code)
		and c:IsCanBeSpecialSummoned(
			e,0,tp,false,false
		)
end

function s.tgfilter(c,e,tp)
	return c:IsFaceup()
		and c:IsSetCard(0xac)
		and c:IsType(TYPE_MONSTER)
		and Duel.IsExistingMatchingCard(
			s.spfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil,
			e,tp,c:GetCode()
		)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_MZONE)
			and s.tgfilter(chkc,e,tp)
	end

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingTarget(
				s.tgfilter,
				tp,
				LOCATION_MZONE,
				0,
				1,
				nil,
				e,tp
			)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)

	local g=Duel.SelectTarget(
		tp,
		s.tgfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		1,
		nil,
		e,tp
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,
		1,
		tp,
		LOCATION_DECK
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if not tc
		or not tc:IsRelateToEffect(e)
		or not tc:IsFaceup() then
		return
	end

	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local g=Duel.SelectMatchingCard(
		tp,
		s.spfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil,
		e,tp,tc:GetCode()
	)

	local sc=g:GetFirst()
	if not sc then return end

	if Duel.SpecialSummon(
		sc,0,tp,tp,false,false,POS_FACEUP
	)==0 then
		return
	end

	-- Annule ses effets
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_DISABLE)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	sc:RegisterEffect(e1)

	local e2=e1:Clone()
	e2:SetCode(EFFECT_DISABLE_EFFECT)
	sc:RegisterEffect(e2)
end
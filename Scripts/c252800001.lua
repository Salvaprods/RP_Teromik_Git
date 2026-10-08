-- Royaume Orcustré
local s,id=GetID()

function s.initial_effect(c)
	-- Activation : optionnellement envoyer 1 monstre Orcust du Deck au GY
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+1000,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.acttg)
	e1:SetOperation(s.actop)
	c:RegisterEffect(e1)

	-- Durant votre End Phase :
	-- 1 carte Orcust bannie -> GY
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_PHASE+PHASE_END)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCondition(s.retcon)
	e2:SetTarget(s.rettg)
	e2:SetOperation(s.retop)
	c:RegisterEffect(e2)

	-- Remplacement de destruction
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EFFECT_DESTROY_REPLACE)
	e3:SetRange(LOCATION_SZONE)
	e3:SetTarget(s.desreptg)
	e3:SetValue(s.desrepval)
	e3:SetOperation(s.repop)
	c:RegisterEffect(e3)

	-- Remplacement de bannissement
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EFFECT_SEND_REPLACE)
	e4:SetRange(LOCATION_SZONE)
	e4:SetTarget(s.rmreptg)
	e4:SetValue(s.rmrepval)
	e4:SetOperation(s.repop)
	c:RegisterEffect(e4)
end

s.listed_series={0x11b}

-- =========================================
-- ACTIVATION : SEND ORCUST DECK -> GY
-- =========================================
function s.deckfilter(c)
	return c:IsSetCard(0x11b)
		and c:IsType(TYPE_MONSTER)
		and c:IsAbleToGrave()
end

function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return true
	end
end

function s.actop(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.IsExistingMatchingCard(
		s.deckfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		nil
	) then
		return
	end

	if not Duel.SelectYesNo(
		tp,
		aux.Stringid(id,0)
	) then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)

	local g=Duel.SelectMatchingCard(
		tp,
		s.deckfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil
	)

	if g:GetCount()>0 then
		Duel.SendtoGrave(
			g,
			REASON_EFFECT
		)
	end
end

-- =========================================
-- END PHASE : ORCUST BANNIE -> GY
-- =========================================
function s.retcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp
end

function s.retfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(0x11b)
		and c:IsAbleToGrave()
end

function s.rettg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_REMOVED)
			and s.retfilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.retfilter,
			tp,
			LOCATION_REMOVED,
			0,
			1,
			nil
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)

	local g=Duel.SelectTarget(
		tp,
		s.retfilter,
		tp,
		LOCATION_REMOVED,
		0,
		1,
		1,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOGRAVE,
		g,
		1,
		tp,
		LOCATION_REMOVED
	)
end

function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if tc
		and tc:IsRelateToEffect(e)
		and tc:IsLocation(LOCATION_REMOVED)
		and tc:IsAbleToGrave() then

		Duel.SendtoGrave(
			tc,
			REASON_EFFECT+REASON_RETURN
		)
	end
end

-- =========================================
-- REMPLACEMENT DE DESTRUCTION
-- =========================================
function s.desrepfilter(c,tp)
	return c:IsControler(tp)
		and c:IsLocation(LOCATION_ONFIELD)
		and c:IsSetCard(0x11b)
		and c:IsReason(REASON_EFFECT)
		and not c:IsReason(REASON_REPLACE)
end

function s.desreptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsAbleToGrave()
			and eg:IsExists(
				s.desrepfilter,
				1,
				nil,
				tp
			)
	end

	return Duel.SelectYesNo(
		tp,
		aux.Stringid(id,2)
	)
end

function s.desrepval(e,c)
	return s.desrepfilter(
		c,
		e:GetHandlerPlayer()
	)
end

-- =========================================
-- REMPLACEMENT DE BANNISSEMENT
-- =========================================
function s.rmrepfilter(c,tp)
	return c:IsControler(tp)
		and c:IsLocation(LOCATION_ONFIELD)
		and c:IsSetCard(0x11b)
		and c:GetDestination()==LOCATION_REMOVED
		and c:IsReason(REASON_EFFECT)
		and not c:IsReason(REASON_REPLACE)
end

function s.rmreptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsAbleToGrave()
			and bit.band(r,REASON_EFFECT)~=0
			and eg:IsExists(
				s.rmrepfilter,
				1,
				nil,
				tp
			)
	end

	return Duel.SelectYesNo(
		tp,
		aux.Stringid(id,2)
	)
end

function s.rmrepval(e,c)
	return s.rmrepfilter(
		c,
		e:GetHandlerPlayer()
	)
end

-- =========================================
-- ROYAUME ORCUSTRÉ -> GY À LA PLACE
-- =========================================
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if c:IsLocation(LOCATION_SZONE)
		and c:IsAbleToGrave() then

		Duel.SendtoGrave(
			c,
			REASON_EFFECT+REASON_REPLACE
		)
	end
end
-- Reino Orcustré
local s,id=GetID()

function s.initial_effect(c)
	-- Activation : vous pouvez envoyer 1 monstre "Orcust" du Deck au Cimetière
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.acttg)
	e1:SetOperation(s.actop)
	c:RegisterEffect(e1)

	-- L'adversaire ne peut pas cibler les monstres "Orcust"
	-- dans votre Zone Monstre Extra
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.tgtg)
	e2:SetValue(aux.tgoval)
	c:RegisterEffect(e2)

	-- Durant votre End Phase :
	-- ciblez 1 carte "Orcust" bannie ; renvoyez-la au Cimetière
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOGRAVE)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_PHASE+PHASE_END)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1)
	e3:SetCondition(s.retcon)
	e3:SetTarget(s.rettg)
	e3:SetOperation(s.retop)
	c:RegisterEffect(e3)

	-- Si une ou plusieurs cartes "Orcust" que vous contrôlez
	-- vont être détruites par un effet :
	-- envoyez cette carte au Cimetière à la place
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EFFECT_DESTROY_REPLACE)
	e4:SetRange(LOCATION_SZONE)
	e4:SetTarget(s.desreptg)
	e4:SetValue(s.desrepval)
	e4:SetOperation(s.repop)
	c:RegisterEffect(e4)

	-- Si une ou plusieurs cartes "Orcust" que vous contrôlez
	-- vont être bannies par un effet :
	-- envoyez cette carte au Cimetière à la place
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e5:SetCode(EFFECT_SEND_REPLACE)
	e5:SetRange(LOCATION_SZONE)
	e5:SetTarget(s.rmreptg)
	e5:SetValue(s.rmrepval)
	e5:SetOperation(s.repop)
	c:RegisterEffect(e5)
end

-- =========================================================
-- ACTIVATION : ENVOI OPTIONNEL DEPUIS LE DECK
-- =========================================================
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

	-- L'envoi est OPTIONNEL
	if not Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
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

	if #g>0 then
		Duel.SendtoGrave(g,REASON_EFFECT)
	end
end

-- =========================================================
-- PROTECTION DES MONSTRES ORCUST EN EXTRA MONSTER ZONE
-- =========================================================
function s.tgtg(e,c)
	return c:IsFaceup()
		and c:IsSetCard(0x11b)
		and c:GetSequence()>4
end

-- =========================================================
-- END PHASE : CARTE ORCUST BANNIE -> CIMETIÈRE
-- =========================================================
function s.retcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp
end

function s.retfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(0x11b)
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
		and tc:IsFaceup()
		and tc:IsLocation(LOCATION_REMOVED) then

		Duel.SendtoGrave(
			tc,
			REASON_EFFECT+REASON_RETURN
		)
	end
end

-- =========================================================
-- REMPLACEMENT : DESTRUCTION
-- =========================================================
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

-- =========================================================
-- REMPLACEMENT : BANNISSEMENT
-- EFFECT_SEND_REPLACE permet ici d'empêcher l'envoi
-- vers LOCATION_REMOVED et d'envoyer cette Magie au GY
-- à la place.
-- =========================================================
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

-- =========================================================
-- ENVOI DE "ROYAUME ORCUSTRÉ" AU CIMETIÈRE À LA PLACE
-- Ce n'est PAS un effet qui s'active / aucune nouvelle chaîne.
-- =========================================================
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if c:IsRelateToEffect(e)
		and c:IsLocation(LOCATION_SZONE) then

		Duel.SendtoGrave(
			c,
			REASON_EFFECT+REASON_REPLACE
		)
	end
end
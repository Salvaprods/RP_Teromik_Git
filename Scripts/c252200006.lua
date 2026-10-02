-- Transformage - Contre Parfait
local s,id=GetID()

function s.initial_effect(c)
	-- Activable le tour où elle est Posée avec Helios Doré
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
	e0:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	e0:SetCondition(s.setturncon)
	c:RegisterEffect(e0)

	-- Negate + mélange dans le Deck
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.negcon)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)

	-- Remplacement destruction
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EFFECT_DESTROY_REPLACE)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetTarget(s.desreptg)
	e2:SetValue(s.desrepval)
	e2:SetOperation(s.repop)
	c:RegisterEffect(e2)

	-- Remplacement bannissement
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EFFECT_SEND_REPLACE)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,id+100)
	e3:SetTarget(s.rmreptg)
	e3:SetValue(s.rmrepval)
	e3:SetOperation(s.repop)
	c:RegisterEffect(e3)

	-- Si Fusion Transformage invoquée pendant que cette carte est bannie
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetRange(LOCATION_REMOVED)
	e4:SetCountLimit(1,id+200)
	e4:SetCondition(s.setcon)
	e4:SetTarget(s.settg)
	e4:SetOperation(s.setop)
	c:RegisterEffect(e4)
end

-- =========================================
-- ACTIVATION LE TOUR OÙ ELLE EST POSÉE
-- =========================================
function s.heliosfilter(c)
	return c:IsFaceup() and c:IsCode(252200004)
end

function s.setturncon(e)
	local tp=e:GetHandlerPlayer()
	return Duel.IsExistingMatchingCard(
		s.heliosfilter,tp,LOCATION_ONFIELD,0,1,nil
	)
end

-- =========================================
-- NEGATE + SHUFFLE
-- =========================================
function s.fusfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(0x6e7)
		and c:IsType(TYPE_FUSION)
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
		and Duel.IsChainNegatable(ev)
		and Duel.IsExistingMatchingCard(
			s.fusfilter,tp,LOCATION_MZONE,0,1,nil
		)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end

	Duel.SetOperationInfo(
		0,CATEGORY_NEGATE,eg,1,0,0
	)

	local rc=re:GetHandler()
	if rc and rc:IsAbleToDeck() then
		Duel.SetOperationInfo(
			0,CATEGORY_TODECK,rc,1,0,0
		)
	end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	if not rc then return end

	local neg=false

	-- Activation d'une Magie/Piège
	if re:IsHasType(EFFECT_TYPE_ACTIVATE) then
		neg=Duel.NegateActivation(ev)
	else
		-- Effet de monstre / effet déjà face recto
		neg=Duel.NegateEffect(ev)
	end

	if not neg then return end

	-- Pas de IsRelateToEffect ici :
	-- ça bloquait le renvoi dans ton core
	if rc:IsAbleToDeck() then
		Duel.SendtoDeck(
			rc,
			nil,
			SEQ_DECKSHUFFLE,
			REASON_EFFECT
		)
	end
end

-- =========================================
-- REMPLACEMENT DE DESTRUCTION
-- =========================================
function s.repfilter(c,tp)
	return c:IsControler(tp)
		and c:IsLocation(LOCATION_ONFIELD)
		and c:IsSetCard(0x6e7)
		and c:IsReason(REASON_EFFECT)
		and not c:IsReason(REASON_REPLACE)
end

function s.desreptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsAbleToRemove()
			and eg:IsExists(s.repfilter,1,nil,tp)
	end

	return Duel.SelectYesNo(
		tp,aux.Stringid(id,2)
	)
end

function s.desrepval(e,c)
	return s.repfilter(
		c,e:GetHandlerPlayer()
	)
end

-- =========================================
-- REMPLACEMENT DE BANNISSEMENT
-- =========================================
function s.rmfilter(c,tp)
	return c:IsControler(tp)
		and c:IsLocation(LOCATION_ONFIELD)
		and c:IsSetCard(0x6e7)
		and c:GetDestination()==LOCATION_REMOVED
		and c:IsReason(REASON_EFFECT)
		and not c:IsReason(REASON_REPLACE)
end

function s.rmreptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return bit.band(r,REASON_EFFECT)~=0
			and re
			and c:IsAbleToRemove()
			and eg:IsExists(s.rmfilter,1,nil,tp)
	end

	return Duel.SelectYesNo(
		tp,aux.Stringid(id,2)
	)
end

function s.rmrepval(e,c)
	return s.rmfilter(
		c,e:GetHandlerPlayer()
	)
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Remove(
		e:GetHandler(),
		POS_FACEUP,
		REASON_EFFECT+REASON_REPLACE
	)
end

-- =========================================
-- SI FUSION TRANSFORMAGE INVOQUÉE
-- PENDANT QUE CETTE CARTE EST BANNIE
-- =========================================
function s.fsfilter(c,tp)
	return c:IsControler(tp)
		and c:IsSetCard(0x6e7)
		and c:IsType(TYPE_FUSION)
		and c:IsSummonType(SUMMON_TYPE_FUSION)
end

function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(
		s.fsfilter,1,nil,tp
	)
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and c:IsSSetable()
	end
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsRelateToEffect(e)
		or Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then
		return
	end

	Duel.SSet(tp,c)
end
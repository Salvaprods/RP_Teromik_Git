-- Transformage - Hestiavagum, Armure De Titane
local s,id=GetID()

function s.initial_effect(c)
	-- "Transformage - Hestiaros" + 1 Fusion "Transformage"
	aux.AddFusionProcMix(
		c,false,true,
		aux.FilterBoolFunction(Card.IsFusionCode,252200000),
		s.ffilter
	)
	c:EnableReviveLimit()

	-- Si Invoquée par Fusion : détruire toutes les cartes adverses
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.descon)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)

	-- Si elle quitte votre Terrain par un effet adverse
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOEXTRA+CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_LEAVE_FIELD)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.drcon)
	e2:SetTarget(s.drtg)
	e2:SetOperation(s.drop)
	c:RegisterEffect(e2)
end

-- =========================================
-- MATÉRIAUX FUSION
-- =========================================
function s.ffilter(c)
	return c:IsSetCard(0x6e7)
		and c:IsType(TYPE_FUSION)
end

-- =========================================
-- EFFET 1
-- =========================================
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end

	-- Dès l'activation : impossible de déclarer une attaque ce tour
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ATTACK_ANNOUNCE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(1,0)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)

	local g=Duel.GetMatchingGroup(
		Card.IsDestructable,
		tp,
		0,
		LOCATION_ONFIELD,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_DESTROY,
		g,
		g:GetCount(),
		0,
		0
	)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(
		Card.IsDestructable,
		tp,
		0,
		LOCATION_ONFIELD,
		nil
	)

	if g:GetCount()>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end

-- =========================================
-- EFFET 2
-- QUITTE VOTRE TERRAIN PAR EFFET ADVERSE
-- =========================================
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	return c:IsPreviousControler(tp)
		and c:IsPreviousLocation(LOCATION_ONFIELD)
		and c:IsReason(REASON_EFFECT)
		and rp==1-tp
		and not c:IsLocation(LOCATION_EXTRA)
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsAbleToExtra()
			and Duel.IsPlayerCanDraw(tp,1)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOEXTRA,
		c,
		1,
		0,
		0
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_DRAW,
		nil,
		0,
		tp,
		1
	)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsRelateToEffect(e)
		or not c:IsAbleToExtra() then
		return
	end

	if Duel.SendtoDeck(
		c,
		nil,
		SEQ_DECKSHUFFLE,
		REASON_EFFECT
	)>0
		and c:IsLocation(LOCATION_EXTRA) then

		Duel.Draw(tp,1,REASON_EFFECT)
	end
end
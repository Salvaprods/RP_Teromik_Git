-- Souffrada - Âme Du Chasseur
local s,id=GetID()

function s.initial_effect(c)
	aux.EnablePendulumAttribute(c)

	-- ==========================================
	-- EFFETS PENDULE
	-- ==========================================

	-- Protection contre le ciblage adverse
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetRange(LOCATION_PZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.tgtg)
	e1:SetValue(aux.tgoval)
	c:RegisterEffect(e1)

	-- Annulation : détruit Souffrada en coût
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_NEGATE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_PZONE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.negcon)
	e2:SetCost(s.negcost)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)

	-- ==========================================
	-- EFFETS MONSTRE
	-- ==========================================

	-- L'adversaire ne peut pas répondre à vos Magies/Pièges Âme Du Chasseur
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetOperation(s.chainop)
	c:RegisterEffect(e3)

	-- Si ajoutée face recto à l'Extra Deck
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_MOVE)
	e4:SetCountLimit(1,id+100)
	e4:SetCondition(s.excon)
	e4:SetCost(s.excost)
	e4:SetTarget(s.extg)
	e4:SetOperation(s.exop)
	c:RegisterEffect(e4)

	-- Si Invoquée Spécialement : détruire toutes les M/P adverses
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,2))
	e5:SetCategory(CATEGORY_DESTROY)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e5:SetProperty(EFFECT_FLAG_DELAY)
	e5:SetCode(EVENT_SPSUMMON_SUCCESS)
	e5:SetCountLimit(1,id+200)
	e5:SetTarget(s.destg)
	e5:SetOperation(s.desop)
	c:RegisterEffect(e5)
end

-- ==========================================
-- FILTRE ARCHÉTYPE
-- ==========================================
function s.hunter_filter(c)
	return c:IsSetCard(0xc92)
end

-- ==========================================
-- PENDULE 1 : PROTECTION CIBLAGE
-- ==========================================
function s.tgtg(e,c)
	return s.hunter_filter(c)
end

-- ==========================================
-- PENDULE 2 : ANNULATION
-- ==========================================
function s.cfilter(c)
	return c:IsFaceup()
		and s.hunter_filter(c)
		and c:IsLevelAbove(7)
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
		and Duel.IsChainNegatable(ev)
		and Duel.IsExistingMatchingCard(
			s.cfilter,
			tp,
			LOCATION_MZONE,
			0,
			1,
			nil
		)
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsDestructable()
	end

	Duel.Destroy(
		c,
		REASON_COST
	)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return true
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_NEGATE,
		eg,
		1,
		0,
		0
	)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateEffect(ev)
end

-- ==========================================
-- MONSTRE 1 : BLOQUE LES RÉPONSES
-- ==========================================
function s.chainop(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()

	if re:IsHasType(EFFECT_TYPE_ACTIVATE)
		and rc
		and rc:IsSetCard(0xc92)
		and ep==tp then

		Duel.SetChainLimit(s.chainlm)
	end
end

function s.chainlm(e,rp,tp)
	return tp==rp
end

-- ==========================================
-- MONSTRE 2 : INVOCATION DEPUIS L'EXTRA
-- ==========================================
function s.excon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	return c:IsLocation(LOCATION_EXTRA)
		and c:IsFaceup()
		and not (
			c:IsPreviousLocation(LOCATION_EXTRA)
			and c:IsPreviousPosition(POS_FACEUP)
		)
end

function s.revfilter(c)
	return s.hunter_filter(c)
		and not c:IsPublic()
end

function s.excost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.revfilter,
			tp,
			LOCATION_HAND,
			0,
			1,
			nil
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)

	local g=Duel.SelectMatchingCard(
		tp,
		s.revfilter,
		tp,
		LOCATION_HAND,
		0,
		1,
		1,
		nil
	)

	Duel.ConfirmCards(1-tp,g)
	Duel.ShuffleHand(tp)
end

function s.extg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
			and c:IsCanBeSpecialSummoned(
				e,
				0,
				tp,
				false,
				false
			)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		c,
		1,
		tp,
		LOCATION_EXTRA
	)
end

function s.exop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if c:IsRelateToEffect(e)
		and c:IsLocation(LOCATION_EXTRA)
		and c:IsFaceup()
		and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0 then

		Duel.SpecialSummon(
			c,
			0,
			tp,
			tp,
			false,
			false,
			POS_FACEUP
		)
	end
end

-- ==========================================
-- MONSTRE 3 : DÉTRUIT TOUTES LES M/P ADVERSES
-- ==========================================
function s.stfilter(c)
	return c:IsType(TYPE_SPELL+TYPE_TRAP)
		and c:IsDestructable()
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(
		s.stfilter,
		tp,
		0,
		LOCATION_ONFIELD,
		nil
	)

	if chk==0 then
		return g:GetCount()>0
	end

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
		s.stfilter,
		tp,
		0,
		LOCATION_ONFIELD,
		nil
	)

	if g:GetCount()>0 then
		Duel.Destroy(
			g,
			REASON_EFFECT
		)
	end
end
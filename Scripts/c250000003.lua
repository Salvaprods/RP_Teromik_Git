-- Souffrada - Âme Du Chasseur
local s,id=GetID()

function s.initial_effect(c)
	aux.EnablePendulumAttribute(c)

	-- ==========================================
	-- EFFET PENDULE
	-- ==========================================

	-- Les monstres "Âme Du Chasseur" ne peuvent pas être ciblés
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetRange(LOCATION_PZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.tgtg)
	e1:SetValue(aux.tgoval)
	c:RegisterEffect(e1)

	-- ==========================================
	-- EFFETS MONSTRE
	-- ==========================================

	-- L'adversaire ne peut pas répondre à vos M/P "Âme Du Chasseur"
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetOperation(s.chainop)
	c:RegisterEffect(e2)

	-- Ajoutée face recto à l'Extra Deck -> révéler puis SS
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_LEAVE_FIELD)
	e3:SetCountLimit(1,id+100)
	e3:SetCondition(s.excon)
	e3:SetCost(s.excost)
	e3:SetTarget(s.extg)
	e3:SetOperation(s.exop)
	c:RegisterEffect(e3)

	-- Invoquée Spécialement -> détruire toutes les M/P adverses
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_DESTROY)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	e4:SetCountLimit(1,id+200)
	e4:SetTarget(s.destg)
	e4:SetOperation(s.desop)
	c:RegisterEffect(e4)
end

s.listed_series={0xc92}

-- ==========================================
-- FILTRE ARCHÉTYPE
-- ==========================================
function s.hunter_filter(c)
	return c:IsSetCard(0xc92)
end

-- ==========================================
-- PENDULE : PROTECTION CIBLAGE
-- ==========================================
function s.tgtg(e,c)
	return c:IsSetCard(0xc92)
end

-- ==========================================
-- MONSTRE 1 : BLOQUER LES RÉPONSES
-- ==========================================
function s.chainop(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()

	if ep==tp
		and re:IsHasType(EFFECT_TYPE_ACTIVATE)
		and rc
		and rc:IsSetCard(0xc92)
		and rc:IsType(TYPE_SPELL+TYPE_TRAP) then

		Duel.SetChainLimit(s.chainlm)
	end
end

function s.chainlm(e,rp,tp)
	return rp==tp
end

-- ==========================================
-- MONSTRE 2 : AJOUTÉE FACE RECTO À L'EXTRA
-- ==========================================
function s.excon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	return c:IsLocation(LOCATION_EXTRA)
		and c:IsFaceup()
		and c:IsPreviousLocation(LOCATION_ONFIELD)
end

function s.revfilter(c)
	return c:IsSetCard(0xc92)
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
		return Duel.GetLocationCountFromEx(
			tp,tp,nil,c
		)>0
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

	if not c:IsRelateToEffect(e)
		or not c:IsLocation(LOCATION_EXTRA)
		or not c:IsFaceup()
		or Duel.GetLocationCountFromEx(
			tp,tp,nil,c
		)<=0 then
		return
	end

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

-- ==========================================
-- MONSTRE 3 : DÉTRUIRE TOUTES LES M/P ADVERSES
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
		1-tp,
		LOCATION_ONFIELD
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
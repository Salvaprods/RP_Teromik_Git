-- Réincarnation Du Slime☺
local s,id=GetID()

local SET_SLIME=0xc2a

function s.initial_effect(c)
	-- Cibler 1 Slime☺ Niveau 6 ou moins dans le GY
	-- puis le SS en ignorant ses conditions d'Invocation
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Depuis le GY :
	-- bannir cette carte à la place de la destruction
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EFFECT_DESTROY_REPLACE)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetTarget(s.reptg)
	e2:SetValue(s.repval)
	e2:SetOperation(s.repop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_SLIME}

-- =========================================
-- EFFET 1 : REVIVE
-- =========================================
function s.spfilter(c,e,tp)
	return c:IsSetCard(SET_SLIME)
		and c:IsType(TYPE_MONSTER)
		and c:IsLevelBelow(6)
		and c:IsCanBeSpecialSummoned(
			e,
			0,
			tp,
			true,
			false
		)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_GRAVE)
			and s.spfilter(chkc,e,tp)
	end

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingTarget(
				s.spfilter,
				tp,
				LOCATION_GRAVE,
				0,
				1,
				nil,
				e,
				tp
			)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local g=Duel.SelectTarget(
		tp,
		s.spfilter,
		tp,
		LOCATION_GRAVE,
		0,
		1,
		1,
		nil,
		e,
		tp
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		g,
		1,
		tp,
		LOCATION_GRAVE
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if not tc
		or not tc:IsRelateToEffect(e)
		or Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return
	end

	Duel.SpecialSummon(
		tc,
		0,
		tp,
		tp,
		true,
		false,
		POS_FACEUP
	)
end

-- =========================================
-- EFFET 2 : REMPLACEMENT DE DESTRUCTION
-- =========================================
function s.repfilter(c,tp)
	return c:IsControler(tp)
		and c:IsLocation(LOCATION_ONFIELD)
		and c:IsSetCard(SET_SLIME)
		and c:IsType(TYPE_MONSTER)
		and c:IsReason(REASON_EFFECT)
		and not c:IsReason(REASON_REPLACE)
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsAbleToRemove()
			and eg:IsExists(
				s.repfilter,
				1,
				nil,
				tp
			)
	end

	return Duel.SelectYesNo(
		tp,
		aux.Stringid(id,1)
	)
end

function s.repval(e,c)
	return s.repfilter(
		c,
		e:GetHandlerPlayer()
	)
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Remove(
		e:GetHandler(),
		POS_FACEUP,
		REASON_EFFECT+REASON_REPLACE
	)
end
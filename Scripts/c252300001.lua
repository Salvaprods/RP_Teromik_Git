-- ♪DIABLORCHESTRE♪ - Skrim
local s,id=GetID()

function s.initial_effect(c)
	-- Si ajoutée à la main par un effet "DIABLORCHESTRE" : Special Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_TO_HAND)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Si Invoquée Normalement ou Spécialement : Set 1 M/P DIABLORCHESTRE
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id+100)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)

	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)

	-- Bannir depuis le GY ; regarder 1 carte au hasard dans la main adverse
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_GRAVE)
	e4:SetCountLimit(1,id+200)
	e4:SetCost(aux.bfgcost)
	e4:SetTarget(s.looktg)
	e4:SetOperation(s.lookop)
	c:RegisterEffect(e4)
end

-- =========================================
-- EFFET 1
-- =========================================
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return re
		and bit.band(r,REASON_EFFECT)~=0
		and re:GetHandler()
		and re:GetHandler():IsSetCard(0xd1f)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end

	Duel.SetOperationInfo(
		0,CATEGORY_SPECIAL_SUMMON,c,1,tp,LOCATION_HAND
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if c:IsRelateToEffect(e)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then

		Duel.SpecialSummon(
			c,0,tp,tp,false,false,POS_FACEUP
		)
	end
end

-- =========================================
-- EFFET 2
-- =========================================
function s.setfilter(c)
	return c:IsSetCard(0xd1f)
		and c:IsType(TYPE_SPELL+TYPE_TRAP)
		and c:IsSSetable()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingMatchingCard(
				s.setfilter,tp,LOCATION_DECK,0,1,nil
			)
	end
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)

	local g=Duel.SelectMatchingCard(
		tp,
		s.setfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil
	)

	local tc=g:GetFirst()

	if tc then
		Duel.SSet(tp,tc)
	end
end

-- =========================================
-- EFFET 3
-- =========================================
function s.looktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetFieldGroupCount(tp,0,LOCATION_HAND)>0
	end
end

function s.lookop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetFieldGroup(
		tp,
		0,
		LOCATION_HAND
	)

	if g:GetCount()==0 then
		return
	end

	-- Sélection aléatoire d'1 carte de la main adverse
	local sg=g:RandomSelect(tp,1)

	if sg:GetCount()>0 then
		Duel.ConfirmCards(tp,sg)
		Duel.ShuffleHand(1-tp)
	end
end
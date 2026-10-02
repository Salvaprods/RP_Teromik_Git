-- Kuriboh Le Pirate
local s,id=GetID()
local LINKURIBOH=41999284

function s.initial_effect(c)
	-- 2 monstres avec 300 ATK / 200 DEF
	c:EnableReviveLimit()
	aux.AddLinkProcedure(c,s.matfilter,2,2)

	-- Première destruction par effet chaque tour de chaque Kuriboh
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_GRANT)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.indtg)

	local e1a=Effect.CreateEffect(c)
	e1a:SetType(EFFECT_TYPE_SINGLE)
	e1a:SetCode(EFFECT_INDESTRUCTABLE_COUNT)
	e1a:SetCountLimit(1)
	e1a:SetValue(s.indval)

	e1:SetLabelObject(e1a)
	c:RegisterEffect(e1)

	-- Link Summon : revive 1 Kuriboh en Défense
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	-- Activation adverse : Sacrifier 1 monstre pointé ; détruire la carte
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+200)
	e3:SetCondition(s.descon)
	e3:SetCost(s.descost)
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)
end

s.listed_series={0xa4}
s.listed_names={LINKURIBOH}

-- =========================================
-- LINK
-- =========================================
function s.matfilter(c,lc,st,tp)
	return c:IsType(TYPE_MONSTER)
		and c:IsAttack(300)
		and c:IsDefense(200)
end

-- =========================================
-- KURIBOH
-- =========================================
function s.iskuriboh(c)
	return c:IsSetCard(0xa4)
		or c:IsCode(LINKURIBOH)
end

-- =========================================
-- PROTECTION
-- =========================================
function s.indtg(e,c)
	return c:IsFaceup()
		and s.iskuriboh(c)
end

function s.indval(e,re,r,rp)
	return bit.band(r,REASON_EFFECT)~=0
end

-- =========================================
-- LINK SUMMON -> REVIVE EN DÉFENSE
-- =========================================
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

function s.spfilter(c,e,tp)
	return s.iskuriboh(c)
		and c:IsType(TYPE_MONSTER)
		and not c:IsType(TYPE_LINK)
		and c:IsCanBeSpecialSummoned(
			e,0,tp,false,false,POS_FACEUP_DEFENSE
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
				e,tp
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
		e,tp
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
		false,
		false,
		POS_FACEUP_DEFENSE
	)
end

-- =========================================
-- QUICK : SACRIFIER MONSTRE POINTÉ
-- =========================================
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
end

function s.relfilter(c,tp)
	return c:IsControler(tp)
		and c:IsReleasable()
end

function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local g=c:GetLinkedGroup():Filter(
		s.relfilter,
		nil,
		tp
	)

	if chk==0 then
		return g:GetCount()>0
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)

	local sg=g:Select(tp,1,1,nil)

	Duel.Release(
		sg,
		REASON_COST
	)

	-- L'adversaire ne peut pas répondre
	Duel.SetChainLimit(s.chainlm)
end

function s.chainlm(e,rp,tp)
	return rp==tp
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return true
	end

	local rc=re:GetHandler()

	if rc then
		Duel.SetOperationInfo(
			0,
			CATEGORY_DESTROY,
			rc,
			1,
			0,
			rc:GetLocation()
		)
	end
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()

	if rc
		and rc:IsRelateToEffect(re)
		and rc:IsDestructable() then

		Duel.Destroy(
			rc,
			REASON_EFFECT
		)
	end
end
-- ♪DIABLORCHESTRE♪ - Metalskrim Mic Caesar
local s,id=GetID()

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- Bannie par effet d'un monstre DIABLORCHESTRE -> Ritual Summon + LP /2
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_REMOVE)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Main Phase Quick -> Ritual Summon depuis la main
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_HAND)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.ritcon)
	e2:SetTarget(s.rittg)
	e2:SetOperation(s.ritop)
	c:RegisterEffect(e2)

	-- Negate effet qui va invoquer
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+200)
	e3:SetCondition(s.negcon)
	e3:SetCost(s.negcost)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)

	-- M/P DIABLORCHESTRE indestructibles
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e4:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTargetRange(LOCATION_SZONE+LOCATION_FZONE,0)
	e4:SetTarget(s.stfilter)
	e4:SetValue(aux.indoval)
	c:RegisterEffect(e4)

	-- M/P DIABLORCHESTRE protégées du bannissement adverse
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD)
	e5:SetCode(EFFECT_IMMUNE_EFFECT)
	e5:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	e5:SetRange(LOCATION_MZONE)
	e5:SetTargetRange(LOCATION_SZONE+LOCATION_FZONE,0)
	e5:SetTarget(s.stfilter)
	e5:SetValue(s.rmimmune)
	c:RegisterEffect(e5)
end

s.listed_series={0xd1f}

-- =========================================
-- EFFET 1
-- =========================================
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	if not re or bit.band(r,REASON_EFFECT)==0 then
		return false
	end

	local rc=re:GetHandler()

	return rc
		and rc:IsType(TYPE_MONSTER)
		and rc:IsSetCard(0xd1f)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(
				e,SUMMON_TYPE_RITUAL,tp,false,true
			)
	end

	Duel.SetOperationInfo(
		0,CATEGORY_SPECIAL_SUMMON,c,1,tp,LOCATION_REMOVED
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsRelateToEffect(e)
		or Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return
	end

	if Duel.SpecialSummon(
		c,
		SUMMON_TYPE_RITUAL,
		tp,
		tp,
		false,
		true,
		POS_FACEUP
	)>0 then
		c:CompleteProcedure()

		-- Divisez vos LP par deux
		Duel.SetLP(
			tp,
			math.ceil(Duel.GetLP(tp)/2)
		)
	end
end

-- =========================================
-- EFFET 2 : RITUAL QUICK
-- =========================================
function s.ritcon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()

	return ph==PHASE_MAIN1
		or ph==PHASE_MAIN2
end

function s.matfilter(c,self)
	return c~=self
		and c:IsSetCard(0xd1f)
		and c:IsType(TYPE_MONSTER)
		and c:GetLevel()>0
		and (c:IsLocation(LOCATION_HAND) or c:IsFaceup())
		and c:IsAbleToRemove()
end

function s.getmat(tp,c)
	return Duel.GetMatchingGroup(
		s.matfilter,
		tp,
		LOCATION_HAND+LOCATION_MZONE,
		0,
		c,
		c
	)
end

function s.ritcheck(g,lv,needfield)
	local sum=0
	local hasfield=false
	local tc=g:GetFirst()

	while tc do
		sum=sum+tc:GetLevel()

		if tc:IsLocation(LOCATION_MZONE) then
			hasfield=true
		end

		tc=g:GetNext()
	end

	return sum>=lv
		and (not needfield or hasfield)
end

function s.rittg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local mg=s.getmat(tp,c)
	local lv=c:GetLevel()
	local needfield=Duel.GetLocationCount(tp,LOCATION_MZONE)<=0

	if chk==0 then
		return c:IsLocation(LOCATION_HAND)
			and c:IsCanBeSpecialSummoned(
				e,SUMMON_TYPE_RITUAL,tp,false,true
			)
			and mg:CheckSubGroup(
				s.ritcheck,
				1,
				mg:GetCount(),
				lv,
				needfield
			)
	end

	Duel.SetOperationInfo(
		0,CATEGORY_SPECIAL_SUMMON,c,1,tp,LOCATION_HAND
	)
end

function s.ritop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsRelateToEffect(e)
		or not c:IsLocation(LOCATION_HAND) then
		return
	end

	local mg=s.getmat(tp,c)
	local lv=c:GetLevel()
	local needfield=Duel.GetLocationCount(tp,LOCATION_MZONE)<=0

	if not mg:CheckSubGroup(
		s.ritcheck,
		1,
		mg:GetCount(),
		lv,
		needfield
	) then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)

	local mat=mg:SelectSubGroup(
		tp,
		s.ritcheck,
		false,
		1,
		mg:GetCount(),
		lv,
		needfield
	)

	if not mat or mat:GetCount()==0 then
		return
	end

	c:SetMaterial(mat)

	if Duel.Remove(
		mat,
		POS_FACEUP,
		REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL
	)~=mat:GetCount() then
		return
	end

	-- Les matériaux Terrain sont déjà partis,
	-- donc une zone peut maintenant être libre.
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return
	end

	Duel.BreakEffect()

	if Duel.SpecialSummon(
		c,
		SUMMON_TYPE_RITUAL,
		tp,
		tp,
		false,
		true,
		POS_FACEUP
	)>0 then
		c:CompleteProcedure()
	end
end

-- =========================================
-- EFFET 3 : NEGATE
-- =========================================
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
		and re:IsHasCategory(CATEGORY_SPECIAL_SUMMON)
		and Duel.IsChainNegatable(ev)
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsAbleToRemoveAsCost()
	end

	Duel.Remove(
		c,
		POS_FACEUP,
		REASON_COST
	)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return true
	end

	Duel.SetOperationInfo(
		0,CATEGORY_NEGATE,eg,1,0,0
	)

	local rc=re:GetHandler()

	if rc and rc:IsDestructable() then
		Duel.SetOperationInfo(
			0,CATEGORY_DESTROY,rc,1,0,0
		)
	end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	local neg=false

	if re:IsHasType(EFFECT_TYPE_ACTIVATE) then
		neg=Duel.NegateActivation(ev)
	else
		neg=Duel.NegateEffect(ev)
	end

	if neg
		and rc
		and rc:IsDestructable() then

		Duel.Destroy(
			rc,
			REASON_EFFECT
		)
	end
end

-- =========================================
-- PROTECTION M/P
-- =========================================
function s.stfilter(e,c)
	return c:IsSetCard(0xd1f)
		and c:IsType(TYPE_SPELL+TYPE_TRAP)
end

function s.rmimmune(e,re)
	return re:GetOwnerPlayer()~=e:GetHandlerPlayer()
		and re:IsHasCategory(CATEGORY_REMOVE)
end
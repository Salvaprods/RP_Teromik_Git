-- Transformage - Hestitanium Le Roi
local s,id=GetID()

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- Procédure Fusion custom
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_FUSION_MATERIAL)
	e0:SetCondition(s.fcondition)
	e0:SetOperation(s.foperation)
	c:RegisterEffect(e0)

	local e00=Effect.CreateEffect(c)
	e00:SetType(EFFECT_TYPE_SINGLE)
	e00:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e00:SetCode(EFFECT_SPSUMMON_CONDITION)
	e00:SetValue(aux.fuslimit)
	c:RegisterEffect(e00)

	-- Quick Fusion durant la Main Phase
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.fscon)
	e1:SetTarget(s.fstg)
	e1:SetOperation(s.fsop)
	c:RegisterEffect(e1)

	-- Negate
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_NEGATE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.negcon)
	e2:SetCost(s.negcost)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)
end

-- =========================================
-- MATÉRIAUX FUSION
-- Hestiaros + 2 non-FEU d'Attributs différents
-- =========================================
function s.hestfilter(c,fc)
	return c:IsFusionCode(252200000)
		or c:CheckFusionSubstitute(fc)
end

function s.otherfilter(c)
	return c:IsType(TYPE_MONSTER)
		and not c:IsAttribute(ATTRIBUTE_FIRE)
end

function s.ffilter(c,fc)
	return c:IsCanBeFusionMaterial(fc)
end

function s.fcheck(sg,fc,tp,gc,chkf)
	if sg:GetCount()~=3 then return false end
	if gc and not sg:IsContains(gc) then return false end

	if chkf~=PLAYER_NONE
		and Duel.GetLocationCountFromEx(tp,tp,sg,fc)<=0 then
		return false
	end

	if aux.FCheckAdditional
		and not aux.FCheckAdditional(tp,sg,fc) then
		return false
	end

	-- Cherche lequel des 3 est Hestiaros
	local tc=sg:GetFirst()
	while tc do
		if s.hestfilter(tc,fc) then
			local g=sg:Clone()
			g:RemoveCard(tc)

			if g:GetCount()==2
				and g:FilterCount(s.otherfilter,nil)==2
				and g:GetClassCount(Card.GetAttribute)==2 then
				return true
			end
		end
		tc=sg:GetNext()
	end

	return false
end

function s.fcondition(e,g,gc,chkf)
	if g==nil then return true end

	local c=e:GetHandler()
	local tp=c:GetControler()
	local mg=g:Filter(s.ffilter,nil,c)

	if gc and not mg:IsContains(gc) then
		return false
	end

	return mg:CheckSubGroup(
		s.fcheck,
		3,
		3,
		c,
		tp,
		gc,
		chkf
	)
end

function s.foperation(e,tp,eg,ep,ev,re,r,rp,gc,chkf)
	local c=e:GetHandler()
	local mg=eg:Filter(s.ffilter,nil,c)

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)

	local g=mg:SelectSubGroup(
		tp,
		s.fcheck,
		false,
		3,
		3,
		c,
		tp,
		gc,
		chkf
	)

	Duel.SetFusionMaterial(g)
end

-- =========================================
-- QUICK FUSION
-- =========================================
function s.fscon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return ph==PHASE_MAIN1 or ph==PHASE_MAIN2
end

function s.fsfilter(c,e,tp,mg,chkf)
	return c:IsSetCard(0x6e7)
		and c:IsType(TYPE_FUSION)
		and c:IsCanBeSpecialSummoned(
			e,SUMMON_TYPE_FUSION,tp,false,false
		)
		and c:CheckFusionMaterial(mg,nil,chkf)
end

function s.fstg(e,tp,eg,ep,ev,re,r,rp,chk)
	local chkf=tp
	local mg=Duel.GetFusionMaterial(tp)

	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.fsfilter,
			tp,
			LOCATION_EXTRA,
			0,
			1,
			nil,
			e,tp,mg,chkf
		)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,
		1,
		tp,
		LOCATION_EXTRA
	)
end

function s.fsop(e,tp,eg,ep,ev,re,r,rp)
	local chkf=tp
	local mg=Duel.GetFusionMaterial(tp)

	local fg=Duel.GetMatchingGroup(
		s.fsfilter,
		tp,
		LOCATION_EXTRA,
		0,
		nil,
		e,tp,mg,chkf
	)

	if fg:GetCount()==0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local fc=fg:Select(tp,1,1,nil):GetFirst()
	if not fc then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)

	local mat=Duel.SelectFusionMaterial(
		tp,
		fc,
		mg,
		nil,
		chkf
	)

	if not mat or mat:GetCount()==0 then return end

	fc:SetMaterial(mat)

	Duel.SendtoGrave(
		mat,
		REASON_EFFECT+REASON_MATERIAL+REASON_FUSION
	)

	Duel.BreakEffect()

	if Duel.SpecialSummon(
		fc,
		SUMMON_TYPE_FUSION,
		tp,tp,
		false,false,
		POS_FACEUP
	)>0 then
		fc:CompleteProcedure()
	end
end

-- =========================================
-- NEGATE
-- =========================================
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
		and bit.band(
			re:GetActivateLocation(),
			LOCATION_ONFIELD
		)~=0
		and Duel.IsChainDisablable(ev)
end

function s.relfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(0x6e7)
		and c:IsReleasable()
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.relfilter,
			tp,
			LOCATION_MZONE,
			0,
			1,
			c
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)

	local g=Duel.SelectMatchingCard(
		tp,
		s.relfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		1,
		c
	)

	Duel.Release(g,REASON_COST)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
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
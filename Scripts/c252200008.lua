-- Transformage - Paradis Des Mages
local s,id=GetID()

function s.initial_effect(c)
	-- Activation normale de la Magie Continue
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-- Vous ne pouvez contrôler qu'1
	c:SetUniqueOnField(1,0,id)

	-- Protection de ciblage
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetRange(LOCATION_SZONE)
	e1:SetTargetRange(LOCATION_ONFIELD,0)
	e1:SetCondition(s.tgcon)
	e1:SetTarget(s.tgtg)
	e1:SetValue(aux.tgoval)
	c:RegisterEffect(e1)

	-- Une fois par tour, si un ou plusieurs "Transformage" sont Invoqués Spécialement
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1)
	e2:SetCondition(s.fuscon)
	e2:SetTarget(s.fustg)
	e2:SetOperation(s.fusop)
	c:RegisterEffect(e2)
end

-- ==========================================
-- PROTECTION DE CIBLAGE
-- ==========================================
function s.fusmon(c)
	return c:IsFaceup()
		and c:IsSetCard(0x6e7)
		and c:IsType(TYPE_FUSION)
end

function s.tgcon(e)
	local tp=e:GetHandlerPlayer()
	return Duel.IsExistingMatchingCard(
		s.fusmon,tp,LOCATION_MZONE,0,1,nil
	)
end

function s.tgtg(e,c)
	return not (
		c:IsFaceup()
		and c:IsSetCard(0x6e7)
		and c:IsType(TYPE_FUSION)
	)
end

-- ==========================================
-- DÉCLENCHEMENT DE LA FUSION
-- ==========================================
function s.spfilter(c,tp)
	return c:IsControler(tp)
		and c:IsSetCard(0x6e7)
		and c:IsType(TYPE_MONSTER)
end

function s.fuscon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(
		s.spfilter,
		1,
		nil,
		tp
	)
end

-- Main / Terrain / Cimetière / bannis face recto
function s.matfilter(c)
	return c:IsType(TYPE_MONSTER)
		and (
			not c:IsLocation(LOCATION_REMOVED)
			or c:IsFaceup()
		)
end

function s.fusfilter(c,e,tp,mg,chkf)
	return c:IsSetCard(0x6e7)
		and c:IsType(TYPE_FUSION)
		and c:IsCanBeSpecialSummoned(
			e,
			SUMMON_TYPE_FUSION,
			tp,
			false,
			false
		)
		and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
		and c:CheckFusionMaterial(mg,nil,chkf)
end

function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	local chkf=tp+0x200

	local mg=Duel.GetMatchingGroup(
		s.matfilter,
		tp,
		LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE+LOCATION_REMOVED,
		0,
		nil
	)

	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.fusfilter,
			tp,
			LOCATION_EXTRA,
			0,
			1,
			nil,
			e,
			tp,
			mg,
			chkf
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

-- ==========================================
-- FUSION EN MÉLANGEANT LES MATÉRIELS
-- ==========================================
function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	local chkf=tp+0x200

	local mg=Duel.GetMatchingGroup(
		s.matfilter,
		tp,
		LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE+LOCATION_REMOVED,
		0,
		nil
	)

	local fg=Duel.GetMatchingGroup(
		s.fusfilter,
		tp,
		LOCATION_EXTRA,
		0,
		nil,
		e,
		tp,
		mg,
		chkf
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

	if Duel.SendtoDeck(
		mat,
		nil,
		SEQ_DECKSHUFFLE,
		REASON_EFFECT+REASON_MATERIAL+REASON_FUSION
	)~=mat:GetCount() then
		return
	end

	Duel.BreakEffect()

	if Duel.SpecialSummon(
		fc,
		SUMMON_TYPE_FUSION,
		tp,
		tp,
		false,
		false,
		POS_FACEUP
	)>0 then
		fc:CompleteProcedure()
	end
end
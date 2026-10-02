-- ♪DIABLORCHESTRE♪ - Big Mic
local s,id=GetID()

function s.initial_effect(c)
	-- Fusion : 2 monstres "DIABLORCHESTRE"
	aux.AddFusionProcFunRep(
		c,
		aux.FilterBoolFunction(Card.IsSetCard,0xd1f),
		2,
		true
	)
	c:EnableReviveLimit()

	-- Si Invoquée Spécialement : revive Niveau 3
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Main Phase Quick : Fusion en bannissant main/Terrain/GY
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON+CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.fuscon)
	e2:SetTarget(s.fustg)
	e2:SetOperation(s.fusop)
	c:RegisterEffect(e2)
end

-- =========================================
-- EFFET 1
-- =========================================
function s.spfilter(c,e,tp)
	return c:IsSetCard(0xd1f)
		and c:IsType(TYPE_MONSTER)
		and c:IsLevel(3)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED)
			and s.spfilter(chkc,e,tp)
	end

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingTarget(
				s.spfilter,tp,
				LOCATION_GRAVE+LOCATION_REMOVED,
				0,1,nil,e,tp
			)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(
		tp,s.spfilter,tp,
		LOCATION_GRAVE+LOCATION_REMOVED,
		0,1,1,nil,e,tp
	)
	Duel.SetOperationInfo(
		0,CATEGORY_SPECIAL_SUMMON,g,1,tp,
		LOCATION_GRAVE+LOCATION_REMOVED
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if tc
		and tc:IsRelateToEffect(e)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		Duel.SpecialSummon(
			tc,0,tp,tp,false,false,POS_FACEUP
		)
	end
end

-- =========================================
-- EFFET 2 : QUICK FUSION
-- =========================================
function s.fuscon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return ph==PHASE_MAIN1 or ph==PHASE_MAIN2
end

-- Main + Terrain + GY
function s.getmat(tp)
	local mg=Duel.GetFusionMaterial(tp)

	local gg=Duel.GetMatchingGroup(
		Card.IsType,
		tp,
		LOCATION_GRAVE,
		0,
		nil,
		TYPE_MONSTER
	)

	mg:Merge(gg)
	return mg
end

function s.fusfilter(c,e,tp,mg,chkf)
	return c:IsSetCard(0xd1f)
		and c:IsType(TYPE_FUSION)
		and c:IsCanBeSpecialSummoned(
			e,SUMMON_TYPE_FUSION,tp,false,false
		)
		and c:CheckFusionMaterial(
			mg,nil,chkf
		)
end

function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	local chkf=tp+0x200
	local mg=s.getmat(tp)

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
		0,CATEGORY_SPECIAL_SUMMON,
		nil,1,tp,LOCATION_EXTRA
	)
end

function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	local chkf=tp+0x200
	local mg=s.getmat(tp)

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

	-- On bannit D'ABORD les Matériels.
	-- Si le Terrain était plein, ça peut libérer une zone.
	if Duel.Remove(
		mat,
		POS_FACEUP,
		REASON_EFFECT+REASON_MATERIAL+REASON_FUSION
	)~=mat:GetCount() then
		return
	end

	-- Maintenant seulement on vérifie la place dans l'Extra
	if Duel.GetLocationCountFromEx(
		tp,tp,nil,fc
	)<=0 then
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
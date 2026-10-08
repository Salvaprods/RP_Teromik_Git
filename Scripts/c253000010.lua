-- Fusion Slime☺
local s,id=GetID()

local SET_SLIME=0xc2a
local TOKEN_SLIME=253000007

function s.initial_effect(c)
	-- Activation -> Fusion Summon Slime☺
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.fustg)
	e1:SetOperation(s.fusop)
	c:RegisterEffect(e1)
end

s.listed_series={SET_SLIME}
s.listed_names={TOKEN_SLIME}

-- =========================================
-- JETON SLIME☺
-- =========================================
function s.tokenfilter(c)
	return c:IsFaceup()
		and c:IsCode(TOKEN_SLIME)
end

-- Seul le joueur qui active Fusion Slime☺
-- peut répondre si un Jeton Slime☺ est contrôlé
function s.chainlm(e,rp,tp)
	return rp==tp
end

-- =========================================
-- MONSTRE FUSION SLIME☺
-- =========================================
function s.fusfilter(c,e,tp,mg,chkf)
	return c:IsSetCard(SET_SLIME)
		and c:IsType(TYPE_FUSION)
		and c:IsCanBeSpecialSummoned(
			e,
			SUMMON_TYPE_FUSION,
			tp,
			false,
			false
		)
		and c:CheckFusionMaterial(
			mg,
			nil,
			chkf
		)
end

-- =========================================
-- TARGET
-- =========================================
function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	local chkf=tp+0x200

	-- Main + Terrain
	local mg=Duel.GetFusionMaterial(tp)

	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.fusfilter,
			tp,
			LOCATION_EXTRA,
			0,
			1,
			nil,
			e,tp,mg,chkf
		)
	end

	-- Si on contrôle un Jeton Slime☺,
	-- l'adversaire ne peut pas répondre
	if Duel.IsExistingMatchingCard(
		s.tokenfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		nil
	) then
		Duel.SetChainLimit(s.chainlm)
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

-- =========================================
-- FUSION SUMMON
-- =========================================
function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	local chkf=tp+0x200
	local mg=Duel.GetFusionMaterial(tp)

	local fg=Duel.GetMatchingGroup(
		s.fusfilter,
		tp,
		LOCATION_EXTRA,
		0,
		nil,
		e,tp,mg,chkf
	)

	if fg:GetCount()==0 then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local fc=fg:Select(
		tp,
		1,
		1,
		nil
	):GetFirst()

	if not fc then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)

	local mat=Duel.SelectFusionMaterial(
		tp,
		fc,
		mg,
		nil,
		chkf
	)

	if not mat
		or mat:GetCount()==0 then
		return
	end

	fc:SetMaterial(mat)

	-- Envoyer les Matériels Main/Terrain
	Duel.SendtoGrave(
		mat,
		REASON_EFFECT+
		REASON_MATERIAL+
		REASON_FUSION
	)

	-- Check de zone APRÈS le départ des Matériels
	if Duel.GetLocationCountFromEx(
		tp,
		tp,
		nil,
		fc
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
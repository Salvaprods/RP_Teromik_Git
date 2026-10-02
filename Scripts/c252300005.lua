-- ♪DIABLORCHESTRE♪ - Fusion Symphonique
local s,id=GetID()

function s.initial_effect(c)
	-- Fusion en mélangeant les Matériels
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.fustg)
	e1:SetOperation(s.fusop)
	c:RegisterEffect(e1)

	-- GY : bannir ; placer 1 Piège Continu DIABLORCHESTRE face recto
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.pltg)
	e2:SetOperation(s.plop)
	c:RegisterEffect(e2)
end

-- =========================================
-- EFFET 1 : FUSION
-- =========================================
function s.matfilter(c)
	return c:IsType(TYPE_MONSTER)
		and (not c:IsLocation(LOCATION_REMOVED) or c:IsFaceup())
end

function s.getmat(tp)
	return Duel.GetMatchingGroup(
		s.matfilter,
		tp,
		LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE+LOCATION_REMOVED,
		0,
		nil
	)
end

function s.fusfilter(c,e,tp,mg,chkf)
	return c:IsSetCard(0xd1f)
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
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,
		1,
		tp,
		LOCATION_EXTRA
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

	-- Mélange d'abord les Matériels dans le Deck
	if Duel.SendtoDeck(
		mat,
		nil,
		SEQ_DECKSHUFFLE,
		REASON_EFFECT+REASON_MATERIAL+REASON_FUSION
	)~=mat:GetCount() then
		return
	end

	-- Vérifie la place APRÈS le départ des Matériels
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

-- =========================================
-- EFFET 2
-- PLACER UNIQUEMENT UN PIÈGE CONTINU
-- DIABLORCHESTRE DEPUIS LE DECK
-- =========================================
function s.trapfilter(c)
	return c:IsSetCard(0xd1f)
		and c:IsType(TYPE_TRAP)
		and c:IsType(TYPE_CONTINUOUS)
end

function s.pltg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingMatchingCard(
				s.trapfilter,
				tp,
				LOCATION_DECK,
				0,
				1,
				nil
			)
	end
end

function s.plop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)

	local g=Duel.SelectMatchingCard(
		tp,
		s.trapfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil
	)

	local tc=g:GetFirst()

	if not tc then
		return
	end

	Duel.MoveToField(
		tc,
		tp,
		tp,
		LOCATION_SZONE,
		POS_FACEUP,
		true
	)
end
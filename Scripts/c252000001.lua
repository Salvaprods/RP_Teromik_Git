-- Dragonirène Moisellede
local s,id=GetID()
local sid=120000002

function s.initial_effect(c)
	-- 2 monstres "Dragonirène" + 1 Dragon Niveau 5+
	aux.AddFusionProcFunFun(
		c,
		s.ffilter,
		aux.FilterBoolFunction(Card.IsFusionSetCard,0x133),
		2,
		false,
		true
	)
	c:EnableReviveLimit()

	-- Si Invoquée par Fusion : choisissez 1 effet
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(sid,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.efcon)
	e1:SetTarget(s.eftg)
	e1:SetOperation(s.efop)
	c:RegisterEffect(e1)

	-- Lorsque l'adversaire active une carte ou un effet
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(sid,2))
	e2:SetCategory(
		CATEGORY_NEGATE+
		CATEGORY_REMOVE+
		CATEGORY_TOEXTRA+
		CATEGORY_SPECIAL_SUMMON
	)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.negcon)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)
end

-- =========================================================
-- MATÉRIEL : DRAGON NIVEAU 5+
-- =========================================================
function s.ffilter(c)
	return c:IsRace(RACE_DRAGON)
		and c:IsLevelAbove(5)
end

-- =========================================================
-- EFFET 1 : INVOQUÉE PAR FUSION
-- =========================================================
function s.efcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

-- Matériels depuis :
-- Main / Terrain / Cimetière / Bannissement
function s.fmatfilter(c,e)
	return c:IsType(TYPE_MONSTER)
		and c:IsAbleToDeck()
		and (not c:IsLocation(LOCATION_REMOVED) or c:IsFaceup())
		and not c:IsImmuneToEffect(e)
end

function s.fusfilter(c,e,tp,mg,chkf)
	return c:IsSetCard(0x133)
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

function s.canfusion(e,tp)
	local chkf=tp+0x200

	local mg=Duel.GetMatchingGroup(
		s.fmatfilter,
		tp,
		LOCATION_HAND+
		LOCATION_MZONE+
		LOCATION_GRAVE+
		LOCATION_REMOVED,
		0,
		nil,
		e
	)

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

-- =========================================================
-- DRAGONIRÈNE DU GY / BANNISSEMENT
-- =========================================================
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x133)
		and (not c:IsLocation(LOCATION_REMOVED) or c:IsFaceup())
		and c:IsCanBeSpecialSummoned(
			e,
			0,
			tp,
			false,
			false,
			POS_FACEUP
		)
end

function s.canspecial(e,tp)
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(
			s.spfilter,
			tp,
			LOCATION_GRAVE+LOCATION_REMOVED,
			0,
			1,
			nil,
			e,tp
		)
end

-- =========================================================
-- CHOIX DE L'EFFET À L'INVOCATION FUSION
-- =========================================================
function s.eftg(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1=s.canfusion(e,tp)
	local b2=s.canspecial(e,tp)

	if chk==0 then
		return b1 or b2
	end

	local op

	if b1 and b2 then
		op=Duel.SelectOption(
			tp,
			aux.Stringid(sid,0),
			aux.Stringid(sid,1)
		)
	elseif b1 then
		op=0
	else
		op=1
	end

	e:SetLabel(op)

	if op==0 then
		Duel.SetOperationInfo(
			0,
			CATEGORY_SPECIAL_SUMMON,
			nil,
			1,
			tp,
			LOCATION_EXTRA
		)
	else
		Duel.SetOperationInfo(
			0,
			CATEGORY_SPECIAL_SUMMON,
			nil,
			1,
			tp,
			LOCATION_GRAVE+LOCATION_REMOVED
		)
	end
end

-- =========================================================
-- RÉSOLUTION EFFET 1
-- =========================================================
function s.efop(e,tp,eg,ep,ev,re,r,rp)

	-- OPTION 1 : FUSION
	if e:GetLabel()==0 then
		local chkf=tp+0x200

		local mg=Duel.GetMatchingGroup(
			s.fmatfilter,
			tp,
			LOCATION_HAND+
			LOCATION_MZONE+
			LOCATION_GRAVE+
			LOCATION_REMOVED,
			0,
			nil,
			e
		)

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

		local fc=fg:Select(tp,1,1,nil):GetFirst()

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

		if not mat or mat:GetCount()==0 then
			return
		end

		fc:SetMaterial(mat)

		local ct=mat:GetCount()

		if Duel.SendtoDeck(
			mat,
			nil,
			SEQ_DECKSHUFFLE,
			REASON_EFFECT+
			REASON_MATERIAL+
			REASON_FUSION
		)~=ct then
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

	-- OPTION 2 : SPECIAL SUMMON
	else
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
			return
		end

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

		local g=Duel.SelectMatchingCard(
			tp,
			s.spfilter,
			tp,
			LOCATION_GRAVE+LOCATION_REMOVED,
			0,
			1,
			1,
			nil,
			e,tp
		)

		if g:GetCount()>0 then
			Duel.SpecialSummon(
				g,
				0,
				tp,
				tp,
				false,
				false,
				POS_FACEUP
			)
		end
	end
end

-- =========================================================
-- EFFET 2 : NEGATE
-- =========================================================

-- Dès que l'adversaire active une carte ou un effet
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED)
		and ep==1-tp
		and Duel.IsChainNegatable(ev)
end

-- =========================================================
-- CAMÉRISTE DRAGONIRÈNE
-- ID : 48658295
--
-- IMPORTANT :
-- On ne fait PAS IsCanBeSpecialSummoned(false,false)
-- car cette carte possède sa propre condition d'invocation.
-- =========================================================
function s.camfilter(c,tp,ec)
	return c:IsCode(48658295)
		and Duel.GetLocationCountFromEx(
			tp,
			tp,
			ec,
			c
		)>0
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsAbleToExtra()
			and Duel.IsExistingMatchingCard(
				s.camfilter,
				tp,
				LOCATION_EXTRA,
				0,
				1,
				nil,
				tp,
				c
			)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_NEGATE,
		eg,
		1,
		0,
		0
	)

	local rc=re:GetHandler()

	if rc and rc:IsAbleToRemove() then
		Duel.SetOperationInfo(
			0,
			CATEGORY_REMOVE,
			rc,
			1,
			1-tp,
			rc:GetLocation()
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

-- =========================================================
-- RÉSOLUTION NEGATE
-- =========================================================
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=re:GetHandler()

	-- 1) Annule l'effet adverse
	if not Duel.NegateEffect(ev) then
		return
	end

	-- 2) Bannit la carte
	if not rc
		or not rc:IsRelateToEffect(re)
		or not rc:IsAbleToRemove() then
		return
	end

	if Duel.Remove(
		rc,
		POS_FACEUP,
		REASON_EFFECT
	)==0 then
		return
	end

	-- 3) Renvoie Moisellede dans l'Extra Deck
	if not c:IsRelateToEffect(e)
		or not c:IsAbleToExtra() then
		return
	end

	Duel.BreakEffect()

	if Duel.SendtoDeck(
		c,
		nil,
		SEQ_DECKSHUFFLE,
		REASON_EFFECT
	)==0 then
		return
	end

	if not c:IsLocation(LOCATION_EXTRA) then
		return
	end

	-- 4) Invoque 48658295 depuis l'Extra Deck
	local g=Duel.GetMatchingGroup(
		s.camfilter,
		tp,
		LOCATION_EXTRA,
		0,
		nil,
		tp,
		nil
	)

	if g:GetCount()==0 then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local sg=g:Select(tp,1,1,nil)
	local tc=sg:GetFirst()

	if tc then
		-- nocheck=true :
		-- ignore sa procédure normale d'Invocation depuis l'Extra
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
end
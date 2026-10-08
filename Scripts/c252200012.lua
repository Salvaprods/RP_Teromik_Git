-- Transformage - Diliagus
local s,id=GetID()

function s.initial_effect(c)
	-- Main Phase : révéler cette carte puis Fusion Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.fuscon)
	e1:SetCost(s.fuscost)
	e1:SetTarget(s.fustg)
	e1:SetOperation(s.fusop)
	c:RegisterEffect(e1)

	-- Main Phase : mélanger Diliagus dans le Deck
	-- puis prendre 1 autre Transformage du Deck
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_HAND)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.thcon)
	e2:SetCost(s.thcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

s.listed_series={0x6e7}

-- =========================================
-- EFFET 1 : FUSION
-- =========================================
function s.fuscon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return Duel.GetTurnPlayer()==tp
		and (ph==PHASE_MAIN1 or ph==PHASE_MAIN2)
end

function s.fuscost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsLocation(LOCATION_HAND)
	end

	Duel.ConfirmCards(1-tp,c)
end

function s.fusfilter(fc,e,tp,mg,gc,chkf)
	return fc:IsSetCard(0x6e7)
		and fc:IsType(TYPE_FUSION)
		and fc:IsCanBeSpecialSummoned(
			e,SUMMON_TYPE_FUSION,tp,false,false
		)
		and fc:CheckFusionMaterial(
			mg,
			gc,
			chkf
		)
end

function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local chkf=tp+0x200

	-- Main + Terrain uniquement
	local mg=Duel.GetFusionMaterial(tp)

	if chk==0 then
		return c:IsLocation(LOCATION_HAND)
			and Duel.IsExistingMatchingCard(
				s.fusfilter,
				tp,
				LOCATION_EXTRA,
				0,
				1,
				nil,
				e,tp,mg,c,chkf
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
	local c=e:GetHandler()

	if not c:IsRelateToEffect(e)
		or not c:IsLocation(LOCATION_HAND) then
		return
	end

	local chkf=tp+0x200
	local mg=Duel.GetFusionMaterial(tp)

	local fg=Duel.GetMatchingGroup(
		s.fusfilter,
		tp,
		LOCATION_EXTRA,
		0,
		nil,
		e,tp,mg,c,chkf
	)

	if fg:GetCount()==0 then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local fc=fg:Select(tp,1,1,nil):GetFirst()
	if not fc then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)

	-- Diliagus est obligatoire
	local mat=Duel.SelectFusionMaterial(
		tp,
		fc,
		mg,
		c,
		chkf
	)

	if not mat or mat:GetCount()==0 then
		return
	end

	fc:SetMaterial(mat)

	Duel.SendtoGrave(
		mat,
		REASON_EFFECT+
		REASON_MATERIAL+
		REASON_FUSION
	)

	-- Vérification après départ des Matériels
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

-- =========================================
-- EFFET 2 : SHUFFLE -> AJOUTER / SS
-- =========================================
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()

	return Duel.GetTurnPlayer()==tp
		and (ph==PHASE_MAIN1 or ph==PHASE_MAIN2)
end

function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsAbleToDeckAsCost()
	end

	Duel.SendtoDeck(
		c,
		nil,
		SEQ_DECKSHUFFLE,
		REASON_COST
	)
end

function s.thfilter(c,e,tp)
	return c:IsSetCard(0x6e7)
		and c:IsType(TYPE_MONSTER)
		and not c:IsCode(id)
		and (
			c:IsAbleToHand()
			or (
				Duel.GetLocationCount(tp,LOCATION_MZONE)>0
				and c:IsCanBeSpecialSummoned(
					e,0,tp,false,false
				)
			)
		)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.thfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil,
			e,tp
		)
	end
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_ATOHAND
	)

	local g=Duel.SelectMatchingCard(
		tp,
		s.thfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil,
		e,tp
	)

	local tc=g:GetFirst()
	if not tc then return end

	local b1=tc:IsAbleToHand()

	local b2=Duel.GetLocationCount(
		tp,
		LOCATION_MZONE
	)>0
		and tc:IsCanBeSpecialSummoned(
			e,0,tp,false,false
		)

	local op=0

	if b1 and b2 then
		op=Duel.SelectOption(
			tp,
			aux.Stringid(id,2),
			aux.Stringid(id,3)
		)
	elseif b2 then
		op=1
	end

	if op==0 then
		if Duel.SendtoHand(
			tc,nil,REASON_EFFECT
		)>0 then
			Duel.ConfirmCards(1-tp,tc)
		end
	else
		Duel.SpecialSummon(
			tc,
			0,
			tp,
			tp,
			false,
			false,
			POS_FACEUP
		)
	end
end
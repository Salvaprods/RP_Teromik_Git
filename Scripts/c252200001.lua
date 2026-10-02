-- Transformage - Rage Incontrôlée
local s,id=GetID()

function s.initial_effect(c)
	-- Effet 1 :
	-- Prenez 1 monstre "Transformage" de nom différent
	-- de ceux que vous contrôlez, puis ajoutez-le ou Invoquez-le Spécialement
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- Effet 2 :
	-- Bannissez cette carte du Cimetière ;
	-- Invoquez par Fusion 1 Fusion "Transformage"
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.fustg)
	e2:SetOperation(s.fusop)
	c:RegisterEffect(e2)
end

-- ==========================================
-- EFFET 1
-- ==========================================

-- Vérifie si on contrôle déjà un monstre du même nom
function s.namefilter(c,code)
	return c:IsFaceup() and c:IsCode(code)
end

function s.deckfilter(c,tp)
	return c:IsSetCard(0x6e7)
		and c:IsType(TYPE_MONSTER)
		and not Duel.IsExistingMatchingCard(
			s.namefilter,
			tp,
			LOCATION_MZONE,
			0,
			1,
			nil,
			c:GetCode()
		)
		and (
			c:IsAbleToHand()
			or (
				Duel.GetLocationCount(tp,LOCATION_MZONE)>0
				and c:IsCanBeSpecialSummoned(nil,0,tp,false,false)
			)
		)
end

function s.hestfilter(c)
	return c:IsFaceup() and c:IsCode(252200000)
end

function s.chainlm(e,rp,tp)
	return tp==rp
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.deckfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil,
			tp
		)
	end

	-- Si Hestiaros est contrôlé,
	-- l'adversaire ne peut pas répondre à cet effet
	if Duel.IsExistingMatchingCard(
		s.hestfilter,
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
		CATEGORY_TOHAND,
		nil,
		1,
		tp,
		LOCATION_DECK
	)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)

	local g=Duel.SelectMatchingCard(
		tp,
		s.deckfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil,
		tp
	)

	local tc=g:GetFirst()
	if not tc then return end

	local b1=tc:IsAbleToHand()
	local b2=Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and tc:IsCanBeSpecialSummoned(e,0,tp,false,false)

	local op=0

	if b1 and b2 then
		op=Duel.SelectOption(
			tp,
			aux.Stringid(id,2), -- Ajouter à la main
			aux.Stringid(id,3)  -- Invoquer Spécialement
		)
	elseif b2 then
		op=1
	end

	if op==0 then
		if Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 then
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

-- ==========================================
-- EFFET 2 : FUSION DEPUIS MAIN / TERRAIN
-- ==========================================

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
	local mg=Duel.GetFusionMaterial(tp)

	local fg=Duel.GetMatchingGroup(
		s.fusfilter,
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
		tp,
		tp,
		false,
		false,
		POS_FACEUP
	)>0 then
		fc:CompleteProcedure()
	end
end
-- Esprit Du Dragon d'Atlas
local s,id=GetID()

function s.initial_effect(c)
	-- Activation : 1 seule par tour
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	e0:SetCountLimit(1,id+1000,EFFECT_COUNT_CODE_OATH)
	c:RegisterEffect(e0)

	-- L'adversaire ne peut pas répondre avec des effets de monstre
	-- aux effets de vos Dragons TÉNÈBRES Synchro Terrain/GY
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_CHAINING)
	e1:SetRange(LOCATION_FZONE)
	e1:SetOperation(s.chainop)
	c:RegisterEffect(e1)

	-- 1 fois par tour : chercher 1 Diapason,
	-- puis possibilité de SS 1 Démon Niveau 4 ou moins Main/GY
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_FZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	-- Protection : bannir cette carte à la place
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EFFECT_DESTROY_REPLACE)
	e3:SetRange(LOCATION_FZONE)
	e3:SetTarget(s.reptg)
	e3:SetValue(s.repval)
	e3:SetOperation(s.repop)
	c:RegisterEffect(e3)
end

s.listed_series={0x57}

-- =========================================
-- BLOQUE LES RÉPONSES MONSTRE
-- =========================================
function s.drfilter(c)
	return c:IsType(TYPE_MONSTER)
		and c:IsType(TYPE_SYNCHRO)
		and c:IsRace(RACE_DRAGON)
		and c:IsAttribute(ATTRIBUTE_DARK)
end

function s.chainop(e,tp,eg,ep,ev,re,r,rp)
	if rp~=tp
		or not re:IsActiveType(TYPE_MONSTER) then
		return
	end

	local rc=re:GetHandler()
	if not rc then return end

	if not s.drfilter(rc) then
		return
	end

	if not (
		rc:IsLocation(LOCATION_MZONE)
		or rc:IsLocation(LOCATION_GRAVE)
	) then
		return
	end

	Duel.SetChainLimit(s.chainlm)
end

function s.chainlm(e,rp,tp)
	return not (
		rp==1-tp
		and e:IsActiveType(TYPE_MONSTER)
	)
end

-- =========================================
-- SEARCH DIAPASON
-- =========================================
function s.thfilter(c)
	return c:IsSetCard(0x57)
		and c:IsType(TYPE_MONSTER)
		and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.thfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil
		)
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

function s.spfilter(c,e,tp)
	return c:IsRace(RACE_FIEND)
		and c:IsLevelBelow(4)
		and c:IsCanBeSpecialSummoned(
			e,0,tp,false,false
		)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)

	local g=Duel.SelectMatchingCard(
		tp,
		s.thfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil
	)

	local tc=g:GetFirst()
	if not tc then return end

	if Duel.SendtoHand(
		tc,nil,REASON_EFFECT
	)==0 then
		return
	end

	Duel.ConfirmCards(1-tp,tc)

	-- Puis possibilité de Special Summon
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return
	end

	if not Duel.IsExistingMatchingCard(
		s.spfilter,
		tp,
		LOCATION_HAND+LOCATION_GRAVE,
		0,
		1,
		nil,
		e,tp
	) then
		return
	end

	if not Duel.SelectYesNo(tp,90) then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local sg=Duel.SelectMatchingCard(
		tp,
		s.spfilter,
		tp,
		LOCATION_HAND+LOCATION_GRAVE,
		0,
		1,
		1,
		nil,
		e,tp
	)

	if sg:GetCount()>0 then
		Duel.SpecialSummon(
			sg,
			0,
			tp,
			tp,
			false,
			false,
			POS_FACEUP
		)
	end
end

-- =========================================
-- PROTECTION DRAGON TÉNÈBRES SYNCHRO
-- =========================================
function s.repfilter(c,tp)
	return c:IsControler(tp)
		and c:IsLocation(LOCATION_MZONE)
		and c:IsFaceup()
		and c:IsType(TYPE_SYNCHRO)
		and c:IsRace(RACE_DRAGON)
		and c:IsAttribute(ATTRIBUTE_DARK)
		and c:IsReason(REASON_EFFECT)
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsAbleToRemove()
			and eg:IsExists(
				s.repfilter,
				1,
				nil,
				tp
			)
	end

	return Duel.SelectEffectYesNo(tp,c,96)
end

function s.repval(e,c)
	return s.repfilter(
		c,
		e:GetHandlerPlayer()
	)
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Remove(
		e:GetHandler(),
		POS_FACEUP,
		REASON_EFFECT+REASON_REPLACE
	)
end
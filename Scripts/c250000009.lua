-- Œil De Gokvelgr - Âme Du Chasseur
local s,id=GetID()

function s.initial_effect(c)
	-- Activation normale de la carte
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-- Main Phase : détruire 1 monstre -> SS Niveau +1/-1
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(1,id+100)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- +200 ATK par Âme Du Chasseur face recto dans l'Extra
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.valtg)
	e2:SetValue(s.val)
	c:RegisterEffect(e2)

	-- +200 DEF
	local e3=e2:Clone()
	e3:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e3)
end

s.listed_series={0xc92}

-- =========================================
-- MAIN PHASE
-- =========================================
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return Duel.GetTurnPlayer()==tp
		and (ph==PHASE_MAIN1 or ph==PHASE_MAIN2)
end

-- Monstre Âme Du Chasseur Niveau +/-1
function s.spfilter(c,e,tp,lv)
	return c:IsSetCard(0xc92)
		and c:IsType(TYPE_MONSTER)
		and (c:GetLevel()==lv+1 or c:GetLevel()==lv-1)
		and (not c:IsLocation(LOCATION_EXTRA) or c:IsFaceup())
		and c:IsCanBeSpecialSummoned(
			e,0,tp,false,false
		)
end

-- Monstre que l'on peut détruire
-- et pour lequel il existe une cible Niveau +/-1
function s.desfilter(c,e,tp)
	if not c:IsFaceup()
		or not c:IsType(TYPE_MONSTER)
		or c:GetLevel()<=0
		or not c:IsDestructable() then
		return false
	end

	return Duel.IsExistingMatchingCard(
		s.spfilter,
		tp,
		LOCATION_DECK+LOCATION_EXTRA,
		0,
		1,
		nil,
		e,tp,c:GetLevel()
	)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.desfilter,
			tp,
			LOCATION_MZONE,
			0,
			1,
			nil,
			e,tp
		)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_DESTROY,
		nil,
		1,
		tp,
		LOCATION_MZONE
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,
		1,
		tp,
		LOCATION_DECK+LOCATION_EXTRA
	)
end

function s.resfilter(c,e,tp,lv)
	if not s.spfilter(c,e,tp,lv) then
		return false
	end

	-- Depuis l'Extra : vérifier la zone APRÈS la destruction
	if c:IsLocation(LOCATION_EXTRA) then
		return Duel.GetLocationCountFromEx(
			tp,tp,nil,c
		)>0
	end

	return Duel.GetLocationCount(
		tp,
		LOCATION_MZONE
	)>0
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)

	local g=Duel.SelectMatchingCard(
		tp,
		s.desfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		1,
		nil,
		e,tp
	)

	local tc=g:GetFirst()
	if not tc then return end

	local lv=tc:GetLevel()

	-- Il faut réellement détruire le monstre
	if Duel.Destroy(
		tc,
		REASON_EFFECT
	)==0 then
		return
	end

	-- Vérification APRÈS destruction,
	-- donc marche aussi si le Terrain était plein
	if not Duel.IsExistingMatchingCard(
		s.resfilter,
		tp,
		LOCATION_DECK+LOCATION_EXTRA,
		0,
		1,
		nil,
		e,tp,lv
	) then
		return
	end

	Duel.BreakEffect()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local sg=Duel.SelectMatchingCard(
		tp,
		s.resfilter,
		tp,
		LOCATION_DECK+LOCATION_EXTRA,
		0,
		1,
		1,
		nil,
		e,tp,lv
	)

	local sc=sg:GetFirst()
	if not sc then return end

	if Duel.SpecialSummon(
		sc,
		0,
		tp,
		tp,
		false,
		false,
		POS_FACEUP
	)==0 then
		return
	end

	-- Annule les effets du monstre invoqué
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_DISABLE)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	sc:RegisterEffect(e1)

	local e2=e1:Clone()
	e2:SetCode(EFFECT_DISABLE_EFFECT)
	sc:RegisterEffect(e2)
end

-- =========================================
-- BOOST ATK / DEF
-- =========================================
function s.valtg(e,c)
	return c:IsFaceup()
		and c:IsSetCard(0xc92)
end

function s.extfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(0xc92)
		and c:IsType(TYPE_MONSTER)
end

function s.val(e,c)
	return Duel.GetMatchingGroupCount(
		s.extfilter,
		e:GetHandlerPlayer(),
		LOCATION_EXTRA,
		0,
		nil
	)*200
end
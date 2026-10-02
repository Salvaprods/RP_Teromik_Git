-- ♪DIABLORCHESTRE♪ - Mise En Scene
local s,id=GetID()

function s.initial_effect(c)
	-- Activation normale du Piège Continu
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-- Bannir 1 DIABLORCHESTRE ; revive un nom différent
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Si envoyée du Terrain au GY : se Poser
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.setcon)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
end

-- =========================================
-- REVIVE
-- =========================================
function s.spfilter(c,e,tp,code)
	return c:IsSetCard(0xd1f)
		and c:IsType(TYPE_MONSTER)
		and not c:IsCode(code)
		and (not c:IsLocation(LOCATION_REMOVED) or c:IsFaceup())
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- =========================================
-- COÛT
-- =========================================
function s.costfilter(c,e,tp,needfield)
	if not c:IsSetCard(0xd1f)
		or not c:IsType(TYPE_MONSTER)
		or not c:IsAbleToRemoveAsCost() then
		return false
	end

	-- Si le Terrain est plein, le coût doit venir du Terrain
	-- pour libérer une Zone Monstre
	if needfield and not c:IsLocation(LOCATION_MZONE) then
		return false
	end

	-- Il faut pouvoir revive un DIABLORCHESTRE d'un nom différent
	return Duel.IsExistingMatchingCard(
		s.spfilter,
		tp,
		LOCATION_GRAVE+LOCATION_REMOVED,
		0,
		1,
		nil,
		e,tp,c:GetCode()
	)
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local needfield=Duel.GetLocationCount(tp,LOCATION_MZONE)<=0

	if chk==0 then
		-- Empêche une ancienne valeur de Label de gêner
		e:SetLabel(0)

		return Duel.IsExistingMatchingCard(
			s.costfilter,
			tp,
			LOCATION_HAND+LOCATION_MZONE,
			0,
			1,
			nil,
			e,tp,needfield
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

	local g=Duel.SelectMatchingCard(
		tp,
		s.costfilter,
		tp,
		LOCATION_HAND+LOCATION_MZONE,
		0,
		1,
		1,
		nil,
		e,tp,needfield
	)

	local tc=g:GetFirst()
	if not tc then return end

	e:SetLabel(tc:GetCode())
	Duel.Remove(tc,POS_FACEUP,REASON_COST)
end

-- =========================================
-- TARGET
-- =========================================
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local code=e:GetLabel()

	if chk==0 then
		-- Après paiement réel du coût
		if code~=0 then
			return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
				and Duel.IsExistingMatchingCard(
					s.spfilter,
					tp,
					LOCATION_GRAVE+LOCATION_REMOVED,
					0,
					1,
					nil,
					e,tp,code
				)
		end

		-- Vérification avant activation :
		-- si board plein, un monstre du Terrain peut servir de coût
		local needfield=Duel.GetLocationCount(tp,LOCATION_MZONE)<=0

		return Duel.IsExistingMatchingCard(
			s.costfilter,
			tp,
			LOCATION_HAND+LOCATION_MZONE,
			0,
			1,
			nil,
			e,tp,needfield
		)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,
		1,
		tp,
		LOCATION_GRAVE+LOCATION_REMOVED
	)
end

-- =========================================
-- NIVEAU / RANG 7
-- =========================================
function s.lv7filter(c)
	return c:IsFaceup()
		and c:IsSetCard(0xd1f)
		and (c:IsLevel(7) or c:IsRank(7))
end

function s.negfilter(c)
	return c:IsFaceup()
end

-- =========================================
-- RÉSOLUTION
-- =========================================
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local code=e:GetLabel()

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
		e,tp,code
	)

	local tc=g:GetFirst()
	if not tc then return end

	if Duel.SpecialSummon(
		tc,0,tp,tp,false,false,POS_FACEUP
	)==0 then
		return
	end

	-- Puis, si vous contrôlez un Niveau/Rang 7 DIABLORCHESTRE,
	-- vous pouvez annuler 1 carte face recto
	if not Duel.IsExistingMatchingCard(
		s.lv7filter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		nil
	) then
		return
	end

	if not Duel.IsExistingMatchingCard(
		s.negfilter,
		tp,
		LOCATION_ONFIELD,
		LOCATION_ONFIELD,
		1,
		nil
	) then
		return
	end

	if not Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)

	local ng=Duel.SelectMatchingCard(
		tp,
		s.negfilter,
		tp,
		LOCATION_ONFIELD,
		LOCATION_ONFIELD,
		1,
		1,
		nil
	)

	local nc=ng:GetFirst()
	if not nc then return end

	-- Annule ses effets jusqu'à la End Phase
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_DISABLE)
	e1:SetReset(
		RESET_EVENT+RESETS_STANDARD+
		RESET_PHASE+PHASE_END
	)
	nc:RegisterEffect(e1)

	local e2=e1:Clone()
	e2:SetCode(EFFECT_DISABLE_EFFECT)
	nc:RegisterEffect(e2)
end

-- =========================================
-- EFFET 2 : SE REPOSER
-- =========================================
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_ONFIELD)
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and c:IsSSetable()
	end
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if c:IsRelateToEffect(e)
		and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then

		Duel.SSet(tp,c)
	end
end
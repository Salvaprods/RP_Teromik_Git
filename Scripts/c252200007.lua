-- Transformage - Filania
local s,id=GetID()

function s.initial_effect(c)
	-- Si envoyée au GY par un effet "Transformage"
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_TO_GRAVE)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.plcon)
	e1:SetTarget(s.pltg)
	e1:SetOperation(s.plop)
	c:RegisterEffect(e1)

	-- Si ajoutée à la main par un effet "Transformage"
	local e2=e1:Clone()
	e2:SetCode(EVENT_TO_HAND)
	c:RegisterEffect(e2)

	-- Quick Effect : Sacrifiez cette carte ; annulez l'effet de monstre
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_NEGATE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+100)
	e3:SetCondition(s.negcon)
	e3:SetCost(s.negcost)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)
end

-- ==========================================
-- EFFET 1
-- ==========================================
function s.plcon(e,tp,eg,ep,ev,re,r,rp)
	return re
		and bit.band(r,REASON_EFFECT)~=0
		and re:GetHandler():IsSetCard(0x6e7)
end

function s.contfilter(c)
	return c:IsSetCard(0x6e7)
		and (
			(c:IsType(TYPE_SPELL) and c:IsType(TYPE_CONTINUOUS))
			or
			(c:IsType(TYPE_TRAP) and c:IsType(TYPE_CONTINUOUS))
			or
			(c:IsType(TYPE_SPELL) and c:IsType(TYPE_FIELD))
		)
end

function s.plfilter(c,tp)
	if not s.contfilter(c) then return false end

	if c:IsType(TYPE_FIELD) then
		return true
	end

	return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
end

function s.pltg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.plfilter,tp,LOCATION_DECK,0,1,nil,tp
		)
	end
end

function s.plop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)

	local g=Duel.SelectMatchingCard(
		tp,s.plfilter,tp,LOCATION_DECK,0,1,1,nil,tp
	)

	local tc=g:GetFirst()
	if not tc then return end

	local success=false

	-- Magie de Terrain
	if tc:IsType(TYPE_FIELD) then
		success=Duel.MoveToField(
			tc,tp,tp,
			LOCATION_FZONE,
			POS_FACEUP,
			true
		)
	-- Magie/Piège Continu
	else
		if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end

		success=Duel.MoveToField(
			tc,tp,tp,
			LOCATION_SZONE,
			POS_FACEUP,
			true
		)
	end

	-- Puis vous pouvez Invoquer Spécialement Filania
	if success then
		local c=e:GetHandler()

		if c:IsRelateToEffect(e)
			and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
			and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then

			Duel.SpecialSummon(
				c,0,tp,tp,false,false,POS_FACEUP
			)
		end
	end
end

-- ==========================================
-- EFFET 2 : NEGATE
-- ==========================================
function s.fusfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(0x6e7)
		and c:IsType(TYPE_FUSION)
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
		and re:IsActiveType(TYPE_MONSTER)
		and Duel.IsChainNegatable(ev)
		and Duel.IsExistingMatchingCard(
			s.fusfilter,
			tp,
			LOCATION_MZONE,
			0,
			1,
			nil
		)
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsReleasable()
	end

	Duel.Release(c,REASON_COST)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateEffect(ev)
end
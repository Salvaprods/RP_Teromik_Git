-- Universo - Supra Transmission Dragon
local s,id=GetID()

function s.initial_effect(c)
	-- 2+ monstres "Universo"
	c:EnableReviveLimit()
	aux.AddLinkProcedure(
		c,
		aux.FilterBoolFunction(Card.IsSetCard,0xc17),
		2,
		99
	)

	-- Indestructible par effets de carte
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- Quick : payer 500 LP -> bannir les colonnes
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetCost(s.rmcost)
	e2:SetTarget(s.rmtg)
	e2:SetOperation(s.rmop)
	c:RegisterEffect(e2)

	-- Quitte le Terrain par effet adverse -> revive
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_LEAVE_FIELD)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1,id+100)
	e3:SetCondition(s.spcon)
	e3:SetCost(s.spcost)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

s.listed_series={0xc17}

-- =========================================
-- QUICK : COLONNES
-- =========================================
function s.rmcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.CheckLPCost(tp,500)
	end

	Duel.PayLPCost(tp,500)
end

function s.linkfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(0xc17)
		and c:IsType(TYPE_MONSTER)
end

function s.rmfilter(c,tp)
	return c:IsControler(1-tp)
		and c:IsLocation(LOCATION_ONFIELD)
		and c:IsAbleToRemove()
end

function s.getremovegroup(e,tp)
	local c=e:GetHandler()

	-- Monstres Universo pointés par cette carte
	local lg=c:GetLinkedGroup():Filter(
		s.linkfilter,
		nil
	)

	local rg=Group.CreateGroup()
	local tc=lg:GetFirst()

	while tc do
		-- Cartes adverses dans la même colonne
		local cg=tc:GetColumnGroup():Filter(
			s.rmfilter,
			nil,
			tp
		)

		rg:Merge(cg)

		-- GetColumnGroup peut ne pas inclure tc lui-même
		if tc:IsControler(1-tp)
			and tc:IsAbleToRemove() then

			rg:AddCard(tc)
		end

		tc=lg:GetNext()
	end

	return rg
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	local lg=c:GetLinkedGroup():Filter(
		s.linkfilter,
		nil
	)

	if chk==0 then
		return lg:GetCount()>0
			and s.getremovegroup(e,tp):GetCount()>0
	end

	local rg=s.getremovegroup(e,tp)

	Duel.SetOperationInfo(
		0,
		CATEGORY_REMOVE,
		rg,
		rg:GetCount(),
		1-tp,
		LOCATION_ONFIELD
	)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsRelateToEffect(e)
		or not c:IsFaceup() then
		return
	end

	local rg=s.getremovegroup(e,tp)

	if rg:GetCount()>0 then
		Duel.Remove(
			rg,
			POS_FACEUP,
			REASON_EFFECT
		)
	end
end

-- =========================================
-- QUITTE LE TERRAIN PAR EFFET ADVERSE
-- =========================================
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	return c:IsPreviousLocation(LOCATION_ONFIELD)
		and c:IsPreviousControler(tp)
		and c:IsReason(REASON_EFFECT)
		and rp==1-tp
end

-- 4 AUTRES monstres Universo
function s.spcostfilter(c)
	return c:IsSetCard(0xc17)
		and c:IsType(TYPE_MONSTER)
		and c:IsAbleToRemoveAsCost()
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return Duel.CheckLPCost(tp,1000)
			and Duel.IsExistingMatchingCard(
				s.spcostfilter,
				tp,
				LOCATION_GRAVE,
				0,
				4,
				c
			)
	end

	Duel.PayLPCost(tp,1000)

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_REMOVE
	)

	local g=Duel.SelectMatchingCard(
		tp,
		s.spcostfilter,
		tp,
		LOCATION_GRAVE,
		0,
		4,
		4,
		c
	)

	Duel.Remove(
		g,
		POS_FACEUP,
		REASON_COST
	)
end

-- =========================================
-- VÉRIFICATION DE LA ZONE POUR LE REVIVE
-- =========================================
function s.spzone(c,tp)
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

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return s.spzone(c,tp)
			and c:IsCanBeSpecialSummoned(
				e,
				0,
				tp,
				false,
				false
			)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		c,
		1,
		tp,
		c:GetLocation()
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsRelateToEffect(e)
		or not s.spzone(c,tp) then
		return
	end

	Duel.SpecialSummon(
		c,
		0,
		tp,
		tp,
		false,
		false,
		POS_FACEUP
	)
end
-- Universo - Supra Transmission Dragon
local s,id=GetID()

function s.initial_effect(c)
	-- Invocation Lien : 2+ monstres "Universo"
	c:EnableReviveLimit()
	aux.AddLinkProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,0xc17),2,99)

	-- Cette carte et les "Universo" pointés ne peuvent pas être Sacrifiés
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UNRELEASABLE_SUM)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e1:SetTarget(s.prottg)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	local e2=e1:Clone()
	e2:SetCode(EFFECT_UNRELEASABLE_NONSUM)
	c:RegisterEffect(e2)

	-- Cette carte et les "Universo" pointés
	-- ne peuvent pas être utilisés comme Matériel Fusion
	local e3=e1:Clone()
	e3:SetCode(EFFECT_CANNOT_BE_FUSION_MATERIAL)
	c:RegisterEffect(e3)

	-- Cette carte ne peut pas être détruite par des effets de carte
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e4:SetValue(1)
	c:RegisterEffect(e4)

	-- Effet Rapide : payer 500 LP -> bannir les colonnes
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,0))
	e5:SetCategory(CATEGORY_REMOVE)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_FREE_CHAIN)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1,id)
	e5:SetCost(s.rmcost)
	e5:SetTarget(s.rmtg)
	e5:SetOperation(s.rmop)
	c:RegisterEffect(e5)

	-- Si elle quitte le Terrain par effet adverse
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,1))
	e6:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
	e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e6:SetCode(EVENT_LEAVE_FIELD)
	e6:SetProperty(EFFECT_FLAG_DELAY)
	e6:SetCountLimit(1,id+100)
	e6:SetCondition(s.spcon)
	e6:SetCost(s.spcost)
	e6:SetTarget(s.sptg)
	e6:SetOperation(s.spop)
	c:RegisterEffect(e6)
end

-- ==========================================
-- PROTECTIONS
-- ==========================================
function s.prottg(e,c)
	local hc=e:GetHandler()
	return c==hc
		or (c:IsSetCard(0xc17) and hc:GetLinkedGroup():IsContains(c))
end

-- ==========================================
-- EFFET RAPIDE : COLONNES
-- ==========================================
function s.rmcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.CheckLPCost(tp,500)
	end
	Duel.PayLPCost(tp,500)
end

function s.colfilter(c,tp)
	return c:IsControler(1-tp)
		and c:IsLocation(LOCATION_ONFIELD)
		and c:IsAbleToRemove()
end

function s.getremovegroup(e,tp)
	local c=e:GetHandler()
	local lg=c:GetLinkedGroup():Filter(Card.IsSetCard,nil,0xc17)
	local rg=Group.CreateGroup()

	local tc=lg:GetFirst()
	while tc do
		local cg=tc:GetColumnGroup():Filter(s.colfilter,nil,tp)
		rg:Merge(cg)
		tc=lg:GetNext()
	end

	return rg
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local lg=c:GetLinkedGroup():Filter(Card.IsSetCard,nil,0xc17)

	if chk==0 then
		if lg:GetCount()==0 then
			return false
		end

		return s.getremovegroup(e,tp):GetCount()>0
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

	if not c:IsRelateToEffect(e) then
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

-- ==========================================
-- QUITTE LE TERRAIN PAR EFFET ADVERSE
-- ==========================================
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	return c:IsPreviousPosition(POS_FACEUP)
		and c:IsPreviousControler(tp)
		and c:IsReason(REASON_EFFECT)
		and rp==1-tp
		and not c:IsLocation(LOCATION_EXTRA)
end

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

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

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

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
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
		0,
		0
	)

	local rg=Duel.GetMatchingGroup(
		Card.IsAbleToRemove,
		tp,
		0,
		LOCATION_ONFIELD,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_REMOVE,
		rg,
		rg:GetCount(),
		1-tp,
		LOCATION_ONFIELD
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsRelateToEffect(e) then
		return
	end

	if Duel.SpecialSummon(
		c,
		0,
		tp,
		tp,
		false,
		false,
		POS_FACEUP
	)==0 then
		return
	end

	local rg=Duel.GetMatchingGroup(
		Card.IsAbleToRemove,
		tp,
		0,
		LOCATION_ONFIELD,
		nil
	)

	if rg:GetCount()>0 then
		Duel.Remove(
			rg,
			POS_FACEUP,
			REASON_EFFECT
		)
	end
end
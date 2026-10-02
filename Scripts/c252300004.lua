-- ♪DIABLORCHESTRE♪ - Riks L'Audieux
local s,id=GetID()

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- Uniquement Xyz avec 1 Xyz Rang 3 "DIABLORCHESTRE"
	aux.AddXyzProcedure(
		c,
		s.nomfilter,
		3,
		2,
		s.ovfilter,
		aux.Stringid(id,0),
		2,
		s.xyzop
	)

	-- Negate effet de monstre
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_CHAINING)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.negcon)
	e1:SetCost(s.negcost)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)

	-- Si Fusion "DIABLORCHESTRE" invoquée
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetCategory(CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.rmcon)
	e2:SetTarget(s.rmtg)
	e2:SetOperation(s.rmop)
	c:RegisterEffect(e2)
end

-- =========================================
-- PROCÉDURE XYZ
-- =========================================
function s.nomfilter(c)
	return false
end

function s.ovfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(0xd1f)
		and c:IsType(TYPE_XYZ)
		and c:IsRank(3)
end

function s.xyzop(e,tp,chk,mc)
	if chk==0 then
		return Duel.GetFlagEffect(tp,id+1000)==0
	end

	Duel.RegisterFlagEffect(
		tp,
		id+1000,
		RESET_PHASE+PHASE_END,
		EFFECT_FLAG_OATH,
		1
	)
end

-- =========================================
-- EFFET 1 : NEGATE
-- =========================================
function s.concfilter(c)
	return c:IsFaceup()
		and c:IsCode(252300002)
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
		and re:IsActiveType(TYPE_MONSTER)
		and Duel.IsChainDisablable(ev)
		and Duel.IsExistingMatchingCard(
			s.concfilter,
			tp,
			LOCATION_FZONE,
			0,
			1,
			nil
		)
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:CheckRemoveOverlayCard(
			tp,
			1,
			REASON_COST
		)
	end

	c:RemoveOverlayCard(
		tp,
		1,
		1,
		REASON_COST
	)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end

	Duel.SetOperationInfo(
		0,
		CATEGORY_NEGATE,
		eg,
		1,
		0,
		0
	)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.NegateEffect(ev) then
		return
	end

	-- Puis vous pouvez payer 1000 LP ; piochez 1 carte
	if Duel.CheckLPCost(tp,1000)
		and Duel.IsPlayerCanDraw(tp,1)
		and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then

		Duel.PayLPCost(tp,1000)
		Duel.Draw(tp,1,REASON_EFFECT)
	end
end

-- =========================================
-- EFFET 2 : FUSION "DIABLORCHESTRE" INVOQUÉE
-- =========================================
function s.fusfilter(c,tp)
	return c:IsControler(tp)
		and c:IsSetCard(0xd1f)
		and c:IsType(TYPE_FUSION)
end

function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(
		s.fusfilter,
		1,
		nil,
		tp
	)
end

function s.deckfilter(c)
	return c:IsSetCard(0xd1f)
		and c:IsType(TYPE_MONSTER)
		and c:IsAbleToRemove()
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.deckfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil
		)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_REMOVE,
		nil,
		1,
		tp,
		LOCATION_DECK
	)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

	local g=Duel.SelectMatchingCard(
		tp,
		s.deckfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil
	)

	local tc=g:GetFirst()

	if tc then
		Duel.Remove(
			tc,
			POS_FACEUP,
			REASON_EFFECT
		)
	end
end
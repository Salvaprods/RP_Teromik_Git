-- Entrepôt Des Gobelins Motards
local s,id=GetID()

function s.initial_effect(c)
	-- Activation : 1 seule activation par tour
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	e0:SetCountLimit(1,id+1000,EFFECT_COUNT_CODE_OATH)
	c:RegisterEffect(e0)

	-- Xyz Goblin +500 ATK
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetRange(LOCATION_FZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.xyzfilter)
	e1:SetValue(500)
	c:RegisterEffect(e1)

	-- Xyz Goblin indestructibles par effets de monstre adverses
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.xyzfilter)
	e2:SetValue(s.indval)
	c:RegisterEffect(e2)

	-- Main Phase : envoyer 1 Goblin Deck -> GY ; chercher nom différent
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_TOGRAVE+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCountLimit(1,id+100)
	e3:SetCondition(s.thcon)
	e3:SetCost(s.thcost)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)

	-- Adversaire active effet Magie/Piège : détacher 1 ; negate
	-- UNE FOIS PAR TOUR
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_NEGATE)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_CHAINING)
	e4:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e4:SetRange(LOCATION_FZONE)
	e4:SetCountLimit(1,id+200)
	e4:SetCondition(s.negcon)
	e4:SetCost(s.negcost)
	e4:SetOperation(s.negop)
	c:RegisterEffect(e4)
end

s.listed_series={0xac}

-- =========================================
-- BOOST / PROTECTION
-- =========================================
function s.xyzfilter(e,c)
	return c:IsFaceup()
		and c:IsSetCard(0xac)
		and c:IsType(TYPE_XYZ)
end

function s.indval(e,re,tp)
	return re:IsActiveType(TYPE_MONSTER)
		and re:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

-- =========================================
-- EFFET 1 : SEND + SEARCH
-- =========================================
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return ph==PHASE_MAIN1 or ph==PHASE_MAIN2
end

function s.thfilter(c,code)
	return c:IsSetCard(0xac)
		and c:IsType(TYPE_MONSTER)
		and not c:IsCode(code)
		and c:IsAbleToHand()
end

function s.costfilter(c,tp)
	return c:IsSetCard(0xac)
		and c:IsType(TYPE_MONSTER)
		and c:IsAbleToGraveAsCost()
		and Duel.IsExistingMatchingCard(
			s.thfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			c,
			c:GetCode()
		)
end

function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.costfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil,
			tp
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)

	local g=Duel.SelectMatchingCard(
		tp,
		s.costfilter,
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

	e:SetLabel(tc:GetCode())
	Duel.SendtoGrave(tc,REASON_COST)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return true
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
	local code=e:GetLabel()

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)

	local g=Duel.SelectMatchingCard(
		tp,
		s.thfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil,
		code
	)

	if g:GetCount()>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- =========================================
-- EFFET 2 : NEGATE MAGIE / PIÈGE
-- =========================================
function s.xyzconfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(0xac)
		and c:IsType(TYPE_XYZ)
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return ep==1-tp
		and (re:IsActiveType(TYPE_SPELL) or re:IsActiveType(TYPE_TRAP))
		and Duel.IsChainNegatable(ev)
		and Duel.IsExistingMatchingCard(
			s.xyzconfilter,
			tp,
			LOCATION_MZONE,
			0,
			1,
			nil
		)
end

function s.ovfilter(c)
	return c:IsFaceup()
		and c:IsType(TYPE_XYZ)
		and c:GetOverlayCount()>0
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.ovfilter,
			tp,
			LOCATION_MZONE,
			LOCATION_MZONE,
			1,
			nil
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)

	local g=Duel.SelectMatchingCard(
		tp,
		s.ovfilter,
		tp,
		LOCATION_MZONE,
		LOCATION_MZONE,
		1,
		1,
		nil
	)

	local tc=g:GetFirst()

	if tc then
		tc:RemoveOverlayCard(
			tp,
			1,
			1,
			REASON_COST
		)
	end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateEffect(ev)
end
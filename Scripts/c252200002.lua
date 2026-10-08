-- Transformage - Toge
local s,id=GetID()

function s.initial_effect(c)
	-- Invocation Spéciale depuis la main
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	-- Si Invoquée Spécialement
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOGRAVE+CATEGORY_COIN+CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id+100)
	e2:SetCost(s.cost)
	e2:SetTarget(s.target)
	e2:SetOperation(s.operation)
	c:RegisterEffect(e2)
end

s.listed_series={0x6e7}

-- ==========================================
-- INVOCATION SPÉCIALE DEPUIS LA MAIN
-- ==========================================
function s.spfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(0x6e7)
		and c:IsType(TYPE_MONSTER)
end

function s.spcon(e,c)
	if c==nil then return true end

	local tp=c:GetControler()

	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(
			s.spfilter,
			tp,
			LOCATION_MZONE,
			0,
			1,
			nil
		)
end

-- ==========================================
-- COÛT :
-- ENVOYER 1 TRANSFORMAGE NON-NIVEAU 3
-- ==========================================
function s.costfilter(c)
	return c:IsSetCard(0x6e7)
		and c:IsType(TYPE_MONSTER)
		and c:GetLevel()~=3
		and c:IsAbleToGraveAsCost()
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.costfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil
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
		nil
	)

	Duel.SendtoGrave(
		g,
		REASON_COST
	)
end

-- ==========================================
-- LANCER DE PIÈCE
-- ==========================================
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return true
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_COIN,
		nil,
		0,
		tp,
		1
	)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	-- Sur ton core :
	-- 1 = FACE
	-- 0 = PILE
	local res=Duel.TossCoin(tp,1)

	-- ======================================
	-- FACE
	-- L'adversaire ne peut pas répondre
	-- avec des effets de monstre à tes
	-- cartes/effets Transformage
	-- ======================================
	if res==1 then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_CANNOT_ACTIVATE)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e1:SetTargetRange(0,1)
		e1:SetValue(s.aclimit)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)

	-- ======================================
	-- PILE
	-- L'adversaire pioche 2
	-- ======================================
	else
		Duel.Draw(
			1-tp,
			2,
			REASON_EFFECT
		)
	end
end

-- ==========================================
-- FACE :
-- BLOQUE UNIQUEMENT LES EFFETS DE MONSTRE
-- EN RÉPONSE À UNE CARTE/EFFET TRANSFORMAGE
-- ==========================================
function s.aclimit(e,re,tp)
	-- Seulement les effets de monstre adverses
	if not re:IsActiveType(TYPE_MONSTER) then
		return false
	end

	local ct=Duel.GetCurrentChain()

	if ct<=0 then
		return false
	end

	-- Effet auquel l'adversaire essaie de répondre
	local te=Duel.GetChainInfo(
		ct,
		CHAININFO_TRIGGERING_EFFECT
	)

	local p=Duel.GetChainInfo(
		ct,
		CHAININFO_TRIGGERING_PLAYER
	)

	-- Ça doit être notre activation
	if not te
		or p~=e:GetHandlerPlayer() then
		return false
	end

	local tc=te:GetHandler()

	-- Et la carte activée doit être "Transformage"
	return tc~=nil
		and tc:IsSetCard(0x6e7)
end
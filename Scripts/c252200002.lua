-- Transformage - Toge
local s,id=GetID()

function s.initial_effect(c)
	-- Invocation Spéciale inhérente depuis la main
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
	e2:SetCategory(CATEGORY_TOGRAVE+CATEGORY_COIN)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id+100)
	e2:SetCost(s.cost)
	e2:SetTarget(s.target)
	e2:SetOperation(s.operation)
	c:RegisterEffect(e2)
end

-- ==========================================
-- INVOCATION SPÉCIALE INHÉRENTE
-- ==========================================
function s.spfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x6e7)
end

function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(
			s.spfilter,tp,LOCATION_MZONE,0,1,nil
		)
end

-- ==========================================
-- COÛT
-- Envoyer 1 monstre Transformage non-Niveau 3
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
			s.costfilter,tp,LOCATION_DECK,0,1,nil
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)

	local g=Duel.SelectMatchingCard(
		tp,s.costfilter,tp,LOCATION_DECK,0,1,1,nil
	)

	Duel.SendtoGrave(g,REASON_COST)
end

-- ==========================================
-- LANCER DE PIÈCE
-- ==========================================
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_COIN,nil,0,tp,1)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	-- Sur ton core :
	-- 1 = FACE
	-- 0 = PILE
	local res=Duel.TossCoin(tp,1)

	-- ======================================
	-- FACE
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
	-- ======================================
	else
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(EVENT_SPSUMMON_SUCCESS)
		e1:SetOperation(s.recop)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
	end
end

-- ==========================================
-- FACE
-- L'adversaire ne peut pas répondre avec
-- un effet de monstre à une carte/effet Transformage
-- ==========================================
function s.aclimit(e,re,tp)
	-- Bloque uniquement les effets de monstre
	if not re:IsActiveType(TYPE_MONSTER) then
		return false
	end

	local ct=Duel.GetCurrentChain()

	if ct<=0 then
		return false
	end

	-- Dernier effet déjà présent dans la Chaîne
	local te=Duel.GetChainInfo(
		ct,
		CHAININFO_TRIGGERING_EFFECT
	)

	local p=Duel.GetChainInfo(
		ct,
		CHAININFO_TRIGGERING_PLAYER
	)

	-- Il faut que ce soit NOTRE activation
	if not te or p~=e:GetHandlerPlayer() then
		return false
	end

	local tc=te:GetHandler()

	-- Et que la carte soit "Transformage"
	return tc~=nil
		and tc:IsSetCard(0x6e7)
end

-- ==========================================
-- PILE
-- Chaque fois que vous Invoquez Spécialement
-- un ou plusieurs Transformage :
-- adversaire +100 LP
-- ==========================================
function s.recfilter(c,tp)
	return c:IsControler(tp)
		and c:IsSetCard(0x6e7)
end

function s.recop(e,tp,eg,ep,ev,re,r,rp)
	if eg:IsExists(
		s.recfilter,
		1,
		nil,
		tp
	) then
		Duel.Recover(
			1-tp,
			100,
			REASON_EFFECT
		)
	end
end
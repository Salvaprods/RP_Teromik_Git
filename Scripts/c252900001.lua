-- Mulcharmy
local s,id=GetID()
s.flag=id+5000

function s.initial_effect(c)
	-- Compte les activations d'effets de monstres "Mulcharmy"
	if not s.global_check then
		s.global_check=true
		local ge=Effect.CreateEffect(c)
		ge:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge:SetCode(EVENT_CHAINING)
		ge:SetOperation(s.checkop)
		Duel.RegisterEffect(ge,0)
	end

	-- Si vous ne contrôlez aucune carte :
	-- défaussez cette carte ; appliquez les effets ce tour
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetCondition(s.condition)
	e1:SetCost(s.cost)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

s.listed_series={0x1b2}

-- =========================================
-- COMPTE LES EFFETS MULCHARMY ACTIVÉS
-- =========================================
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()

	if rc
		and re:IsActiveType(TYPE_MONSTER)
		and rc:IsSetCard(0x1b2) then

		Duel.RegisterFlagEffect(
			rp,
			s.flag,
			RESET_PHASE+PHASE_END,
			0,
			1
		)
	end
end

-- =========================================
-- CONDITION
-- =========================================
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	-- Aucune carte contrôlée
	-- + pas déjà 2 effets Mulcharmy activés ce tour
	return Duel.GetFieldGroupCount(
		tp,
		LOCATION_ONFIELD,
		0
	)==0
		and Duel.GetFlagEffect(tp,s.flag)<2
end

-- =========================================
-- COÛT
-- =========================================
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsDiscardable()
	end

	Duel.SendtoGrave(
		c,
		REASON_COST+REASON_DISCARD
	)

	-- Durant ce tour, bloque les effets Mulcharmy
	-- après qu'un seul autre ait été activé
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(1,0)
	e1:SetValue(s.aclimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

function s.aclimit(e,re,tp)
	local rc=re:GetHandler()

	return Duel.GetFlagEffect(tp,s.flag)>=2
		and rc
		and re:IsActiveType(TYPE_MONSTER)
		and rc:IsSetCard(0x1b2)
end

-- =========================================
-- APPLICATION DES EFFETS POUR CE TOUR
-- =========================================
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	-- Chaque fois que l'adversaire ajoute
	-- une carte Deck -> Main : piochez 1
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_TO_HAND)
	e1:SetCondition(s.drcon)
	e1:SetOperation(s.drop)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)

	-- End Phase : remettre au hasard les cartes en trop
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_PHASE+PHASE_END)
	e2:SetCondition(s.epcon)
	e2:SetOperation(s.epop)
	e2:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e2,tp)
end

-- =========================================
-- DRAW QUAND ADVERSAIRE AJOUTE DEPUIS DECK
-- =========================================
function s.addfilter(c,p)
	return c:IsControler(p)
		and c:IsLocation(LOCATION_HAND)
		and c:IsPreviousLocation(LOCATION_DECK)
end

function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	return eg
		and eg:IsExists(
			s.addfilter,
			1,
			nil,
			1-tp
		)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.IsPlayerCanDraw(tp,1) then
		Duel.Draw(
			tp,
			1,
			REASON_EFFECT
		)
	end
end

-- =========================================
-- END PHASE
-- Main > cartes adverses contrôlées + 6
-- =========================================
function s.epcon(e,tp,eg,ep,ev,re,r,rp)
	local hand=Duel.GetFieldGroupCount(
		tp,
		LOCATION_HAND,
		0
	)

	local opp=Duel.GetFieldGroupCount(
		tp,
		0,
		LOCATION_ONFIELD
	)

	return hand>opp+6
end

function s.epop(e,tp,eg,ep,ev,re,r,rp)
	local hand=Duel.GetFieldGroupCount(
		tp,
		LOCATION_HAND,
		0
	)

	local opp=Duel.GetFieldGroupCount(
		tp,
		0,
		LOCATION_ONFIELD
	)

	local limit=opp+6

	if hand<=limit then
		return
	end

	local ct=hand-limit

	local g=Duel.GetFieldGroup(
		tp,
		LOCATION_HAND,
		0
	)

	if g:GetCount()<ct then
		return
	end

	-- Cartes choisies au hasard
	local sg=g:RandomSelect(
		tp,
		ct
	)

	if sg:GetCount()>0 then
		Duel.SendtoDeck(
			sg,
			nil,
			SEQ_DECKSHUFFLE,
			REASON_EFFECT
		)
	end
end
-- Arrêt Purrely
local s,id=GetID()

function s.initial_effect(c)
	-- ==========================================
	-- EFFET 1 : CONTRE-PIÈGE
	-- Annule un effet adverse puis peut attacher
	-- la carte à un Xyz "Purrely"
	-- ==========================================
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_NEGATE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.negcon)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)

	-- ==========================================
	-- EFFET 2 : EFFET RAPIDE DEPUIS LE CIMETIÈRE
	-- Utilisable pendant TON tour ou le tour adverse
	-- ==========================================
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

-- ==========================================
-- EFFET 1 : ANNULATION
-- ==========================================
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
		and Duel.IsChainNegatable(ev)
end

function s.xyzfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(0x18c)
		and c:IsType(TYPE_XYZ)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return true
	end

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

	local rc=re:GetHandler()

	if not rc then
		return
	end

	local g=Duel.GetMatchingGroup(
		s.xyzfilter,
		tp,
		LOCATION_MZONE,
		0,
		nil
	)

	if #g==0 then
		return
	end

	-- Demande si on veut attacher la carte annulée
	if not Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_TARGET
	)

	local sg=g:Select(tp,1,1,nil)
	local tc=sg:GetFirst()

	if not tc then
		return
	end

	-- Attache la carte dont l'effet a été annulé
	-- si elle existe encore dans une zone valide
	if rc:IsLocation(
		LOCATION_MZONE+
		LOCATION_SZONE+
		LOCATION_GRAVE+
		LOCATION_REMOVED
	) then
		Duel.Overlay(
			tc,
			Group.FromCards(rc)
		)
	end
end

-- ==========================================
-- EFFET 2 :
-- COMPTER LES NOMS DE MONSTRES "PURRELY"
-- TERRAIN + CIMETIÈRE
-- ==========================================
function s.monfilter(c)
	return c:IsSetCard(0x18c)
		and c:IsType(TYPE_MONSTER)
		and (
			c:IsLocation(LOCATION_GRAVE)
			or c:IsFaceup()
		)
end

function s.name_count(tp)
	local g=Duel.GetMatchingGroup(
		s.monfilter,
		tp,
		LOCATION_MZONE+LOCATION_GRAVE,
		0,
		nil
	)

	local codes={}

	for tc in aux.Next(g) do
		codes[tc:GetCode()]=true
	end

	local ct=0

	for _ in pairs(codes) do
		ct=ct+1
	end

	return ct
end

-- ==========================================
-- MAGIES / PIÈGES "PURRELY" À RÉCUPÉRER
-- ==========================================
function s.thfilter(c)
	return c:IsSetCard(0x18c)
		and c:IsType(TYPE_SPELL+TYPE_TRAP)
		and c:IsAbleToHand()
end

-- ==========================================
-- TARGET
-- ==========================================
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_GRAVE)
			and s.thfilter(chkc)
	end

	local ct=s.name_count(tp)

	if chk==0 then
		return ct>0
			and Duel.IsExistingTarget(
				s.thfilter,
				tp,
				LOCATION_GRAVE,
				0,
				1,
				nil
			)
	end

	local g=Duel.GetMatchingGroup(
		s.thfilter,
		tp,
		LOCATION_GRAVE,
		0,
		nil
	)

	local maxc=math.min(ct,#g)

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_ATOHAND
	)

	local sg=Duel.SelectTarget(
		tp,
		s.thfilter,
		tp,
		LOCATION_GRAVE,
		0,
		1,
		maxc,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOHAND,
		sg,
		#sg,
		tp,
		LOCATION_GRAVE
	)
end

-- ==========================================
-- RESOLUTION
-- Compatible avec les cores Omega qui n'ont pas
-- Duel.GetTargetCards()
-- ==========================================
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tg=Duel.GetChainInfo(
		0,
		CHAININFO_TARGET_CARDS
	)

	if not tg then
		return
	end

	-- Garde uniquement les cartes encore liées à l'effet
	local g=tg:Filter(
		Card.IsRelateToEffect,
		nil,
		e
	)

	if #g==0 then
		return
	end

	local ct=Duel.SendtoHand(
		g,
		nil,
		REASON_EFFECT
	)

	if ct>0 then
		Duel.ConfirmCards(
			1-tp,
			g
		)
	end
end
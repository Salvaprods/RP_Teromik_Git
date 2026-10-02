-- Universo - Transmission d'Univers
local s,id=GetID()

function s.initial_effect(c)
	-- Ne peut contrôler qu'1 "Universo - Transmission d'Univers"
	c:SetUniqueOnField(1,0,id)

	-- Activation
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-- Effet 1 : End Phase -> payer 1000 LP ou détruire cette carte
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_PHASE+PHASE_END)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(1)
	e1:SetCondition(s.effcon)
	e1:SetTarget(s.efftg)
	e1:SetOperation(s.effop)
	c:RegisterEffect(e1)

	-- Effet 2 :
	-- Pendant la résolution d'un effet adverse,
	-- payer 200 LP pour déplacer 1 de vos monstres
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_CHAIN_SOLVING)
	e2:SetRange(LOCATION_SZONE)
	e2:SetOperation(s.atop)
	c:RegisterEffect(e2)
end

-- ==========================================
-- EFFET 1 : END PHASE
-- ==========================================
function s.effcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp
end

function s.efftg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return true
	end
end

function s.effop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsRelateToEffect(e) then
		return
	end

	if Duel.CheckLPCost(tp,1000) then
		local op=Duel.SelectOption(
			tp,
			aux.Stringid(id,0),
			aux.Stringid(id,1)
		)

		if op==0 then
			Duel.PayLPCost(tp,1000)
		else
			Duel.Destroy(c,REASON_EFFECT)
		end
	else
		Duel.Destroy(c,REASON_EFFECT)
	end
end

-- ==========================================
-- EFFET 2 : DEPLACEMENT
-- ==========================================
function s.mvfilter(c,tp)
	return c:IsControler(tp)
		and c:IsLocation(LOCATION_MZONE)
end

function s.atop(e,tp,eg,ep,ev,re,r,rp)
	-- Seulement si l'effet en résolution appartient à l'adversaire
	if rp~=1-tp then
		return
	end

	-- Il faut pouvoir payer 200 LP
	if not Duel.CheckLPCost(tp,200) then
		return
	end

	-- Il faut au moins une zone monstre libre
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return
	end

	-- Il faut contrôler au moins un monstre
	if not Duel.IsExistingMatchingCard(
		s.mvfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		nil,
		tp
	) then
		return
	end

	-- Demande si on veut activer le déplacement
	if not Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		return
	end

	-- Paiement
	Duel.PayLPCost(tp,200)

	-- Sélection du monstre
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)

	local g=Duel.SelectMatchingCard(
		tp,
		s.mvfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		1,
		nil,
		tp
	)

	local tc=g:GetFirst()

	if not tc then
		return
	end

	-- Sélection d'une nouvelle Main Monster Zone
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOZONE)

	local zone=Duel.SelectDisableField(
		tp,
		1,
		LOCATION_MZONE,
		0,
		0x60
	)

	-- Garde uniquement les 5 Main Monster Zones
	zone=zone&0x1f

	if zone==0 then
		return
	end

	-- Conversion zone -> séquence
	local seq=-1

	if zone&0x01~=0 then
		seq=0
	elseif zone&0x02~=0 then
		seq=1
	elseif zone&0x04~=0 then
		seq=2
	elseif zone&0x08~=0 then
		seq=3
	elseif zone&0x10~=0 then
		seq=4
	end

	if seq<0 then
		return
	end

	Duel.MoveSequence(tc,seq)
end
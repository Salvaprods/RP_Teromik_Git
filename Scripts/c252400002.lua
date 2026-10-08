-- Monstre Elu Par Les Gobelin Motards
local s,id=GetID()

Duel.EnableGlobalFlag(GLOBALFLAG_DETACH_EVENT)

function s.initial_effect(c)
	-- 2+ monstres de Niveau 3
	aux.AddXyzProcedure(c,nil,3,2,nil,nil,99)
	c:EnableReviveLimit()

	-- Invocation Normale
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1,id+100)
	e1:SetTarget(s.attg)
	e1:SetOperation(s.atop)
	c:RegisterEffect(e1)

	-- Invocation Spéciale
	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)

	-- Si un ou plusieurs Matériels sont détachés d'un Xyz
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_DETACH_MATERIAL)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+100)
	e3:SetCondition(s.detcon)
	e3:SetTarget(s.attg)
	e3:SetOperation(s.atop)
	c:RegisterEffect(e3)

	-- End Phase : optionnel
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_PHASE+PHASE_END)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id+200)
	e4:SetTarget(s.eptg)
	e4:SetOperation(s.epop)
	c:RegisterEffect(e4)

	-- Main Phase adverse : détacher 1 ; attacher 1 carte du Terrain
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_FREE_CHAIN)
	e5:SetRange(LOCATION_MZONE)
	e5:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e5:SetCountLimit(1,id+300)
	e5:SetCondition(s.qcon)
	e5:SetCost(s.qcost)
	e5:SetTarget(s.qtg)
	e5:SetOperation(s.qop)
	c:RegisterEffect(e5)

	-- Protection par remplacement
	-- Pas d'activation, pas de once per turn
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e6:SetCode(EFFECT_DESTROY_REPLACE)
	e6:SetRange(LOCATION_MZONE)
	e6:SetTarget(s.reptg)
	e6:SetValue(s.repval)
	e6:SetOperation(s.repop)
	c:RegisterEffect(e6)
end

s.listed_series={0xac}

-- =========================================
-- EFFET 1 : SUMMON / DETACH
-- MAIN + LES DEUX TERRAINS UNIQUEMENT
-- =========================================
function s.detfilter(c)
	return c:IsType(TYPE_XYZ)
		and c:IsLocation(LOCATION_MZONE)
end

function s.detcon(e,tp,eg,ep,ev,re,r,rp)
	return eg and eg:IsExists(s.detfilter,1,nil)
end

function s.attachfilter(c,xc)
	return c~=xc
		and not c:IsType(TYPE_TOKEN)
end

function s.attg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.attachfilter,
			tp,
			LOCATION_HAND+LOCATION_ONFIELD,
			LOCATION_ONFIELD,
			1,
			c,
			c
		)
	end
end

function s.atop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsRelateToEffect(e)
		or not c:IsFaceup() then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)

	local g=Duel.SelectMatchingCard(
		tp,
		s.attachfilter,
		tp,
		LOCATION_HAND+LOCATION_ONFIELD,
		LOCATION_ONFIELD,
		1,
		1,
		c,
		c
	)

	if g:GetCount()>0 then
		Duel.Overlay(c,g)
	end
end

-- =========================================
-- EFFET 2 : END PHASE OPTIONNEL
-- =========================================
function s.epfilter(c)
	return c:IsSetCard(0xac)
		and c:IsType(TYPE_MONSTER)
end

function s.eptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.epfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil
		)
	end
end

function s.epop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsRelateToEffect(e)
		or not c:IsFaceup() then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)

	local g=Duel.SelectMatchingCard(
		tp,
		s.epfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil
	)

	if g:GetCount()>0 then
		Duel.Overlay(c,g)
	end
end

-- =========================================
-- EFFET 3 : MAIN PHASE ADVERSE
-- =========================================
function s.qcon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()

	return Duel.GetTurnPlayer()==1-tp
		and (ph==PHASE_MAIN1 or ph==PHASE_MAIN2)
end

function s.xyzfilter(c)
	return c:IsFaceup()
		and c:IsType(TYPE_XYZ)
		and c:GetOverlayCount()>0
end

function s.qcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.xyzfilter,
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
		s.xyzfilter,
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

function s.qfilter(c,xc)
	return c~=xc
		and not c:IsType(TYPE_TOKEN)
end

function s.qtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()

	if chkc then
		return chkc:IsOnField()
			and s.qfilter(chkc,c)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.qfilter,
			tp,
			LOCATION_ONFIELD,
			LOCATION_ONFIELD,
			1,
			c,
			c
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)

	Duel.SelectTarget(
		tp,
		s.qfilter,
		tp,
		LOCATION_ONFIELD,
		LOCATION_ONFIELD,
		1,
		1,
		c,
		c
	)
end

function s.qop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()

	if not c:IsRelateToEffect(e)
		or not c:IsFaceup()
		or not tc
		or not tc:IsRelateToEffect(e) then
		return
	end

	local g=Group.CreateGroup()
	g:AddCard(tc)
	Duel.Overlay(c,g)
end

-- =========================================
-- PROTECTION : DETACH À LA PLACE
-- =========================================
function s.repfilter(c,tp)
	return c:IsControler(tp)
		and c:IsLocation(LOCATION_ONFIELD)
		and c:IsReason(REASON_EFFECT)
		and c:GetReasonPlayer()==1-tp
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:GetOverlayCount()>0
			and eg:IsExists(s.repfilter,1,nil,tp)
	end

	return Duel.SelectEffectYesNo(tp,c,96)
end

function s.repval(e,c)
	return s.repfilter(
		c,
		e:GetHandlerPlayer()
	)
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	c:RemoveOverlayCard(
		tp,
		1,
		1,
		REASON_EFFECT+REASON_REPLACE
	)
end
-- Queentwins - Ornella
local s,id=GetID()

s.listed_series={0xd44}

function s.initial_effect(c)
	-- 2+ monstres "Queentwins" de Niveau 4
	c:EnableReviveLimit()
	aux.AddXyzProcedure(c,s.mfilter,4,2,nil,nil,99)

	-- +200 ATK par Matériel Xyz
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)

	-- Tant qu'elle a du Matériel :
	-- immunisée aux effets de monstres adverses sur le Terrain
	-- qui ciblent cette carte
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetCondition(s.immcon)
	e2:SetValue(s.efilter)
	c:RegisterEffect(e2)

	-- Lorsqu'elle combat :
	-- détacher 1 -> +500 ATK par monstre sur le Terrain
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_ATKCHANGE)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_PRE_DAMAGE_CALCULATE)
	e3:SetCountLimit(1,id)
	e3:SetCost(s.atkcost)
	e3:SetOperation(s.atkop)
	c:RegisterEffect(e3)

	-- Durant VOTRE End Phase :
	-- défausser 1 -> attacher 1 Queentwins depuis le Deck
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_PHASE+PHASE_END)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id+100)
	e4:SetCondition(s.epcon)
	e4:SetCost(s.ovcost)
	e4:SetTarget(s.ovtg)
	e4:SetOperation(s.ovop)
	c:RegisterEffect(e4)
end

-- ==========================================
-- MATÉRIAUX XYZ
-- ==========================================
function s.mfilter(c,sc,sumtype,tp)
	return c:IsSetCard(0xd44,sc,sumtype,tp)
		or c:IsOriginalSetCard(0xd44)
end

-- ==========================================
-- EFFET 1 : +200 ATK PAR MATÉRIEL
-- ==========================================
function s.atkval(e,c)
	return c:GetOverlayCount()*200
end

-- ==========================================
-- EFFET 2 : IMMUNITÉ
-- ==========================================
function s.immcon(e)
	return e:GetHandler():GetOverlayCount()>0
end

function s.efilter(e,te)
	local tc=te:GetHandler()

	if not te:IsActiveType(TYPE_MONSTER) then
		return false
	end

	if not tc
		or not tc:IsLocation(LOCATION_MZONE)
		or tc:GetControler()==e:GetHandlerPlayer() then
		return false
	end

	if not te:IsHasProperty(EFFECT_FLAG_CARD_TARGET) then
		return false
	end

	local g=Duel.GetChainInfo(
		0,
		CHAININFO_TARGET_CARDS
	)

	return g
		and g:IsContains(e:GetHandler())
end

-- ==========================================
-- EFFET 3 : COMBAT
-- ==========================================
function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
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

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsFaceup() then
		return
	end

	local ct=Duel.GetFieldGroupCount(
		tp,
		LOCATION_MZONE,
		LOCATION_MZONE
	)

	if ct<=0 then
		return
	end

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(ct*500)
	e1:SetReset(
		RESET_EVENT+
		RESETS_STANDARD+
		RESET_PHASE+
		PHASE_DAMAGE
	)
	c:RegisterEffect(e1)
end

-- ==========================================
-- EFFET 4 : VOTRE END PHASE
-- ==========================================
function s.epcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp
end

function s.disfilter(c)
	return c:IsDiscardable()
end

function s.ovcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.disfilter,
			tp,
			LOCATION_HAND,
			0,
			1,
			nil
		)
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_DISCARD
	)

	local g=Duel.SelectMatchingCard(
		tp,
		s.disfilter,
		tp,
		LOCATION_HAND,
		0,
		1,
		1,
		nil
	)

	Duel.SendtoGrave(
		g,
		REASON_COST+REASON_DISCARD
	)
end

function s.ovfilter(c)
	return (
		c:IsSetCard(0xd44)
		or c:IsOriginalSetCard(0xd44)
	)
		and c:IsType(TYPE_MONSTER)
end

function s.ovtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.ovfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil
		)
	end
end

function s.ovop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsFaceup()
		or not c:IsLocation(LOCATION_MZONE) then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_XMATERIAL
	)

	local g=Duel.SelectMatchingCard(
		tp,
		s.ovfilter,
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
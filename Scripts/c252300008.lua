-- ♪DIABLORCHESTRE♪ - Dansoz
local s,id=GetID()

function s.initial_effect(c)
	-- 1 monstre "♪DIABLORCHESTRE♪"
	c:EnableReviveLimit()
	aux.AddLinkProcedure(c,s.matfilter,1,1)

	-- Vous ne pouvez contrôler qu'1
	c:SetUniqueOnField(1,0,id)

	-- Si vous ne contrôlez pas de DIABLORCHESTRE Niveau/Rang 7 :
	-- bannissez cette carte
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e0:SetCode(EVENT_ADJUST)
	e0:SetRange(LOCATION_MZONE)
	e0:SetOperation(s.selfrmop)
	c:RegisterEffect(e0)

	-- Une fois par tour, lorsqu'une carte/effet adverse est activé :
	-- cibler 1 carte dans son GY ; la bannir
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_CHAINING)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id+100)
	e1:SetCondition(s.rmcon)
	e1:SetTarget(s.rmtg)
	e1:SetOperation(s.rmop)
	c:RegisterEffect(e1)

	-- L'adversaire ne peut pas cibler d'autres monstres avec des attaques
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_SELECT_BATTLE_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(0,LOCATION_MZONE)
	e2:SetValue(s.atlimit)
	c:RegisterEffect(e2)
end

s.listed_series={0xd1f}

-- =========================================
-- LINK
-- =========================================
function s.matfilter(c,lc,st,tp)
	return c:IsSetCard(0xd1f,lc,st,tp)
end

-- =========================================
-- AUTO-BANNISSEMENT
-- =========================================
function s.lv7filter(c)
	return c:IsFaceup()
		and c:IsSetCard(0xd1f)
		and (c:IsLevel(7) or c:IsRank(7))
end

function s.selfrmop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsFaceup()
		or not c:IsLocation(LOCATION_MZONE) then
		return
	end

	if not Duel.IsExistingMatchingCard(
		s.lv7filter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		nil
	) then
		Duel.Remove(
			c,
			POS_FACEUP,
			REASON_EFFECT
		)
	end
end

-- =========================================
-- BANISH DU GY ADVERSE
-- =========================================
function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
end

function s.rmfilter(c)
	return c:IsAbleToRemove()
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(1-tp)
			and chkc:IsLocation(LOCATION_GRAVE)
			and chkc:IsAbleToRemove()
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.rmfilter,
			tp,
			0,
			LOCATION_GRAVE,
			1,
			nil
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

	local g=Duel.SelectTarget(
		tp,
		s.rmfilter,
		tp,
		0,
		LOCATION_GRAVE,
		1,
		1,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_REMOVE,
		g,
		1,
		1-tp,
		LOCATION_GRAVE
	)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if tc
		and tc:IsRelateToEffect(e)
		and tc:IsAbleToRemove() then

		Duel.Remove(
			tc,
			POS_FACEUP,
			REASON_EFFECT
		)
	end
end

-- =========================================
-- PROTECTION DE COMBAT
-- =========================================
function s.atlimit(e,c)
	return c~=e:GetHandler()
end
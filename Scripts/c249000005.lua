-- Universo - Plasma Interdit
local s,id=GetID()

function s.initial_effect(c)
	-- Activation adverse -> negate + banish carte + 1 Extra Deck au hasard
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.negcon)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)
end

s.listed_series={0xc17}

-- =========================================
-- CONTRÔLER AU MOINS 1 LINK UNIVERSO
-- =========================================
function s.lkfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(0xc17)
		and c:IsType(TYPE_LINK)
end

-- =========================================
-- CONDITION
-- =========================================
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	if rp~=1-tp then
		return false
	end

	if not Duel.IsExistingMatchingCard(
		s.lkfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		nil
	) then
		return false
	end

	if re:IsHasType(EFFECT_TYPE_ACTIVATE) then
		return Duel.IsChainNegatable(ev)
	end

	return Duel.IsChainDisablable(ev)
end

-- =========================================
-- TARGET
-- =========================================
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

	Duel.SetOperationInfo(
		0,
		CATEGORY_REMOVE,
		nil,
		1,
		1-tp,
		LOCATION_EXTRA
	)
end

-- =========================================
-- NEGATE + DOUBLE BANISH
-- =========================================
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	local neg=false

	-- Carte activée = negate activation
	if re:IsHasType(EFFECT_TYPE_ACTIVATE) then
		neg=Duel.NegateActivation(ev)
	else
		-- Effet activé = negate effect
		neg=Duel.NegateEffect(ev)
	end

	if not neg then
		return
	end

	-- Bannir la carte annulée
	if rc and rc:IsAbleToRemove() then
		Duel.Remove(
			rc,
			POS_FACEUP,
			REASON_EFFECT
		)
	end

	-- Bannir 1 carte aléatoire de l'Extra Deck adverse
	local ex=Duel.GetFieldGroup(
		tp,
		0,
		LOCATION_EXTRA
	)

	if ex:GetCount()>0 then
		local rg=ex:RandomSelect(
			tp,
			1
		)

		if rg:GetCount()>0 then
			Duel.Remove(
				rg,
				POS_FACEUP,
				REASON_EFFECT
			)
		end
	end
end
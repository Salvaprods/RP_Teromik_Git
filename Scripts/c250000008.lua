-- Défense De Gokvelgr - Âme Du Chasseur
local s,id=GetID()

function s.initial_effect(c)
	-- Effet 1 : révèle depuis le Deck -> negate + bannit
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Effet 2 : bannir du GY -> Special Summon depuis l'Extra
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

-- =========================================
-- EFFET 1
-- =========================================
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and Duel.IsChainNegatable(ev)
end

-- Uniquement depuis le Deck
function s.revfilter(c)
	return c:IsCode(250000002)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.revfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil
		)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_NEGATE,
		eg,
		1,
		0,
		0
	)

	local rc=re:GetHandler()

	if rc and rc:IsAbleToRemove() then
		Duel.SetOperationInfo(
			0,
			CATEGORY_REMOVE,
			rc,
			1,
			0,
			0
		)
	end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	-- Révéler 1 Gokvelgr depuis le Deck
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)

	local g=Duel.SelectMatchingCard(
		tp,
		s.revfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil
	)

	local tc=g:GetFirst()
	if not tc then return end

	Duel.ConfirmCards(1-tp,tc)
	Duel.ShuffleDeck(tp)

	-- Annule l'effet
	if Duel.NegateEffect(ev) then
		local rc=re:GetHandler()

		-- Puis bannit la carte annulée
		if rc
			and rc:IsRelateToEffect(re)
			and rc:IsAbleToRemove() then

			Duel.Remove(
				rc,
				POS_FACEUP,
				REASON_EFFECT
			)
		end
	end

	-- Si activée durant le tour adverse :
	-- peut se Poser directement après résolution
	local c=e:GetHandler()

	if Duel.GetTurnPlayer()~=tp
		and c:IsRelateToEffect(e)
		and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then

		c:CancelToGrave()
		Duel.ChangePosition(c,POS_FACEDOWN)
	end
end

-- =========================================
-- EFFET 2
-- =========================================
function s.spfilter(c,e,tp)
	return c:IsSetCard(0xc92)
		and c:IsCanBeSpecialSummoned(
			e,
			0,
			tp,
			false,
			false
		)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(
				s.spfilter,
				tp,
				LOCATION_EXTRA,
				0,
				1,
				nil,
				e,
				tp
			)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,
		1,
		tp,
		LOCATION_EXTRA
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local g=Duel.SelectMatchingCard(
		tp,
		s.spfilter,
		tp,
		LOCATION_EXTRA,
		0,
		1,
		1,
		nil,
		e,
		tp
	)

	local tc=g:GetFirst()

	if tc then
		Duel.SpecialSummon(
			tc,
			0,
			tp,
			tp,
			false,
			false,
			POS_FACEUP
		)
	end
end
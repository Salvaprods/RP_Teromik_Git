-- ♪DIABLORCHESTRE♪ - Concerto
local s,id=GetID()

function s.initial_effect(c)
	-- Activation : optionnellement ajouter 1 M/P DIABLORCHESTRE
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- +200 ATK par carte DIABLORCHESTRE bannie
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.atktg)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)

	-- Niveau/Rang 7+ non ciblables
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e3:SetRange(LOCATION_FZONE)
	e3:SetTargetRange(LOCATION_MZONE,0)
	e3:SetTarget(s.tgtg)
	e3:SetValue(aux.tgoval)
	c:RegisterEffect(e3)
end

s.listed_series={0xd1f}

-- =========================================
-- ACTIVATION : SEARCH OPTIONNEL
-- =========================================
function s.thfilter(c)
	return c:IsSetCard(0xd1f)
		and c:IsType(TYPE_SPELL+TYPE_TRAP)
		and not c:IsCode(id)
		and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return true
	end
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.IsExistingMatchingCard(
		s.thfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		nil
	) then
		return
	end

	if not Duel.SelectYesNo(
		tp,
		aux.Stringid(id,0)
	) then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)

	local g=Duel.SelectMatchingCard(
		tp,
		s.thfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil
	)

	local tc=g:GetFirst()

	if tc
		and Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 then

		Duel.ConfirmCards(1-tp,tc)
	end
end

-- =========================================
-- BONUS ATK
-- =========================================
function s.atktg(e,c)
	return c:IsFaceup()
		and c:IsSetCard(0xd1f)
		and c:IsType(TYPE_MONSTER)
end

function s.banfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(0xd1f)
end

function s.atkval(e,c)
	local tp=e:GetHandlerPlayer()

	local ct=Duel.GetMatchingGroupCount(
		s.banfilter,
		tp,
		LOCATION_REMOVED,
		0,
		nil
	)

	return ct*200
end

-- =========================================
-- PROTECTION NIVEAU / RANG 7+
-- =========================================
function s.tgtg(e,c)
	return c:IsFaceup()
		and c:IsSetCard(0xd1f)
		and (
			c:IsLevelAbove(7)
			or c:GetRank()>=7
		)
end
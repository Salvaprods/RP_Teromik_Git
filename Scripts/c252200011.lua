-- Transformage - Tornade d'Elements
local s,id=GetID()

function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end

-- Contrôler un Fusion "Transformage"
function s.fusfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(0x6e7)
		and c:IsType(TYPE_FUSION)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(
		s.fusfilter,tp,LOCATION_MZONE,0,1,nil
	)
end

-- =========================================
-- OPTION 1 : HESTIAROS
-- =========================================
function s.hestfilter(c,e,tp)
	return c:IsCode(252200000)
		and (
			c:IsAbleToHand()
			or (
				Duel.GetLocationCount(tp,LOCATION_MZONE)>0
				and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
			)
		)
end

function s.canop1(e,tp)
	return Duel.IsExistingMatchingCard(
		s.hestfilter,tp,LOCATION_DECK,0,1,nil,e,tp
	)
end

-- =========================================
-- OPTION 2 : DESTRUCTION SELON ATTRIBUTS
-- =========================================
function s.attrfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(0x6e7)
		and c:IsType(TYPE_MONSTER)
end

function s.getattrcount(tp)
	local g=Duel.GetMatchingGroup(
		s.attrfilter,tp,LOCATION_MZONE,0,nil
	)
	return g:GetClassCount(Card.GetAttribute)
end

function s.desfilter(c)
	return c:IsDestructable()
end

function s.canop2(tp)
	return s.getattrcount(tp)>0
		and Duel.IsExistingMatchingCard(
			s.desfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil
		)
end

-- =========================================
-- CHOIX
-- =========================================
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1=s.canop1(e,tp)
	local b2=s.canop2(tp)

	if chk==0 then
		return b1 or b2
	end

	local op
	if b1 and b2 then
		op=Duel.SelectOption(
			tp,
			aux.Stringid(id,1), -- Hestiaros
			aux.Stringid(id,2)  -- Détruire
		)
	elseif b1 then
		op=0
	else
		op=1
	end

	e:SetLabel(op)

	if op==0 then
		Duel.SetOperationInfo(
			0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK
		)
	else
		local ct=s.getattrcount(tp)
		local g=Duel.GetMatchingGroup(
			s.desfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil
		)
		Duel.SetOperationInfo(
			0,CATEGORY_DESTROY,g,math.min(ct,g:GetCount()),0,0
		)
	end
end

-- =========================================
-- RÉSOLUTION
-- =========================================
function s.operation(e,tp,eg,ep,ev,re,r,rp)

	-- OPTION 1 : Hestiaros
	if e:GetLabel()==0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)

		local g=Duel.SelectMatchingCard(
			tp,s.hestfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp
		)

		local tc=g:GetFirst()
		if not tc then return end

		local b1=tc:IsAbleToHand()
		local b2=Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and tc:IsCanBeSpecialSummoned(e,0,tp,false,false)

		local op=0

		if b1 and b2 then
			op=Duel.SelectOption(
				tp,
				aux.Stringid(id,3), -- Ajouter
				aux.Stringid(id,4)  -- Invoquer Spécialement
			)
		elseif b2 then
			op=1
		end

		if op==0 then
			if Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 then
				Duel.ConfirmCards(1-tp,tc)
			end
		else
			Duel.SpecialSummon(
				tc,0,tp,tp,false,false,POS_FACEUP
			)
		end

	-- OPTION 2 : destruction
	else
		local ct=s.getattrcount(tp)
		if ct<=0 then return end

		local g=Duel.GetMatchingGroup(
			s.desfilter,
			tp,
			LOCATION_ONFIELD,
			LOCATION_ONFIELD,
			nil
		)

		if g:GetCount()==0 then return end

		local max=math.min(ct,g:GetCount())

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)

		local sg=g:Select(
			tp,
			1,
			max,
			nil
		)

		if sg:GetCount()>0 then
			Duel.Destroy(sg,REASON_EFFECT)
		end
	end
end
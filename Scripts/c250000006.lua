-- Esprit De Souffrada - Âme Du Chasseur
local s,id=GetID()

function s.initial_effect(c)
	-- 1 monstre non-Lien "Âme Du Chasseur"
	c:EnableReviveLimit()
	aux.AddLinkProcedure(c,s.matfilter,1,1)

	-- Invoqué par Lien -> chercher 1 Magie/Piège
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.lkcon)
	e1:SetTarget(s.lktg)
	e1:SetOperation(s.lkop)
	c:RegisterEffect(e1)

	-- Envoyé au GY -> révéler 1 Âme Du Chasseur + payer 1000 LP
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY+CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetCost(s.gycost)
	e2:SetTarget(s.gytg)
	e2:SetOperation(s.gyop)
	c:RegisterEffect(e2)
end

s.listed_series={0xc92}

-- =========================================
-- LINK
-- =========================================
function s.matfilter(c,lc,st,tp)
	return c:IsSetCard(0xc92,lc,st,tp)
		and not c:IsType(TYPE_LINK,lc,st,tp)
end

-- =========================================
-- EFFET 1 : SEARCH M/P
-- =========================================
function s.lkcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

function s.lkfilter(c)
	return c:IsSetCard(0xc92)
		and c:IsType(TYPE_SPELL+TYPE_TRAP)
		and c:IsAbleToHand()
end

function s.lktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.lkfilter,tp,LOCATION_DECK,0,1,nil
		)
	end

	Duel.SetOperationInfo(
		0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK
	)
end

function s.lkop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)

	local g=Duel.SelectMatchingCard(
		tp,s.lkfilter,tp,LOCATION_DECK,0,1,1,nil
	)

	if g:GetCount()>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- =========================================
-- EFFET 2 : RÉVÉLER + PAYER 1000
-- =========================================
function s.revfilter(c,tp)
	if not c:IsSetCard(0xc92)
		or c:IsPublic() then
		return false
	end

	-- Monstre -> il faut pouvoir détruire une carte
	if c:IsType(TYPE_MONSTER) then
		return Duel.IsExistingMatchingCard(
			Card.IsDestructable,
			tp,
			LOCATION_ONFIELD,
			LOCATION_ONFIELD,
			1,
			nil
		)
	end

	-- Magie -> il faut pouvoir bannir une carte
	if c:IsType(TYPE_SPELL) then
		return Duel.IsExistingMatchingCard(
			Card.IsAbleToRemove,
			tp,
			LOCATION_ONFIELD,
			LOCATION_ONFIELD,
			1,
			nil
		)
	end

	return false
end

function s.gycost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.CheckLPCost(tp,1000)
			and Duel.IsExistingMatchingCard(
				s.revfilter,
				tp,
				LOCATION_HAND,
				0,
				1,
				nil,
				tp
			)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)

	local g=Duel.SelectMatchingCard(
		tp,
		s.revfilter,
		tp,
		LOCATION_HAND,
		0,
		1,
		1,
		nil,
		tp
	)

	local tc=g:GetFirst()
	if not tc then return end

	if tc:IsType(TYPE_MONSTER) then
		e:SetLabel(1)
	else
		e:SetLabel(2)
	end

	Duel.ConfirmCards(1-tp,tc)
	Duel.PayLPCost(tp,1000)
end

function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return true
	end

	if e:GetLabel()==1 then
		Duel.SetOperationInfo(
			0,
			CATEGORY_DESTROY,
			nil,
			1,
			PLAYER_ALL,
			LOCATION_ONFIELD
		)
	else
		Duel.SetOperationInfo(
			0,
			CATEGORY_REMOVE,
			nil,
			1,
			PLAYER_ALL,
			LOCATION_ONFIELD
		)
	end
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	-- =====================================
	-- MONSTRE : détruire 1 carte
	-- =====================================
	if e:GetLabel()==1 then
		if not Duel.IsExistingMatchingCard(
			Card.IsDestructable,
			tp,
			LOCATION_ONFIELD,
			LOCATION_ONFIELD,
			1,
			nil
		) then
			return
		end

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)

		local g=Duel.SelectMatchingCard(
			tp,
			Card.IsDestructable,
			tp,
			LOCATION_ONFIELD,
			LOCATION_ONFIELD,
			1,
			1,
			nil
		)

		if g:GetCount()>0 then
			Duel.Destroy(g,REASON_EFFECT)
		end

	-- =====================================
	-- MAGIE : bannir 1 carte
	-- =====================================
	else
		if not Duel.IsExistingMatchingCard(
			Card.IsAbleToRemove,
			tp,
			LOCATION_ONFIELD,
			LOCATION_ONFIELD,
			1,
			nil
		) then
			return
		end

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

		local g=Duel.SelectMatchingCard(
			tp,
			Card.IsAbleToRemove,
			tp,
			LOCATION_ONFIELD,
			LOCATION_ONFIELD,
			1,
			1,
			nil
		)

		if g:GetCount()>0 then
			Duel.Remove(
				g,
				POS_FACEUP,
				REASON_EFFECT
			)
		end
	end
end
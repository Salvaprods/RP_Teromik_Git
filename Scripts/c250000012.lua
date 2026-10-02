-- Hrafnketillhrouf - Âme Du Chasseur
local s,id=GetID()

function s.initial_effect(c)
	-- Révéler cette carte + 1 autre "Âme Du Chasseur"
	-- choisir directement celle à Invoquer, mélanger l'autre
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Si envoyée au Cimetière : bannir 1 carte face recto adverse
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,id+100)
	e2:SetTarget(s.rmtg)
	e2:SetOperation(s.rmop)
	c:RegisterEffect(e2)

	-- Si bannie : s'Invoquer Spécialement
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_REMOVE)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1,id+200)
	e3:SetTarget(s.selftg)
	e3:SetOperation(s.selfop)
	c:RegisterEffect(e3)
end

-- =========================================
-- EFFET 1
-- =========================================
function s.handfilter(c,e,tp,self)
	if c==self
		or not c:IsSetCard(0xc92)
		or not c:IsType(TYPE_MONSTER) then
		return false
	end

	return
		(self:IsCanBeSpecialSummoned(e,0,tp,false,false)
			and c:IsAbleToDeck())
		or
		(c:IsCanBeSpecialSummoned(e,0,tp,false,false)
			and self:IsAbleToDeck())
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(
				s.handfilter,
				tp,
				LOCATION_HAND,
				0,
				1,
				c,
				e,
				tp,
				c
			)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)

	local g=Duel.SelectMatchingCard(
		tp,
		s.handfilter,
		tp,
		LOCATION_HAND,
		0,
		1,
		1,
		c,
		e,
		tp,
		c
	)

	local tc=g:GetFirst()

	if tc then
		local rg=Group.FromCards(c,tc)
		Duel.ConfirmCards(1-tp,rg)
		e:SetLabelObject(tc)
	end
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,
		1,
		tp,
		LOCATION_HAND
	)
end

-- Vérifie laquelle des 2 cartes peut être choisie pour être invoquée
function s.pickfilter(sc,e,tp,c,tc)
	local dc

	if sc==c then
		dc=tc
	else
		dc=c
	end

	return sc:IsCanBeSpecialSummoned(
		e,
		0,
		tp,
		false,
		false
	)
		and dc:IsAbleToDeck()
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=e:GetLabelObject()

	if not tc
		or Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return
	end

	if not c:IsLocation(LOCATION_HAND)
		or not tc:IsLocation(LOCATION_HAND) then
		return
	end

	-- Les 2 cartes révélées
	local g=Group.FromCards(c,tc)

	-- Parmi elles, celles qu'on peut légalement Invoquer
	local sg=g:Filter(
		s.pickfilter,
		nil,
		e,
		tp,
		c,
		tc
	)

	if sg:GetCount()==0 then
		return
	end

	-- Choisir DIRECTEMENT la carte à Invoquer Spécialement
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local sc=sg:Select(
		tp,
		1,
		1,
		nil
	):GetFirst()

	if not sc then return end

	-- L'autre carte sera mélangée dans le Deck
	local dc

	if sc==c then
		dc=tc
	else
		dc=c
	end

	if Duel.SpecialSummon(
		sc,
		0,
		tp,
		tp,
		false,
		false,
		POS_FACEUP
	)>0 then

		Duel.SendtoDeck(
			dc,
			nil,
			SEQ_DECKSHUFFLE,
			REASON_EFFECT
		)
	end
end

-- =========================================
-- EFFET 2 : SI ENVOYÉE AU CIMETIÈRE
-- =========================================
function s.rmfilter(c)
	return c:IsFaceup()
		and c:IsAbleToRemove()
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(1-tp)
			and chkc:IsLocation(LOCATION_ONFIELD)
			and s.rmfilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.rmfilter,
			tp,
			0,
			LOCATION_ONFIELD,
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
		LOCATION_ONFIELD,
		1,
		1,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_REMOVE,
		g,
		1,
		0,
		0
	)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if tc
		and tc:IsRelateToEffect(e)
		and tc:IsFaceup() then

		Duel.Remove(
			tc,
			POS_FACEUP,
			REASON_EFFECT
		)
	end
end

-- =========================================
-- EFFET 3 : SI BANNIE
-- =========================================
function s.selftg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(
				e,
				0,
				tp,
				false,
				false
			)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		c,
		1,
		tp,
		LOCATION_REMOVED
	)
end

function s.selfop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if c:IsRelateToEffect(e)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then

		Duel.SpecialSummon(
			c,
			0,
			tp,
			tp,
			false,
			false,
			POS_FACEUP
		)
	end
end
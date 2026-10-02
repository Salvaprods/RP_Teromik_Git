-- Transformage - Hestombre L'Inciniéré
local s,id=GetID()

function s.initial_effect(c)
	-- Fusion : "Transformage - Hestiaros" + 1 monstre "Transformage"
	aux.AddFusionProcMix(
		c,
		false,
		true,
		aux.FilterBoolFunction(Card.IsFusionCode,252200000),
		aux.FilterBoolFunction(Card.IsFusionSetCard,0x6e7)
	)
	c:EnableReviveLimit()

	-- Si Invoquée Spécialement : choisissez 1 effet
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.eftg)
	e1:SetOperation(s.efop)
	c:RegisterEffect(e1)

	-- Si envoyée du Terrain au Cimetière
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,3))
	e2:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

-- ==========================================
-- OPTION 1
-- Révéler Hestiaros puis bannir les cartes
-- dans la colonne de HESTOMBRE
-- ==========================================
function s.hestfilter(c)
	return c:IsCode(252200000)
		and (
			c:IsLocation(LOCATION_HAND)
			or c:IsFaceup()
		)
end

function s.canoption1(tp)
	return Duel.IsExistingMatchingCard(
		s.hestfilter,
		tp,
		LOCATION_HAND+LOCATION_MZONE+LOCATION_REMOVED,
		0,
		1,
		nil
	)
end

function s.colfilter(c)
	return c:IsAbleToRemove()
end

-- ==========================================
-- OPTION 2
-- ==========================================
function s.tgfilter(c)
	return c:IsSetCard(0x6e7)
		and c:IsType(TYPE_MONSTER)
		and c:IsAbleToGrave()
end

function s.canoption2(tp)
	return Duel.IsExistingMatchingCard(
		s.tgfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		nil
	)
end

-- ==========================================
-- CHOIX
-- ==========================================
function s.eftg(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1=s.canoption1(tp)
	local b2=s.canoption2(tp)

	if chk==0 then
		return b1 or b2
	end

	local op

	if b1 and b2 then
		op=Duel.SelectOption(
			tp,
			aux.Stringid(id,1),
			aux.Stringid(id,2)
		)
	elseif b1 then
		op=0
	else
		op=1
	end

	e:SetLabel(op)
end

-- ==========================================
-- RÉSOLUTION
-- ==========================================
function s.efop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	-- ======================================
	-- OPTION 1
	-- ======================================
	if e:GetLabel()==0 then
		if not c:IsRelateToEffect(e)
			or not c:IsLocation(LOCATION_MZONE) then
			return
		end

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)

		local g=Duel.SelectMatchingCard(
			tp,
			s.hestfilter,
			tp,
			LOCATION_HAND+LOCATION_MZONE+LOCATION_REMOVED,
			0,
			1,
			1,
			nil
		)

		local tc=g:GetFirst()

		if not tc then
			return
		end

		-- Révèle Hestiaros.
		-- S'il est déjà face recto sur le Terrain/banni,
		-- aucune action supplémentaire n'est nécessaire.
		if tc:IsLocation(LOCATION_HAND) then
			Duel.ConfirmCards(1-tp,tc)
		end

		-- IMPORTANT :
		-- On prend la colonne de HESTOMBRE, pas celle de Hestiaros.
		-- Une carte en main ou bannie n'a pas de colonne.
		local cg=c:GetColumnGroup()

		if cg then
			cg=cg:Filter(
				s.colfilter,
				nil
			)

			if cg:GetCount()>0 then
				Duel.Remove(
					cg,
					POS_FACEUP,
					REASON_EFFECT
				)
			end
		end

	-- ======================================
	-- OPTION 2
	-- ======================================
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)

		local g=Duel.SelectMatchingCard(
			tp,
			s.tgfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			1,
			nil
		)

		local tc=g:GetFirst()

		if not tc then
			return
		end

		if Duel.SendtoGrave(tc,REASON_EFFECT)==0 then
			return
		end

		-- Regarde la carte du dessus du Deck adverse
		local dg=Duel.GetDecktopGroup(1-tp,1)

		if not dg or dg:GetCount()==0 then
			return
		end

		Duel.ConfirmCards(tp,dg)

		local dc=dg:GetFirst()

		if dc
			and dc:IsAbleToRemove()
			and Duel.SelectYesNo(tp,aux.Stringid(id,4)) then

			Duel.Remove(
				dc,
				POS_FACEUP,
				REASON_EFFECT
			)
		end
	end
end

-- ==========================================
-- SI ENVOYÉE DU TERRAIN AU CIMETIÈRE
-- ==========================================
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_MZONE)
end

function s.hestdeckfilter(c)
	return c:IsCode(252200000)
		and c:IsAbleToGrave()
end

function s.otherfilter(c)
	return c:IsSetCard(0x6e7)
		and c:IsType(TYPE_MONSTER)
		and not c:IsCode(252200000)
		and c:IsAbleToGrave()
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
			and Duel.IsExistingMatchingCard(
				s.hestdeckfilter,
				tp,
				LOCATION_DECK,
				0,
				1,
				nil
			)
			and Duel.IsExistingMatchingCard(
				s.otherfilter,
				tp,
				LOCATION_DECK,
				0,
				1,
				nil
			)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOGRAVE,
		nil,
		2,
		tp,
		LOCATION_DECK
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		c,
		1,
		tp,
		LOCATION_GRAVE
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsRelateToEffect(e) then
		return
	end

	-- Hestiaros
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)

	local g1=Duel.SelectMatchingCard(
		tp,
		s.hestdeckfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil
	)

	if g1:GetCount()==0 then
		return
	end

	-- 1 autre monstre Transformage
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)

	local g2=Duel.SelectMatchingCard(
		tp,
		s.otherfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil
	)

	if g2:GetCount()==0 then
		return
	end

	g1:Merge(g2)

	if Duel.SendtoGrave(g1,REASON_EFFECT)~=2 then
		return
	end

	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return
	end

	if Duel.SpecialSummon(
		c,
		0,
		tp,
		tp,
		false,
		false,
		POS_FACEUP
	)>0 then

		-- Bannissez cette carte lorsqu'elle quitte le Terrain
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_REDIRECT)
		e1:SetValue(LOCATION_REMOVED)
		c:RegisterEffect(e1,true)
	end
end
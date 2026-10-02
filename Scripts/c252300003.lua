-- ♪DIABLORCHESTRE♪ - Cratzz
local s,id=GetID()

function s.initial_effect(c)
	-- Xyz : 2 monstres "DIABLORCHESTRE" Niveau 3
	aux.AddXyzProcedure(c,s.xyzfilter,3,2)
	c:EnableReviveLimit()

	-- Xyz Summon : détacher X -> envoyer X noms différents du Deck
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.tgcon)
	e1:SetCost(s.tgcost)
	e1:SetOperation(s.tgop)
	c:RegisterEffect(e1)

	-- Special Summon depuis le GY :
	-- retourne dans Extra -> prend contrôle
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOEXTRA+CATEGORY_CONTROL)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.ctcon)
	e2:SetTarget(s.cttg)
	e2:SetOperation(s.ctop)
	c:RegisterEffect(e2)

	-- Envoyée au GY : détruire 1 monstre adverse
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetCountLimit(1,id+200)
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)
end

-- =========================================
-- XYZ
-- =========================================
function s.xyzfilter(c)
	return c:IsSetCard(0xd1f)
end

-- =========================================
-- EFFET 1
-- =========================================
function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end

function s.deckfilter(c)
	return c:IsSetCard(0xd1f)
		and c:IsType(TYPE_MONSTER)
		and c:IsAbleToGrave()
end

function s.tgcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	local dg=Duel.GetMatchingGroup(
		s.deckfilter,
		tp,
		LOCATION_DECK,
		0,
		nil
	)

	-- Maximum selon :
	-- nombre de Matériels + nombre de noms différents dans le Deck
	local max=math.min(
		c:GetOverlayCount(),
		dg:GetClassCount(Card.GetCode)
	)

	if chk==0 then
		return max>0
			and c:CheckRemoveOverlayCard(
				tp,
				1,
				REASON_COST
			)
	end

	-- Omega te fait DIRECTEMENT sélectionner
	-- entre 1 et max Matériels à détacher
	local ct=c:RemoveOverlayCard(
		tp,
		1,
		max,
		REASON_COST
	)

	e:SetLabel(ct)
end

-- Empêche de sélectionner 2 fois le même nom
function s.diffilter(c,sg)
	if not s.deckfilter(c) then
		return false
	end

	local tc=sg:GetFirst()

	while tc do
		if c:IsCode(tc:GetCode()) then
			return false
		end

		tc=sg:GetNext()
	end

	return true
end

function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	local ct=e:GetLabel()

	if ct<=0 then
		return
	end

	local sg=Group.CreateGroup()

	for i=1,ct do
		local g=Duel.GetMatchingGroup(
			s.diffilter,
			tp,
			LOCATION_DECK,
			0,
			nil,
			sg
		)

		if g:GetCount()==0 then
			return
		end

		Duel.Hint(
			HINT_SELECTMSG,
			tp,
			HINTMSG_TOGRAVE
		)

		local tc=g:Select(
			tp,
			1,
			1,
			nil
		):GetFirst()

		if not tc then
			return
		end

		sg:AddCard(tc)
	end

	if sg:GetCount()==ct then
		Duel.SendtoGrave(
			sg,
			REASON_EFFECT
		)
	end
end

-- =========================================
-- EFFET 2
-- SPECIAL SUMMON DEPUIS LE CIMETIÈRE
-- =========================================
function s.ctcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(
		LOCATION_GRAVE
	)
end

function s.ctfilter(c)
	return c:IsFaceup()
end

function s.cttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(1-tp)
			and chkc:IsLocation(LOCATION_MZONE)
			and chkc:IsFaceup()
	end

	if chk==0 then
		return e:GetHandler():IsAbleToExtra()
			and Duel.IsExistingTarget(
				s.ctfilter,
				tp,
				0,
				LOCATION_MZONE,
				1,
				nil
			)
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_FACEUP
	)

	local g=Duel.SelectTarget(
		tp,
		s.ctfilter,
		tp,
		0,
		LOCATION_MZONE,
		1,
		1,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOEXTRA,
		e:GetHandler(),
		1,
		0,
		0
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_CONTROL,
		g,
		1,
		0,
		0
	)
end

function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()

	if not c:IsRelateToEffect(e)
		or not c:IsAbleToExtra() then
		return
	end

	if Duel.SendtoDeck(
		c,
		nil,
		SEQ_DECKSHUFFLE,
		REASON_EFFECT
	)>0
		and c:IsLocation(LOCATION_EXTRA)
		and tc
		and tc:IsRelateToEffect(e)
		and tc:IsFaceup() then

		Duel.GetControl(
			tc,
			tp,
			PHASE_END,
			1
		)
	end
end

-- =========================================
-- EFFET 3
-- ENVOYÉE AU CIMETIÈRE
-- =========================================
function s.desfilter(c)
	return c:IsType(TYPE_MONSTER)
		and c:IsDestructable()
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(1-tp)
			and chkc:IsLocation(LOCATION_MZONE)
			and s.desfilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.desfilter,
			tp,
			0,
			LOCATION_MZONE,
			1,
			nil
		)
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_DESTROY
	)

	local g=Duel.SelectTarget(
		tp,
		s.desfilter,
		tp,
		0,
		LOCATION_MZONE,
		1,
		1,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_DESTROY,
		g,
		1,
		0,
		0
	)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if tc
		and tc:IsRelateToEffect(e) then

		Duel.Destroy(
			tc,
			REASON_EFFECT
		)
	end
end
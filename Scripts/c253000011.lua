-- Géant Métal Slime☺
local s,id=GetID()

local SET_SLIME=0xc2a

function s.initial_effect(c)
	-- Fusion : 3 monstres "Slime☺"
	c:EnableReviveLimit()
	aux.AddFusionProcFunRep(
		c,
		aux.FilterBoolFunction(Card.IsFusionSetCard,SET_SLIME),
		3,
		true
	)

	-- L'adversaire ne peut pas cibler les AUTRES Slime☺
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.tgtg)
	e1:SetValue(aux.tgoval)
	c:RegisterEffect(e1)

	-- Fusion Summon -> ajouter 1 Slime☺ Deck/GY
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	-- Déclare une attaque -> discard 1 ; +1000 ATK
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_ATKCHANGE)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_ATTACK_ANNOUNCE)
	e3:SetCountLimit(1,id+200)
	e3:SetCost(s.atkcost)
	e3:SetOperation(s.atkop)
	c:RegisterEffect(e3)

	-- Quitte le Terrain -> équiper un monstre adverse
	-- d'1 Slime☺ directement depuis le Deck
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_LEAVE_FIELD)
	e4:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e4:SetCountLimit(1,id+300)
	e4:SetTarget(s.eqtg)
	e4:SetOperation(s.eqop)
	c:RegisterEffect(e4)
end

s.listed_series={SET_SLIME}

-- =========================================
-- PROTECTION DE CIBLAGE
-- =========================================
function s.tgtg(e,c)
	return c~=e:GetHandler()
		and c:IsFaceup()
		and c:IsSetCard(SET_SLIME)
		and c:IsType(TYPE_MONSTER)
end

-- =========================================
-- FUSION SUMMON -> SEARCH DECK / GY
-- =========================================
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

function s.thfilter(c)
	return c:IsSetCard(SET_SLIME)
		and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.thfilter,
			tp,
			LOCATION_DECK+LOCATION_GRAVE,
			0,
			1,
			nil
		)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOHAND,
		nil,
		1,
		tp,
		LOCATION_DECK+LOCATION_GRAVE
	)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)

	local g=Duel.SelectMatchingCard(
		tp,
		s.thfilter,
		tp,
		LOCATION_DECK+LOCATION_GRAVE,
		0,
		1,
		1,
		nil
	)

	local tc=g:GetFirst()

	if tc then
		Duel.SendtoHand(
			tc,
			nil,
			REASON_EFFECT
		)
		Duel.ConfirmCards(1-tp,tc)
	end
end

-- =========================================
-- ATTAQUE -> DISCARD 1 ; +1000 ATK
-- =========================================
function s.disfilter(c)
	return c:IsDiscardable()
end

function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
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

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)

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

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsFaceup()
		or not c:IsRelateToEffect(e) then
		return
	end

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(1000)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	c:RegisterEffect(e1)
end

-- =========================================
-- QUITTE LE TERRAIN -> ÉQUIPER SLIME☺
-- =========================================
function s.targetfilter(c)
	return c:IsFaceup()
end

function s.eqfilter(c)
	return c:IsSetCard(SET_SLIME)
		and c:IsType(TYPE_MONSTER)
		and not c:IsForbidden()
end

function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(1-tp)
			and chkc:IsLocation(LOCATION_MZONE)
			and s.targetfilter(chkc)
	end

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingTarget(
				s.targetfilter,
				tp,
				0,
				LOCATION_MZONE,
				1,
				nil
			)
			and Duel.IsExistingMatchingCard(
				s.eqfilter,
				tp,
				LOCATION_DECK,
				0,
				1,
				nil
			)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)

	Duel.SelectTarget(
		tp,
		s.targetfilter,
		tp,
		0,
		LOCATION_MZONE,
		1,
		1,
		nil
	)
end

function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if not tc
		or not tc:IsRelateToEffect(e)
		or not tc:IsFaceup()
		or Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then
		return
	end

	if not Duel.IsExistingMatchingCard(
		s.eqfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		nil
	) then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)

	local g=Duel.SelectMatchingCard(
		tp,
		s.eqfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil
	)

	local ec=g:GetFirst()

	if not ec then
		return
	end

	if Duel.Equip(
		tp,
		ec,
		tc,
		true
	) then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_EQUIP_LIMIT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetValue(s.eqlimit)
		e1:SetLabelObject(tc)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		ec:RegisterEffect(e1)
	end
end

function s.eqlimit(e,c)
	return c==e:GetLabelObject()
end
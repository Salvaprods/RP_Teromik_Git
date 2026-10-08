-- Mine Rouge Slime☺
local s,id=GetID()

local SET_SLIME=0xc2a
local TOKEN_SLIME=253000007

function s.initial_effect(c)
	-- Activation du Piège Continu
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-- Défausser 1 carte -> Invoquer 1 Jeton Slime☺
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(1,id+100)
	e1:SetCost(s.tkcost)
	e1:SetTarget(s.tktg)
	e1:SetOperation(s.tkop)
	c:RegisterEffect(e1)

	-- Contrôle Slime☺ -> envoyer cette carte au GY
	-- puis équiper un monstre adverse depuis le Deck
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_SZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,id+200)
	e2:SetCondition(s.eqcon)
	e2:SetCost(s.eqcost)
	e2:SetTarget(s.eqtg)
	e2:SetOperation(s.eqop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_SLIME}
s.listed_names={TOKEN_SLIME}

-- =========================================
-- EFFET 1 : DÉFAUSSER -> TOKEN
-- =========================================
function s.disfilter(c)
	return c:IsDiscardable()
end

function s.tkcost(e,tp,eg,ep,ev,re,r,rp,chk)
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

function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsPlayerCanSpecialSummonMonster(
				tp,
				TOKEN_SLIME,
				SET_SLIME,
				TYPE_TOKEN,
				0,
				0,
				1,
				RACE_AQUA,
				ATTRIBUTE_WATER
			)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,
		1,
		tp,
		0
	)
end

function s.tkop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return
	end

	if not Duel.IsPlayerCanSpecialSummonMonster(
		tp,
		TOKEN_SLIME,
		SET_SLIME,
		TYPE_TOKEN,
		0,
		0,
		1,
		RACE_AQUA,
		ATTRIBUTE_WATER
	) then
		return
	end

	local token=Duel.CreateToken(
		tp,
		TOKEN_SLIME
	)

	Duel.SpecialSummon(
		token,
		0,
		tp,
		tp,
		false,
		false,
		POS_FACEUP_DEFENSE
	)
end

-- =========================================
-- EFFET 2 : ÉQUIPER DEPUIS LE DECK
-- =========================================
function s.slimefilter(c)
	return c:IsFaceup()
		and c:IsSetCard(SET_SLIME)
		and c:IsType(TYPE_MONSTER)
end

function s.eqcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(
		s.slimefilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		nil
	)
end

-- Envoyer Mine Rouge Slime☺ au GY comme coût
function s.eqcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsAbleToGraveAsCost()
	end

	Duel.SendtoGrave(
		c,
		REASON_COST
	)
end

function s.eqfilter(c)
	return c:IsSetCard(SET_SLIME)
		and c:IsType(TYPE_MONSTER)
		and not c:IsForbidden()
end

function s.targetfilter(c)
	return c:IsFaceup()
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
		local e1=Effect.CreateEffect(ec)
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
-- Roi Slime☺
local s,id=GetID()

local SET_SLIME=0xc2a

function s.initial_effect(c)
	-- Invoqué Normalement ou Spécialement -> chercher 1 M/P "Slime☺"
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)

	-- Monstre équipé : +300 ATK
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_EQUIP)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetValue(300)
	c:RegisterEffect(e3)

	-- Monstre équipé : +300 DEF
	local e4=e3:Clone()
	e4:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e4)

	-- Lorsque le monstre équipé active un effet :
	-- défausser 1 carte, sinon negate
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e5:SetCode(EVENT_CHAINING)
	e5:SetRange(LOCATION_SZONE)
	e5:SetCondition(s.discon)
	e5:SetOperation(s.disop)
	c:RegisterEffect(e5)
end

s.listed_series={SET_SLIME}

-- =========================================
-- SEARCH MAGIE/PIÈGE SLIME☺
-- =========================================
function s.thfilter(c)
	return c:IsSetCard(SET_SLIME)
		and c:IsType(TYPE_SPELL+TYPE_TRAP)
		and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.thfilter,
			tp,
			LOCATION_DECK,
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
		LOCATION_DECK
	)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
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
-- EFFET DU MONSTRE ÉQUIPÉ
-- =========================================
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local ec=c:GetEquipTarget()

	return ec
		and ec:IsFaceup()
		and re:GetHandler()==ec
		and rp==ec:GetControler()
end

function s.disfilter(c)
	return c:IsDiscardable()
end

function s.disop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local ec=c:GetEquipTarget()

	if not ec then
		return
	end

	local p=ec:GetControler()

	-- Si le contrôleur peut défausser, il doit le faire
	if Duel.IsExistingMatchingCard(
		s.disfilter,
		p,
		LOCATION_HAND,
		0,
		1,
		nil
	) then

		Duel.Hint(
			HINT_SELECTMSG,
			p,
			HINTMSG_DISCARD
		)

		local g=Duel.SelectMatchingCard(
			p,
			s.disfilter,
			p,
			LOCATION_HAND,
			0,
			1,
			1,
			nil
		)

		Duel.SendtoGrave(
			g,
			REASON_EFFECT+REASON_DISCARD
		)

	-- Sinon l'effet activé est annulé
	else
		Duel.NegateEffect(ev)
	end
end
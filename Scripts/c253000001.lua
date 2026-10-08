-- Prisonnier Slime☺
local s,id=GetID()

local SET_SLIME=0xc2a
local TOKEN_SLIME=253000007

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- Ni Invocable Normalement ni Posable
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_CANNOT_SUMMON)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	c:RegisterEffect(e0)

	local e0b=e0:Clone()
	e0b:SetCode(EFFECT_CANNOT_MSET)
	c:RegisterEffect(e0b)

	-- Doit d'abord être SS depuis la main en Sacrifiant 1 Jeton Slime☺
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id+100)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Si Invoquée Spécialement -> créer 1 Jeton Slime☺
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCountLimit(1,id+200)
	e2:SetTarget(s.tktg)
	e2:SetOperation(s.tkop)
	c:RegisterEffect(e2)

	-- Main Phase Quick :
	-- Sacrifier 1 Token -> équiper un monstre adverse
	-- avec 1 Slime☺ depuis le Deck
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCountLimit(1,id+300)
	e3:SetCondition(s.eqcon)
	e3:SetCost(s.eqcost)
	e3:SetTarget(s.eqtg)
	e3:SetOperation(s.eqop)
	c:RegisterEffect(e3)
end

s.listed_series={SET_SLIME}
s.listed_names={TOKEN_SLIME}

-- =========================================
-- INVOCATION SPÉCIALE DEPUIS LA MAIN
-- =========================================
function s.tokenfilter(c)
	return c:IsFaceup()
		and c:IsCode(TOKEN_SLIME)
		and c:IsReleasable()
end

function s.spcon(e,c)
	if c==nil then return true end

	local tp=c:GetControler()

	return Duel.GetLocationCount(tp,LOCATION_MZONE)>-1
		and Duel.IsExistingMatchingCard(
			s.tokenfilter,
			tp,
			LOCATION_MZONE,
			0,
			1,
			nil
		)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)

	local g=Duel.SelectMatchingCard(
		tp,
		s.tokenfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		1,
		nil
	)

	if g:GetCount()==0 then
		return false
	end

	g:KeepAlive()
	e:SetLabelObject(g)
	return true
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()

	if g then
		Duel.Release(
			g,
			REASON_COST
		)
		g:DeleteGroup()
	end
end

-- =========================================
-- SI INVOQUÉE SPÉCIALEMENT -> TOKEN
-- =========================================
function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(
			tp,
			LOCATION_MZONE
		)>0
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
	if Duel.GetLocationCount(
		tp,
		LOCATION_MZONE
	)<=0 then
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
-- QUICK EFFECT : MAIN PHASE
-- =========================================
function s.eqcon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()

	return ph==PHASE_MAIN1
		or ph==PHASE_MAIN2
end

-- Sacrifier 1 Jeton Slime☺
function s.costfilter(c)
	return c:IsFaceup()
		and c:IsCode(TOKEN_SLIME)
		and c:IsReleasable()
end

function s.eqcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.costfilter,
			tp,
			LOCATION_MZONE,
			0,
			1,
			nil
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)

	local g=Duel.SelectMatchingCard(
		tp,
		s.costfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		1,
		nil
	)

	Duel.Release(
		g,
		REASON_COST
	)
end

-- =========================================
-- ÉQUIPER DEPUIS LE DECK
-- =========================================
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
		-- Le Slime☺ ne peut rester équipé qu'au monstre ciblé
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
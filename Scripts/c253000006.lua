-- Slifur, Le Dragon Bleu Slime☺
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

	-- SS depuis la main :
	-- 2 Jetons Slime☺ OU 1 Jeton + 1 Slime☺
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Jusqu'à 2 fois par tour :
	-- adversaire SS exactement 1 monstre -> -2000 ATK
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(2,id+100)
	e2:SetCondition(s.atkcon)
	e2:SetTarget(s.atktg)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)

	-- Vous ne pouvez contrôler qu'1
	c:SetUniqueOnField(1,0,id)
end

s.listed_series={SET_SLIME}
s.listed_names={TOKEN_SLIME}

-- =========================================
-- INVOCATION SPÉCIALE
-- =========================================
function s.tokenfilter(c)
	return c:IsFaceup()
		and c:IsCode(TOKEN_SLIME)
		and c:IsReleasable()
end

function s.slimefilter(c)
	return c:IsFaceup()
		and c:IsSetCard(SET_SLIME)
		and c:IsType(TYPE_MONSTER)
		and not c:IsCode(TOKEN_SLIME)
		and c:IsReleasable()
end

function s.spcon(e,c)
	if c==nil then return true end

	local tp=c:GetControler()

	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=-2 then
		return false
	end

	local tk=Duel.GetMatchingGroupCount(
		s.tokenfilter,
		tp,
		LOCATION_MZONE,
		0,
		nil
	)

	-- 2 Jetons
	if tk>=2 then
		return true
	end

	-- 1 Jeton + 1 Slime☺
	return tk>=1
		and Duel.IsExistingMatchingCard(
			s.slimefilter,
			tp,
			LOCATION_MZONE,
			0,
			1,
			nil
		)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)

	-- Premier matériel = obligatoirement 1 Jeton
	local g1=Duel.SelectMatchingCard(
		tp,
		s.tokenfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		1,
		nil
	)

	local tk=g1:GetFirst()
	if not tk then
		return false
	end

	-- Deuxième matériel =
	-- autre Jeton OU monstre Slime☺
	local function matfilter(tc)
		return tc~=tk
			and tc:IsFaceup()
			and tc:IsReleasable()
			and (
				tc:IsCode(TOKEN_SLIME)
				or (
					tc:IsSetCard(SET_SLIME)
					and tc:IsType(TYPE_MONSTER)
					and not tc:IsCode(TOKEN_SLIME)
				)
			)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)

	local g2=Duel.SelectMatchingCard(
		tp,
		matfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		1,
		nil
	)

	local tc=g2:GetFirst()
	if not tc then
		return false
	end

	g1:Merge(g2)
	g1:KeepAlive()
	e:SetLabelObject(g1)

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
-- ADVERSAIRE INVOQUE SPÉCIALEMENT
-- EXACTEMENT 1 MONSTRE
-- =========================================
function s.oppfilter(c,tp)
	return c:IsControler(1-tp)
		and c:IsLocation(LOCATION_MZONE)
end

function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	local g=eg:Filter(
		s.oppfilter,
		nil,
		tp
	)

	return g:GetCount()==1
end

-- Mémorise exactement le monstre invoqué
-- sans le cibler
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=eg:Filter(
		s.oppfilter,
		nil,
		tp
	)

	if chk==0 then
		return g:GetCount()==1
	end

	local tc=g:GetFirst()

	if tc then
		e:SetLabelObject(tc)
	end
end

-- =========================================
-- SLIME☺ UTILISABLE COMME ÉQUIPEMENT
-- =========================================
function s.eqfilter(c)
	return c:IsSetCard(SET_SLIME)
		and c:IsType(TYPE_MONSTER)
		and not c:IsForbidden()
end

function s.eqlimit(e,c)
	return c==e:GetLabelObject()
end

-- =========================================
-- -2000 ATK PUIS ÉQUIPEMENT
-- =========================================
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()

	if not tc
		or not tc:IsFaceup()
		or not tc:IsLocation(LOCATION_MZONE)
		or not tc:IsControler(1-tp) then
		return
	end

	local oldatk=tc:GetAttack()

	-- Faire perdre 2000 ATK
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(-2000)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1)

	-- Doit devenir exactement 0 grâce à cet effet
	if oldatk<=0
		or tc:GetAttack()~=0 then
		return
	end

	-- Il faut une Zone M/P libre
	if Duel.GetLocationCount(
		tp,
		LOCATION_SZONE
	)<=0 then
		return
	end

	-- Il faut un Slime☺ Main / Deck
	if not Duel.IsExistingMatchingCard(
		s.eqfilter,
		tp,
		LOCATION_HAND+LOCATION_DECK,
		0,
		1,
		nil
	) then
		return
	end

	-- "vous pouvez l'équiper"
	if not Duel.SelectYesNo(
		tp,
		aux.Stringid(id,1)
	) then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_EQUIP
	)

	local sg=Duel.SelectMatchingCard(
		tp,
		s.eqfilter,
		tp,
		LOCATION_HAND+LOCATION_DECK,
		0,
		1,
		1,
		nil
	)

	local ec=sg:GetFirst()

	if not ec then
		return
	end

	if Duel.Equip(
		tp,
		ec,
		tc,
		true
	) then
		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_EQUIP_LIMIT)
		e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e2:SetValue(s.eqlimit)
		e2:SetLabelObject(tc)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		ec:RegisterEffect(e2)
	end
end
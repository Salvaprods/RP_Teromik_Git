-- Solfachord Beautia
local s,id=GetID()

function s.initial_effect(c)
	-- Link-5 : 2+ monstres "Solfachord"
	c:EnableReviveLimit()
	s.AddLinkProcedure(c)

	-- Solfachord indestructibles par effets
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.indtg)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- +200 ATK par nom différent
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)

	-- À l'Invocation Spéciale :
	-- cibler Link Solfachord GY -> SS -> échanger zones avec Beautia
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetCountLimit(1,id)
	e3:SetTarget(s.mvtg)
	e3:SetOperation(s.mvop)
	c:RegisterEffect(e3)

	-- Negate + banish
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_CHAINING)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id+100)
	e4:SetCondition(s.negcon)
	e4:SetTarget(s.negtg)
	e4:SetOperation(s.negop)
	c:RegisterEffect(e4)
end

-- =========================================
-- LINK CUSTOM
-- =========================================
function s.matfilter(c,lc)
	return c:IsFaceup()
		and c:IsSetCard(0x162)
		and c:IsCanBeLinkMaterial(lc)
end

function s.linkcount(c)
	-- Pendule Solfachord = 1 ou 2
	if c:IsSetCard(0x162)
		and c:IsType(TYPE_PENDULUM) then
		return 1+0x10000*2
	end

	-- Link = 1 ou Link Rating
	if c:IsType(TYPE_LINK)
		and c:GetLink()>1 then
		return 1+0x10000*c:GetLink()
	end

	return 1
end

function s.linkcheck(g,tp,lc,lmat)
	return (not lmat or g:IsContains(lmat))
		and g:CheckWithSumEqual(
			s.linkcount,
			5,
			g:GetCount(),
			g:GetCount()
		)
		and Duel.GetLocationCountFromEx(
			tp,tp,g,lc
		)>0
end

function s.AddLinkProcedure(c)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(1166)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(
		EFFECT_FLAG_CANNOT_DISABLE+
		EFFECT_FLAG_UNCOPYABLE
	)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.linkcon)
	e1:SetTarget(s.linktg)
	e1:SetOperation(s.linkop)
	e1:SetValue(SUMMON_TYPE_LINK)
	c:RegisterEffect(e1)
end

function s.linkcon(e,c,og,lmat,min,max)
	if c==nil then return true end

	if c:IsType(TYPE_PENDULUM)
		and c:IsFaceup() then
		return false
	end

	local tp=c:GetControler()
	local mg

	if og then
		mg=og:Filter(s.matfilter,nil,c)
	else
		mg=Duel.GetMatchingGroup(
			s.matfilter,
			tp,
			LOCATION_MZONE,
			0,
			nil,
			c
		)
	end

	if lmat then
		if not s.matfilter(lmat,c) then
			return false
		end
		mg:AddCard(lmat)
	end

	local minc=2
	local maxc=5

	if min then
		if min>minc then minc=min end
		if max<maxc then maxc=max end
	end

	if minc>maxc then return false end

	return mg:CheckSubGroup(
		s.linkcheck,
		minc,
		maxc,
		tp,
		c,
		lmat
	)
end

function s.linktg(e,tp,eg,ep,ev,re,r,rp,chk,c,og,lmat,min,max)
	local mg

	if og then
		mg=og:Filter(s.matfilter,nil,c)
	else
		mg=Duel.GetMatchingGroup(
			s.matfilter,
			tp,
			LOCATION_MZONE,
			0,
			nil,
			c
		)
	end

	if lmat then
		if not s.matfilter(lmat,c) then
			return false
		end
		mg:AddCard(lmat)
	end

	local minc=2
	local maxc=5

	if min then
		if min>minc then minc=min end
		if max<maxc then maxc=max end
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_LMATERIAL)

	local g=mg:SelectSubGroup(
		tp,
		s.linkcheck,
		Duel.IsSummonCancelable(),
		minc,
		maxc,
		tp,
		c,
		lmat
	)

	if not g then return false end

	g:KeepAlive()
	e:SetLabelObject(g)
	return true
end

function s.linkop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()

	c:SetMaterial(g)

	Duel.SendtoGrave(
		g,
		REASON_MATERIAL+REASON_LINK
	)

	g:DeleteGroup()
end

-- =========================================
-- PROTECTION
-- =========================================
function s.indtg(e,c)
	return c:IsFaceup()
		and c:IsSetCard(0x162)
end

-- =========================================
-- ATK
-- =========================================
function s.atkfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(0x162)
end

function s.atkval(e,c)
	local g=Duel.GetMatchingGroup(
		s.atkfilter,
		c:GetControler(),
		LOCATION_MZONE,
		0,
		nil
	)

	return g:GetClassCount(Card.GetCode)*200
end

-- =========================================
-- INVOCATION -> LINK DU GY
-- =========================================
function s.gyfilter(c)
	return c:IsSetCard(0x162)
		and c:IsType(TYPE_LINK)
end

function s.mvtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_GRAVE)
			and s.gyfilter(chkc)
	end

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingTarget(
				s.gyfilter,
				tp,
				LOCATION_GRAVE,
				0,
				1,
				nil
			)
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_SPSUMMON
	)

	local g=Duel.SelectTarget(
		tp,
		s.gyfilter,
		tp,
		LOCATION_GRAVE,
		0,
		1,
		1,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		g,
		1,
		tp,
		LOCATION_GRAVE
	)
end

function s.mvop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()

	if not c:IsRelateToEffect(e)
		or not c:IsFaceup()
		or not tc
		or not tc:IsRelateToEffect(e) then
		return
	end

	-- Il faut une Main Monster Zone libre
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return
	end

	-- Invoque normalement le Link du GY.
	-- Omega te fait choisir la Main Monster Zone.
	if Duel.SpecialSummon(
		tc,
		0,
		tp,
		tp,
		false,
		false,
		POS_FACEUP_ATTACK
	)==0 then
		return
	end

	-- Échange les zones :
	-- Beautia -> zone choisie lors de la Special Summon
	-- Link -> ancienne EMZ de Beautia
	Duel.SwapSequence(c,tc)
end

-- =========================================
-- NEGATE + BANISH
-- =========================================
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
		and Duel.IsChainDisablable(ev)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end

	Duel.SetOperationInfo(
		0,
		CATEGORY_NEGATE,
		eg,
		1,
		0,
		0
	)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	local neg=false

	if re:IsHasType(EFFECT_TYPE_ACTIVATE) then
		neg=Duel.NegateActivation(ev)
	else
		neg=Duel.NegateEffect(ev)
	end

	if neg
		and rc
		and rc:IsAbleToRemove() then

		Duel.Remove(
			rc,
			POS_FACEUP,
			REASON_EFFECT
		)
	end
end
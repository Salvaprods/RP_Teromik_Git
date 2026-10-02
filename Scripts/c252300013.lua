-- ♪DIABLORCHESTRE♪ - Electro Mic Lucifer
local s,id=GetID()

function s.initial_effect(c)
	-- Fusion : 4 monstres "DIABLORCHESTRE"
	c:EnableReviveLimit()
	aux.AddFusionProcFunRep(c,aux.FilterBoolFunction(Card.IsSetCard,0xd1f),4,true)

	-- +200 ATK/DEF par carte DIABLORCHESTRE bannie
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)

	local e2=e1:Clone()
	e2:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e2)

	-- Non destructible au combat
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e3:SetValue(1)
	c:RegisterEffect(e3)

	-- Si Invoquée Spécialement : payer 1000 LP ;
	-- prendre le contrôle d'1 monstre adverse
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_CONTROL)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	e4:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e4:SetCountLimit(1,id)
	e4:SetCost(s.ctcost)
	e4:SetTarget(s.cttg)
	e4:SetOperation(s.ctop)
	c:RegisterEffect(e4)
end

function s.banfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xd1f)
end

function s.atkval(e,c)
	return Duel.GetMatchingGroupCount(
		s.banfilter,
		c:GetControler(),
		LOCATION_REMOVED,
		0,
		nil
	)*200
end

function s.ctcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,1000) end
	Duel.PayLPCost(tp,1000)
end

function s.ctfilter(c)
	return c:IsFaceup() and c:IsControlerCanBeChanged()
end

function s.cttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(1-tp)
			and chkc:IsLocation(LOCATION_MZONE)
			and s.ctfilter(chkc)
	end
	if chk==0 then
		return Duel.IsExistingTarget(
			s.ctfilter,tp,0,LOCATION_MZONE,1,nil
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
	local g=Duel.SelectTarget(
		tp,s.ctfilter,tp,0,LOCATION_MZONE,1,1,nil
	)
	Duel.SetOperationInfo(0,CATEGORY_CONTROL,g,1,0,0)
end

function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end

	if Duel.GetControl(tc,tp)>0 then
		-- Annule ses effets
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)

		local e2=e1:Clone()
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		tc:RegisterEffect(e2)

		-- Bannissez-le lorsqu'il quitte le Terrain
		local e3=Effect.CreateEffect(e:GetHandler())
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
		e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e3:SetValue(LOCATION_REMOVED)
		e3:SetReset(RESET_EVENT+RESETS_REDIRECT)
		tc:RegisterEffect(e3,true)
	end
end
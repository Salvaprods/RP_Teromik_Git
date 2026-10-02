-- Œil De Souffrada - Âme Du Chasseur
local s,id=GetID()

function s.initial_effect(c)
	-- Activation de la Magie Continue
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-- Effet 1 :
	-- Les monstres adverses perdent 100 ATK
	-- pour chaque monstre "Âme Du Chasseur" que vous contrôlez
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetRange(LOCATION_SZONE)
	e1:SetTargetRange(0,LOCATION_MZONE)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)

	-- Effet 2 :
	-- Durant la Main Phase, ciblez 1 monstre "Âme Du Chasseur" ;
	-- envoyez les 3 cartes du dessus du Deck au Cimetière,
	-- puis il gagne 500 ATK par monstre "Âme Du Chasseur" envoyé
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOGRAVE+CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCondition(s.tgcon)
	e2:SetTarget(s.tgtg)
	e2:SetOperation(s.tgop)
	c:RegisterEffect(e2)
end

-- ==========================================
-- EFFET 1 : PERTE D'ATK
-- ==========================================
function s.atkfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(0xc92)
		and c:IsType(TYPE_MONSTER)
end

function s.atkval(e,c)
	local tp=e:GetHandlerPlayer()

	local ct=Duel.GetMatchingGroupCount(
		s.atkfilter,
		tp,
		LOCATION_MZONE,
		0,
		nil
	)

	return -100*ct
end

-- ==========================================
-- EFFET 2 : MAIN PHASE
-- ==========================================
function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()

	return ph==PHASE_MAIN1
		or ph==PHASE_MAIN2
end

function s.filter(c)
	return c:IsFaceup()
		and c:IsSetCard(0xc92)
		and c:IsType(TYPE_MONSTER)
end

function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_MZONE)
			and s.filter(chkc)
	end

	if chk==0 then
		return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=3
			and Duel.IsExistingTarget(
				s.filter,
				tp,
				LOCATION_MZONE,
				0,
				1,
				nil
			)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)

	Duel.SelectTarget(
		tp,
		s.filter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		1,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOGRAVE,
		nil,
		3,
		tp,
		LOCATION_DECK
	)
end

function s.millfilter(c)
	return c:IsSetCard(0xc92)
		and c:IsType(TYPE_MONSTER)
end

function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)<3 then
		return
	end

	local g=Duel.GetDecktopGroup(tp,3)

	if g:GetCount()<3 then
		return
	end

	Duel.DisableShuffleCheck()

	if Duel.SendtoGrave(g,REASON_EFFECT)==0 then
		return
	end

	local og=Duel.GetOperatedGroup()

	local ct=og:FilterCount(
		s.millfilter,
		nil
	)

	if ct<=0 then
		return
	end

	if not tc
		or not tc:IsRelateToEffect(e)
		or not tc:IsFaceup() then
		return
	end

	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(ct*500)
	e1:SetReset(
		RESET_EVENT+
		RESETS_STANDARD
	)
	tc:RegisterEffect(e1)
end
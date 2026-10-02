-- Légende Kuriboh
local s,id=GetID()

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- Doit d'abord être Invoquée Spécialement par sa propre procédure
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	c:RegisterEffect(e0)

	-- Invocation Spéciale depuis l'Extra Deck :
	-- mélanger 3 monstres "Kuriboh" depuis Main/Terrain/Cimetière
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- L'adversaire ne peut pas cibler cette carte
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(aux.tgoval)
	c:RegisterEffect(e2)

	-- Si Invoquée Spécialement : choisissez 1 effet
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1,id)
	e3:SetTarget(s.efftg)
	e3:SetOperation(s.effop)
	c:RegisterEffect(e3)

	-- Lorsque l'adversaire active un effet de monstre :
	-- annule + détruit + gagne 1000 ATK
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,3))
	e4:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY+CATEGORY_ATKCHANGE)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_CHAINING)
	e4:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id+100)
	e4:SetCondition(s.negcon)
	e4:SetTarget(s.negtg)
	e4:SetOperation(s.negop)
	c:RegisterEffect(e4)
end

-- =========================================================
-- INVOCATION SPÉCIALE DEPUIS L'EXTRA
-- =========================================================

function s.spfilter(c)
	return c:IsSetCard(0xa4)
		and c:IsType(TYPE_MONSTER)
		and c:IsAbleToDeckAsCost()
end

-- Vérifie qu'après avoir mélangé les 3 cartes,
-- une zone est disponible pour le Fusion depuis l'Extra
function s.spcheck(g,tp,sc)
	return Duel.GetLocationCountFromEx(tp,tp,g,sc)>0
end

function s.spcon(e,c)
	if c==nil then
		return true
	end

	local tp=c:GetControler()

	local g=Duel.GetMatchingGroup(
		s.spfilter,
		tp,
		LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE,
		0,
		nil
	)

	return g:CheckSubGroup(
		s.spcheck,
		3,
		3,
		tp,
		c
	)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g=Duel.GetMatchingGroup(
		s.spfilter,
		tp,
		LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE,
		0,
		nil
	)

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)

	local sg=g:SelectSubGroup(
		tp,
		s.spcheck,
		true,
		3,
		3,
		tp,
		c
	)

	if not sg then
		return false
	end

	sg:KeepAlive()
	e:SetLabelObject(sg)

	return true
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()

	if not g then
		return
	end

	-- Enregistre les 3 Kuriboh utilisés
	c:SetMaterial(g)

	-- Révèle ceux sélectionnés depuis la main
	local hg=g:Filter(Card.IsLocation,nil,LOCATION_HAND)

	if hg:GetCount()>0 then
		Duel.ConfirmCards(1-tp,hg)
	end

	-- Mélange les 3 Kuriboh dans le Deck
	Duel.SendtoDeck(
		g,
		nil,
		SEQ_DECKSHUFFLE,
		REASON_COST+REASON_SPSUMMON
	)

	g:DeleteGroup()
end

-- =========================================================
-- NOMBRE DE NOMS DIFFÉRENTS UTILISÉS
-- =========================================================

function s.getnamecount(c)
	local g=c:GetMaterial()

	if not g then
		return 0
	end

	return g:GetClassCount(Card.GetCode)
end

-- =========================================================
-- EFFET À L'INVOCATION
-- =========================================================

function s.rmfilter(c)
	return c:IsAbleToRemove()
end

function s.efftg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local ct=s.getnamecount(c)

	if chk==0 then
		return true
	end

	local canremove=
		ct>0
		and Duel.IsExistingMatchingCard(
			s.rmfilter,
			tp,
			LOCATION_ONFIELD,
			LOCATION_ONFIELD,
			1,
			nil
		)

	local op=0

	if canremove then
		op=Duel.SelectOption(
			tp,
			aux.Stringid(id,1),
			aux.Stringid(id,2)
		)
	end

	e:SetLabel(op)

	if op==1 then
		Duel.SetOperationInfo(
			0,
			CATEGORY_REMOVE,
			nil,
			1,
			0,
			LOCATION_ONFIELD
		)
	end
end

function s.effop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	-- =====================================================
	-- OPTION 1 :
	-- Aucun dommage de combat jusqu'à la fin
	-- de votre prochain tour
	-- =====================================================
	if e:GetLabel()==0 then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_AVOID_BATTLE_DAMAGE)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e1:SetTargetRange(1,0)

		local ct=1

		-- Si activé pendant notre propre tour,
		-- il faut traverser cette End Phase puis la prochaine
		if Duel.GetTurnPlayer()==tp then
			ct=2
		end

		e1:SetReset(
			RESET_PHASE+PHASE_END+RESET_SELF_TURN,
			ct
		)

		Duel.RegisterEffect(e1,tp)

	-- =====================================================
	-- OPTION 2 :
	-- Bannir jusqu'à X cartes,
	-- X = noms différents parmi les 3 Kuriboh utilisés
	-- =====================================================
	else
		local ct=s.getnamecount(c)

		if ct<=0 then
			return
		end

		local g=Duel.GetMatchingGroup(
			s.rmfilter,
			tp,
			LOCATION_ONFIELD,
			LOCATION_ONFIELD,
			nil
		)

		if g:GetCount()==0 then
			return
		end

		local max=math.min(ct,g:GetCount())

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

		local sg=g:Select(
			tp,
			1,
			max,
			nil
		)

		if sg:GetCount()>0 then
			Duel.Remove(
				sg,
				POS_FACEUP,
				REASON_EFFECT
			)
		end
	end
end

-- =========================================================
-- NEGATE EFFET DE MONSTRE
-- =========================================================

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
		and re:IsActiveType(TYPE_MONSTER)
		and Duel.IsChainNegatable(ev)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return true
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_NEGATE,
		eg,
		1,
		0,
		0
	)

	local rc=re:GetHandler()

	if rc
		and rc:IsRelateToEffect(re)
		and rc:IsDestructable() then

		Duel.SetOperationInfo(
			0,
			CATEGORY_DESTROY,
			rc,
			1,
			0,
			rc:GetLocation()
		)
	end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=re:GetHandler()

	-- Annule l'effet
	if not Duel.NegateEffect(ev) then
		return
	end

	-- Et si vous le faites, détruisez le monstre
	if not rc
		or not rc:IsRelateToEffect(re)
		or not rc:IsDestructable() then
		return
	end

	if Duel.Destroy(
		rc,
		REASON_EFFECT
	)==0 then
		return
	end

	-- Et si vous le faites, gagne 1000 ATK
	if c:IsFaceup()
		and c:IsRelateToEffect(e) then

		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(1000)
		e1:SetReset(
			RESET_EVENT+
			RESETS_STANDARD+
			RESET_DISABLE
		)
		c:RegisterEffect(e1)
	end
end
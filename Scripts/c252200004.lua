-- Transformage - Helios Doré
local s,id=GetID()

function s.initial_effect(c)
	-- Activation : vous pouvez Poser 1 Magie Normale/Piège Normal "Transformage"
	local e0=Effect.CreateEffect(c)
	e0:SetDescription(aux.Stringid(id,0))
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	e0:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e0:SetTarget(s.acttg)
	e0:SetOperation(s.actop)
	c:RegisterEffect(e0)

	-- Une fois par tour, durant la Main Phase :
	-- prenez 1 carte "Transformage" du Deck, ajoutez-la ou Posez-la si M/P
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_FZONE)
	e1:SetCountLimit(1)
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- +300 ATK par nom différent de monstre "Transformage"
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.atktg)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)

	-- Immunité des Fusion "Transformage" hors colonne
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_IMMUNE_EFFECT)
	e3:SetRange(LOCATION_FZONE)
	e3:SetTargetRange(LOCATION_MZONE,0)
	e3:SetTarget(s.imtg)
	e3:SetValue(s.efilter)
	c:RegisterEffect(e3)
end

-- ==========================================
-- MAGIE NORMALE / PIÈGE NORMAL
-- ==========================================
function s.isnormalst(c)
	if c:IsType(TYPE_SPELL) then
		return not c:IsType(
			TYPE_QUICKPLAY+
			TYPE_CONTINUOUS+
			TYPE_EQUIP+
			TYPE_FIELD+
			TYPE_RITUAL
		)
	end

	if c:IsType(TYPE_TRAP) then
		return not c:IsType(
			TYPE_CONTINUOUS+
			TYPE_COUNTER
		)
	end

	return false
end

function s.setfilter(c)
	return c:IsSetCard(0x6e7)
		and s.isnormalst(c)
end

-- ==========================================
-- ACTIVATION : SET OPTIONNEL DEPUIS LE DECK
-- ==========================================
function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return true
	end
end

function s.actop(e,tp,eg,ep,ev,re,r,rp)
	-- Il faut une Zone Magie/Piège libre
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then
		return
	end

	-- Il faut une Magie Normale/Piège Normal Transformage
	if not Duel.IsExistingMatchingCard(
		s.setfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		nil
	) then
		return
	end

	-- Effet optionnel
	if not Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)

	local g=Duel.SelectMatchingCard(
		tp,
		s.setfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil
	)

	local tc=g:GetFirst()

	if tc then
		Duel.SSet(tp,tc)
	end
end

-- ==========================================
-- UNE FOIS PAR TOUR : SEARCH / SET
-- ==========================================
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return ph==PHASE_MAIN1 or ph==PHASE_MAIN2
end

function s.deckfilter(c,tp)
	return c:IsSetCard(0x6e7)
		and (
			c:IsAbleToHand()
			or (
				c:IsType(TYPE_SPELL+TYPE_TRAP)
				and Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			)
		)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.deckfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil,
			tp
		)
	end
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)

	local g=Duel.SelectMatchingCard(
		tp,
		s.deckfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil,
		tp
	)

	local tc=g:GetFirst()

	if not tc then
		return
	end

	local canhand=tc:IsAbleToHand()
	local canset=tc:IsType(TYPE_SPELL+TYPE_TRAP)
		and Duel.GetLocationCount(tp,LOCATION_SZONE)>0

	local op=0

	if canhand and canset then
		op=Duel.SelectOption(
			tp,
			aux.Stringid(id,2),
			aux.Stringid(id,3)
		)
	elseif canset then
		op=1
	end

	if op==0 then
		if Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 then
			Duel.ConfirmCards(1-tp,tc)
		end
	else
		Duel.SSet(tp,tc)
	end
end

-- ==========================================
-- BONUS D'ATK
-- ==========================================
function s.atktg(e,c)
	return c:IsFaceup()
		and c:IsSetCard(0x6e7)
end

function s.namefilter(c)
	return c:IsFaceup()
		and c:IsSetCard(0x6e7)
		and c:IsType(TYPE_MONSTER)
end

function s.atkval(e,c)
	local tp=e:GetHandlerPlayer()

	local g=Duel.GetMatchingGroup(
		s.namefilter,
		tp,
		LOCATION_MZONE,
		0,
		nil
	)

	return g:GetClassCount(Card.GetCode)*300
end

-- ==========================================
-- IMMUNITÉ DES FUSIONS "TRANSFORMAGE"
-- ==========================================
function s.imtg(e,c)
	return c:IsFaceup()
		and c:IsSetCard(0x6e7)
		and c:IsType(TYPE_FUSION)
end

function s.isactivatedeffect(te)
	local typ=te:GetType()

	return typ&EFFECT_TYPE_ACTIVATE~=0
		or typ&EFFECT_TYPE_IGNITION~=0
		or typ&EFFECT_TYPE_TRIGGER_O~=0
		or typ&EFFECT_TYPE_TRIGGER_F~=0
		or typ&EFFECT_TYPE_QUICK_O~=0
		or typ&EFFECT_TYPE_QUICK_F~=0
end

function s.efilter(e,te)
	local tc=e:GetOwner()
	local ec=te:GetHandler()
	local tp=e:GetHandlerPlayer()

	-- Effets adverses uniquement
	if te:GetOwnerPlayer()==tp then
		return false
	end

	-- Effets activés uniquement
	if not s.isactivatedeffect(te) then
		return false
	end

	-- La carte source doit être sur le Terrain adverse
	if not ec
		or not ec:IsOnField()
		or not ec:IsControler(1-tp) then
		return false
	end

	-- Même colonne = pas d'immunité
	if tc:GetColumnGroup():IsContains(ec) then
		return false
	end

	return true
end
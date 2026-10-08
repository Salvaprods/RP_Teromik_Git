-- Slasher Slime☺
local s,id=GetID()

local SET_SLIME=0xc2a
local TOKEN_SLIME=253000007

function s.initial_effect(c)
	-- Si vous contrôlez un Slime☺ ou Jeton Slime☺ :
	-- SS cette carte depuis la main
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	-- Normal/Special Summon -> lancer 1 dé
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DICE+CATEGORY_TOHAND+CATEGORY_DRAW+CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.dicetg)
	e2:SetOperation(s.diceop)
	c:RegisterEffect(e2)

	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)

	-- Monstre équipé : ne peut pas attaquer
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_EQUIP)
	e4:SetCode(EFFECT_CANNOT_ATTACK)
	e4:SetValue(1)
	c:RegisterEffect(e4)
end

s.listed_series={SET_SLIME}
s.listed_names={TOKEN_SLIME}

-- =========================================
-- INVOCATION SPÉCIALE DEPUIS LA MAIN
-- =========================================
function s.spfilter(c)
	return c:IsFaceup()
		and (
			c:IsSetCard(SET_SLIME)
			or c:IsCode(TOKEN_SLIME)
		)
end

function s.spcon(e,c)
	if c==nil then return true end

	local tp=c:GetControler()

	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(
			s.spfilter,
			tp,
			LOCATION_MZONE,
			0,
			1,
			nil
		)
end

-- =========================================
-- DÉ À 6 FACES
-- =========================================
function s.dicetg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return true
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_DICE,
		nil,
		0,
		tp,
		1
	)
end

-- =========================================
-- 1-2 : RÉCUPÉRER 1 SLIME☺ DU GY
-- =========================================
function s.thfilter(c)
	return c:IsSetCard(SET_SLIME)
		and c:IsAbleToHand()
end

-- =========================================
-- RÉSOLUTION DU DÉ
-- =========================================
function s.diceop(e,tp,eg,ep,ev,re,r,rp)
	local res=Duel.TossDice(tp,1)

	-- =====================================
	-- 1 OU 2 : AJOUTER 1 SLIME☺ DU GY
	-- =====================================
	if res==1 or res==2 then
		if not Duel.IsExistingMatchingCard(
			s.thfilter,
			tp,
			LOCATION_GRAVE,
			0,
			1,
			nil
		) then
			return
		end

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)

		local g=Duel.SelectMatchingCard(
			tp,
			s.thfilter,
			tp,
			LOCATION_GRAVE,
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

	-- =====================================
	-- 3 OU 4 : PIOCHER 1
	-- =====================================
	elseif res==3 or res==4 then
		if Duel.IsPlayerCanDraw(tp,1) then
			Duel.Draw(
				tp,
				1,
				REASON_EFFECT
			)
		end

	-- =====================================
	-- 5 OU 6 : INVOQUER 1 JETON
	-- =====================================
	else
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
end
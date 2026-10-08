-- Guerrier Slime☺
local s,id=GetID()

local SET_SLIME=0xc2a
local TOKEN_SLIME=253000007

function s.initial_effect(c)
	-- Défausser cette carte -> Invoquer 1 Jeton Slime☺
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.tkcost)
	e1:SetTarget(s.tktg)
	e1:SetOperation(s.tkop)
	c:RegisterEffect(e1)

	-- Monstre équipé : +300 ATK
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_EQUIP)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetValue(300)
	c:RegisterEffect(e2)

	-- +300 DEF
	local e3=e2:Clone()
	e3:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e3)

	-- Ne peut pas être Matériel Fusion
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_EQUIP)
	e4:SetCode(EFFECT_CANNOT_BE_FUSION_MATERIAL)
	e4:SetValue(1)
	c:RegisterEffect(e4)

	-- Ne peut pas être Matériel Synchro
	local e5=e4:Clone()
	e5:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL)
	c:RegisterEffect(e5)

	-- Ne peut pas être Matériel Xyz
	local e6=e4:Clone()
	e6:SetCode(EFFECT_CANNOT_BE_XYZ_MATERIAL)
	c:RegisterEffect(e6)

	-- Ne peut pas être Matériel Lien
	local e7=e4:Clone()
	e7:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
	c:RegisterEffect(e7)
end

s.listed_series={SET_SLIME}
s.listed_names={TOKEN_SLIME}

-- =========================================
-- DÉFAUSSER CETTE CARTE
-- =========================================
function s.tkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsDiscardable()
	end

	Duel.SendtoGrave(
		c,
		REASON_COST+REASON_DISCARD
	)
end

-- =========================================
-- INVOQUER 1 JETON SLIME☺
-- =========================================
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
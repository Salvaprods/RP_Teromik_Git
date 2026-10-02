-- Mimighoul Trap
local s,id,o=GetID()

function s.initial_effect(c)
	--Xyz Summon
	c:EnableReviveLimit()
	aux.AddXyzProcedure(c,s.xyzfilter,1,2)

	--Cannot control more than 1 "Mimighoul Trap"
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetCondition(s.limitcon)
	c:RegisterEffect(e1)

	--Face-down monsters cannot be used as material for Extra Deck monsters
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_BE_MATERIAL)
	e2:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e2:SetTarget(s.mattg)
	e2:SetValue(s.matval)
	c:RegisterEffect(e2)

	--Face-down monsters cannot be Tributed
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_UNRELEASABLE_SUM)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e3:SetTarget(s.mattg)
	c:RegisterEffect(e3)

	--When a monster is flipped face-up
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_CHANGE_POS)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(3,id)
	e4:SetCondition(s.flipcon)
	e4:SetTarget(s.fliptg)
	e4:SetOperation(s.flipop)
	c:RegisterEffect(e4)
end

--2 Level 1 "Mimighoul" monsters
function s.xyzfilter(c,tp)
	return c:IsSetCard(0x1b7) and c:IsLevel(1)
end

--You can only control 1 "Mimighoul Trap"
function s.limitcon(e)
	local c=e:GetHandler()
	local code=c:GetCode()
	return Duel.IsExistingMatchingCard(
		function(tc) return tc:IsFaceup() and tc:IsCode(code) end,
		c:GetControler(),LOCATION_MZONE,0,1,c)
end

--Face-down monsters
function s.mattg(e,c)
	return c:IsFacedown()
end

--Only prevent use as Extra Deck material
function s.matval(e,c)
	return c:IsType(TYPE_FUSION)
		or c:IsType(TYPE_SYNCHRO)
		or c:IsType(TYPE_XYZ)
		or c:IsType(TYPE_LINK)
end

--Check for a monster changing from face-down to face-up
function s.flipfilter(c)
	return c:IsFaceup() and c:IsPreviousPosition(POS_FACEDOWN)
end

function s.flipcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.flipfilter,1,nil)
end

--Check if at least one usable zone exists
function s.fliptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			or Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			or Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
			or Duel.GetLocationCount(1-tp,LOCATION_SZONE)>0
	end
end

function s.flipop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsFaceup() then return end

	--Select an unused Main Monster Zone or Spell/Trap Zone
	local zone=Duel.SelectDisableField(tp,1,
		LOCATION_MZONE+LOCATION_SZONE,
		LOCATION_MZONE+LOCATION_SZONE,0)

	if zone==0 then return end

	--Disable the selected zone while this monster remains face-up
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_DISABLE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(1,0)
	e1:SetValue(zone)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e1)
end
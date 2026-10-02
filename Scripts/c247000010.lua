-- Queentwins - Ornella
local s, id = GetID()

s.listed_series = {0xd44}

function s.initial_effect(c)
	-- Invocation Xyz : 2+ monstres « Queentwins » de Niveau 4
	c:EnableReviveLimit()
	aux.AddXyzProcedure(c, s.mfilter, 4, 2, nil, nil, 99)

	-- Effet 1 : Gain de 300 ATK par Matériel Xyz attaché
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)

	-- Effet 2 : Insensibilité aux effets de monstre adverses tant qu'elle a du Matériel
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetCondition(s.immcon)
	e2:SetValue(s.efilter)
	c:RegisterEffect(e2)

	-- Effet 3 : Lors du combat -> Détacher 1 matériel, gagner 500 ATK par monstre sur le Terrain jusqu'à la fin de la BP
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 0))
	e3:SetCategory(CATEGORY_ATKCHANGE)
	e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_PRE_DAMAGE_CALCULATE)
	e3:SetCountLimit(1, id)
	e3:SetCost(s.atkcost)
	e3:SetOperation(s.atkop)
	c:RegisterEffect(e3)

	-- Effet 4 : Durant la End Phase -> Attacher 1 monstre Queentwins depuis le Deck
	local e4 = Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id, 1))
	e4:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_PHASE + PHASE_END)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1, id + 100)
	e4:SetTarget(s.ovtg)
	e4:SetOperation(s.ovop)
	c:RegisterEffect(e4)
end

function s.mfilter(c, sc, sumtype, tp)
	return c:IsSetCard(0xd44, sc, sumtype, tp) or c:IsOriginalSetCard(0xd44)
end

-- ==========================================
-- EFFET 1 : GAIN D'ATK PERMANENT
-- ==========================================
function s.atkval(e, c)
	return c:GetOverlayCount() * 300
end

-- ==========================================
-- EFFET 2 : IMMUNITÉ AUX EFFETS DE MONSTRE
-- ==========================================
function s.immcon(e)
	return e:GetHandler():GetOverlayCount() > 0
end

function s.efilter(e, te)
	return te:IsActiveType(TYPE_MONSTER) and te:GetOwnerPlayer() ~= e:GetHandlerPlayer()
end

-- ==========================================
-- EFFET 3 : GAIN D'ATK PENDANT LE COMBAT
-- ==========================================
function s.atkcost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return e:GetHandler():CheckRemoveOverlayCard(tp, 1, REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp, 1, 1, REASON_COST)
end

function s.atkop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsFaceup() then
		local count = Duel.GetFieldGroupCount(tp, LOCATION_MZONE, LOCATION_MZONE)
		local e1 = Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(count * 500)
		e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_BATTLE)
		c:RegisterEffect(e1)
	end
end

-- ==========================================
-- EFFET 4 : ATTACHER DEPUIS LE DECK (END PHASE)
-- ==========================================
function s.ovfilter(c)
	return (c:IsSetCard(0xd44) or c:IsOriginalSetCard(0xd44)) and c:IsType(TYPE_MONSTER)
end

function s.ovtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return e:GetHandler():IsType(TYPE_XYZ)
			and Duel.IsExistingMatchingCard(s.ovfilter, tp, LOCATION_DECK, 0, 1, nil)
	end
end

function s.ovop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_XMATERIAL)
	local g = Duel.SelectMatchingCard(tp, s.ovfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
	if #g > 0 then
		Duel.Overlay(c, g)
	end
end
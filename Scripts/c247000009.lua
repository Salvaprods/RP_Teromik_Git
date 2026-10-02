-- Magie Continue Queentwins
local s, id = GetID()

s.listed_series = {0xd44}

function s.initial_effect(c)
	-- Activation
	local e0 = Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-- Effet 1 : Restriction d'activation d'effets de monstre dans la même colonne
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetRange(LOCATION_SZONE)
	e1:SetTargetRange(0, 1)
	e1:SetValue(s.actlimit)
	c:RegisterEffect(e1)

	-- Effet 2 : Réduction de Niveau / Annulation d'effets sur Invocation Spéciale
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 0))
	e2:SetCategory(CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET + EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1) -- Limite par exemplaire (Soft OPT)
	e2:SetCondition(s.lvcon)
	e2:SetTarget(s.lvtg)
	e2:SetOperation(s.lvop)
	c:RegisterEffect(e2)
end

-- ==========================================
-- EFFET 1 : RESTRICTION D'ACTIVATION
-- ==========================================
function s.qtfilter(c)
	return c:IsFaceup() and (c:IsSetCard(0xd44) or c:IsOriginalSetCard(0xd44))
end

function s.colfilter(c, rc)
	return c:GetColumnGroup():IsContains(rc)
end

function s.actlimit(e, re, tp)
	local rc = re:GetHandler()
	if not (re:IsActiveType(TYPE_MONSTER) and rc:IsLocation(LOCATION_MZONE)) then return false end
	local p = e:GetHandlerPlayer()
	local g = Duel.GetMatchingGroup(s.qtfilter, p, LOCATION_MZONE, 0, nil)
	return g:IsExists(s.colfilter, 1, nil, rc)
end

-- ==========================================
-- EFFET 2 : RÉDUCTION DE NIVEAU ET ANNULATION
-- ==========================================
function s.xyzfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_XYZ) and (c:IsSetCard(0xd44) or c:IsOriginalSetCard(0xd44))
end

function s.spfilter(c, tp, e)
	return c:IsControler(1 - tp)
		and c:IsSummonLocation(LOCATION_DECK + LOCATION_GRAVE)
		and c:IsFaceup()
		and not c:IsType(TYPE_XYZ + TYPE_LINK)
		and c:IsCanBeEffectTarget(e)
end

function s.lvcon(e, tp, eg, ep, ev, re, r, rp)
	return Duel.IsExistingMatchingCard(s.xyzfilter, tp, LOCATION_MZONE, 0, 1, nil)
		and eg:IsExists(s.spfilter, 1, nil, tp, e)
end

function s.lvtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return eg:IsContains(chkc) and s.spfilter(chkc, tp, e) end
	if chk == 0 then return true end
	local g = eg:Filter(s.spfilter, nil, tp, e)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
	local sg = g:Select(tp, 1, 1, nil)
	Duel.SetTargetCard(sg)
end

function s.lvop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	local tc = Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() and not tc:IsType(TYPE_XYZ + TYPE_LINK) then
		-- Réduction du niveau de 3
		local e1 = Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_LEVEL)
		e1:SetValue(-3)
		e1:SetReset(RESET_EVENT + RESETS_STANDARD)
		tc:RegisterEffect(e1)

		-- Si le niveau est tombé à 1, annulation des effets
		if tc:GetLevel() == 1 then
			local e2 = Effect.CreateEffect(c)
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_DISABLE)
			e2:SetReset(RESET_EVENT + RESETS_STANDARD)
			tc:RegisterEffect(e2)
			
			local e3 = Effect.CreateEffect(c)
			e3:SetType(EFFECT_TYPE_SINGLE)
			e3:SetCode(EFFECT_DISABLE_EFFECT)
			e3:SetReset(RESET_EVENT + RESETS_STANDARD)
			tc:RegisterEffect(e3)
		end
	end
end
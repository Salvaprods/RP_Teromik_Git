-- Queentwins - Rose Lance
local s, id = GetID()

s.listed_series = {0xd44}

function s.initial_effect(c)
	-- Limite d'équipement (Monstre Queentwins uniquement)
	local e0 = Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_EQUIP_LIMIT)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e0:SetValue(s.eqlimit)
	c:RegisterEffect(e0)

	-- Activation : Invoquer Spécialement 1 monstre Queentwins et équiper cette carte
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_EQUIP)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1, id, EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Protection : Indestructible par les effets de carte de l'adversaire
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_EQUIP)
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e2:SetValue(s.indval)
	c:RegisterEffect(e2)

	-- Protection : Ne peut pas être banni par les effets de carte de l'adversaire
	local e3 = Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_EQUIP)
	e3:SetCode(EFFECT_CANNOT_REMOVE)
	e3:SetValue(s.rmval)
	c:RegisterEffect(e3)
end

function s.eqlimit(e, c)
	return c:IsSetCard(0xd44) or c:IsOriginalSetCard(0xd44)
end

function s.spfilter(c, e, tp)
	return (c:IsSetCard(0xd44) or c:IsOriginalSetCard(0xd44))
		and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_DECK + LOCATION_GRAVE, 0, 1, nil, e, tp)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_DECK + LOCATION_GRAVE)
	Duel.SetOperationInfo(0, CATEGORY_EQUIP, e:GetHandler(), 1, 0, 0)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local g = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.spfilter), tp, LOCATION_DECK + LOCATION_GRAVE, 0, 1, 1, nil, e, tp)
	local tc = g:GetFirst()
	if tc and Duel.SpecialSummon(tc, 0, tp, tp, false, false, POS_FACEUP) > 0 then
		Duel.Equip(tp, c, tc)
	end
end

function s.indval(e, re, rp)
	return rp ~= e:GetHandlerPlayer()
end

function s.rmval(e, re, rp)
	return rp ~= e:GetHandlerPlayer()
end
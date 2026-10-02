-- Roi Des Crânes Serviteurs - Ultimate
local s, id = GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	c:SetUniqueOnField(1, 0, id)

	-- Interdit STRICTEMENT l'Invocation Normale et le Pose
	local e0a = Effect.CreateEffect(c)
	e0a:SetType(EFFECT_TYPE_SINGLE)
	e0a:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
	e0a:SetCode(EFFECT_CANNOT_SUMMON)
	c:RegisterEffect(e0a)
	local e0b = e0a:Clone()
	e0b:SetCode(EFFECT_CANNOT_MSET)
	c:RegisterEffect(e0b)

	-- Invocable UNIQUEMENT par la Magie 210000000
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_CONDITION)
	e1:SetValue(s.splimit)
	c:RegisterEffect(e1)

	-- ATK d'origine
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetCode(EFFECT_SET_BASE_ATTACK)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)

	-- Invoquer + Envoyer au Cimetière
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 0))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_TOGRAVE)
	e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)

	-- Dégâts perçants
	local e4 = Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_PIERCE)
	e4:SetCondition(s.piercecon)
	c:RegisterEffect(e4)
end

s.listed_names = {32274490, 36021814, 210000000}

function s.splimit(e, se, sp, st)
	return se and se:GetHandler():IsCode(210000000)
end

function s.atkval(e, c)
	return Duel.GetMatchingGroupCount(s.atkfilter, e:GetHandlerPlayer(), LOCATION_GRAVE, 0, nil) * 2000
end

function s.atkfilter(c)
	return c:IsCode(32274490, 36021814)
end

function s.spfilter(c, e, tp)
	return (c:IsCode(32274490) or aux.IsCodeListed(c, 32274490) or c:IsSetCard(0x159)) 
		and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.tgfilter(c, code)
	return (c:IsCode(32274490) or aux.IsCodeListed(c, 32274490) or c:IsSetCard(0x159)) 
		and not c:IsCode(code) and c:IsAbleToGrave()
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
		and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_DECK + LOCATION_GRAVE, 0, 1, nil, e, tp) end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_DECK + LOCATION_GRAVE)
	Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, nil, 1, tp, LOCATION_DECK)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local g = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.spfilter), tp, LOCATION_DECK + LOCATION_GRAVE, 0, 1, 1, nil, e, tp)
	if #g > 0 and Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP) > 0 then
		local tc = g:GetFirst()
		local code = tc:GetCode()
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
		local tg = Duel.SelectMatchingCard(tp, s.tgfilter, tp, LOCATION_DECK, 0, 1, 1, nil, code)
		if #tg > 0 then
			Duel.SendtoGrave(tg, REASON_EFFECT)
		end
	end
end

function s.piercecon(e)
	return Duel.IsExistingMatchingCard(s.piercefilter, e:GetHandlerPlayer(), LOCATION_MZONE, 0, 2, nil)
end

function s.piercefilter(c)
	return c:IsFaceup() and (c:IsCode(id, 32274490) or aux.IsCodeListed(c, 32274490) or c:IsSetCard(0x159))
end
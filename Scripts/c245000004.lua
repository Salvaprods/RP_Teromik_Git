-- Relique Égyptienne - Slifer, Le Dragon Céleste
local s, id = GetID()

s.listed_series = {0xdd7}

function s.initial_effect(c)
	-- Effet 1 : Invocation Spéciale depuis la main si aucun monstre
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1, id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Effet 2 : Invoqué Normalement ou Spécialement -> Sacrifice + Invocation Main/Deck
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1, id + 100)
	e2:SetCost(s.rscost)
	e2:SetTarget(s.hstg)
	e2:SetOperation(s.hsop)
	c:RegisterEffect(e2)
	local e3 = e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)

	-- Effet 3 : Boost ATK/DEF si Niveau 12 (1000 par carte en main)
	local e4 = Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCode(EFFECT_UPDATE_ATTACK)
	e4:SetCondition(s.atkcon)
	e4:SetValue(s.atkval)
	c:RegisterEffect(e4)
	local e5 = e4:Clone()
	e5:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e5)

	-- Effet 4 : Si Niveau 12 et invocation adverse -> Réduction d'ATK et envoi au GY si 0 (Effet obligatoire)
	local e6 = Effect.CreateEffect(c)
	e6:SetCategory(CATEGORY_ATKCHANGE + CATEGORY_TOGRAVE)
	e6:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_F)
	e6:SetCode(EVENT_SUMMON_SUCCESS)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCondition(s.valcon)
	e6:SetTarget(s.valtg)
	e6:SetOperation(s.valop)
	c:RegisterEffect(e6)
	local e7 = e6:Clone()
	e7:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e7)

	-- Effet 5 : Son nom devient « Slifer, Le Dragon Céleste » dans le Cimetière
	local e8 = Effect.CreateEffect(c)
	e8:SetType(EFFECT_TYPE_SINGLE)
	e8:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e8:SetRange(LOCATION_GRAVE)
	e8:SetCode(EFFECT_CHANGE_CODE)
	e8:SetValue(10000020)
	c:RegisterEffect(e8)
end

function s.spcon(e, tp, eg, ep, ev, re, r, rp)
	return Duel.GetFieldGroupCount(tp, LOCATION_MZONE, 0) == 0
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, 0, 0)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP)
	end
end

function s.rscost(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then return c:IsReleasable() end
	Duel.Release(c, REASON_COST)
end

function s.hsfilter(c, e, tp)
	return c:IsSetCard(0xdd7) and not c:IsCode(id) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.hstg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and Duel.IsExistingMatchingCard(s.hsfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, nil, e, tp)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_DECK)
end

function s.hsop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local g = Duel.SelectMatchingCard(tp, s.hsfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, 1, 1, nil, e, tp)
	if #g > 0 then
		Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
	end
end

function s.atkcon(e)
	return e:GetHandler():IsLevel(12)
end

function s.atkval(e, c)
	return Duel.GetFieldGroupCount(c:GetControler(), LOCATION_HAND, 0) * 1000
end

function s.valfilter(c, tp)
	return c:IsControler(1 - tp) and c:IsFaceup()
end

function s.valcon(e, tp, eg, ep, ev, re, r, rp)
	return e:GetHandler():IsLevel(12) and eg:IsExists(s.valfilter, 1, nil, tp)
end

function s.valtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return eg:IsExists(s.valfilter, 1, nil, tp) end
	local g = eg:Filter(s.valfilter, nil, tp)
	Duel.SetOperationInfo(0, CATEGORY_ATKCHANGE, g, #g, 0, 0)
	Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, g, #g, 0, 0)
end

function s.valop(e, tp, eg, ep, ev, re, r, rp)
	local g = eg:Filter(s.valfilter, nil, tp)
	local c = e:GetHandler()
	for tc in aux.Next(g) do
		if tc:IsFaceup() then
			local e1 = Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(-2000)
			e1:SetReset(RESET_EVENT + RESETS_STANDARD)
			tc:RegisterEffect(e1)
			if tc:GetAttack() == 0 then
				Duel.SendtoGrave(tc, REASON_EFFECT)
			end
		end
	end
end
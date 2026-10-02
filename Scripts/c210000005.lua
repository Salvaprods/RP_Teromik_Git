-- Assault Mercefourure
local s, id = GetID()
function s.initial_effect(c)
	-- Magie Rapide
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_DESTROY + CATEGORY_DISABLE + CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0, TIMINGS_CHECK_MONSTER + TIMING_MAIN_END)
	e1:SetCountLimit(1, id, EFFECT_COUNT_CODE_OATH)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

s.listed_names = {}

-- Coût : Envoyer 1 carte "Mercefourure" depuis le Deck au Cimetière
function s.costfilter(c)
	return c:IsSetCard(0x114) and c:IsAbleToGraveAsCost()
end

function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(s.costfilter, tp, LOCATION_DECK, 0, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
	local g = Duel.SelectMatchingCard(tp, s.costfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
	Duel.SendtoGrave(g, REASON_COST)
end

-- Filtres d'effets (Position de Défense Face Recto stricte)
function s.spfilter(c, e, tp)
	return c:IsSetCard(0x114) and c:IsLevelBelow(4) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false, POS_FACEUP_DEFENSE)
end

function s.negfilter(c)
	return c:IsFaceup() and not c:IsDisabled()
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
	local b1 = Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
		and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_DECK, 0, 1, nil, e, tp)
	local b2 = Duel.IsExistingMatchingCard(s.negfilter, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, nil)

	if chk == 0 then return b1 or b2 end

	local ops = {}
	local opvals = {}
	if b1 then
		table.insert(ops, aux.Stringid(id, 1))
		table.insert(opvals, 0)
	end
	if b2 then
		table.insert(ops, aux.Stringid(id, 2))
		table.insert(opvals, 1)
	end

	local sel = Duel.SelectOption(tp, table.unpack(ops))
	local op = opvals[sel + 1]
	e:SetLabel(op)

	if op == 0 then
		e:SetProperty(0)
		Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_DECK)
		Duel.SetOperationInfo(0, CATEGORY_DESTROY, nil, 0, tp, LOCATION_ONFIELD)
	else
		e:SetProperty(EFFECT_FLAG_CARD_TARGET)
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DISABLE)
		local g = Duel.SelectMatchingCard(tp, s.negfilter, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, 1, nil)
		Duel.SetTargetCard(g)
		Duel.SetOperationInfo(0, CATEGORY_DISABLE, g, 1, 0, 0)
		Duel.SetOperationInfo(0, CATEGORY_REMOVE, nil, 0, 0, LOCATION_ONFIELD)
	end
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
	-- Restriction d'invocation pour le reste du tour
	local e2 = Effect.CreateEffect(e:GetHandler())
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e2:SetTargetRange(1, 0)
	e2:SetTarget(s.sumlimit)
	e2:SetReset(RESET_PHASE + PHASE_END)
	Duel.RegisterEffect(e2, tp)
	local e3 = e2:Clone()
	e3:SetCode(EFFECT_CANNOT_SUMMON)
	Duel.RegisterEffect(e3, tp)

	local op = e:GetLabel()
	if op == 0 then
		if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
		local g = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_DECK, 0, 1, 1, nil, e, tp)
		if #g > 0 and Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP_DEFENSE) > 0 then
			if Duel.GetFieldGroupCount(tp, 0, LOCATION_MZONE) >= 2
				and Duel.IsExistingMatchingCard(aux.TRUE, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, nil)
				and Duel.SelectYesNo(tp, aux.Stringid(id, 3)) then
				Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
				local dg = Duel.SelectMatchingCard(tp, aux.TRUE, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, 1, nil)
				if #dg > 0 then
					Duel.BreakEffect()
					Duel.Destroy(dg, REASON_EFFECT)
				end
			end
		end
	else
		local tc = Duel.GetFirstTarget()
		if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
			Duel.NegateRelatedChain(tc, RESET_TURN_SET)
			local e1 = Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT + RESETS_STANDARD)
			tc:RegisterEffect(e1)
			local e2 = Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			e2:SetValue(RESET_TURN_SET)
			e2:SetReset(RESET_EVENT + RESETS_STANDARD)
			tc:RegisterEffect(e2)
			if tc:IsType(TYPE_TRAPMONSTER) then
				local e3 = Effect.CreateEffect(e:GetHandler())
				e3:SetType(EFFECT_TYPE_SINGLE)
				e3:SetCode(EFFECT_DISABLE_TRAPMONSTER)
				e3:SetReset(RESET_EVENT + RESETS_STANDARD)
				tc:RegisterEffect(e3)
			end

			if Duel.GetFieldGroupCount(tp, 0, LOCATION_MZONE) >= 2
				and tc:IsAbleToRemove(tp, POS_FACEDOWN)
				and Duel.SelectYesNo(tp, aux.Stringid(id, 3)) then
				Duel.BreakEffect()
				Duel.Remove(tc, POS_FACEDOWN, REASON_EFFECT)
			end
		end
	end
end

function s.sumlimit(e, c)
	return not c:IsSetCard(0x114)
end
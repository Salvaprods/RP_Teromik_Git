-- Détresse Seigneur Lumière
local s, id = GetID()
function s.initial_effect(c)
	-- Effet 1 : Activation (Magie Rapide) - Choix entre ajouter un monstre ou meuler 3 et annuler
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH + CATEGORY_DECKDES + CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0, TIMINGS_CHECK_MONSTER + TIMING_MAIN_END)
	e1:SetCountLimit(1, id, EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Effet 2 : Si envoyée depuis le Deck au Cimetière
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_LEAVE_GRAVE + CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1, id + 100)
	e2:SetCondition(s.setcon)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
end

s.listed_names = {}

-- Filtre pour chercher un monstre "Seigneur Lumière"
function s.thfilter(c)
	return c:IsType(TYPE_MONSTER) and c:IsSetCard(0x38) and c:IsAbleToHand()
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	local b1 = Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil)
	-- On exclut 'c' (la carte elle-même) pour être sûr qu'il y a une AUTRE carte face recto
	local b2 = Duel.IsPlayerCanDiscardDeck(tp, 3) and Duel.IsExistingMatchingCard(Card.IsFaceup, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, c)
	if chk == 0 then return b1 or b2 end
	
	local ops = {}
	local opvals = {}
	if b1 then
		table.insert(ops, aux.Stringid(id, 2))
		table.insert(opvals, 0)
	end
	if b2 then
		table.insert(ops, aux.Stringid(id, 3))
		table.insert(opvals, 1)
	end
	
	local op = Duel.SelectOption(tp, table.unpack(ops))
	local sel = opvals[op + 1]
	e:SetLabel(sel)
	
	if sel == 0 then
		Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
	else
		Duel.SetOperationInfo(0, CATEGORY_DECKDES, nil, 0, tp, 3)
	end
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	-- Restriction d'Invocation pour le reste du tour (sauf "Seigneur Lumière")
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1, 0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE + PHASE_END)
	Duel.RegisterEffect(e1, tp)
	local e2 = e1:Clone()
	e2:SetCode(EFFECT_CANNOT_SUMMON)
	Duel.RegisterEffect(e2, tp)

	local sel = e:GetLabel()
	if sel == 0 then
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
		local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
		if #g > 0 then
			Duel.SendtoHand(g, nil, REASON_EFFECT)
			Duel.ConfirmCards(1 - tp, g)
		end
	else
		if Duel.DiscardDeck(tp, 3, REASON_EFFECT) > 0 then
			Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DISABLE)
			-- On exclut 'c' ici aussi pour ne pas cibler / annuler la Magie elle-même
			local g = Duel.SelectMatchingCard(tp, Card.IsFaceup, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, 1, c)
			local tc = g:GetFirst()
			if tc then
				Duel.NegateRelatedChain(tc, RESET_TURN_SET)
				local le1 = Effect.CreateEffect(c)
				le1:SetType(EFFECT_TYPE_SINGLE)
				le1:SetCode(EFFECT_DISABLE)
				le1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
				tc:RegisterEffect(le1)
				local le2 = Effect.CreateEffect(c)
				le2:SetType(EFFECT_TYPE_SINGLE)
				le2:SetCode(EFFECT_DISABLE_EFFECT)
				le2:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
				tc:RegisterEffect(le2)
				if tc:IsType(TYPE_TRAPMONSTER) then
					local le3 = Effect.CreateEffect(c)
					le3:SetType(EFFECT_TYPE_SINGLE)
					le3:SetCode(EFFECT_DISABLE_TRAPMONSTER)
					le3:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
					tc:RegisterEffect(le3)
				end
			end
		end
	end
end

function s.splimit(e, c)
	return not c:IsSetCard(0x38)
end

-- Effet 2 : Condition (envoyée depuis le Deck au Cimetière)
function s.setcon(e, tp, eg, ep, ev, re, r, rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_DECK)
end

function s.settg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	local b1 = c:IsSSetable()
	local b2 = c:IsAbleToHand()
	if chk == 0 then return b1 or b2 end
	
	local ops = {}
	local opvals = {}
	if b1 then
		table.insert(ops, aux.Stringid(id, 4))
		table.insert(opvals, 0)
	end
	if b2 then
		table.insert(ops, aux.Stringid(id, 5))
		table.insert(opvals, 1)
	end
	
	local op = Duel.SelectOption(tp, table.unpack(ops))
	local sel = opvals[op + 1]
	e:SetLabel(sel)
	
	if sel == 0 then
		Duel.SetOperationInfo(0, CATEGORY_LEAVE_GRAVE, c, 1, 0, 0)
	else
		Duel.SetOperationInfo(0, CATEGORY_TOHAND, c, 1, tp, LOCATION_GRAVE)
	end
end

function s.setop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if e:GetLabel() == 0 then
		Duel.SSet(tp, c)
	else
		Duel.SendtoHand(c, nil, REASON_EFFECT)
		Duel.ConfirmCards(1 - tp, c)
	end
end
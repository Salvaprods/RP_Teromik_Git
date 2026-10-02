-- Pion En Passant - Echec Divin
local s, id = GetID()
function s.initial_effect(c)
	-- Activer la carte (Magie Continue standard)
	local e0 = Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-- Effet 1 : Boost d'ATK/DEF pour les monstres "Echec Divin"
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetRange(LOCATION_SZONE)
	e1:SetTargetRange(LOCATION_MZONE, 0)
	e1:SetTarget(aux.TargetBoolFunction(Card.IsSetCard, 0xe7a))
	e1:SetValue(s.val)
	c:RegisterEffect(e1)
	local e2 = e1:Clone()
	e2:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e2)

	-- Effet 2 : Envoyer un monstre "Echec Divin" de la S-Zone au Cimetière pour placer un autre depuis le Deck
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 0))
	e3:SetCategory(CATEGORY_TOGRAVE)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1, id)
	e3:SetCost(s.cost)
	e3:SetTarget(s.target)
	e3:SetOperation(s.operation)
	c:RegisterEffect(e3)
end

s.listed_series = {0xe7a} -- Echec Divin

-- ==========================================
-- CALCUL DU BOOST D'ATK/DEF
-- ==========================================
function s.countfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xe7a)
end

function s.val(e, c)
	return Duel.GetMatchingGroupCount(s.countfilter, e:GetHandlerPlayer(), LOCATION_SZONE, 0, nil) * 200
end

-- ==========================================
-- EFFET 2 : COÛT, CIBLE ET OPÉRATION
-- ==========================================
function s.cfilter(c, tp)
	-- Utilisation de GetOriginalType pour vérifier si c'était à l'origine un monstre (maintenant traité comme Magie)
	return c:IsFaceup() and c:IsSetCard(0xe7a) and (c:GetOriginalType() & TYPE_MONSTER) ~= 0 and c:IsLocation(LOCATION_SZONE) and c:IsAbleToGraveAsCost()
end

function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then return Duel.IsExistingMatchingCard(s.cfilter, tp, LOCATION_SZONE, 0, 1, c, tp) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
	local g = Duel.SelectMatchingCard(tp, s.cfilter, tp, LOCATION_SZONE, 0, 1, 1, c, tp)
	Duel.SendtoGrave(g, REASON_COST)
end

function s.deckfilter(c)
	return c:IsSetCard(0xe7a) and c:IsType(TYPE_MONSTER)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_SZONE) > 0
			and Duel.IsExistingMatchingCard(s.deckfilter, tp, LOCATION_DECK, 0, 1, nil)
	end
end

function s.operation(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetLocationCount(tp, LOCATION_SZONE) <= 0 then return end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOFIELD)
	local g = Duel.SelectMatchingCard(tp, s.deckfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
	local tc = g:GetFirst()
	if tc then
		Duel.MoveToField(tc, tp, tp, LOCATION_SZONE, POS_FACEUP, true)
		local e1 = Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CHANGE_TYPE)
		e1:SetValue(TYPE_SPELL + TYPE_CONTINUOUS)
		e1:SetReset(RESET_EVENT + RESETS_STANDARD - RESET_TURN_SET)
		tc:RegisterEffect(e1)
	end
end
-- Universo - Source d'Énergie
local s, id = GetID()

function s.initial_effect(c)
	-- Activation de la Magie de Terrain
	local e0 = Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-- Effet 1 : Les monstres "Universo" gagnent 100 ATK/DEF pour chaque carte bannie
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetRange(LOCATION_FZONE)
	e1:SetTargetRange(LOCATION_MZONE, 0)
	e1:SetTarget(aux.TargetBoolFunction(Card.IsSetCard, 0xc17))
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)
	
	local e2 = e1:Clone()
	e2:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e2)

	-- Effet 1 (suite) : Ne peuvent pas être détruits par des effets de Magie de l'adversaire
	local e3 = Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e3:SetRange(LOCATION_FZONE)
	e3:SetTargetRange(LOCATION_MZONE, 0)
	e3:SetTarget(aux.TargetBoolFunction(Card.IsSetCard, 0xc17))
	e3:SetValue(s.efilter)
	c:RegisterEffect(e3)

	-- Effet 1 (suite) : Ne peuvent pas être bannis par des effets de Magie de l'adversaire
	local e4 = e3:Clone()
	e4:SetCode(EFFECT_CANNOT_REMOVE)
	c:RegisterEffect(e4)

	-- Effet 2 : Main Phase : Bannir 1 carte de la main -> Ajouter 1 monstre "Universo" depuis le Deck
	local e5 = Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id, 0))
	e5:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
	e5:SetType(EFFECT_TYPE_IGNITION)
	e5:SetRange(LOCATION_FZONE)
	e5:SetCountLimit(1, id)
	e5:SetCost(s.thcost)
	e5:SetTarget(s.thtg)
	e5:SetOperation(s.thop)
	c:RegisterEffect(e5)

	-- Effet 3 : Si quitte le Terrain par un effet adverse -> Poser cette carte
	local e6 = Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id, 1))
	e6:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e6:SetProperty(EFFECT_FLAG_DELAY)
	e6:SetCode(EVENT_LEAVE_FIELD)
	e6:SetCountLimit(1, id + 100) -- HOPT séparé de l'effet 2
	e6:SetCondition(s.setcon)
	e6:SetTarget(s.settg)
	e6:SetOperation(s.setop)
	c:RegisterEffect(e6)
end

-- Fonction pour compter le total des cartes bannies (des deux joueurs)
function s.atkval(e, c)
	return Duel.GetFieldGroupCount(e:GetHandlerPlayer(), LOCATION_REMOVED, LOCATION_REMOVED) * 100
end

-- Filtre de protection : effet provenant de l'adversaire (rp) et de type Magie (TYPE_SPELL)
function s.efilter(e, re, rp)
	return rp == 1 - e:GetHandlerPlayer() and re:IsActiveType(TYPE_SPELL)
end

-- Filtres et fonctions pour la recherche (Effet 2)
function s.cfilter(c)
	return c:IsAbleToRemoveAsCost()
end

function s.thcost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(s.cfilter, tp, LOCATION_HAND, 0, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
	local g = Duel.SelectMatchingCard(tp, s.cfilter, tp, LOCATION_HAND, 0, 1, 1, nil)
	Duel.Remove(g, POS_FACEUP, REASON_COST)
end

function s.thfilter(c)
	return c:IsSetCard(0xc17) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil) end
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end

function s.thop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
	local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
	if #g > 0 then
		Duel.SendtoHand(g, nil, REASON_EFFECT)
		Duel.ConfirmCards(1 - tp, g)
	end
end

-- Fonctions pour reposer la carte (Effet 3)
function s.setcon(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	-- Vérifie qu'elle était sous notre contrôle et que l'effet vient de l'adversaire
	return c:IsPreviousControler(tp) and c:IsReason(REASON_EFFECT) and c:GetReasonPlayer() == 1 - tp
end

function s.settg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return e:GetHandler():IsSSetable() end
end

function s.setop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsSSetable() then
		Duel.SSet(tp, c)
	end
end
-- Universo - Dragon Du Trou Noir
local s, id = GetID()

function s.initial_effect(c)
	-- Lien : 2+ monstres "Universo" (Link-3)
	c:EnableReviveLimit()
	if Link and Link.AddProcedure then
		Link.AddProcedure(c, s.matfilter, 2, 3)
	else
		aux.AddLinkProcedure(c, s.matfilter, 2, 3)
	end

	-- Effet 1 : L'adversaire ne peut pas cibler de cartes dans les Cimetières
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_GRAVE, LOCATION_GRAVE)
	e1:SetValue(s.tgval)
	c:RegisterEffect(e1)

	-- Effet 2 : Non affecté par les effets activés de l'adversaire si ne pointe aucun monstre
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetCondition(s.immcon)
	e2:SetValue(s.immval)
	c:RegisterEffect(e2)

	-- Effet 3 : Bannir des cartes sur le Terrain/Cimetières selon le nombre de matériels
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 0))
	e3:SetCategory(CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_CARD_TARGET)
	e3:SetCountLimit(1, id)
	e3:SetCondition(s.rmcon)
	e3:SetTarget(s.rmtg)
	e3:SetOperation(s.rmop)
	c:RegisterEffect(e3)

	-- Effet 4 : Effet Rapide - Renvoyer la carte activée de l'adversaire au Deck
	local e4 = Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id, 1))
	e4:SetCategory(CATEGORY_TODECK)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_CHAINING)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1, id + 100)
	e4:SetCondition(s.deckcon)
	e4:SetTarget(s.decktg)
	e4:SetOperation(s.deckop)
	c:RegisterEffect(e4)
end

-- ==========================================
-- FILTRES DE MATÉRIELS
-- ==========================================
function s.matfilter(c, lc, sumtype, tp)
	return c:IsSetCard(0xc17, lc, sumtype, tp)
end

-- ==========================================
-- EFFET 1 : PROTECTION DES CIMETIÈRES
-- ==========================================
function s.tgval(e, re, rp)
	return rp ~= e:GetHandlerPlayer()
end

-- ==========================================
-- EFFET 2 : IMMUNITÉ SI AUCUN MONSTRE POINTÉ
-- ==========================================
function s.immcon(e)
	return not e:GetHandler():GetLinkedGroup():IsExists(Card.IsType, 1, nil, TYPE_MONSTER)
end

function s.immval(e, te)
	return te:IsActivated() and te:GetOwnerPlayer() ~= e:GetHandlerPlayer()
end

-- ==========================================
-- EFFET 3 : BANNISSEMENT SELON MATÉRIELS
-- ==========================================
function s.rmcon(e, tp, eg, ep, ev, re, r, rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

function s.rmtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_ONFIELD + LOCATION_GRAVE) and chkc:IsAbleToRemove()
	end
	local ct = #e:GetHandler():GetMaterial()
	if ct < 1 then ct = 1 end
	if chk == 0 then
		return Duel.IsExistingTarget(Card.IsAbleToRemove, tp, LOCATION_ONFIELD + LOCATION_GRAVE, LOCATION_ONFIELD + LOCATION_GRAVE, 1, nil)
	end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
	local g = Duel.SelectTarget(tp, Card.IsAbleToRemove, tp, LOCATION_ONFIELD + LOCATION_GRAVE, LOCATION_ONFIELD + LOCATION_GRAVE, 1, ct, nil)
	Duel.SetOperationInfo(0, CATEGORY_REMOVE, g, #g, 0, 0)
end

function s.rmop(e, tp, eg, ep, ev, re, r, rp)
	local g = Duel.GetChainInfo(0, CHAININFO_TARGET_CARDS):Filter(Card.IsRelateToEffect, nil, e)
	if #g > 0 then
		Duel.Remove(g, POS_FACEUP, REASON_EFFECT)
	end
end

-- ==========================================
-- EFFET 4 : RENVOI DE LA CARTE ADVERSE AU DECK
-- ==========================================
function s.deckcon(e, tp, eg, ep, ev, re, r, rp)
	if rp == tp then return false end
	local rc = re:GetHandler()
	return rc:IsLocation(LOCATION_ONFIELD) and rc:IsAbleToDeck()
end

function s.decktg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return true end
	local rc = re:GetHandler()
	Duel.SetTargetCard(rc)
	Duel.SetOperationInfo(0, CATEGORY_TODECK, rc, 1, 0, 0)
end

function s.deckop(e, tp, eg, ep, ev, re, r, rp)
	local rc = re:GetHandler()
	if rc:IsRelateToEffect(re) and rc:IsAbleToDeck() then
		Duel.SendtoDeck(rc, nil, SEQ_DECKSHUFFLE, REASON_EFFECT)
	end
end
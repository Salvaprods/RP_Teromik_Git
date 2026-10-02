-- Esprit De Souffrada - Âme Du Chasseur
local s, id = GetID()

function s.initial_effect(c)
	-- ==========================================
	-- PROCÉDURE DE LIEN
	-- ==========================================
	c:EnableReviveLimit()
	aux.AddLinkProcedure(c, s.matfilter, 1, 1)

	-- ==========================================
	-- EFFETS DE MONSTRE
	-- ==========================================
	-- Effet 1 : Invoqué par Lien -> Chercher Magie/Piège
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1, id)
	e1:SetCondition(s.lkcon)
	e1:SetTarget(s.lktg)
	e1:SetOperation(s.lkop)
	c:RegisterEffect(e1)

	-- Effet 2 : Envoyé au Cimetière -> Révéler + Effet selon type
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_DESTROY + CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1, id + 100)
	e2:SetTarget(s.gytg)
	e2:SetOperation(s.gyop)
	c:RegisterEffect(e2)
end

-- Matériel : 1 monstre non-Lien « Âme Du Chasseur »
function s.matfilter(c, lc, st, tp)
	return c:IsSetCard(0xc92, lc, st, tp) and not c:IsType(TYPE_LINK, lc, st, tp)
end

-- ==========================================
-- EFFET 1 : Recherche Magie/Piège
-- ==========================================
function s.lkcon(e, tp, eg, ep, ev, re, r, rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

function s.lkfilter(c)
	return c:IsSetCard(0xc92) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand()
end

function s.lktg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(s.lkfilter, tp, LOCATION_DECK, 0, 1, nil) end
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end

function s.lkop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
	local g = Duel.SelectMatchingCard(tp, s.lkfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
	if #g > 0 then
		Duel.SendtoHand(g, nil, REASON_EFFECT)
		Duel.ConfirmCards(1 - tp, g)
	end
end

-- ==========================================
-- EFFET 2 : Envoyé au Cimetière (Révéler + Effet)
-- ==========================================
function s.revfilter(c, tp)
	if not (c:IsSetCard(0xc92) and not c:IsPublic()) then return false end
	-- CORRECTION : Utilisation de IsType(TYPE_MONSTER) au lieu de IsMonster()
	if c:IsType(TYPE_MONSTER) then
		return Duel.IsExistingMatchingCard(Card.IsDestructable, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, nil)
	elseif c:IsType(TYPE_SPELL) then
		return Duel.IsExistingMatchingCard(Card.IsAbleToRemove, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, nil)
	elseif c:IsType(TYPE_TRAP) then
		return Duel.GetFieldGroupCount(tp, 0, LOCATION_HAND) > 0
	end
	return false
end

function s.gytg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(s.revfilter, tp, LOCATION_HAND, 0, 1, nil, tp) end
	Duel.SetOperationInfo(0, CATEGORY_DESTROY, nil, 1, PLAYER_ALL, LOCATION_ONFIELD)
	Duel.SetOperationInfo(0, CATEGORY_REMOVE, nil, 1, PLAYER_ALL, LOCATION_ONFIELD)
end

function s.gyop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_CONFIRM)
	local g = Duel.SelectMatchingCard(tp, s.revfilter, tp, LOCATION_HAND, 0, 1, 1, nil, tp)
	local tc = g:GetFirst()
	if tc then
		Duel.ConfirmCards(1 - tp, tc)
		Duel.ShuffleHand(tp)
		if tc:IsType(TYPE_MONSTER) then
			-- Monstre : Détruire 1 carte sur le Terrain
			Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
			local dg = Duel.SelectMatchingCard(tp, Card.IsDestructable, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, 1, nil)
			if #dg > 0 then
				Duel.Destroy(dg, REASON_EFFECT)
			end
		elseif tc:IsType(TYPE_SPELL) then
			-- Magie : Bannir 1 carte sur le Terrain
			Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
			local rg = Duel.SelectMatchingCard(tp, Card.IsAbleToRemove, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, 1, nil)
			if #rg > 0 then
				Duel.Remove(rg, POS_FACEUP, REASON_EFFECT)
			end
		elseif tc:IsType(TYPE_TRAP) then
			-- Piège : Regarder la main de l'adversaire
			local hg = Duel.GetFieldGroup(tp, 0, LOCATION_HAND)
			if #hg > 0 then
				Duel.ConfirmCards(tp, hg)
				Duel.ShuffleHand(1 - tp)
			end
		end
	end
end
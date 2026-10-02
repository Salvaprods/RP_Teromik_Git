-- Naigro, Le Petit Du Monde Tenebreux
local s, id = GetID()
function s.initial_effect(c)
	-- Effet 1 : Invoqué Normalement ou Spécialement (Tuto + Défausse)
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH + CATEGORY_HANDES)
	e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1, id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	
	local e2 = e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)

	-- Effet 2 : Effet Rapide dans le Cimetière (Bannir, défausser, et potentiellement renvoyer en main)
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 1))
	e3:SetCategory(CATEGORY_HANDES + CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetHintTiming(0, TIMING_MAIN_END + TIMINGS_CHECK_MONSTER)
	e3:SetCountLimit(1, id + 1)
	e3:SetCondition(s.gycon)
	e3:SetCost(aux.bfgcost) -- "bfgcost" veut dire "Banish from Grave as cost"
	e3:SetTarget(s.gytg)
	e3:SetOperation(s.gyop)
	c:RegisterEffect(e3)
end

s.listed_names = {}
s.listed_series = {0x6} -- 0x6 correspond à "Monde Tenebreux" (Dark World)

-- ==========================================
-- EFFET 1 : RECHERCHE ET DÉFAUSSE
-- ==========================================
function s.thfilter(c)
	return c:IsSetCard(0x6) and c:IsAbleToHand()
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil) end
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
	Duel.SetOperationInfo(0, CATEGORY_HANDES, nil, 0, tp, 1)
end

function s.thop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
	local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
	if #g > 0 and Duel.SendtoHand(g, nil, REASON_EFFECT) > 0 then
		Duel.ConfirmCards(1 - tp, g)
		Duel.ShuffleHand(tp)
		Duel.BreakEffect()
		-- Défausse par un EFFET de carte pour que les "Monde Tenebreux" puissent s'activer !
		Duel.DiscardHand(tp, nil, 1, 1, REASON_EFFECT + REASON_DISCARD, nil)
	end
end

-- ==========================================
-- EFFET 2 : DEPUIS LE CIMETIÈRE
-- ==========================================
function s.gycon(e, tp, eg, ep, ev, re, r, rp)
	-- Utilisable uniquement durant la Main Phase
	local ph = Duel.GetCurrentPhase()
	return ph == PHASE_MAIN1 or ph == PHASE_MAIN2
end

function s.gytg(e, tp, eg, ep, ev, re, r, rp, chk)
	-- Vérifie s'il y a au moins 1 carte en main pour pouvoir payer l'effet (la défausse)
	if chk == 0 then return Duel.GetFieldGroupCount(tp, LOCATION_HAND, 0) > 0 end
	Duel.SetOperationInfo(0, CATEGORY_HANDES, nil, 0, tp, 1)
end

function s.bouncefilter(c)
	-- Filtre : Magie/Piège, face recto, et pouvant retourner à la main
	return c:IsFaceup() and c:IsType(TYPE_SPELL + TYPE_TRAP) and c:IsAbleToHand()
end

function s.gyop(e, tp, eg, ep, ev, re, r, rp)
	-- 1. On défausse 1 carte
	if Duel.DiscardHand(tp, nil, 1, 1, REASON_EFFECT + REASON_DISCARD, nil) > 0 then
		-- 2. On récupère la carte qu'on vient de défausser
		local tc = Duel.GetOperatedGroup():GetFirst()
		
		-- 3. Si la carte défaussée est bien "Monde Tenebreux"
		if tc and tc:IsSetCard(0x6) then
			-- On vérifie s'il y a une cible légale sur le terrain pour le bounce
			local bgroup = Duel.GetMatchingGroup(s.bouncefilter, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, nil)
			
			-- Si oui, on demande au joueur s'il veut utiliser l'effet optionnel
			if #bgroup > 0 and Duel.SelectYesNo(tp, aux.Stringid(id, 2)) then
				Duel.BreakEffect()
				Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_RTOHAND)
				local sg = bgroup:Select(tp, 1, 1, nil)
				Duel.SendtoHand(sg, nil, REASON_EFFECT)
			end
		end
	end
end
-- Universo - Extralance
local s, id = GetID()

function s.initial_effect(c)
	-- Effet 1 : Invoqué Normalement/Spécialement ou Banni -> Ajouter Magie/Piège "Universo"
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH + CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1, id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	
	local e2 = e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)
	
	local e3 = e1:Clone()
	e3:SetCode(EVENT_REMOVE)
	c:RegisterEffect(e3)

	-- Effet 2 : Effet Rapide - Annuler l'effet d'un monstre adverse
	local e4 = Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id, 1))
	e4:SetCategory(CATEGORY_DISABLE)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_CHAINING)
	e4:SetRange(LOCATION_GRAVE)
	e4:SetCountLimit(1, id + 100)
	e4:SetCondition(s.negcon)
	e4:SetCost(aux.bfgcost) -- Banni cette carte depuis le Cimetière comme coût
	e4:SetTarget(s.negtg)
	e4:SetOperation(s.negop)
	c:RegisterEffect(e4)
end

-- ==========================================
-- EFFET 1 : RECHERCHE ET AUTO-INVOCATION
-- ==========================================
function s.thfilter(c)
	return c:IsSetCard(0xc17) and c:IsType(TYPE_SPELL + TYPE_TRAP) and c:IsAbleToHand()
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil) end
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
	if e:GetCode() == EVENT_REMOVE then
		Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, e:GetHandler(), 1, 0, 0)
	end
end

function s.thop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
	local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
	if #g > 0 and Duel.SendtoHand(g, nil, REASON_EFFECT) > 0 then
		Duel.ConfirmCards(1 - tp, g)
		
		local c = e:GetHandler()
		-- Si cette carte est actuellement bannie, on demande l'Invocation Spéciale
		if c:IsRelateToEffect(e) and c:IsLocation(LOCATION_REMOVED) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false) then
			if Duel.SelectYesNo(tp, aux.Stringid(id, 2)) then -- Demande "Voulez-vous Invoquer Spécialement cette carte ?"
				Duel.BreakEffect()
				Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP)
			end
		end
	end
end

-- ==========================================
-- EFFET 2 : ANNULATION EFFET MONSTRE
-- ==========================================
function s.lkfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xc17) and c:IsType(TYPE_LINK) and c:GetLink() == 3
end

function s.negcon(e, tp, eg, ep, ev, re, r, rp)
	-- L'adversaire active un effet de monstre ET vous contrôlez un Monstre Lien-3 "Universo"
	return rp == 1 - tp and re:IsActiveType(TYPE_MONSTER) and Duel.IsChainDisablable(ev)
		and Duel.IsExistingMatchingCard(s.lkfilter, tp, LOCATION_MZONE, 0, 1, nil)
end

function s.negtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return true end
	Duel.SetOperationInfo(0, CATEGORY_DISABLE, eg, 1, 0, 0)
end

function s.negop(e, tp, eg, ep, ev, re, r, rp)
	Duel.NegateEffect(ev)
end
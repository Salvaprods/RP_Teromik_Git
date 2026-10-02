-- Queentwins - Surprise
local s, id = GetID()

s.listed_series = {0xd44}

function s.initial_effect(c)
	-- Activation : Tuto 1 monstre Queentwins + Annulation d'un monstre dans la Main Zone adverse
	local e1 = Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH + CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1, id, EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- ==========================================
-- FILTRES ET CIBLAGE
-- ==========================================
function s.thfilter(c)
	return (c:IsSetCard(0xd44) or c:IsOriginalSetCard(0xd44))
		and c:IsType(TYPE_MONSTER)
		and c:IsAbleToHand()
end

function s.disfilter(c)
	return c:IsFaceup() and c:IsLocation(LOCATION_MMZONE) and not c:IsDisabled()
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsControler(1 - tp) and s.disfilter(chkc) end
	if chk == 0 then
		return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil)
	end
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
	
	-- Ciblage optionnel du monstre dans la Main Zone adverse
	if Duel.IsExistingTarget(s.disfilter, tp, 0, LOCATION_MMZONE, 1, nil)
		and Duel.SelectYesNo(tp, aux.Stringid(id, 0)) then
		e:SetProperty(EFFECT_FLAG_CARD_TARGET)
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DISABLE)
		local g = Duel.SelectTarget(tp, s.disfilter, tp, 0, LOCATION_MMZONE, 1, 1, nil)
		Duel.SetOperationInfo(0, CATEGORY_DISABLE, g, 1, 0, 0)
	else
		e:SetProperty(0)
	end
end

-- ==========================================
-- RÉSOLUTION DE L'EFFET
-- ==========================================
function s.activate(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
	local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
	if #g > 0 and Duel.SendtoHand(g, nil, REASON_EFFECT) > 0 and g:GetFirst():IsLocation(LOCATION_HAND) then
		Duel.ConfirmCards(1 - tp, g)
		
		-- Partie optionnelle : Annulation des effets
		local tc = Duel.GetFirstTarget()
		if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() and not tc:IsDisabled() then
			Duel.BreakEffect()
			local c = e:GetHandler()
			
			local e1 = Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT + RESETS_STANDARD)
			tc:RegisterEffect(e1)
			
			local e2 = Effect.CreateEffect(c)
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			e2:SetReset(RESET_EVENT + RESETS_STANDARD)
			tc:RegisterEffect(e2)
		end
	end
end
-- Le Seigneur Des Tenebres Du Monde Tenebreux
local s, id = GetID()

s.listed_series = {0x6} -- Monde Ténébreux

function s.initial_effect(c)
	-- Invocation Fusion : 5 monstres "Monde Ténébreux"
	c:EnableReviveLimit()
	aux.AddFusionProcFunRep(c, aux.FilterBoolFunction(Card.IsSetCard, 0x6), 5, true)

	-- Effet 1 : Effet Rapide (Défausser n'importe quel nombre -> Piocher autant + bannir cartes adverses par tranche de 3 "Monde Ténébreux")
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_DRAW + CATEGORY_HANDES + CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetHintTiming(0, TIMING_MAIN_END + TIMINGS_CHECK_MONSTER)
	e1:SetCountLimit(1, id)
	e1:SetCondition(s.drcon)
	e1:SetTarget(s.drtg)
	e1:SetOperation(s.drop)
	c:RegisterEffect(e1)

	-- Effet 2 : Si renvoyée dans l'Extra Deck -> Détruire 1 carte sur le terrain
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_TO_DECK)
	e2:SetCountLimit(1, id + 100)
	e2:SetCondition(s.todccon)
	e2:SetTarget(s.todctg)
	e2:SetOperation(s.todcop)
	c:RegisterEffect(e2)
end

-- ==========================================
-- EFFET 1 : DÉFAUSSE & PIOCHE + BANNISSEMENT
-- ==========================================
function s.drcon(e, tp, eg, ep, ev, re, r, rp)
	local ph = Duel.GetCurrentPhase()
	return ph == PHASE_MAIN1 or ph == PHASE_MAIN2
end

function s.drtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then 
		return Duel.GetFieldGroupCount(tp, LOCATION_HAND, 0) > 0 
			and Duel.IsPlayerCanDraw(tp, 1) 
	end
	Duel.SetOperationInfo(0, CATEGORY_HANDES, nil, 1, tp, LOCATION_HAND)
	Duel.SetOperationInfo(0, CATEGORY_DRAW, nil, 0, tp, 1)
end

function s.drop(e, tp, eg, ep, ev, re, r, rp)
	local hg = Duel.GetFieldGroup(tp, LOCATION_HAND, 0)
	if #hg == 0 then return end
	
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DISCARD)
	local g = Duel.SelectMatchingCard(tp, nil, tp, LOCATION_HAND, 0, 1, #hg, nil)
	if #g > 0 then
		local ct = Duel.SendtoGrave(g, REASON_EFFECT + REASON_DISCARD)
		if ct > 0 then
			local dw_count = g:FilterCount(Card.IsSetCard, nil, 0x6)
			Duel.Draw(tp, ct, REASON_EFFECT)
			
			local ban_count = math.floor(dw_count / 3)
			if ban_count > 0 then
				for i = 1, ban_count do
					local bgroup = Duel.GetMatchingGroup(Card.IsAbleToRemove, 1 - tp, LOCATION_HAND + LOCATION_ONFIELD, 0, nil)
					if #bgroup > 0 then
						Duel.Hint(HINT_SELECTMSG, 1 - tp, HINTMSG_REMOVE)
						local sg = bgroup:Select(1 - tp, 1, 1, nil)
						Duel.Remove(sg, POS_FACEUP, REASON_EFFECT)
					end
				end
			end
		end
	end
end

-- ==========================================
-- EFFET 2 : RENVOYÉE DANS L'EXTRA DECK
-- ==========================================
function s.todccon(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	return c:IsLocation(LOCATION_EXTRA)
end

function s.todctg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsOnField() end
	if chk == 0 then return Duel.IsExistingTarget(nil, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
	local g = Duel.SelectTarget(tp, nil, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, 1, 0, 0)
end

function s.todcop(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc, REASON_EFFECT)
	end
end
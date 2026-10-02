-- Erik - Âme Du Chasseur
local s, id = GetID()

function s.initial_effect(c)
	-- ==========================================
	-- MÉCANIQUE PENDULE
	-- ==========================================
	aux.EnablePendulumAttribute(c)

	-- ==========================================
	-- EFFET PENDULE (P)
	-- ==========================================
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_PZONE)
	e1:SetCountLimit(1, id)
	e1:SetCost(s.drcost)
	e1:SetTarget(s.drtg)
	e1:SetOperation(s.drop)
	c:RegisterEffect(e1)
	
	-- ==========================================
	-- EFFETS DE MONSTRE (E)
	-- ==========================================
	-- Effet 1 : Arrivé face recto à l'Extra Deck -> S'Invoquer (Condition stricte de zone Extra)
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_LEAVE_FIELD)
	e2:SetRange(LOCATION_EXTRA)
	e2:SetCountLimit(1, id + 100)
	e2:SetCondition(s.pzcon)
	e2:SetTarget(s.extg)
	e2:SetOperation(s.exop)
	c:RegisterEffect(e2)

	-- Effet 2 : Invoqué Normalement ou Spécialement -> Envoyer ED au Cimetière -> SS Deck
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 2))
	e3:SetCategory(CATEGORY_TOGRAVE + CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetCountLimit(1, id + 200)
	e3:SetTarget(s.sptg2)
	e3:SetOperation(s.spop2)
	c:RegisterEffect(e3)
	
	local e3_bis = e3:Clone()
	e3_bis:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3_bis)
end

function s.hunter_filter(c)
	return c:IsSetCard(0xc92)
end

-- ==========================================
-- EFFET PENDULE (Pioche)
-- ==========================================
function s.drcost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return e:GetHandler():IsDestructable() end
	Duel.Destroy(e:GetHandler(), REASON_COST)
end

function s.drtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsPlayerCanDraw(tp, 1) end
	local ct = 1
	if Duel.GetFieldGroupCount(tp, 0, LOCATION_ONFIELD) > Duel.GetFieldGroupCount(tp, LOCATION_ONFIELD, 0) then
		ct = 2
	end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(ct)
	Duel.SetOperationInfo(0, CATEGORY_DRAW, nil, 0, tp, ct)
end

function s.drop(e, tp, eg, ep, ev, re, r, rp)
	local p, d = Duel.GetChainInfo(0, CHAININFO_TARGET_PLAYER, CHAININFO_TARGET_PARAM)
	Duel.Draw(p, d, REASON_EFFECT)
end

-- ==========================================
-- EFFET MONSTRE 1 : Arrivée Extra Deck
-- ==========================================
function s.pzcon(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	return c:IsLocation(LOCATION_EXTRA) and c:IsFaceup() and c:IsPreviousLocation(LOCATION_ONFIELD)
end

function s.extg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then 
		-- EMPÊCHE L'ACTIVATION S'IL N'Y A PAS DE PLACE VALIDE DEPUIS L'EXTRA DECK
		return Duel.GetLocationCountFromEx(tp, tp, nil, c) > 0 
			and c:IsCanBeSpecialSummoned(e, 0, tp, false, false) 
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, 0, 0)
end

function s.exop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP)
	end
end

-- ==========================================
-- EFFET MONSTRE 2 : Envoyer ED au Cimetière -> SS depuis le Deck
-- ==========================================
function s.tgfilter(c, e, tp)
	return c:IsSetCard(0xc92) and c:IsFaceup() and c:IsAbleToGrave()
		and Duel.IsExistingMatchingCard(s.spfilter2, tp, LOCATION_DECK, 0, 1, nil, e, tp)
end

function s.spfilter2(c, e, tp)
	return c:IsSetCard(0xc92) and not c:IsCode(id) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.sptg2(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then 
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and Duel.IsExistingMatchingCard(s.tgfilter, tp, LOCATION_EXTRA, 0, 1, nil, e, tp)
	end
	Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, nil, 1, tp, LOCATION_EXTRA)
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_DECK)
end

function s.spop2(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
	local g = Duel.SelectMatchingCard(tp, s.tgfilter, tp, LOCATION_EXTRA, 0, 1, 1, nil, e, tp)
	if #g > 0 and Duel.SendtoGrave(g, REASON_EFFECT) > 0 then
		if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
		local sg = Duel.SelectMatchingCard(tp, s.spfilter2, tp, LOCATION_DECK, 0, 1, 1, nil, e, tp)
		local tc = sg:GetFirst()
		if tc and Duel.SpecialSummon(tc, 0, tp, tp, false, false, POS_FACEUP) > 0 then
			local e1 = Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
			local e2 = Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e2)
		end
	end
end
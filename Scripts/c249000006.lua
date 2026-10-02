-- Universo - Double Dragon Du Vide
local s, id = GetID()

function s.initial_effect(c)
	-- Matériels : 2 monstres non-Lien "Universo"
	c:EnableReviveLimit()
	if Link and Link.AddProcedure then
		Link.AddProcedure(c, s.matfilter, 2, 2)
	else
		aux.AddLinkProcedure(c, s.matfilter, 2, 2)
	end

	-- Effet 1 : Invoquer Spécialement en Défense face recto dans une zone pointée + anti-réponse si "Source d'Énergie"
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1, id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Effet 2 : Effet Rapide immédiatement après la résolution d'une carte/effet adverse -> Invocation Lien
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAIN_SOLVED)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1, id + 100)
	e2:SetCondition(s.lkcon)
	e2:SetTarget(s.lktg)
	e2:SetOperation(s.lkop)
	c:RegisterEffect(e2)
end

-- ==========================================
-- FILTRES DE BASE
-- ==========================================
function s.matfilter(c, lc, sumtype, tp)
	return c:IsSetCard(0xc17, lc, sumtype, tp) and not c:IsType(TYPE_LINK, lc, sumtype, tp)
end

function s.cfilter(c)
	return c:IsFaceup() and c:IsCode(249000000)
end

-- ==========================================
-- EFFET 1 : INVOCATION EN ZONE POINTÉE (FACE RECTO)
-- ==========================================
function s.spcon(e, tp, eg, ep, ev, re, r, rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

function s.spfilter(c, e, tp, zone)
	return c:IsSetCard(0xc17) and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup())
		and c:IsCanBeSpecialSummoned(e, 0, tp, false, false, POS_FACEUP_DEFENSE, tp, zone)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	local zone = c:GetLinkedZone(tp)
	if chk == 0 then
		return zone ~= 0 and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_GRAVE + LOCATION_REMOVED, 0, 1, nil, e, tp, zone)
	end
	-- Bloque les effets de monstre adverses si "Universo - Source d'Énergie" (ID: 249000000) est sur le Terrain
	if Duel.IsExistingMatchingCard(s.cfilter, tp, LOCATION_ONFIELD, 0, 1, nil) then
		Duel.SetChainLimit(s.chainlm)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_GRAVE + LOCATION_REMOVED)
end

function s.chainlm(e, ep, tp)
	return tp == ep or not e:IsActiveType(TYPE_MONSTER)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local zone = c:GetLinkedZone(tp)
	if zone == 0 then return end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local g = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_GRAVE + LOCATION_REMOVED, 0, 1, 1, nil, e, tp, zone)
	if #g > 0 then
		Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP_DEFENSE, zone)
	end
end

-- ==========================================
-- EFFET 2 : INVOCATION LIEN APRÈS RÉPONSE (TERRAIN UNIQUEMENT)
-- ==========================================
function s.lkcon(e, tp, eg, ep, ev, re, r, rp)
	return rp == 1 - tp
end

function s.lkfilter(c)
	return c:IsSetCard(0xc17) and c:IsType(TYPE_LINK) and c:IsLinkSummonable(nil)
end

function s.lktg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.IsExistingMatchingCard(s.lkfilter, tp, LOCATION_EXTRA, 0, 1, nil)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_EXTRA)
end

function s.lkop(e, tp, eg, ep, ev, re, r, rp)
	local g = Duel.GetMatchingGroup(s.lkfilter, tp, LOCATION_EXTRA, 0, nil)
	if #g > 0 then
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
		local sg = g:Select(tp, 1, 1, nil)
		local lkc = sg:GetFirst()
		
		if Link and Link.Summon then
			Link.Summon(tp, lkc, nil)
		else
			Duel.LinkSummon(tp, lkc, nil)
		end
	end
end
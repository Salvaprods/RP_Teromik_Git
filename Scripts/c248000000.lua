-- Typhon Radieux Fonix, Flamme Divine
local s, id = GetID()

function s.initial_effect(c)
	-- Matériels Lien : 2+ monstres "Typhon Radieux"
	c:EnableReviveLimit()
	
	-- Compatibilité Ancienne et Nouvelle version du Core
	if Link and Link.AddProcedure then
		Link.AddProcedure(c, s.matfilter, 2, 99)
	else
		aux.AddLinkProcedure(c, s.matfilter, 2, 99)
	end

	-- Effet 1 : Boost d'ATK pour chaque monstre "Typhon Radieux" de nom différent dans le Cimetière
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_MZONE, 0)
	e1:SetTarget(s.atktg)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)

	-- Effet 2 : Cibler 1 Zone Monstre adverse -> l'adversaire envoie le monstre au Cimetière (1x par DUEL)
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 0))
	e2:SetCategory(CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1, id + EFFECT_COUNT_CODE_DUEL) 
	e2:SetTarget(s.tgtg)
	e2:SetOperation(s.tgop)
	c:RegisterEffect(e2)

	-- Effet 3 : Si une Magie Jeu-Rapide est activée -> Invoquer Spécialement depuis le Cimetière (1x par TOUR)
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1, id)
	e3:SetCondition(s.spcon)
	e3:SetCost(s.spcost)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

-- Vérification de l'archétype "Typhon Radieux"
function s.is_setcard(c)
	return c:IsSetCard(0xd101) or c:IsSetCard(0x01d1)
end

-- Filtre des matériels Link
function s.matfilter(c, scard, sumtype, tp)
	return s.is_setcard(c)
end

-- ==========================================
-- EFFET 1 : BOOST ATK
-- ==========================================
function s.atktg(e, c)
	return s.is_setcard(c)
end

function s.atkval(e, c)
	local tp = e:GetHandlerPlayer()
	local g = Duel.GetMatchingGroup(function(tc)
		-- CORRECTION ICI : Remplacement de tc:IsMonster() par tc:IsType(TYPE_MONSTER)
		return tc:IsType(TYPE_MONSTER) and s.is_setcard(tc)
	end, tp, LOCATION_GRAVE, 0, nil)
	return g:GetClassCount(Card.GetCode) * 100
end

-- ==========================================
-- EFFET 2 : ADVERSAIRE ENVOIE AU CIMETIÈRE (1x/Duel)
-- ==========================================
function s.tgtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) end
	if chk == 0 then
		return Duel.IsExistingTarget(aux.TRUE, tp, 0, LOCATION_MZONE, 1, nil)
	end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
	local g = Duel.SelectTarget(tp, aux.TRUE, tp, 0, LOCATION_MZONE, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, g, 1, 0, 0)
end

function s.tgop(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsControler(1-tp) then
		Duel.SendtoGrave(tc, REASON_RULE, 1-tp)
	end
end

-- ==========================================
-- EFFET 3 : AUTO-REINVOCATION DU CIMETIÈRE
-- ==========================================
function s.spcon(e, tp, eg, ep, ev, re, r, rp)
	return re:IsHasType(EFFECT_TYPE_ACTIVATE) and re:IsActiveType(TYPE_QUICKPLAY)
end

function s.costfilter(c)
	return s.is_setcard(c) and c:IsAbleToDeckAsCost()
end

function s.spcost(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	local g = Duel.GetMatchingGroup(s.costfilter, tp, LOCATION_GRAVE, 0, c)
	if chk == 0 then
		return g:GetClassCount(Card.GetCode) >= 3
	end
	
	local sg = Group.CreateGroup()
	for i = 1, 3 do
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TODECK)
		local cg = g:Filter(function(tc) return not sg:IsExists(Card.IsCode, 1, nil, tc:GetCode()) end, nil)
		local tc = cg:Select(tp, 1, 1, nil):GetFirst()
		sg:AddCard(tc)
	end
	
	Duel.SendtoDeck(sg, nil, SEQ_DECKSHUFFLE, REASON_COST)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, 0, 0)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP)
	end
end
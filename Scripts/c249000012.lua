-- Universo - Clonage Temporel
local s, id = GetID()

function s.initial_effect(c)
	-- Activer
	local e1 = Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	-- "Vous ne pouvez activer qu'1 [Nom] par tour" (OATH)
	e1:SetCountLimit(1, id, EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- ==========================================
-- FILTRES ET CONDITIONS
-- ==========================================
function s.spfilter(c, e, tp)
	-- Doit avoir un niveau > 0, appartenir à l'archétype Universo, 
	-- et être Invocable Spécialement depuis la Main, le Cimetière ou les Bannis.
	return c:IsSetCard(0xc17) and c:IsType(TYPE_MONSTER) and c:GetLevel() > 0
		and (c:IsLocation(LOCATION_HAND) or c:IsLocation(LOCATION_GRAVE) or c:IsFaceup())
		and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.filter1(c, e, tp)
	return c:IsFaceup() and c:IsSetCard(0xc17) and c:IsType(TYPE_LINK)
		and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND + LOCATION_GRAVE + LOCATION_REMOVED, 0, 1, nil, e, tp)
end

-- Filtre manuel pour s'assurer que les niveaux sont différents
function s.chkfilter(c, sg)
	if #sg == 0 then return true end
	local tc = sg:GetFirst()
	while tc do
		-- Si le niveau de la carte correspond au niveau d'une carte déjà sélectionnée, on la bloque
		if tc:GetLevel() == c:GetLevel() then return false end
		tc = sg:GetNext()
	end
	return true
end

-- ==========================================
-- ACTIVATION ET RÉSOLUTION
-- ==========================================
function s.target(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then 
		return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.filter1(chkc, e, tp) 
	end
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and Duel.GetLP(tp) >= 500
			and Duel.IsExistingTarget(s.filter1, tp, LOCATION_MZONE, 0, 1, nil, e, tp)
	end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
	Duel.SelectTarget(tp, s.filter1, tp, LOCATION_MZONE, 0, 1, 1, nil, e, tp)
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND + LOCATION_GRAVE + LOCATION_REMOVED)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if not tc:IsRelateToEffect(e) or tc:IsFacedown() then return end
	
	local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
	if ft <= 0 then return end
	if Duel.IsPlayerAffectedByEffect(tp, CARD_BLUEEYES_SPIRIT) then ft = 1 end
	
	-- Le nombre maximum est défini par le Classement Lien de la cible et les LP disponibles (500 LP par monstre)
	local max_by_lp = math.floor(Duel.GetLP(tp) / 500)
	local max_sum = math.min(tc:GetLink(), max_by_lp)
	local count = math.min(ft, max_sum)
	if count == 0 then return end
	
	local g = Duel.GetMatchingGroup(aux.NecroValleyFilter(s.spfilter), tp, LOCATION_HAND + LOCATION_GRAVE + LOCATION_REMOVED, 0, nil, e, tp)
	if #g == 0 then return end
	
	-- Boucle de sélection universelle (fonctionne sur toutes les versions)
	local sg = Group.CreateGroup()
	while #sg < count do
		-- On filtre le groupe pour ne garder que des monstres avec des niveaux non sélectionnés
		local cg = g:Filter(s.chkfilter, nil, sg)
		if #cg == 0 then break end
		
		-- S'il y a déjà 1 monstre de choisi, le min passe à 0 pour permettre au joueur de s'arrêter
		local min = (#sg == 0) and 1 or 0
		
		-- S'assurer qu'on a toujours assez de LP pour un monstre supplémentaire
		if Duel.GetLP(tp) < (#sg + 1) * 500 then break end
		
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
		local sc = cg:Select(tp, min, 1, nil):GetFirst()
		
		-- Si le joueur annule / choisit 0, on stoppe la boucle
		if not sc then break end 
		
		sg:AddCard(sc)
	end
	
	if #sg > 0 then
		-- Paiement des LP : 500 LP pour chaque monstre sélectionné/invoqué
		Duel.PayLPCost(tp, #sg * 500)
		Duel.SpecialSummon(sg, 0, tp, tp, false, false, POS_FACEUP)
	end
end
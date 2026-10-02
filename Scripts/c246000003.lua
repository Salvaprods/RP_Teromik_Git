-- Vortex Dinomorphia
local s, id = GetID()

s.listed_series = {0x173}

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- Restriction d'Invocation Spéciale (1/tour)
	c:SetSPSummonOnce(id)

	-- Condition : Non Invocable par Fusion.
	local e0 = Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(aux.FALSE)
	c:RegisterEffect(e0)

	-- Procédure d'Invocation Spéciale (Contact par Sacrifice)
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.sprcon)
	e1:SetTarget(s.sprtg)
	e1:SetOperation(s.sprop)
	c:RegisterEffect(e1)

	-- ATK/DEF d'origine : 8000 - LP
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_SET_BASE_ATTACK)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)
	local e3 = e2:Clone()
	e3:SetCode(EFFECT_SET_BASE_DEFENSE)
	c:RegisterEffect(e3)

	-- Effet 1 : Si Invoquée Spécialement -> Poser 1 M/P Dinomorphia depuis le Deck
	local e4 = Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id, 0))
	e4:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	e4:SetCountLimit(1, id)
	e4:SetTarget(s.settg)
	e4:SetOperation(s.setop)
	c:RegisterEffect(e4)

	-- Effet 2 (Effet Rapide) : Sacrifier cette carte -> Activer 1 Piège Normal Dinomorphia depuis le Deck
	local e5 = Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id, 1))
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_FREE_CHAIN)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1, id + 100)
	e5:SetCost(s.actcost)
	e5:SetTarget(s.acttg)
	e5:SetOperation(s.actop)
	c:RegisterEffect(e5)
end

-- ==========================================
-- INVOCATION PAR CONTACT (SACRIFICE)
-- ==========================================
function s.matfilter1(c)
	return c:IsFaceup() and (c:IsSetCard(0x173) or c:IsOriginalSetCard(0x173)) and c:IsReleasable()
end

function s.matfilter2(c)
	return c:IsFaceup() and c:IsReleasable()
end

function s.sprcon(e, c)
	if c == nil then return true end
	local tp = c:GetControler()
	local g1 = Duel.GetMatchingGroup(s.matfilter1, tp, LOCATION_MZONE, 0, nil)
	local g2 = Duel.GetMatchingGroup(s.matfilter2, tp, LOCATION_MZONE, LOCATION_MZONE, nil)
	return g1:IsExists(function(tc1) 
		return g2:IsExists(function(tc2) return tc1 ~= tc2 end, 1, nil) 
	end, 1, nil)
end

function s.sprtg(e, tp, eg, ep, ev, re, r, rp, c)
	local g1 = Duel.GetMatchingGroup(s.matfilter1, tp, LOCATION_MZONE, 0, nil)
	local g2 = Duel.GetMatchingGroup(s.matfilter2, tp, LOCATION_MZONE, LOCATION_MZONE, nil)
	
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_RELEASE)
	local sg1 = g1:Select(tp, 1, 1, nil)
	local tc1 = sg1:GetFirst()
	
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_RELEASE)
	local sg2 = g2:FilterSelect(tp, function(tc) return tc ~= tc1 end, 1, 1, nil)
	
	sg1:Merge(sg2)
	if #sg1 == 2 then
		sg1:KeepAlive()
		e:SetLabelObject(sg1)
		return true
	end
	return false
end

function s.sprop(e, tp, eg, ep, ev, re, r, rp, c)
	local g = e:GetLabelObject()
	if not g then return end
	Duel.Release(g, REASON_COST)
	g:DeleteGroup()
end

-- ==========================================
-- CALCUL ATK/DEF
-- ==========================================
function s.atkval(e, c)
	local lp = Duel.GetLP(e:GetHandlerPlayer())
	return math.max(0, 8000 - lp)
end

-- ==========================================
-- EFFET 1 : POSER DEPUIS LE DECK
-- ==========================================
function s.setfilter(c)
	return (c:IsSetCard(0x173) or c:IsOriginalSetCard(0x173))
		and (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP))
		and c:IsSSetable()
end

function s.settg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_SZONE) > 0
			and Duel.IsExistingMatchingCard(s.setfilter, tp, LOCATION_DECK, 0, 1, nil)
	end
end

function s.setop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetLocationCount(tp, LOCATION_SZONE) <= 0 then return end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SET)
	local g = Duel.SelectMatchingCard(tp, s.setfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
	if #g > 0 then
		Duel.SSet(tp, g:GetFirst())
	end
end

-- ==========================================
-- EFFET 2 : ACTIVATION PIÈGE NORMAL DEPUIS LE DECK
-- ==========================================
function s.actcost(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then return c:IsReleasable() end
	Duel.Release(c, REASON_COST)
end

function s.actfilter(c, tp)
	-- On utilise la bonne méthode : CheckActivateEffect(false, false, false)
	return (c:IsSetCard(0x173) or c:IsOriginalSetCard(0x173))
		and c:GetType() == TYPE_TRAP
		and c:CheckActivateEffect(false, false, false) ~= nil
end

function s.acttg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_SZONE) > 0
			and Duel.IsExistingMatchingCard(s.actfilter, tp, LOCATION_DECK, 0, 1, nil, tp)
	end
end

function s.actop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetLocationCount(tp, LOCATION_SZONE) <= 0 then return end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_OPERATECARD)
	local g = Duel.SelectMatchingCard(tp, s.actfilter, tp, LOCATION_DECK, 0, 1, 1, nil, tp)
	local tc = g:GetFirst()
	if tc then
		-- On récupère la bonne fonction d'activation
		local te, ceg, cep, cev, cre, cr, crp = tc:CheckActivateEffect(false, false, false)
		if not te then return end
		
		-- On déplace la carte sur le Terrain pour la "jouer"
		Duel.MoveToField(tc, tp, tp, LOCATION_SZONE, POS_FACEUP, true)
		Duel.Hint(HINT_CARD, 0, tc:GetCode())
		
		-- On récupère les opérations du Piège
		local tg = te:GetTarget()
		local co = te:GetCost()
		local op = te:GetOperation()
		
		e:SetCategory(te:GetCategory())
		e:SetProperty(te:GetProperty())
		
		-- Résolution forcée de l'effet
		Duel.ClearTargetCard()
		tc:CreateEffectRelation(te)
		if co then co(te, tp, ceg, cep, cev, cre, cr, crp, 1) end
		if tg then tg(te, tp, ceg, cep, cev, cre, cr, crp, 1) end
		Duel.BreakEffect()
		
		-- Gestion des cibles (si le Piège ciblait des cartes)
		local cg = Duel.GetChainInfo(0, CHAININFO_TARGET_CARDS)
		if cg then
			local etc = cg:GetFirst()
			while etc do
				etc:CreateEffectRelation(te)
				etc = cg:GetNext()
			end
		end
		
		-- Exécution de l'effet du Piège
		if op then op(te, tp, ceg, cep, cev, cre, cr, crp) end
		
		-- Nettoyage des relations
		tc:ReleaseEffectRelation(te)
		if cg then
			local etc = cg:GetFirst()
			while etc do
				etc:ReleaseEffectRelation(te)
				etc = cg:GetNext()
			end
		end
		
		-- Envoi du Piège au Cimetière (règle standard d'un Piège Normal)
		Duel.SendtoGrave(tc, REASON_RULE)
	end
end
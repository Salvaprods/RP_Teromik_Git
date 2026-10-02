-- Universo - Extrakuriboh
local s, id = GetID()

function s.initial_effect(c)
	-- Effet Rapide : Défausser cette carte ; appliquer 1 effet
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1, id)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end

-- ==========================================
-- COÛT ET CONDITIONS
-- ==========================================
function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then return c:IsDiscardable() end
	Duel.SendtoGrave(c, REASON_COST + REASON_DISCARD)
end

function s.setfilter(c)
	return c:IsSetCard(0xc17) and c:IsType(TYPE_SPELL + TYPE_TRAP) and c:IsSSetable()
end

-- ==========================================
-- SÉLECTION DE L'EFFET (CIBLE)
-- ==========================================
function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
	-- L'effet 1 (réduire les prochains dommages à 0) est toujours activable en Free Chain
	local b1 = true 
	-- L'effet 2 nécessite une carte à Poser et de pouvoir piocher
	local b2 = Duel.IsExistingMatchingCard(s.setfilter, tp, LOCATION_DECK, 0, 1, nil) and Duel.IsPlayerCanDraw(tp, 1)
	
	if chk == 0 then return b1 or b2 end
	
	local op = 0
	if b1 and b2 then
		op = Duel.SelectOption(tp, aux.Stringid(id, 1), aux.Stringid(id, 2))
	elseif b1 then
		op = Duel.SelectOption(tp, aux.Stringid(id, 1))
	else
		op = Duel.SelectOption(tp, aux.Stringid(id, 2)) + 1
	end
	e:SetLabel(op)
	
	if op == 1 then
		e:SetCategory(CATEGORY_DRAW)
		Duel.SetOperationInfo(0, CATEGORY_DRAW, nil, 0, tp, 1)
	end
end

-- ==========================================
-- RÉSOLUTION DE L'EFFET
-- ==========================================
function s.operation(e, tp, eg, ep, ev, re, r, rp)
	if e:GetLabel() == 0 then
		-- Option 1 : Les prochains dommages de combat que vous recevez ce tour deviennent 0
		local e1 = Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_CHANGE_BATTLE_DAMAGE)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e1:SetTargetRange(1, 0)
		e1:SetValue(0)
		e1:SetCountLimit(1) -- Limite l'effet uniquement à la prochaine occurrence
		e1:SetReset(RESET_PHASE + PHASE_END)
		Duel.RegisterEffect(e1, tp)
	else
		-- Option 2 : Poser 1 Magie/Piège "Universo" depuis le Deck, puis piocher 1 carte
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SET)
		local g = Duel.SelectMatchingCard(tp, s.setfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
		if #g > 0 and Duel.SSet(tp, g:GetFirst()) > 0 then
			Duel.Draw(tp, 1, REASON_EFFECT)
		end
	end
end
-- Universo - Plasma Interdit
local s, id = GetID()

function s.initial_effect(c)
	-- Règle d'activation : Peut être activée le tour où elle est Posée si vous contrôlez un Lien-2 ou 3 "Universo"
	local e0 = Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
	e0:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	e0:SetCondition(s.actcon)
	c:RegisterEffect(e0)

	-- Effet 1 : Annuler l'effet, bannir la carte et bannir 1 carte au hasard de l'Extra Deck adverse
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_DISABLE + CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCountLimit(1, id) -- HOPT 1
	e1:SetCondition(s.negcon)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)

	-- Effet 2 : Si cette carte est bannie -> Payer la moitié des LP + 1000 ; la renvoyer au Cimetière ou la Poser
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_REMOVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1, id + 100) -- HOPT 2
	e2:SetCost(s.gycost)
	e2:SetTarget(s.gytg)
	e2:SetOperation(s.gyop)
	c:RegisterEffect(e2)
end

-- ==========================================
-- ACTIVATION LE TOUR MÊME (Lien-2 ou 3)
-- ==========================================
function s.lkfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xc17) and c:IsType(TYPE_LINK) and (c:GetLink() == 2 or c:GetLink() == 3)
end

function s.actcon(e)
	return Duel.IsExistingMatchingCard(s.lkfilter, e:GetHandlerPlayer(), LOCATION_MZONE, 0, 1, nil)
end

-- ==========================================
-- EFFET 1 : ANNULATION & BANNISSEMENT (Lien quelconque requis)
-- ==========================================
function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xc17) and c:IsType(TYPE_LINK)
end

function s.negcon(e, tp, eg, ep, ev, re, r, rp)
	-- Doit contrôler au moins 1 monstre Lien "Universo"
	return rp == 1 - tp and Duel.IsChainDisablable(ev)
		and Duel.IsExistingMatchingCard(s.cfilter, tp, LOCATION_MZONE, 0, 1, nil)
end

function s.negtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return true end
	Duel.SetOperationInfo(0, CATEGORY_DISABLE, eg, 1, 0, 0)
	local rc = re:GetHandler()
	if rc:IsRelateToEffect(re) and rc:IsAbleToRemove() then
		Duel.SetOperationInfo(0, CATEGORY_REMOVE, nil, 2, 1 - tp, LOCATION_EXTRA)
	end
end

function s.negop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.NegateEffect(ev) then
		local rc = re:GetHandler()
		local rg = Group.CreateGroup()
		
		if rc:IsRelateToEffect(re) and rc:IsAbleToRemove() then
			rg:AddCard(rc)
		end
		
		local ex = Duel.GetFieldGroup(tp, 0, LOCATION_EXTRA)
		if #ex > 0 then
			local sg = ex:RandomSelect(tp, 1)
			rg:Merge(sg)
		end
		
		if #rg > 0 then
			Duel.Remove(rg, POS_FACEUP, REASON_EFFECT)
		end
	end
end

-- ==========================================
-- EFFET 2 : RECYCLAGE AVEC COÛT DE LP (MOITIÉ + 1000)
-- ==========================================
function s.gycost(e, tp, eg, ep, ev, re, r, rp, chk)
	local lp = Duel.GetLP(tp)
	local cost = math.floor(lp / 2) + 1000
	if chk == 0 then return lp > cost end
	Duel.PayLPCost(tp, cost)
end

function s.gytg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	local b1 = c:IsAbleToGrave()
	local b2 = c:IsSSetable()
	if chk == 0 then return b1 or b2 end
end

function s.gyop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local b1 = c:IsAbleToGrave()
	local b2 = c:IsSSetable()
	local op = 0
	
	if b1 and b2 then
		op = Duel.SelectOption(tp, aux.Stringid(id, 2), aux.Stringid(id, 3))
	elseif b1 then
		op = 0
	else
		op = 1
	end
	
	if op == 0 then
		Duel.SendtoGrave(c, REASON_EFFECT + REASON_RETURN)
	else
		Duel.SSet(tp, c)
	end
end
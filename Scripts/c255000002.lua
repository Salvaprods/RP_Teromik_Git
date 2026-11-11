-- Vinh, Navire de la Patroll du Pillage (Fusion)
local s,id=GetID()
local SET_PLUNDER=0x13f

function s.initial_effect(c)
	c:EnableReviveLimit()
	-- Matériels : 3 monstres "Patroll du Pillage"
	if Fusion and Fusion.AddProcMixN then
		Fusion.AddProcMixN(c,true,true,s.matfilter,3)
	else
		aux.AddFusionProcFunRep(c,s.matfilter,3,true)
	end

	-- Si Invoquée Spécialement : ajouter 1 monstre "Patroll du Pillage" du Cimetière à la main (restreint ce tour)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- Effet Rapide : l'adversaire active une Magie/Piège -> défausser 1 "Patroll du Pillage" ; annuler, détruire cette carte...
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.negcon)
	e2:SetCost(s.negcost)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)
end

-- Matériel de Fusion : monstre "Patroll du Pillage"
function s.matfilter(c)
	return c:IsSetCard(SET_PLUNDER)
end

---------------------------------------------------------------
-- Effet 1 : récupération restreinte
---------------------------------------------------------------
function s.thfilter(c)
	return c:IsSetCard(SET_PLUNDER) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local tc=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_GRAVE,0,1,1,nil):GetFirst()
	if not tc or Duel.SendtoHand(tc,nil,REASON_EFFECT)==0 then return end
	Duel.ConfirmCards(1-tp,tc)
	local c=e:GetHandler()
	-- Jusqu'à la fin du tour : impossible d'Invoquer cette carte précise ou d'activer ses effets
	local function sumlimit(e,sc) return sc==tc end
	local codes={EFFECT_CANNOT_SUMMON,EFFECT_CANNOT_MSET,EFFECT_CANNOT_FLIP_SUMMON,EFFECT_CANNOT_SPECIAL_SUMMON}
	for _,code in ipairs(codes) do
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e1:SetCode(code)
		e1:SetTargetRange(1,0)
		e1:SetTarget(sumlimit)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
	end
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetCode(EFFECT_CANNOT_ACTIVATE)
	e2:SetTargetRange(1,0)
	e2:SetValue(function(e,re,rp) return re:GetHandler()==tc end)
	e2:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e2,tp)
end

---------------------------------------------------------------
-- Effet 2 : annulation d'une Magie/Piège adverse
---------------------------------------------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
		and not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED)
		and re:IsHasType(EFFECT_TYPE_ACTIVATE)
		and re:IsActiveType(TYPE_SPELL+TYPE_TRAP)
		and Duel.IsChainNegatable(ev)
end
function s.costfilter(c)
	return c:IsSetCard(SET_PLUNDER) and c:IsDiscardable()
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_HAND,0,1,nil)
	end
	Duel.DiscardHand(tp,s.costfilter,1,1,REASON_COST+REASON_DISCARD)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,e:GetHandler(),1,0,0)
end
function s.eqfilter(c)
	return c:IsSetCard(SET_PLUNDER)
end
function s.gythfilter(c)
	return c:IsSetCard(SET_PLUNDER) and c:IsAbleToHand()
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not Duel.NegateActivation(ev) then return end
	if not c:IsRelateToEffect(e) then return end
	-- On regarde l'équipement AVANT la destruction (après, il n'est plus équipé)
	local equipped=c:GetEquipGroup():IsExists(s.eqfilter,1,nil)
	if Duel.Destroy(c,REASON_EFFECT)==0 then return end
	if not equipped then return end
	if not Duel.IsExistingMatchingCard(aux.NecroValleyFilter(s.gythfilter),tp,LOCATION_GRAVE,0,1,nil) then return end
	-- str3 : "Add 1 'Plunder Patroll' card from your GY to your hand?"
	if not Duel.SelectYesNo(tp,aux.Stringid(id,2)) then return end
	Duel.BreakEffect()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.gythfilter),tp,LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
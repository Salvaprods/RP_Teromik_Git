-- Pièce Dorée de l'Animépée (Magie Normale)
local s,id=GetID()
function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- gc (Cimetière) est-il un monstre "Animépée" du même nom que c ?
function s.samename(gc,c)
	return gc:IsSetCard(0xd64) and gc:IsType(TYPE_MONSTER) and gc:IsCode(c:GetCode())
end
-- Monstre "Animépée" du Deck dont le nom n'est pas déjà dans le Cimetière
-- dc = carte qu'on va défausser (elle sera aussi au Cimetière au moment de la recherche)
function s.thfilter(c,tp,dc)
	if not (c:IsSetCard(0xd64) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()) then return false end
	if Duel.IsExistingMatchingCard(s.samename,tp,LOCATION_GRAVE,0,1,nil,c) then return false end
	if dc and s.samename(dc,c) then return false end
	return true
end
-- Carte défaussable qui laisse encore une recherche possible après la défausse
function s.discfilter(c,tp)
	return c:IsDiscardable()
		and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil,tp,c)
end

-- Le coût est payé dans le target pour pouvoir vérifier la défausse + la recherche ensemble
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	e:SetLabel(1)
	return true
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		if e:GetLabel()~=1 then return false end
		e:SetLabel(0)
		return Duel.IsExistingMatchingCard(s.discfilter,tp,LOCATION_HAND,0,1,c,tp)
	end
	e:SetLabel(0)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
	local g=Duel.SelectMatchingCard(tp,s.discfilter,tp,LOCATION_HAND,0,1,1,c,tp)
	Duel.SendtoGrave(g,REASON_COST+REASON_DISCARD)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil,tp,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
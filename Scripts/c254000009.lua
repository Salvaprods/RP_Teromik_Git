-- Bouclier de l'Animépée (Magie d'Équipement)
local s,id=GetID()
function s.initial_effect(c)
	-- Activation : équiper un monstre face recto (1 activation par tour)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_EQUIP)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_CONTINUOUS_TARGET)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.eqtg)
	e1:SetOperation(s.eqop)
	c:RegisterEffect(e1)
	-- Peut équiper n'importe quel monstre
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_EQUIP_LIMIT)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e2:SetValue(1)
	c:RegisterEffect(e2)

	-- Remplacement : détruire cette carte à la place du monstre "Animépée" équipé (optionnel)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_DESTROY_REPLACE)
	e3:SetRange(LOCATION_SZONE)
	e3:SetTarget(s.reptg)
	e3:SetValue(s.repval)
	e3:SetOperation(s.repop)
	c:RegisterEffect(e3)

	-- Cimetière : bannir cette carte + défausser 1 carte ; piocher puis replacer sous le Deck
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_DRAW+CATEGORY_TODECK)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_GRAVE)
	e4:SetCountLimit(1,id+100)
	e4:SetCost(s.drcost)
	e4:SetTarget(s.drtg)
	e4:SetOperation(s.drop)
	c:RegisterEffect(e4)
end

---------------------------------------------------------------
-- Équipement
---------------------------------------------------------------
function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsFaceup() end
	if chk==0 then
		return Duel.IsExistingTarget(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local g=Duel.SelectTarget(tp,Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,e:GetHandler(),1,0,0)
end
function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		Duel.Equip(tp,c,tc)
	end
end

---------------------------------------------------------------
-- Remplacement de destruction (combat OU effet)
---------------------------------------------------------------
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local ec=c:GetEquipTarget()
	if chk==0 then
		return ec and eg:IsContains(ec)
			and ec:IsFaceup() and ec:IsSetCard(0xd64)
			and ec:IsReason(REASON_BATTLE+REASON_EFFECT) and not ec:IsReason(REASON_REPLACE)
			and c:IsDestructable(e) and not c:IsStatus(STATUS_DESTROY_CONFIRMED)
	end
	return Duel.SelectEffectYesNo(tp,c,96)
end
function s.repval(e,c)
	return c==e:GetHandler():GetEquipTarget()
end
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Destroy(e:GetHandler(),REASON_EFFECT+REASON_REPLACE)
end

---------------------------------------------------------------
-- Effet Cimetière
---------------------------------------------------------------
function s.animefilter(c)
	return c:IsFaceup() and c:IsSetCard(0xd64) and c:IsType(TYPE_MONSTER)
end
function s.drcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return c:IsAbleToRemoveAsCost()
			and Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil)
	end
	-- "bannir cette carte, puis défausser 1 carte"
	Duel.Remove(c,POS_FACEUP,REASON_COST)
	Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=Duel.GetMatchingGroupCount(s.animefilter,tp,LOCATION_MZONE,0,nil)
	if chk==0 then
		return ct>0 and Duel.IsPlayerCanDraw(tp,ct)
	end
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,ct)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,ct,tp,LOCATION_HAND)
end
function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local ct=Duel.GetMatchingGroupCount(s.animefilter,tp,LOCATION_MZONE,0,nil)
	if ct==0 then return end
	local dc=Duel.Draw(tp,ct,REASON_EFFECT)
	if dc==0 then return end
	Duel.BreakEffect()
	Duel.ShuffleHand(tp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,Card.IsAbleToDeck,tp,LOCATION_HAND,0,dc,dc,nil)
	if #g==0 then return end
	-- Même méthode que Royaume des Bêtes (YGO Omega n'a pas SortDeckbottom)
	local sent=Duel.SendtoDeck(g,nil,0,REASON_EFFECT)
	if sent==0 then return end
	if sent>1 then
		Duel.SortDecktop(tp,tp,sent)
	end
	for i=1,sent do
		local tc=Duel.GetDecktopGroup(tp,1):GetFirst()
		Duel.MoveSequence(tc,1)
	end
end
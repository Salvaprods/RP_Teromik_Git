-- Animépée - Sworderila (Lien 3)
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	-- Matériels : 2+ monstres "Animépée"
	if Link and Link.AddProcedure then
		Link.AddProcedure(c,s.matfilter,2,3)
	else
		aux.AddLinkProcedure(c,s.matfilter,2,3)
	end

	-- Gagne 200 ATK pour chaque monstre "Animépée" que tu contrôles
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)

	-- Déclaration d'attaque : réanimer des "Animépée" (effets annulés), perte de LP
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_ATTACK_ANNOUNCE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	-- Envoyée du Terrain au Cimetière : réanimer 1 "Animépée"
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetCountLimit(1,id+100)
	e3:SetCondition(s.gycon)
	e3:SetTarget(s.gytg)
	e3:SetOperation(s.gyop)
	c:RegisterEffect(e3)
end

-- Matériel de Lien : monstre "Animépée"
function s.matfilter(c)
	return c:IsSetCard(0xd64)
end

---------------------------------------------------------------
-- ATK
---------------------------------------------------------------
function s.animefilter(c)
	return c:IsFaceup() and c:IsSetCard(0xd64) and c:IsType(TYPE_MONSTER)
end
function s.atkval(e,c)
	return Duel.GetMatchingGroupCount(s.animefilter,c:GetControler(),LOCATION_MZONE,0,nil)*200
end

---------------------------------------------------------------
-- Effet d'attaque
---------------------------------------------------------------
-- Nombre de Zones Monstre pointées et inoccupées (ton côté + côté adverse)
function s.freelinked(c,tp)
	local ct=0
	-- Ton côté : Zones Monstre Principales (0-4) + Zones Monstre Extra (5-6)
	local z1=c:GetLinkedZone(tp)&0x7f
	for i=0,6 do
		if z1&(1<<i)~=0 and Duel.CheckLocation(tp,LOCATION_MZONE,i) then ct=ct+1 end
	end
	-- Côté adverse : Zones Monstre Principales (0-4)
	local z2=c:GetLinkedZone(1-tp)&0x1f
	for i=0,4 do
		if z2&(1<<i)~=0 and Duel.CheckLocation(1-tp,LOCATION_MZONE,i) then ct=ct+1 end
	end
	return ct
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0xd64) and c:IsType(TYPE_MONSTER)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.getmax(c,tp)
	local ct=math.min(s.freelinked(c,tp),Duel.GetLocationCount(tp,LOCATION_MZONE))
	-- Esprit Dragon aux Yeux Bleus : 1 seule Invocation Spéciale à la fois
	if ct>1 and Duel.IsPlayerAffectedByEffect(tp,59822133) then ct=1 end
	return ct
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.spfilter(chkc,e,tp) end
	local ct=s.getmax(e:GetHandler(),tp)
	if chk==0 then
		return ct>0 and Duel.IsExistingTarget(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,ct,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,#g,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS):Filter(Card.IsRelateToEffect,nil,e)
	g=g:Filter(s.spfilter,nil,e,tp)
	if #g==0 then return end
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 then return end
	if ft>1 and Duel.IsPlayerAffectedByEffect(tp,59822133) then ft=1 end
	-- Pas assez de place : tu choisis lesquels Invoquer
	if #g>ft then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		g=g:Select(tp,ft,ft,nil)
	end
	local sg=Group.CreateGroup()
	for tc in aux.Next(g) do
		if Duel.SpecialSummonStep(tc,0,tp,tp,false,false,POS_FACEUP) then
			-- Effets annulés
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
			local e2=e1:Clone()
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			tc:RegisterEffect(e2)
			sg:AddCard(tc)
		end
	end
	Duel.SpecialSummonComplete()
	-- Perte de LP = somme des Niveaux x 100
	if #sg>0 then
		local lp=sg:GetSum(Card.GetLevel)*100
		if lp>0 then
			Duel.SetLP(tp,math.max(Duel.GetLP(tp)-lp,0))
		end
	end
end

---------------------------------------------------------------
-- Effet Cimetière
---------------------------------------------------------------
function s.gycon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_ONFIELD)
end
function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.spfilter(chkc,e,tp) end
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingTarget(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end
function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end
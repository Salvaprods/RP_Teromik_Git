-- Animépée - Archera (Lien 2)
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	-- Matériels : 2 monstres (À ADAPTER si tes matériels sont différents)
	if Link and Link.AddProcedure then
		Link.AddProcedure(c,nil,2,2)
	else
		aux.AddLinkProcedure(c,nil,2,2)
	end

	-- Si Invoquée par Lien : Invoquer Spécialement 1 "Animépée" depuis le Cimetière, en Défense, dans une zone pointée
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.gycon)
	e1:SetTarget(s.gytg)
	e1:SetOperation(s.gyop)
	c:RegisterEffect(e1)

	-- Si un monstre est Invoqué Spécialement dans une zone pointée : effet selon son contrôleur
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.zcon)
	e2:SetTarget(s.ztg)
	e2:SetOperation(s.zop)
	c:RegisterEffect(e2)
end

---------------------------------------------------------------
-- Effet 1 : réanimation dans une zone pointée
---------------------------------------------------------------
function s.gycon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end
-- Zones pointées ET libres d'un côté (p = joueur sur le terrain duquel on invoque)
function s.getzone(c,tp,p)
	local linked=c:GetLinkedZone(p)&0x1f
	local zone=0
	for i=0,4 do
		if linked&(1<<i)~=0 and Duel.CheckLocation(p,LOCATION_MZONE,i) then
			zone=zone|(1<<i)
		end
	end
	return zone
end
-- Peut aller dans une zone pointée de ton terrain (z1) OU du terrain adverse (z2)
function s.gyfilter(c,e,tp,z1,z2)
	if not (c:IsSetCard(0xd64) and c:IsType(TYPE_MONSTER)) then return false end
	return (z1~=0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE,tp,z1))
		or (z2~=0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE,1-tp,z2))
end
function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local z1=s.getzone(c,tp,tp)
	local z2=s.getzone(c,tp,1-tp)
	if chk==0 then
		return (z1~=0 or z2~=0)
			and Duel.IsExistingMatchingCard(s.gyfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp,z1,z2)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
	local z1=s.getzone(c,tp,tp)
	local z2=s.getzone(c,tp,1-tp)
	if z1==0 and z2==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.gyfilter),tp,LOCATION_GRAVE,0,1,1,nil,e,tp,z1,z2):GetFirst()
	if not tc then return end
	-- Zones où CE monstre peut aller
	if not (z1~=0 and tc:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE,tp,z1)) then z1=0 end
	if not (z2~=0 and tc:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE,1-tp,z2)) then z2=0 end
	if z1==0 and z2==0 then return end
	-- Sélection directe sur le terrain : bits 0-4 = tes zones, bits 16-20 = zones adverses
	-- Le dernier paramètre = zones INTERDITES, donc on inverse les zones autorisées
	local allowed=z1|(z2<<16)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOZONE or 571)
	local sel=Duel.SelectField(tp,1,LOCATION_MZONE,LOCATION_MZONE,~allowed)
	if sel&0x1f~=0 then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP_DEFENSE,sel&0x1f)
	else
		Duel.SpecialSummon(tc,0,tp,1-tp,false,false,POS_FACEUP_DEFENSE,(sel>>16)&0x1f)
	end
end

---------------------------------------------------------------
-- Effet 2 : monstre Invoqué Spécialement dans une zone pointée
---------------------------------------------------------------
-- Monstre face recto, Invoqué dans une zone pointée par Archera
function s.zfilter(c,lg)
	return c:IsFaceup() and lg:IsContains(c)
end
function s.zcon(e,tp,eg,ep,ev,re,r,rp)
	local lg=e:GetHandler():GetLinkedGroup()
	return lg and eg:IsExists(s.zfilter,1,nil,lg)
end

-- Toi : Magie/Piège "Animépée" depuis le Deck
function s.thfilter(c)
	return c:IsSetCard(0xd64) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand()
end
-- Adversaire : monstre de ta main avec ATK <= celle de ce monstre
function s.hspfilter(c,e,tp,atk)
	return c:IsType(TYPE_MONSTER) and c:GetAttack()<=atk
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
-- Le monstre peut-il servir de déclencheur (un effet applicable existe) ?
function s.validfilter(c,e,tp,lg)
	if not s.zfilter(c,lg) then return false end
	if c:IsControler(tp) then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
	else
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.hspfilter,tp,LOCATION_HAND,0,1,nil,e,tp,c:GetAttack())
	end
end
function s.ztg(e,tp,eg,ep,ev,re,r,rp,chk)
	local lg=e:GetHandler():GetLinkedGroup()
	if chk==0 then
		return lg and eg:IsExists(s.validfilter,1,nil,e,tp,lg)
	end
	-- S'il y a plusieurs monstres possibles, on choisit lequel sert de référence (sans cibler)
	local g=eg:Filter(s.validfilter,nil,e,tp,lg)
	local tc=g:GetFirst()
	if #g>1 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SELECT)
		tc=g:Select(tp,1,1,nil):GetFirst()
	end
	tc:CreateEffectRelation(e)
	e:SetLabelObject(tc)
	if tc:IsControler(tp) then
		e:SetLabel(0)
		e:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	else
		e:SetLabel(1)
		e:SetCategory(CATEGORY_SPECIAL_SUMMON)
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
	end
end
function s.zop(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	if e:GetLabel()==0 then
		-- Toi : recherche
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end
	else
		-- Adversaire : Invocation Spéciale depuis ta main (ATK du monstre vérifiée à la résolution)
		if not tc or not tc:IsRelateToEffect(e) or tc:IsFacedown() then return end
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.hspfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp,tc:GetAttack())
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end
-- Royaume des Bêtes
local s,id=GetID()
function s.initial_effect(c)
	-- Toujours traité comme une carte "Animépée"
	-- (idéalement, ajoute aussi 0xd64 dans le champ setcode de la carte dans ta base de données)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CANNOT_DISABLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(0xd64)
	c:RegisterEffect(e0)

	-- Activation : piocher puis replacer le même nombre de cartes sous le Deck
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetOperation(s.actop)
	c:RegisterEffect(e1)

	-- Les monstres adverses avec 2000 ATK ou plus perdent 500 ATK
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(0,LOCATION_MZONE)
	e2:SetCondition(s.debuffcon)
	e2:SetTarget(s.debufftg)
	e2:SetValue(-500)
	c:RegisterEffect(e2)
	-- ... et 500 DEF
	local e3=e2:Clone()
	e3:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e3)

	-- Si l'adversaire active une carte ou un effet dans sa main : Invocation Spéciale
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_CHAINING)
	e4:SetRange(LOCATION_FZONE)
	e4:SetCountLimit(1,id+100)
	e4:SetCondition(s.spcon)
	e4:SetTarget(s.sptg)
	e4:SetOperation(s.spop)
	c:RegisterEffect(e4)
end

function s.animefilter(c)
	return c:IsFaceup() and c:IsSetCard(0xd64) and c:IsType(TYPE_MONSTER)
end

-- Activation : pioche optionnelle, puis on replace autant de cartes sous le Deck, dans l'ordre choisi
function s.actop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local ct=Duel.GetMatchingGroupCount(s.animefilter,tp,LOCATION_MZONE,0,nil)
	if ct==0 or not Duel.IsPlayerCanDraw(tp,ct) then return end
	if not Duel.SelectYesNo(tp,aux.Stringid(id,0)) then return end
	local dc=Duel.Draw(tp,ct,REASON_EFFECT)
	if dc==0 then return end
	Duel.BreakEffect()
	Duel.ShuffleHand(tp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,Card.IsAbleToDeck,tp,LOCATION_HAND,0,dc,dc,nil)
	if #g==0 then return end
	-- YGO Omega n'a pas Duel.SortDeckbottom :
	-- on pose les cartes sur le dessus (0 = dessus), on les trie, puis on les glisse une par une en dessous (1 = dessous)
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

-- Affaiblissement : actif seulement si tu contrôles un monstre "Animépée"
function s.debuffcon(e)
	return Duel.IsExistingMatchingCard(s.animefilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end
function s.debufftg(e,c)
	return c:IsFaceup() and c:GetAttack()>=2000
end

-- Carte/effet activé DANS la main adverse (main traps, effets de monstres en main)
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	if rp~=1-tp then return false end
	local loc=Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION)
	return loc==LOCATION_HAND
end

-- Monstre "Animépée" de Niveau <= moitié de l'Extra Deck (arrondi à l'inférieur)
function s.getlv(tp)
	return math.floor(Duel.GetFieldGroupCount(tp,LOCATION_EXTRA,0)/2)
end
function s.spfilter(c,e,tp,lv)
	return c:IsSetCard(0xd64) and c:IsType(TYPE_MONSTER)
		and c:IsLevelAbove(1) and c:IsLevelBelow(lv)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local lv=s.getlv(tp)
	if chk==0 then
		return lv>0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp,lv)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local lv=s.getlv(tp)
	if lv<=0 or Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,e,tp,lv):GetFirst()
	if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
		local lp=tc:GetLevel()*100
		Duel.SetLP(tp,math.max(Duel.GetLP(tp)-lp,0))
	end
end
-- Carte de la Patroll du Pillage (Magie Normale)
local s,id=GetID()
local SET_PLUNDER=0x13f
-- Marque laissée dans le Cimetière (gardée pour compatibilité avec Vinh)
local EFFECT_PLUNDER_DISCARD_REPLACE=20905985

function s.initial_effect(c)
	-- Activation : défausser 1 carte ; ajouter ou Invoquer 1 monstre "Patroll du Pillage" du Deck
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Effet inhérent : depuis le Cimetière, peut être bannie à la place d'une défausse "Patroll du Pillage"
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_PLUNDER_DISCARD_REPLACE)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE)
	c:RegisterEffect(e2)
end

---------------------------------------------------------------
-- Activation
---------------------------------------------------------------
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,e:GetHandler())
	end
	Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD,e:GetHandler())
end
function s.filter(c,e,tp,ft)
	return c:IsSetCard(SET_PLUNDER) and c:IsType(TYPE_MONSTER)
		and (c:IsAbleToHand() or (ft>0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false)))
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK,0,1,nil,e,tp,ft)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_OPERATECARD)
	local tc=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_DECK,0,1,1,nil,e,tp,ft):GetFirst()
	if not tc then return end
	local b1=tc:IsAbleToHand()
	local b2=ft>0 and tc:IsCanBeSpecialSummoned(e,0,tp,false,false)
	local op
	if b1 and b2 then
		op=Duel.SelectOption(tp,1190,1152) -- textes système : "Ajouter à la main" / "Invoquer Spécialement"
	elseif b1 then op=0 else op=1 end
	if op==0 then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,tc)
	elseif Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
		e1:SetDescription(aux.Stringid(id,0))
		e1:SetCode(EFFECT_CANNOT_ACTIVATE)
		e1:SetTargetRange(1,0)
		e1:SetValue(s.aclimit)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
	end
end
function s.aclimit(e,re,tp)
	return re:IsActiveType(TYPE_MONSTER) and not re:GetHandler():IsSetCard(SET_PLUNDER)
end

---------------------------------------------------------------
-- SYSTÈME GLOBAL : bannir depuis le Cimetière à la place de défausser
-- Les scripts des autres cartes (y compris officielles) ne sont pas modifiés :
-- on intercepte Duel.DiscardHand / Duel.IsExistingMatchingCard / Card.IsDiscardable.
-- Une "défausse Patroll du Pillage" est détectée ainsi : le filtre de coût
-- accepte cette Magie UNIQUEMENT si elle est considérée défaussable
-- (donc le filtre teste bien IsDiscardable + "Patroll du Pillage"),
-- et refuse une carte non-"Patroll du Pillage".
---------------------------------------------------------------
if not PLUNDER_REPLACE_INSTALLED then
	PLUNDER_REPLACE_INSTALLED=true

	local orig_IsDiscardable=Card.IsDiscardable
	local orig_IsExisting=Duel.IsExistingMatchingCard
	local orig_GetGroup=Duel.GetMatchingGroup
	local orig_DiscardHand=Duel.DiscardHand
	local probe=nil -- carte temporairement considérée comme défaussable

	Card.IsDiscardable=function(c,...)
		if probe and c==probe then return true end
		return orig_IsDiscardable(c,...)
	end

	-- Le filtre f accepte-t-il c en tant que carte défaussée ?
	local function acceptsAsDiscard(f,c,...)
		local ok1,without=pcall(f,c,...)
		probe=c
		local ok2,with=pcall(f,c,...)
		probe=nil
		return ok1 and ok2 and with and not without
	end

	-- Le filtre est-il spécifique "Patroll du Pillage" (refuse une carte non-Plunder) ?
	local function isPlunderFilter(f,tp,...)
		local others=orig_GetGroup(function(x) return not x:IsSetCard(SET_PLUNDER) end,
			tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,nil)
		local x=others:GetFirst()
		if not x then return true end
		probe=x
		local ok,res=pcall(f,x,...)
		probe=nil
		return not (ok and res)
	end

	-- Magies "remplaçantes" du Cimetière utilisables pour ce filtre
	local function getReplacements(f,tp,...)
		if type(f)~="function" then return Group.CreateGroup() end
		local reps=orig_GetGroup(function(c)
			return c:IsHasEffect(EFFECT_PLUNDER_DISCARD_REPLACE) and c:IsAbleToRemoveAsCost()
		end,tp,LOCATION_GRAVE,0,nil)
		if #reps==0 then return reps end
		local args={...}
		reps=reps:Filter(function(c) return acceptsAsDiscard(f,c,table.unpack(args)) end,nil)
		if #reps==0 or not isPlunderFilter(f,tp,...) then return Group.CreateGroup() end
		return reps
	end

	-- Vérifications "chk==0" des coûts : la Magie du Cimetière compte comme une carte défaussable
	Duel.IsExistingMatchingCard=function(f,tp,sloc,oloc,count,ex,...)
		if orig_IsExisting(f,tp,sloc,oloc,count,ex,...) then return true end
		if sloc~=LOCATION_HAND or oloc~=0 or type(f)~="function" then return false end
		local n=orig_GetGroup(f,tp,LOCATION_HAND,0,ex,...):GetCount()
		local reps=getReplacements(f,tp,...)
		return #reps>0 and n+#reps>=count
	end

	-- Paiement : la fenêtre propose la main + les Magies du Cimetière
	Duel.DiscardHand=function(tp,f,min,max,reason,ex,...)
		if not reason or reason&REASON_COST==0 or type(f)~="function" then
			return orig_DiscardHand(tp,f,min,max,reason,ex,...)
		end
		local reps=getReplacements(f,tp,...)
		if #reps==0 then
			return orig_DiscardHand(tp,f,min,max,reason,ex,...)
		end
		local g=orig_GetGroup(f,tp,LOCATION_HAND,0,ex,...)
		g:Merge(reps)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
		local sg=g:Select(tp,min,max,nil)
		local fromgy=sg:Filter(Card.IsLocation,nil,LOCATION_GRAVE)
		local fromhand=sg:Filter(Card.IsLocation,nil,LOCATION_HAND)
		local ct=0
		if #fromgy>0 then ct=ct+Duel.Remove(fromgy,POS_FACEUP,REASON_COST) end
		if #fromhand>0 then ct=ct+Duel.SendtoGrave(fromhand,reason) end
		return ct
	end
end
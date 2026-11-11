-- Cheveux d'Argent, Bombardier de la Patroll du Pillage
local s,id=GetID()
local SET_PLUNDER=0x13f

function s.initial_effect(c)
	-- Effet 1 (1 fois par tour) : défausser cette carte + 1 autre ;
	-- révéler les 5 cartes du dessus, Invoquer 1 monstre révélé sur le terrain adverse (effets annulés), changer son Attribut
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.revcost)
	e1:SetTarget(s.revtg)
	e1:SetOperation(s.revop)
	c:RegisterEffect(e1)

	-- Effet 2 (1 fois par Duel) : Effet Rapide depuis le Cimetière pendant la Main Phase ;
	-- payer 1000 LP, Invoquer 1 "Patroll du Pillage" de l'Extra Deck, puis l'équiper avec cette carte
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_EQUIP)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e2:SetCountLimit(1,id+100,EFFECT_COUNT_CODE_DUEL)
	e2:SetCondition(s.excon)
	e2:SetCost(s.excost)
	e2:SetTarget(s.extg)
	e2:SetOperation(s.exop)
	c:RegisterEffect(e2)
end

---------------------------------------------------------------
-- Effet 1 : révélation + Invocation chez l'adversaire
---------------------------------------------------------------
function s.revcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return c:IsDiscardable()
			and Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,c)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
	local g=Duel.SelectMatchingCard(tp,Card.IsDiscardable,tp,LOCATION_HAND,0,1,1,c)
	g:AddCard(c)
	Duel.SendtoGrave(g,REASON_COST+REASON_DISCARD)
end
function s.revtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=5
	end
end
-- Monstre révélé pouvant être Invoqué sur le terrain adverse
function s.oppspfilter(c,e,tp)
	return c:IsType(TYPE_MONSTER)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP,1-tp)
end
function s.revop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)<5 then return end
	-- Révéler les 5 cartes du dessus (visibles par les 2 joueurs)
	Duel.ConfirmDecktop(tp,5)
	local g=Duel.GetDecktopGroup(tp,5):Filter(s.oppspfilter,nil,e,tp)
	if #g==0 or Duel.GetLocationCount(1-tp,LOCATION_MZONE,tp)<=0 then return end
	-- str3 : "Special Summon a monster to your opponent's field?"
	if not Duel.SelectYesNo(tp,aux.Stringid(id,2)) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc=g:Select(tp,1,1,nil):GetFirst()
	if not tc then return end
	Duel.DisableShuffleCheck()
	if Duel.SpecialSummonStep(tc,0,tp,1-tp,false,false,POS_FACEUP) then
		local c=e:GetHandler()
		-- Effets annulés
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		tc:RegisterEffect(e2)
		-- Changement d'Attribut optionnel (str4 : "Change its Attribute?")
		local available=ATTRIBUTE_ALL&~tc:GetAttribute()
		if available~=0 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATTRIBUTE)
			local att=Duel.AnnounceAttribute(tp,1,available)
			local e3=Effect.CreateEffect(c)
			e3:SetType(EFFECT_TYPE_SINGLE)
			e3:SetCode(EFFECT_CHANGE_ATTRIBUTE)
			e3:SetValue(att)
			e3:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e3)
		end
	end
	Duel.SpecialSummonComplete()
end

---------------------------------------------------------------
-- Effet 2 : Invocation depuis l'Extra Deck + équipement
---------------------------------------------------------------
function s.excon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return ph==PHASE_MAIN1 or ph==PHASE_MAIN2
end
function s.excost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,1000) end
	Duel.PayLPCost(tp,1000)
end
-- Monstre adverse (face recto sur le terrain ou au Cimetière) de l'Attribut donné
function s.attfilter(c,att)
	return c:IsType(TYPE_MONSTER) and c:IsAttribute(att)
		and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup())
end
-- "Patroll du Pillage" de l'Extra Deck du même Attribut qu'un monstre adverse
function s.exfilter(c,e,tp)
	return c:IsSetCard(SET_PLUNDER)
		and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and Duel.IsExistingMatchingCard(s.attfilter,tp,0,LOCATION_MZONE+LOCATION_GRAVE,1,nil,c:GetAttribute())
end
function s.extg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.exfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,e:GetHandler(),1,0,0)
end
function s.exop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc=Duel.SelectMatchingCard(tp,s.exfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp):GetFirst()
	if not tc or Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)==0 then return end
	-- "et si vous le faites" : équiper cette carte depuis le Cimetière
	if not c:IsRelateToEffect(e) or not c:IsLocation(LOCATION_GRAVE) then return end
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 or tc:IsFacedown() then return end
	if not Duel.Equip(tp,c,tc) then return end
	-- Ne peut équiper que ce monstre
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_EQUIP_LIMIT)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	e1:SetValue(function(e,ec) return ec==tc end)
	c:RegisterEffect(e1)
end
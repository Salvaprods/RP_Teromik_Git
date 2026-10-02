-- Meduse Mimigoule
local s,id=GetID()
function s.initial_effect(c)
	-- Invoquer Spécialement depuis la main
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Effet de FLIP
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_FLIP)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.flipcon)
	e2:SetTarget(s.fliptg)
	e2:SetOperation(s.flipop)
	c:RegisterEffect(e2)

	-- Effet 3 : Annulation (si "Maitre Mimigoule" est contrôlé)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_DISABLE+CATEGORY_TOGRAVE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+200)
	e3:SetCondition(s.negcon)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)
end

s.listed_names = {55537983} -- Maitre Mimigoule
s.listed_series = {0x1b7} -- Mimigoule / Mimighoul

-- ==========================================
-- EFFET 1 : INVOCATION SPÉCIALE DEPUIS LA MAIN
-- ==========================================
function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x1b7)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local b1=c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEDOWN_DEFENSE,1-tp)
	local b2=Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP)
	if chk==0 then return b1 or b2 end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,tp,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local b1=c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEDOWN_DEFENSE,1-tp)
	local b2=Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP)
	if not (b1 or b2) then return end
	
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))
	elseif b1 then
		op=0
	else
		op=1
	end
	
	if op==0 then
		Duel.SpecialSummon(c,0,tp,1-tp,false,false,POS_FACEDOWN_DEFENSE)
		Duel.ConfirmCards(tp,c)
	else
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- ==========================================
-- EFFET 2 : FLIP
-- ==========================================
function s.flipcon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return ph==PHASE_MAIN1 or ph==PHASE_MAIN2
end

function s.fliptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local p=e:GetHandler():GetControler()
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,p,LOCATION_GRAVE)
end

function s.flipop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local p=c:GetControler() -- Le contrôleur actuel de la méduse au moment de la résolution du flip
	
	local mg=Duel.GetMatchingGroup(Card.IsAbleToRemove,p,LOCATION_GRAVE,0,nil)
	local g1=mg:Filter(Card.IsType,nil,TYPE_MONSTER)
	local g2=mg:Filter(Card.IsType,nil,TYPE_SPELL)
	local g3=mg:Filter(Card.IsType,nil,TYPE_TRAP)
	
	local sg=Group.CreateGroup()
	if #g1>0 then
		Duel.Hint(HINT_SELECTMSG,p,HINTMSG_REMOVE)
		local tc1=g1:Select(p,1,1,nil)
		sg:Merge(tc1)
	end
	if #g2>0 then
		Duel.Hint(HINT_SELECTMSG,p,HINTMSG_REMOVE)
		local tc2=g2:Select(p,1,1,nil)
		sg:Merge(tc2)
	end
	if #g3>0 then
		Duel.Hint(HINT_SELECTMSG,p,HINTMSG_REMOVE)
		local tc3=g3:Select(p,1,1,nil)
		sg:Merge(tc3)
	end
	
	if #sg>0 then
		Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)
	end
	
	if c:IsRelateToEffect(e) and c:IsFaceup() then
		Duel.GetControl(c,1-p)
	end
end

-- ==========================================
-- EFFET 3 : ANNULATION (MAITRE MIMIGOULE)
-- ==========================================
function s.masterfilter(c)
	return c:IsFaceup() and c:IsCode(55537983)
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp~=tp and Duel.IsChainNegatable(ev)
		and Duel.IsExistingMatchingCard(s.masterfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToGrave() end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,nil,1,0,ev)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,e:GetHandler(),1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.NegateEffect(ev) and c:IsRelateToEffect(e) then
		Duel.SendtoGrave(c, REASON_EFFECT)
	end
end
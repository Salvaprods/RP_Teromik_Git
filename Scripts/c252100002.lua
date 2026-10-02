-- Kuriboh Kuricute
local s,id=GetID()

function s.initial_effect(c)
	-- Révéler cette carte ; SS elle-même puis 1 monstre 300 ATK / 200 DEF
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id+100)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Si envoyée au GY : piocher 1
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,id+200)
	e2:SetTarget(s.drtg)
	e2:SetOperation(s.drop)
	c:RegisterEffect(e2)
end

s.listed_series={0xa4}

-- =========================================
-- EFFET 1
-- =========================================
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return c:IsLocation(LOCATION_HAND)
	end
	Duel.ConfirmCards(1-tp,c)
end

function s.spfilter(c,e,tp)
	return c:IsType(TYPE_MONSTER)
		and c:IsAttack(300)
		and c:IsDefense(200)
		and c:IsCanBeSpecialSummoned(
			e,0,tp,false,false
		)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>=2
			and c:IsCanBeSpecialSummoned(
				e,0,tp,false,false
			)
			and Duel.IsExistingMatchingCard(
				s.spfilter,
				tp,
				LOCATION_DECK,
				0,
				1,
				nil,
				e,tp
			)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,
		2,
		tp,
		LOCATION_HAND+LOCATION_DECK
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsRelateToEffect(e)
		or Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return
	end

	-- Invoque Kuricute
	if Duel.SpecialSummon(
		c,0,tp,tp,false,false,POS_FACEUP
	)==0 then
		return
	end

	-- Puis invoque 1 monstre 300 ATK / 200 DEF
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return
	end

	if not Duel.IsExistingMatchingCard(
		s.spfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		nil,
		e,tp
	) then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local g=Duel.SelectMatchingCard(
		tp,
		s.spfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil,
		e,tp
	)

	if g:GetCount()>0 then
		Duel.SpecialSummon(
			g,0,tp,tp,false,false,POS_FACEUP
		)
	end
end

-- =========================================
-- EFFET 2 : DRAW
-- =========================================
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsPlayerCanDraw(tp,1)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_DRAW,
		nil,
		0,
		tp,
		1
	)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Draw(tp,1,REASON_EFFECT)
end
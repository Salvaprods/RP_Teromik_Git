-- Esprit De Gokvelgr - Âme Du Chasseur
local s,id=GetID()

function s.initial_effect(c)
	-- Link : 2 monstres "Âme Du Chasseur"
	c:EnableReviveLimit()
	aux.AddLinkProcedure(c,s.matfilter,2,2)

	-- L'adversaire ne peut pas bannir vos autres "Âme Du Chasseur"
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_REMOVE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.rmlimit)
	c:RegisterEffect(e1)

	-- Indestructible au combat
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e2:SetValue(1)
	c:RegisterEffect(e2)

	-- Monstre(s) Invoqué(s) dans zone(s) pointée(s) : +500 LP chacun
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_RECOVER)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.reccon)
	e3:SetTarget(s.rectg)
	e3:SetOperation(s.recop)
	c:RegisterEffect(e3)

	-- Main Phase Quick Effect : invoquer depuis l'Extra
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id+100)
	e4:SetCondition(s.spcon)
	e4:SetTarget(s.sptg)
	e4:SetOperation(s.spop)
	c:RegisterEffect(e4)
end

-- ==========================================
-- MATÉRIAUX LINK
-- ==========================================
function s.matfilter(c,lc,st,tp)
	return c:IsSetCard(0xc92,lc,st,tp)
end

-- ==========================================
-- PROTECTION CONTRE LE BANNISSEMENT
-- ==========================================
function s.rmlimit(e,c)
	return c:IsSetCard(0xc92)
		and c~=e:GetHandler()
end

-- ==========================================
-- +500 LP PAR MONSTRE INVOQUÉ
-- DANS UNE ZONE POINTÉE
-- ==========================================
function s.recfilter(c,tp,lc)
	return c:IsLocation(LOCATION_MZONE)
		and c:IsControler(tp)
		and bit.band(
			lc:GetLinkedZone(tp),
			bit.lshift(1,c:GetSequence())
		)~=0
end

function s.reccon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(
		s.recfilter,
		1,
		nil,
		tp,
		e:GetHandler()
	)
end

function s.rectg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=eg:FilterCount(
		s.recfilter,
		nil,
		tp,
		e:GetHandler()
	)

	if chk==0 then
		return ct>0
	end

	Duel.SetTargetParam(ct*500)

	Duel.SetOperationInfo(
		0,
		CATEGORY_RECOVER,
		nil,
		0,
		tp,
		ct*500
	)
end

function s.recop(e,tp,eg,ep,ev,re,r,rp)
	local ct=eg:FilterCount(
		s.recfilter,
		nil,
		tp,
		e:GetHandler()
	)

	if ct>0 then
		Duel.Recover(
			tp,
			ct*500,
			REASON_EFFECT
		)
	end
end

-- ==========================================
-- QUICK EFFECT : EXTRA DECK
-- ==========================================
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return ph==PHASE_MAIN1
		or ph==PHASE_MAIN2
end

function s.spfilter(c,e,tp,zone)
	return c:IsFaceup()
		and c:IsCanBeSpecialSummoned(
			e,
			0,
			tp,
			false,
			false,
			POS_FACEUP,
			tp,
			zone
		)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local zone=c:GetLinkedZone(tp)

	if chk==0 then
		return zone~=0
			and Duel.IsExistingMatchingCard(
				s.spfilter,
				tp,
				LOCATION_EXTRA,
				0,
				1,
				nil,
				e,
				tp,
				zone
			)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,
		1,
		tp,
		LOCATION_EXTRA
	)

	Duel.Hint(HINT_ZONE,tp,zone)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsRelateToEffect(e) then
		return
	end

	local zone=c:GetLinkedZone(tp)

	if zone==0 then
		return
	end

	-- Nombre de zones pointées disponibles
	local ft=0

	for i=0,4 do
		if bit.band(zone,bit.lshift(1,i))~=0
			and Duel.CheckLocation(
				tp,
				LOCATION_MZONE,
				i
			) then
			ft=ft+1
		end
	end

	if ft<=0 then
		return
	end

	local g=Duel.GetMatchingGroup(
		s.spfilter,
		tp,
		LOCATION_EXTRA,
		0,
		nil,
		e,
		tp,
		zone
	)

	if g:GetCount()==0 then
		return
	end

	if Duel.IsPlayerAffectedByEffect(
		tp,
		CARD_BLUEEYES_SPIRIT
	) then
		ft=1
	end

	ft=math.min(
		ft,
		g:GetCount()
	)

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_SPSUMMON
	)

	local sg=g:Select(
		tp,
		ft,
		ft,
		nil
	)

	if sg:GetCount()==0 then
		return
	end

	for tc in aux.Next(sg) do
		Duel.SpecialSummonStep(
			tc,
			0,
			tp,
			tp,
			false,
			false,
			POS_FACEUP,
			zone
		)
	end

	Duel.SpecialSummonComplete()
end
-- Universo - Chevalier Du Vide
local s, id = GetID()

function s.initial_effect(c)
	-- Effet 1 : Invoqué Normalement/Spécialement ou Banni -> Bannir 1 carte "Universo" depuis le Deck
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1, id)
	e1:SetTarget(s.rmtg)
	e1:SetOperation(s.rmop)
	c:RegisterEffect(e1)
	
	local e2 = e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)
	
	local e3 = e1:Clone()
	e3:SetCode(EVENT_REMOVE)
	c:RegisterEffect(e3)

	-- Effet 2 : Utilisé comme Matériel Lien pour un "Universo" -> Détruire 1 carte face recto adverse
	local e4 = Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id, 1))
	e4:SetCategory(CATEGORY_DESTROY)
	e4:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_BE_MATERIAL)
	e4:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_CARD_TARGET)
	e4:SetCountLimit(1, id + 100) -- HOPT séparé
	e4:SetCondition(s.descon)
	e4:SetTarget(s.destg)
	e4:SetOperation(s.desop)
	c:RegisterEffect(e4)
end

-- ==========================================
-- EFFET 1 : BANNIR DEPUIS LE DECK
-- ==========================================
function s.rmfilter(c)
	return c:IsSetCard(0xc17) and c:IsAbleToRemove()
end

function s.rmtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(s.rmfilter, tp, LOCATION_DECK, 0, 1, nil) end
	Duel.SetOperationInfo(0, CATEGORY_REMOVE, nil, 1, tp, LOCATION_DECK)
end

function s.rmop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
	local g = Duel.SelectMatchingCard(tp, s.rmfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
	if #g > 0 then
		Duel.Remove(g, POS_FACEUP, REASON_EFFECT)
	end
end

-- ==========================================
-- EFFET 2 : DESTRUCTION SI MATÉRIEL LIEN
-- ==========================================
function s.descon(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	local rc = c:GetReasonCard()
	-- Vérifie que c'est une Invocation Lien et que le monstre Invoqué est un "Universo"
	return c:IsLocation(LOCATION_GRAVE) and r == REASON_LINK and rc:IsSetCard(0xc17)
end

function s.destg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsControler(1 - tp) and chkc:IsLocation(LOCATION_ONFIELD) and chkc:IsFaceup() end
	if chk == 0 then return Duel.IsExistingTarget(Card.IsFaceup, tp, 0, LOCATION_ONFIELD, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
	local g = Duel.SelectTarget(tp, Card.IsFaceup, tp, 0, LOCATION_ONFIELD, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, 1, 0, 0)
end

function s.desop(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc, REASON_EFFECT)
	end
end
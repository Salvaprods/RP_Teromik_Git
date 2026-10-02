-- Pion Central - Echec Divin
local s, id = GetID()

s.listed_series = {0xe7a}

function s.initial_effect(c)
	-- Effet 1 : Recherche Magie/Piège "Echec Divin" depuis le Deck ou Cimetière lors de l'Invocation
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1, id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	local e1_bis = e1:Clone()
	e1_bis:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e1_bis)

	-- Effet 2 : Durant la End Phase, envoyer au Cimetière pour piocher 1 carte
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_TOGRAVE + CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_PHASE + PHASE_END)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1, id + 100)
	e2:SetTarget(s.eptg)
	e2:SetOperation(s.epop)
	c:RegisterEffect(e2)
end

-- ==========================================
-- EFFET 1 : RECHERCHE MAGIE/PIÈGE
-- ==========================================
function s.thfilter(c)
	return c:IsSetCard(0xe7a) and c:IsType(TYPE_SPELL + TYPE_TRAP) and c:IsAbleToHand()
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK + LOCATION_GRAVE, 0, 1, nil)
	end
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK + LOCATION_GRAVE)
end

function s.thop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
	local g = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.thfilter), tp, LOCATION_DECK + LOCATION_GRAVE, 0, 1, 1, nil)
	if #g > 0 then
		Duel.SendtoHand(g, nil, REASON_EFFECT)
		Duel.ConfirmCards(1 - tp, g)
	end
end

-- ==========================================
-- EFFET 2 : ENVOI END PHASE & PIOCHE
-- ==========================================
function s.eptg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then
		return c:IsAbleToGrave() and Duel.IsPlayerCanDraw(tp, 1)
	end
	Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, c, 1, tp, LOCATION_MZONE)
	Duel.SetOperationInfo(0, CATEGORY_DRAW, nil, 1, tp, 1)
end

function s.epop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SendtoGrave(c, REASON_EFFECT) ~= 0 then
		Duel.Draw(tp, 1, REASON_EFFECT)
	end
end
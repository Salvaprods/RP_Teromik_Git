-- Noble chien des Crânes Serviteurs
local s, id = GetID()
function s.initial_effect(c)
	-- Effet 1 : Meuler 3 cartes si "Crâne Serviteur" est au Cimetière
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_DECKDES)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1, id)
	e1:SetCondition(s.millcon)
	e1:SetTarget(s.milltg)
	e1:SetOperation(s.millop)
	c:RegisterEffect(e1)

	-- Effet 2 : Poser 1 M/P qui mentionne "Crâne Serviteur" si envoyé au Cimetière
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1, id + 100)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
end

s.listed_names = {32274490}

-- Condition Effet 1
function s.cfilter(c)
	return c:IsType(TYPE_MONSTER) and (c:IsCode(32274490) or aux.IsCodeListed(c, 32274490) or c:IsSetCard(0x159))
end

function s.millcon(e, tp, eg, ep, ev, re, r, rp)
	return Duel.IsExistingMatchingCard(s.cfilter, tp, LOCATION_GRAVE, 0, 1, nil)
end

function s.milltg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsPlayerCanDiscardDeck(tp, 3) end
	Duel.SetOperationInfo(0, CATEGORY_DECKDES, nil, 0, tp, 3)
end

function s.millop(e, tp, eg, ep, ev, re, r, rp)
	Duel.DiscardDeck(tp, 3, REASON_EFFECT)
end

-- Target & Operation Effet 2 (Élargi pour reconnaître à coup sûr les cartes custom)
function s.stfilter(c)
	return (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP)) 
		and (c:IsCode(32274490) or aux.IsCodeListed(c, 32274490) or c:IsSetCard(0x159)) 
		and c:IsSSetable()
end

function s.settg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(s.stfilter, tp, LOCATION_DECK, 0, 1, nil) end
end

function s.setop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SET)
	local g = Duel.SelectMatchingCard(tp, s.stfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
	if #g > 0 then
		Duel.SSet(tp, g:GetFirst())
	end
end
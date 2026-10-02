-- La Planque Dinomorphia
local s, id = GetID()

s.listed_series = {0x173}

function s.initial_effect(c)
	-- Activation de la carte + Poser 1 M/P Normal Dinomorphia depuis le Deck
	local e1 = Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1, id, EFFECT_COUNT_CODE_OATH)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Protection contre les dommages d'effet adverses + Dommages de combat divisés par 2
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CHANGE_DAMAGE)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(1, 0)
	e2:SetValue(s.damval)
	c:RegisterEffect(e2)

	-- Effet 3 : Lors de l'activation d'un Piège Normal Dinomorphia -> Détruire 1 carte sur le Terrain
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 1))
	e3:SetCategory(CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET + EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCondition(s.descon)
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)
end

function s.setfilter(c)
	return (c:IsSetCard(0x173) or c:IsOriginalSetCard(0x173))
		and c:IsType(TYPE_SPELL + TYPE_TRAP)
		and not c:IsType(TYPE_QUICKPLAY + TYPE_CONTINUOUS + TYPE_EQUIP + TYPE_FIELD + TYPE_COUNTER)
		and c:IsSSetable()
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetLocationCount(tp, LOCATION_SZONE) <= 0 then return end
	local g = Duel.GetMatchingGroup(s.setfilter, tp, LOCATION_DECK, 0, nil)
	if #g > 0 and Duel.SelectYesNo(tp, aux.Stringid(id, 0)) then
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SET)
		local sg = g:Select(tp, 1, 1, nil)
		if #sg > 0 then
			Duel.SSet(tp, sg:GetFirst())
		end
	end
end

function s.damval(e, re, val, r, rp)
	local tp = e:GetHandlerPlayer()
	if (r & REASON_EFFECT) ~= 0 and rp == 1 - tp then
		return 0
	end
	if (r & REASON_BATTLE) ~= 0 then
		return math.floor(val / 2)
	end
	return val
end

function s.descon(e, tp, eg, ep, ev, re, r, rp)
	local rc = re:GetHandler()
	return ep == tp and re:IsHasType(EFFECT_TYPE_ACTIVATE)
		and rc:IsType(TYPE_TRAP)
		and not rc:IsType(TYPE_CONTINUOUS + TYPE_COUNTER)
		and (rc:IsSetCard(0x173) or rc:IsOriginalSetCard(0x173))
end

function s.destg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsOnField() end
	if chk == 0 then return Duel.IsExistingTarget(nil, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
	local g = Duel.SelectTarget(tp, nil, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, 1, 0, 0)
end

function s.desop(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc, REASON_EFFECT)
	end
end
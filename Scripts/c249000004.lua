-- Universo - Dragon Lancero
local s, id = GetID()

function s.initial_effect(c)
	-- Effet 1 : Protection ciblante (L'adversaire ne peut pas cibler de cartes "Universo" sauf cette carte)
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNITY)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_ONFIELD, 0)
	e1:SetTarget(s.tglimit)
	e1:SetValue(aux.tgovval)
	c:RegisterEffect(e1)

	-- Effet 2 : Si bannie -> Invoquer Spécialement cette carte, puis Invocation Lien optionnelle (depuis le Terrain)
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_REMOVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1, id)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

-- ==========================================
-- EFFET 1 : PROTECTION CIBLANTE
-- ==========================================
function s.tglimit(e, c)
	return c:IsSetCard(0xc17) and c ~= e:GetHandler()
end

-- ==========================================
-- EFFET 2 : INVOCATION SPÉCIALE ET LINK (TERRAIN UNIQUEMENT)
-- ==========================================
function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, 0, 0)
end

function s.lkfilter(c)
	return c:IsSetCard(0xc17) and c:IsType(TYPE_LINK) and c:IsLinkSummonable(nil)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP) > 0 then
		local g = Duel.GetMatchingGroup(s.lkfilter, tp, LOCATION_EXTRA, 0, nil)
		if #g > 0 and Duel.SelectYesNo(tp, aux.Stringid(id, 1)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
			local sg = g:Select(tp, 1, 1, nil)
			local lkc = sg:GetFirst()
			
			if Link and Link.Summon then
				Link.Summon(tp, lkc, nil)
			else
				Duel.LinkSummon(tp, lkc, nil)
			end
		end
	end
end
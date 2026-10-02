-- Solfachord Duet
local s,id=GetID()
local sid=120000001

function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(
		1,id+1000,EFFECT_COUNT_CODE_OATH
	)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.pfilter(c)
	return c:IsSetCard(0x162)
		and c:IsType(TYPE_MONSTER)
		and c:IsType(TYPE_PENDULUM)
end

function s.stfilter(c)
	return c:IsSetCard(0x162)
		and c:IsType(TYPE_SPELL+TYPE_TRAP)
		and not c:IsCode(id)
		and c:IsSSetable()
end

function s.canplacepend(tp)
	return Duel.CheckLocation(tp,LOCATION_PZONE,0)
		or Duel.CheckLocation(tp,LOCATION_PZONE,1)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1=s.canplacepend(tp)
		and Duel.IsExistingMatchingCard(
			s.pfilter,tp,LOCATION_DECK,0,1,nil
		)

	local b2=Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingMatchingCard(
			s.stfilter,tp,LOCATION_DECK,0,1,nil
		)

	if chk==0 then
		return b1 or b2
	end

	local op

	if b1 and b2 then
		if Duel.CheckLPCost(tp,1000) then
			op=Duel.SelectOption(
				tp,
				aux.Stringid(sid,4),
				aux.Stringid(sid,5),
				aux.Stringid(sid,6)
			)
		else
			op=Duel.SelectOption(
				tp,
				aux.Stringid(sid,4),
				aux.Stringid(sid,5)
			)
		end
	elseif b1 then
		op=0
	else
		op=1
	end

	if op==2 then
		Duel.PayLPCost(tp,1000)
	end

	e:SetLabel(op)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local op=e:GetLabel()

	-- Pendule
	if op==0 or op==2 then
		if s.canplacepend(tp) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)

			local g=Duel.SelectMatchingCard(
				tp,s.pfilter,tp,
				LOCATION_DECK,0,1,1,nil
			)

			local tc=g:GetFirst()

			if tc then
				Duel.MoveToField(
					tc,tp,tp,
					LOCATION_PZONE,
					POS_FACEUP,
					true
				)
			end
		end
	end

	-- Magie/Piège
	if op==1 or op==2 then
		if Duel.GetLocationCount(
			tp,LOCATION_SZONE
		)>0 then

			if op==2 then
				Duel.BreakEffect()
			end

			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)

			local g=Duel.SelectMatchingCard(
				tp,s.stfilter,tp,
				LOCATION_DECK,0,1,1,nil
			)

			local tc=g:GetFirst()

			if tc then
				Duel.SSet(tp,tc)
			end
		end
	end
end
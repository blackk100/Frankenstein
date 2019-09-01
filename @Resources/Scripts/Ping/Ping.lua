function Initialize()
	active, MeasurePing, ping, variable, tint, graphH, flagSet, flagInput, setVar, setPos = 0, {}, {}, {['Open'] = {}, ['Name'] = {}, ['ThresholdY'] = {}, ['ThresholdR'] = {}}, {'00FF00', 'FFFF00', 'FF0000', 'FF0000'}, tonumber(SKIN:GetVariable('GraphH')), false, false
	local varName = {'Open', 'Name', 'ThresholdY', 'ThresholdR'}
	for i = 1, 10 do
		for j = 1, 4 do
			variable[varName[j]][i] = tonumber(SKIN:GetVariable(varName[j]..i)) or SKIN:GetVariable(varName[j]..i)
		end
		MeasurePing[i] = SKIN:GetMeasure('MeasurePing'..i)
	end
	Add(tonumber(SKIN:GetVariable('Active')))
end

function Update()
	for i = 1, active do
		local p = MeasurePing[i]:GetValue()
		p = p < variable['ThresholdY'][i] and 1 or p < variable['ThresholdR'][i] and 2 or p == 30000 and 4 or 3
		if p ~= ping[i] then
			SKIN:Bang('[!SetOption MeterDot'..i..' ImageTint '..tint[p]..'][!UpdateMeter MeterDot'..i..']')
			if ping[i] == 4 then
				SKIN:Bang('[!SetOption MeterNumber'..i..' FontColor FFFFFF][!UpdateMeter MeterNumber'..i..']')
			elseif p == 4 then
				SKIN:Bang('[!SetOption MeterNumber'..i..' FontColor FF0000][!UpdateMeter MeterNumber'..i..']')
			end
			ping[i] = p
		end
	end
	SKIN:Bang('!Redraw')
end

function ToggleName(n, m)
	if variable['Name'][n] ~= '' then
		SKIN:Bang('[!SetOption MeterNumber'..n..' Text '..(m and '#*Name'..n..'*#' or '""')..'][!UpdateMeter MeterNumber'..n..'][!Redraw]')
	end
end

function ToggleGraph(n, m)
	if not flagSet then
		variable['Open'][n] = m and 0 or 1
		SKIN:Bang('[!'..(m and 'Hide' or 'Show')..'Meter MeterGraph'..n..'][!SetOption MeterNumber'..n..' LeftMouseUpAction '..(m and '"!CommandMeasure MeasureScript ToggleGraph('..n..')"' or '""')..'][!UpdateMeter MeterNumber'..n..']'..(n < 10 and '[!SetOption MeterGraph'..(n)..' Y '..(m and 9 or (graphH - 8))..'r][!UpdateMeter MeterGraph'..(n)..']' or '')..'[!WriteKeyValue Variables Open'..n..' '..(m and 0 or 1)..' "#@#/Scripts/Ping/Settings.inc"][!HideMeter MeterCog][!Redraw]')
	end
end

function ShowCog(n)
	if not flagSet then
		SKIN:Bang('[!MoveMeter 0 '..(SKIN:GetMeter('MeterGraph'..n):GetY())..' MeterCog][!ShowMeter MeterCog][!Redraw]')
		setPos = n
	end
end

function ShowSet()
	flagSet = true
	SKIN:Bang('[!SetOption MeterNameSet Text #*Name'..setPos..'*#][!SetOption MeterAddressSet Text #*Address'..setPos..'*#][!SetOption MeterThresholdYSet Text #*ThresholdY'..setPos..'*#][!SetOption MeterThresholdRSet Text #*ThresholdR'..setPos..'*#][!UpdateMeterGroup Set][!ShowMeterGroup Set][!Redraw]')
end

function HideSet()
	if flagSet and not flagInput then
		flagSet = false
		SKIN:Bang('[!HideMeterGroup Set][!Redraw]')
	end
end

function Set1(var, y, command)
	setVar, flagInput = var, true
	SKIN:Bang('[!SetVariable Var '..var..setPos..'][!SetVariable VarValue """#'..var..setPos..'#"""][!SetVariable Y '..(SKIN:GetMeter('MeterGraph'..setPos):GetY() + y)..'][!Update][!CommandMeasure MeasureInput "ExecuteBatch '..command..'"]')
end

function Set2()
	flagInput = false
	local val = SKIN:GetVariable(SKIN:GetVariable('Var'))
	if setVar == 'Address' then
		SKIN:Bang('[!SetOption MeasurePing'..setPos..' DestAddress "'..val..'"][!UpdateMeasure MeasurePing'..setPos..']')
	end
	SKIN:Bang('[!WriteKeyValue Variables '..setVar..setPos..' """'..val..'""" "#@#/Scripts/Ping/Settings.inc"][!SetOption Meter'..setVar..'Set Text """'..val..'"""][!UpdateMeter Meter'..setVar..'Set][!Redraw]')
end

function Swap(n, m)
	local varName = {'Open', 'Name', 'Address', 'ThresholdY', 'ThresholdR'}
	for i = 1, 6 do
		if i ~= 3 and i ~= 4 then
			variable[varName[i]][n], variable[varName[i]][m] = variable[varName[i]][m], variable[varName[i]][n]
		end
		SKIN:Bang('[!WriteKeyValue Variables '..varName[i]..n..' """#'..varName[i]..m..'#""" "#@#/Scripts/Ping/Settings.inc"][!WriteKeyValue Variables '..varName[i]..m..' """#'..varName[i]..n..'#""" "#@#/Scripts/Ping/Settings.inc"][!SetVariable '..varName[i]..n..' """#'..varName[i]..m..'#"""][!SetVariable '..varName[i]..m..' """#'..varName[i]..n..'#"""]')
	end
	SKIN:Bang('[!SetOption MeasurePing'..n..' DestAddress "#Address'..n..'#"][!SetOption MeasurePing'..m..' DestAddress "#Address'..m..'#"][!UpdateMeasure MeasurePing'..n..'][!UpdateMeasure MeasurePing'..m..']')
	if variable['Open'][n] ~= variable['Open'][m] then
		flagSet = false
		ToggleGraph(n, (variable['Open'][n] == 0 and 1 or nil))
		ToggleGraph(m, (variable['Open'][m] == 0 and 1 or nil))
		flagSet = true
	end
end

function Shift(p)
	if setPos + p >= 1 and setPos + p <= active then
		Swap(setPos, setPos + p)
		ShowSet()
	end
end

function Remove()
	if active == 1 then
		return
	end
	for i = setPos, active - 1 do
		Swap(i, i + 1)
	end
	SKIN:Bang('[!DisableMeasure MeasurePing'..active..'][!HideMeter MeterGraph'..active..'][!HideMeterGroup '..active..'][!WriteKeyValue Variables Active '..(active - 1)..' "#@#/Scripts/Ping/Settings.inc"][!Redraw]')
	active = active - 1
end

function Add(n)
	if active == 10 then
		return
	end
	for i = 1, n do
		active = active + 1
		SKIN:Bang('[!EnableMeasure MeasurePing'..active..'][!ShowMeterGroup '..active..']')
		if variable['Open'][active] == 1 then
			ToggleGraph(active)
		end
	end
	SKIN:Bang('[!WriteKeyValue Variables Active '..active..' "#@#/Scripts/Ping/Settings.inc"][!Redraw]')
end

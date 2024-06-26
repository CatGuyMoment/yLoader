local httpgetfunction = httpget

if not httpgetfunction then
	warn("uhh.. dude... does your executor like... support httpget? if it does, i couldn't find it...")
	--return
end

local literallyAllTheProperties = loadstring(httpgetfunction("https://raw.githubusercontent.com/CatGuyMoment/yLoader/main/silly.qwerty"))()
--local literallyAllTheProperties = require(script.ModuleScript)
local xmlParser = {}
local httpservice = game:GetService("HttpService")

function bool_to_string(bool)
	return if bool then "true" else "false"
end

function wrap(objType,stringToWrap,extraParams,removeNewLine)
	local str = "<"..objType
	if extraParams then
		for i,v in pairs(extraParams) do
			str = str.." "..i.."=".."\""..v.."\""
		end
	end
	str = str..">"..stringToWrap.."</"..objType..">"
	if not removeNewLine then
		str = str.."\n"
	end
	return str
end


local parserScenarios = {
	Axes = function(obj,propertyName)
		local axes = 0
		if obj.Z then
			axes += 4
		end
		if obj.Y then
			axes += 2
		end
		if obj.X then 
			axes += 1
		end
		return wrap(
			"Axes",
				wrap("axes",axes),
			{name=propertyName}
		)
	end,
	BrickColor = function(obj,propertyName)
		return wrap(
			"BrickColor",
			obj.Number,
			{name=propertyName}
			
		)
	end,
	Color3 = function(obj,propertyName)
		return wrap(
			"Color3",
				wrap("R",obj.R)..
				wrap("G",obj.G)..  
				wrap("B",obj.B),
				{name=propertyName}
		)
	end,
	ColorSequence = function(obj,propertyName)
		local sequence = ""
		for i,v in pairs(obj.Keypoints) do
			sequence = sequence..v.Time.." "..v.Value.R.." "..v.Value.G.." "..v.Value.B.." ".."0".." "
		end
		return wrap(
			"ColorSequence",
			sequence,
			{name=propertyName}
						
		)
	end,
	Content = function(asset,propertyName)
		return wrap("Content",wrap("url",asset,nil,true),{name=propertyName})
	end,
	CFrame = function(obj,propertyName)
		return wrap(
			"CoordinateFrame",
				wrap("X",obj.X)..
				wrap("Y",obj.Y)..  
				wrap("Z",obj.Z)..
				wrap("R00",obj.RightVector.X)..
				wrap("R01",obj.UpVector.X)..
				wrap("R02",-obj.LookVector.X)..  --dude cframes are so fucking arbitrary like what???!!
				wrap("R10",obj.RightVector.Y)..
				wrap("R11",obj.UpVector.Y)..
				wrap("R12",-obj.LookVector.Y).. 
				wrap("R20",obj.RightVector.Z)..
				wrap("R21",obj.UpVector.Z)..
				wrap("R22",-obj.LookVector.Z),
			{name=propertyName}
		)
	end,
	Faces = function(obj,propertyName)
		local axes = 0
		if obj.Front then
			axes += 32
		end
		if obj.Bottom then
			axes += 16
		end
		if obj.Left then
			axes += 8
		end
		if obj.Back then
			axes += 4
		end
		if obj.Top then
			axes += 2
		end
		if obj.Right then 
			axes += 1
		end
		return wrap(
			"Faces",
			wrap("faces",axes),
			{name=propertyName}
		)
	end,
	Font = function(obj,propertyName)
		return wrap(
			"Font",
				wrap("Family",wrap("url",obj.Family),nil,true)..
				wrap("Weight",obj.Weight.Value)..
				wrap("Style",obj.Style.Name),
			{name=propertyName} --dude... WHAT. WHAT DO YOU MEAN NAME... USE VALUE LIKE THE OTHER ONE YOU LUNATIC
				
		)
	end,
	NumberRange = function(obj,propertyName)
		return wrap("NumberRange",
			obj.Min.." "..obj.Max,
			{name=propertyName}
		)
	end,
	NumberSequence = function(obj,propertyName)
		local sequence = ""
		for i,v in pairs(obj.Keypoints) do
			sequence = sequence..v.Time.." "..v.Value.." "..v.Envelope.." "
		end
		return wrap(
			"NumberSequence",
			sequence,
			{name=propertyName}

		)
	end,
	referent = function(referent,propertyName)
		return wrap("Ref",referent,{name=propertyName})
	end,
	PhysicalProperties = function(obj,propertyName)
		return wrap(
			"PhysicalProperties",
				wrap("CustomPhysics","true")..
				wrap("Density",obj.Density)..  
				wrap("Friction",obj.Friction)..
				wrap("Elasticity",obj.Elasticity)..
				wrap("FrictionWeight",obj.FrictionWeight)..
				wrap("ElasticityWeight",obj.ElasticityWeight),
			{name=propertyName}
		)
	end,
	UDim = function(obj,propertyName)
		return wrap("UDim",
				wrap("S",obj.Scale).. 
				wrap("O",obj.Offset),
			{name=propertyName}
		)
	end,
	UDim2 = function(obj,propertyName)
		return wrap("UDim2",
				wrap("XS",obj.X.Scale).. 
				wrap("XO",obj.X.Offset)..
				wrap("YS",obj.Y.Scale)..
				wrap("YO",obj.Y.Offset),
			{name=propertyName}
		)
	end,
	Vector2 = function(obj,propertyName)
		return wrap("Vector2",
				wrap("X",obj.X).. 
				wrap("Y",obj.Y),
			{name=propertyName}
		)
	end,
	EnumItem = function(obj,propertyName)
		return wrap("token",obj.Value,{name=propertyName})
	end,
	Vector3 = function(obj,propertyName)
		return wrap(
			"Vector3",
				wrap("X",obj.X)..
				wrap("Y",obj.Y)..  
				wrap("Z",obj.Z),
			{name=propertyName}
		)
	end,
	boolean = function(bool,propertyName)
		return wrap("bool",bool_to_string(bool),{name=propertyName})
	end,
	number = function(number,propertyName) --you gotta detect what KIND of number it is manually because fuck you
		local indicator = "float"
		if number==math.floor(number) then
			indicator = "int"
			number = number%2147483647 --juust in case shit hits the fan
		end
		return wrap(indicator,number,{name=propertyName})
	end,
	string = function(stringe,propertyName)
		return wrap("string",stringe,{name=propertyName})
	end,
}


xmlParser.__index = xmlParser

function createGUID()
	return "RBX"..httpservice:GenerateGUID(false):gsub("-","")
end


xmlParser.new = function()
	local self = setmetatable({}, xmlParser)
	self.referents = {}
	return self
end


function xmlParser:goThruProperties(instanc)
	local propertyTable = {}
	if not literallyAllTheProperties[instanc.ClassName] then
		warn("uhh dude... no properties found? please report to yqat on discord (CLASSNAME:"..instanc.ClassName)
		return false
	end
	for i,v in pairs(literallyAllTheProperties[instanc.ClassName]) do
		if v:find("=>") or i=="Parent" or i=="ClassName" then continue end
		pcall(function()
			local property = instanc[i]
			if typeof(property) == "RBXScriptSignal" then
				return
			end
			if typeof(property) == "Instance" then
				property = self:GetReferent(property)
			end
			propertyTable[i] = property end) --dude... i am NOT risking it.... it may suck for performance, but it's good enough for me.

	end
	if instanc:IsA("MeshPart") then
		propertyTable["InitialSize"] = instanc.MeshSize
	end
	return propertyTable
end

function xmlParser:AddReferent(instanc)
	local guid = createGUID()
	self.referents[instanc] = guid
	return guid
end
function xmlParser:GetReferent(instanc)
	return self.referents[instanc] or self:AddReferent(instanc)
end
function xmlParser:ConvertToTable(instanc)
	local tabl = {}
	tabl.class = instanc.ClassName
	tabl.referent = self:GetReferent(instanc)
	tabl.elements = {}
	tabl.Properties = self:goThruProperties(instanc)
	if tabl.Properties == false then
		return false
	end
	for i,v in pairs(instanc:GetChildren()) do
		local child = self:ConvertToTable(v)
		if child then
			table.insert(tabl.elements,child)
		end
	end
	return tabl
end
function xmlParser:ParseSingleItem(tbl)
	local innerxml = ""
	for i,v in pairs(tbl.Properties) do
		local parserFN = parserScenarios[typeof(v)]
		if typeof(v) == "string" then
			if v:sub(1,3)== "RBX" then
				parserFN = parserScenarios.referent
			elseif v:sub(1,8)=="rbxasset" or v:sub(1,4) == "http" then
				parserFN = parserScenarios.Content
			end
		end
		if not parserFN then warn("warning: type not detected,skipping",v,typeof(v)) continue end
		innerxml = innerxml..parserFN(v,i)
	end
	local innerxml = wrap("Properties",innerxml)
	for i,v in pairs(tbl.elements) do
		innerxml = innerxml..self:ParseSingleItem(v)
	end
	return wrap("Item",innerxml,{class = tbl.class,referent=tbl.referent})
end
function xmlParser:Parse(instanc)
	local tbl = self:ConvertToTable(instanc)
	local parsed = self:ParseSingleItem(tbl)
	
	return wrap("roblox",parsed,{version="4"})
end

return function(inst) if inst == game then warn("SAVEINSTANCE DOESN'T SUPPORT SAVING THE ENTIRE GAME DIRECTLY. PLEASE SAVE IN FRAGMENTS") warn("eg: saveinstance(game.Workspace)") return end return xmlParser.new():Parse(inst) end

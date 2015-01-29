
local SHARED = require("boner.shared");

--[[
	
--]]
local MEventHandler = SHARED.Meta.EventHandler;
MEventHandler.__index = MEventHandler;
local function newEventHandler(actor)
	local t = setmetatable({}, MEventHandler);
	t:SetActor(actor);
	t.Callbacks = {};
	t.Checked = {};
	return t;
end

function MEventHandler:SetActor(actor)
	if (not actor or type(actor) ~= "table") then
		error(errorArgs("BadArg", 1, "SetActor", "table", type(actor)));
	elseif (not SHARED.isMeta(actor, "Actor")) then
		error(SHARED.errorArgs("BadMeta", 1, "SetActor", "Actor", tostring(SHARED.Meta.Actor), tostring(getmetatable(actor))));
	end
	self.Actor = actor;
end
function MEventHandler:GetActor()
	return self.Actor;
end

function MEventHandler:Register(animName, eventName, funcCallback)
	if (not animName or type(animName) ~= "string") then
		error(SHARED.errorArgs("BadArg", 1, "Register", "string", type(animName)));
	elseif (not eventName or type(eventName) ~= "string") then
		error(SHARED.errorArgs("BadArg", 2, "Register", "string", type(eventName)));
	elseif (not funcCallback or type(funcCallback) ~= "function") then
		error(SHARED.errorArgs("BadArg", 3, "Register", "function", type(eventName)));
	end
	self.Callbacks[animName] = self.Callbacks[animName] or {};
	self.Callbacks[animName][eventName] = self.Callbacks[animName][eventName] or {};
	table.insert(self.Callbacks[animName][eventName], funcCallback);
end

function MEventHandler:Fire(animName, eventName)
	if (not animName or type(animName) ~= "string") then
		error(errorArgs("BadArg", 1, "Fire", "string", type(animName)));
	elseif (not eventName or type(eventName) ~= "string") then
		error(errorArgs("BadArg", 2, "Fire", "string", type(eventName)));
	end
	if (animName and self.Callbacks[animName] and eventName and self.Callbacks[animName][eventName]) then
		for i = 1, #self.Callbacks[animName][eventName] do
			--print("Fire callback",animName, eventName, i);
			self.Callbacks[animName][eventName][i](self:GetActor(), animName, eventName);
		end
	end
end

-- TODO: Support checks for animations playing backwards.
function MEventHandler:Check(animObj, keyTime)
	if (not animObj or type(animObj) ~= "table") then
		error(SHARED.errorArgs("BadArg", 1, "Check", "table", type(animObj)));
	elseif (not SHARED.isMeta(animObj, "Animation")) then
		error(SHARED.errorArgs("BadMeta", 1, "Check", "Animation", tostring(SHARED.Meta.Animation), tostring(getmetatable(animObj))));
	elseif (not keyTime or type(keyTime) ~= "number") then
		error(SHARED.errorArgs("BadArg", 2, "Check", "number", type(keyTime)));
	end
	
	-- No events for this anim? Do nothing.
	if (#animObj.Events == 0) then
		return;
	end
	
	-- Did we already checked for events on this animation this frame?
	if (self.Checked[animObj:GetName()] and self.Checked[animObj:GetName()] == keyTime) then
		return;
	end
	self.Checked[animObj:GetName()] = self.Checked[animObj:GetName()] or 0;
	
	local events = animObj:GetEventsInRange(self.Checked[animObj:GetName()], keyTime);
	for i = 1, #events do
		self:Fire(animObj:GetName(), events[i].name);
	end
	
	--self.lastCheck = keyTime;
	self.Checked[animObj:GetName()] = keyTime;
end

return newEventHandler;
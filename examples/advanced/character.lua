local boner = require(LIBNAME);
--[[
	Character
	A wrapper for Actor with a focus on animations. 
	Abstracts Transformation handling from the user for easy animation playback.
--]]
local MCharacter = {}
MCharacter.__index = MCharacter;

local function newCharacter(skeleton, skinData)
	local t = setmetatable({}, MCharacter);
	t.Actor = boner.newActor(skeleton, skinData);
	t.Animations = {};
	t.Layers = {};
	t.Blend = {};
	t.State = {};
	t.Skins = {default = skinData};
	if (skinData) then
		self:SetSkin("default");
	end
	return t;
end

function MCharacter:RegisterAnimation(animName, anim, boneMask)
	self.Animations[animName] = anim;
	self.Blend[animName] = {direction = 0, time = 0};
	self.State[animName] = "stopped";
	self.Actor:GetTransformer():SetTransform(animName, anim, boneMask);
end
function MCharacter:RegisterSkin(skinName, skinData)
	self.Skins[skinName] = skinData;
end
function MCharacter:RegisterEvent(animName, eventName, callback)
	self.Actor:GetEventHandler():Register(self.Animations[animName], eventName, callback);
end
--[[
function MCharacter:SetAttachment(boneName, attachName, attachment)
	
end
function MCharacter:GetAttachment(boneName, attachName)

end
--]]
function MCharacter:GetOrientation(boneName, attachName)
	return {
		rotation = self.Actor:GetTransformer():GetAngle(boneName, attachName),
		translation = {self.Actor:GetTransformer():GetPosition(boneName, attachName)},
		scale = {self.Actor:GetTransformer():GetScale(boneName, attachName)}
	};
end

function MCharacter:SetSkin(skinName)
	local bones = self.Actor:GetSkeleton():GetBoneList();
	for i = 1, #bones do
		local boneName = bones[i];
		local vis = self.Skins[skinName][boneName];
		if (vis and boner.isType(vis, "Visual")) then
			local attach = self.Actor:GetAttachment(boneName, "skin");
			if (not attach) then
				self.Actor:SetAttachment(boneName, "skin", boner.newAttachment(vis));
			else
				attach:SetVisual(vis);
			end
		end
	end
end

-- Root Transformation accessors
function MCharacter:SetPosition(x, y)
	self.Actor:GetTransformer():GetRoot().translation = {x, y};
end
function MCharacter:SetAngle(a)
	self.Actor:GetTransformer():GetRoot().rotation = a;
end
function MCharacter:SetScale(x, y)
	self.Actor:GetTransformer():GetRoot().scale = {x, y};
end
function MCharacter:GetPosition()
	return unpack(self.Actor:GetTransformer():GetRoot().translation);
end
function MCharacter:GetAngle()
	return self.Actor:GetTransformer():GetRoot().rotation;
end
function MCharacter:GetScale()
	return unpack(self.Actor:GetTransformer():GetRoot().scale);
end

function MCharacter:GetAnimationState(animName)
	return self.State[animName];
end

function MCharacter:SetAnimationLayer(animName, layer)
	local transformName = animName;
	local transformer = self.Actor:GetTransformer();
	local boneList = {};
	for boneName, enabled in pairs(transformer.BoneMasks[transformName]) do
		if (enabled) then
			table.insert(boneList, boneName);
		end
	end
	transformer:SetPriority(transformName, layer, boneList);
end

function MCharacter:StartAnimation(animName, blendTime)
	local vars = self.Actor:GetTransformer():GetVariables(animName);
	vars.time = 0;
	self.Blend[animName] = {direction = 1, time = blendTime};
	self.State[animName] = "playing";
end

function MCharacter:EndAnimation(animName, blendTime)
	self.Blend[animName] = {direction = -1, time = blendTime};
end

function MCharacter:ToggleAnimationPlaying(animName)
	if (self.State[animName] == "paused") then
		self.State[animName] = "playing";
	elseif (self.State[animName] == "playing") then
		self.State[animName] = "paused";
	end
end

function MCharacter:StopAnimation(animName)
	local transformName = animName;
	self.State[animName] = "stopped";
	transformer:SetPower(transformName, 0);
end

function MCharacter:Update(dt)
	for animName, _ in pairs(self.Animations) do
		if (self.State[animName] == "playing") then
			local transformName = animName;
			local transformer = self.Actor:GetTransformer();
			
			-- Update time for animations
			local transform = transformer:GetTransform(transformName);
			if (boner.isType(transform, "Animation")) then
				local vars = transformer:GetVariables(transformName);
				vars.time = vars.time + dt;
			end
			
			-- Calculate new power
			local blend = self.Blend[animName];
			local direction = blend.direction or 0;
			local power = transformer:GetPower(transformName);
			power = power + direction * dt * (1/blend.time);
			
			-- Stop animation if power is less than 0.
			if (power <= 0) then
				self.State[animName] = "stopped";
			end
			
			-- Set power
			transformer:SetPower(transformName, power);
		end
	end
	self.Actor:Update();
end
function MCharacter:Draw()
	self.Actor:Draw();
end

return newCharacter;
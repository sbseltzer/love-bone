local boner = require("boner");
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
	self.Blend[animName] = {direction = 0, time = 0, start = 0};
	self.State[animName] = "stopped";
	self.Actor:GetTransformer():Register("anim_" .. animName, anim, boneMask);
end
function MCharacter:RegisterSkin(skinName, skinData)
	self.Skins[skinName] = skinData;
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

function MCharacter:SetPosition(x, y)
	self.Actor:GetTransformer():GetRoot().translation = {x, y};
end
function MCharacter:SetAngle(a)
	self.Actor:GetTransformer():GetRoot().rotation = a;
end
function MCharacter:SetScale(x, y)
	self.Actor:GetTransformer():GetRoot().scale = {x, y};
end

function MCharacter:GetAnimationState(animName)
	return self.State[animName];
end

function MCharacter:SetAnimationLayer(animName, layer)
	local transformName = "anim_" .. animName;
	local transformer = self.Actor:GetTransformer();
	local boneList = {};
	for boneName, enabled in pairs(transformer.BoneMasks[transformName]) do
		if (enabled) then
			table.insert(boneList, boneName);
		end
	end
	transformer:SetPriority(transformName, boneList, layer);
end

function MCharacter:StartAnimation(animName, blendTime)
	local vars = self.Actor:GetTransformer():GetVariables("anim_" .. animName);
	vars.time = 0;
	local curTime = vars.time or 0
	self.Blend[animName] = {direction = 1, time = blendTime, start = curTime};
	self.State[animName] = "playing";
end

function MCharacter:EndAnimation(animName, blendTime)
	local vars = self.Actor:GetTransformer():GetVariables("anim_" .. animName);
	local curTime = vars.time or 0
	self.Blend[animName] = {direction = -1, time = blendTime, start = curTime};
end

function MCharacter:ToggleAnimationPlaying(animName)
	if (self.State[animName] == "paused") then
		self.State[animName] = "playing";
	elseif (self.State[animName] == "playing") then
		self.State[animName] = "paused";
	end
end

function MCharacter:StopAnimation(animName)
	local transformName = "anim_" .. animName;
	self.State[animName] = "stopped";
	transformer:SetPower(transformName, 0);
end

function MCharacter:Update(dt)
	for animName, _ in pairs(self.Animations) do
		if (self.State[animName] == "playing") then
			local transformName = "anim_" .. animName;
			local transformer = self.Actor:GetTransformer();
			local vars = transformer:GetVariables(transformName);
			
			vars.time = vars.time + dt;
			
			local curTime = vars.time;
			local blend = self.Blend[animName];
			local direction = blend.direction or 0;
			
			local power = transformer:GetPower(transformName);
			power = power + direction * dt * (1/blend.time);
			transformer:SetPower(transformName, power);
			power = transformer:GetPower(transformName);
			if (power == 0) then
				self.State[animName] = "stopped";
			end
		end
	end
	self.Actor:Update();
end
function MCharacter:Draw()
	self.Actor:Draw();
end

return newCharacter;
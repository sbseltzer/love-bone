
local SHARED = require("boner.shared");
local newAttachment = require("boner.attachment");

--[[
	Skins define a visual appearance of a skeleton for an actor.
	Contains a list of texture data, and which bones they are assigned to by default.
--]]
local MSkin = SHARED.Meta.Skin;
MSkin.__index = MSkin;
local function newSkin()
	local t = {};
	t.BoneTextures = {};
	t.Textures = {};
	return setmetatable(t, MSkin);
end

-- Skeleton reference.
function MSkin:SetSkeleton(skeleton)
	self.Skeleton = skeleton;
end
function MSkin:GetSkeleton()
	return self.Skeleton;
end

-- Registers a texture for the skin to use.
function MSkin:RegisterTexture(texID, image, origin, quad, angle, scale)
	if (not image) then
		error("Unable to register texture '" .. texID .. "': No image!", 2);
		return; -- No image? Then what's the point?
	end
	print("Register Texture:", texID, image, origin, quad, angle, scale);
	
	origin = origin or {0, 0};
	angle = angle or 0;
	scale = scale or {1, 1};
	
	-- If the image is not an Image, make sure we turn it into one (if possible)
	local isValid = true;
	if (type(image) == "userdata") then
		if (image:typeOf("ImageData")) then
			image = love.graphics.newImage(image);
		elseif (not image:typeOf("Image")) then
			isValid = false;
		end
	elseif (type(image) == "string") then
		image = love.graphics.newImage(image);
	else
		isValid = false;
	end
	if (not isValid) then
		error("Unable to register bone '" .. texID .. "': Invalid image of type '" .. type(image) .. "' (valid types: string, Image, ImageData)!", 2);
		return; -- Invalid image? Bad!
	end
	print(texID, quad);
	
	-- If there is quad data...
	if (quad) then
		if (type(quad) ~= "userdata") then
			-- If it is parameters
			if (type(quad) == "table") then
				if (#quad ~= 4) then
					error("Unable to register texture '" .. texID .. "': There must be exactly 4 quad parameters!", 2);
				end
				local x, y, w, h = unpack(quad);
				quad = love.graphics.newQuad(x, y, w, h, image:getDimensions());
			else
				quad = nil;
			end
		elseif (not quad:typeOf("Quad")) then
			quad = nil;
		end
	end
	print(texID, quad);
	
	local data = {};
	data.Image = image;
	data.Quad = quad;
	data.Angle = angle;
	data.Origin = {unpack(origin)};
	data.Scale = {unpack(scale)};
	
	self.Textures = self.Textures or {};
	self.Textures[texID] = data;
end



-- Tell a bone to use a registered texture
function MSkin:SetBoneTexture(boneName, texID)
	if (not self:GetSkeleton()) then
		error("Unable to register bone '" .. boneName .. "' for skin: Skeleton is not set!", 2);
		return;
	end
	if (not self:GetSkeleton().Bones[boneName]) then
		error("Unable to register bone '" .. boneName .. "' for skin: Skeleton has no such bone!", 2);
		return;
	end
	if (not texID) then
		error("Unable to register bone '" .. boneName .. "' for skin: Invalid texture ID!", 2);
		return;
	end
	if (not self.Textures[texID]) then
		error("Unable to register bone '" .. boneName .. "' for skin: No texture with ID '" .. texID.. "'!", 2);
		return;
	end
	self.BoneTextures = self.BoneTextures or {};
	self.BoneTextures[boneName] = texID;
end

-- Returns true if the bone name has a texture assigned to it in this skin.
function MSkin:IsSkinned(boneName)
	return self.BoneTextures[boneName] ~= nil;
end
-- Returns the image object for a bone.
function MSkin:GetImage(boneName)
	if (not self:IsSkinned(boneName)) then
		return;
	end
	local texID = self.BoneTextures[boneName];
	return self.Textures[texID].Image;
end
-- Returns the quad object for a bone.
function MSkin:GetQuad(boneName)
	if (not self:IsSkinned(boneName)) then
		return;
	end
	local texID = self.BoneTextures[boneName];
	return self.Textures[texID].Quad;
end
-- Returns the image or quad dimensions for a bone.
function MSkin:GetDimensions(boneName)
	if (not self:IsSkinned(boneName)) then
		return;
	end
	local texID = self.BoneTextures[boneName];
	if (texID and self.Textures[texID] and self.Textures[texID].Quad) then
		local x, y, w, h = self.Textures[texID].Quad:getViewport();
		return w, h;
	end
	return self.Textures[texID].Image:getDimensions();
end
-- Returns the origin to render from for the image for a bone.
function MSkin:GetOrigin(boneName)
	if (not self:IsSkinned(boneName)) then
		return;
	end
	local texID = self.BoneTextures[boneName];
	return unpack(self.Textures[texID].Origin)
end
-- Returns the angle that the image is rendered at for a bone.
function MSkin:GetAngle(boneName)
	if (not self:IsSkinned(boneName)) then
		return;
	end
	local texID = self.BoneTextures[boneName];
	return self.Textures[texID].Angle;
end
-- Returns the scale at which the image is rendered for a bone.
function MSkin:GetScale(boneName)
	if (not self:IsSkinned(boneName)) then
		return;
	end
	local texID = self.BoneTextures[boneName];
	return unpack(self.Textures[texID].Scale);
end

return newSkin;
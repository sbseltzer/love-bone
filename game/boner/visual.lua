
local SHARED = require("boner.shared");

--[[
	Visual
	Used by Attachments as a wrapper/abstraction object for anything that could be used to render as an attachment.
	In most cases, the backing visual element will be some type of Drawable.
	The advantage of abstraction is in its utility. The backing visual element could be an image, a particle emitter, or even a canvas.
	We could even extend this to objects with a draw method (like our Actor object).
--]]
local MVisual = SHARED.Meta.Visual;
MVisual.__index = MVisual;
local function newVisual(vis, ...)
	local t = setmetatable({}, MVisual);
	t:SetVisualData(vis, ...);
	t:SetOrigin(0, 0);
	t:SetRotation(0);
	return t;
end

function MVisual:SetVisualData(vis, ...)
	if (vis == nil) then
		error("Attempt to set visual to nil!", 2);
	end
	local vType = type(vis);
	-- Strings are assumed to be image paths
	if (vType == "string") then
		vis = love.graphics.newImage(vis);
	elseif (vType == "userdata") then
		-- ImageData will always be used for images
		if (vis:typeOf("ImageData")) then
			vis = love.graphics.newImage(vis);
		-- Any drawables can just be used as they are.
		elseif(not vis:typeOf("Drawable")) then
			error("Invalid userdata object for visual: Must be a Drawable type!", 2);
		end
	--elseif (vType == "table" and SHARED.isMeta(vis, "Actor")) then
		-- Maybe...
	else
		error("Invalid visual type!", 2);
	end
	-- Attempt to get a quad for texture types.
	local args = {...};
	if (vis.typeOf and (vis:typeOf("Texture") or vis:typeOf("SpriteBatch"))) then
		if (#args >= 4) then
			local x, y, w, h = ...;
			if (tonumber(x) and tonumber(y) and tonumber(w) and tonumber(h)) then
				self.Quad = love.graphics.newQuad(x, y, w, h);
			end
		elseif (#args >= 1) then
			local quad = args[1];
			if (quad and type(quad) == "userdata" and quad:typeOf("Quad")) then
				self.Quad = quad;
			end
		end
		-- If a Sprite ID was already set for this attachment
		--[[if (self.SpriteID) then
			-- If our previous visual was a sprite batch and is different from the new visual, remove it from the sprite batch.
			if (self.Visual:typeOf("SpriteBatch") and vis ~= self.Visual) then
				self.Visual:set(self.SpriteID, 0, 0, 0, 0, 0);
				self.SpriteID = nil;
			end
		end]]
	else
		self.Quad = nil;
	end
	self.Visual = vis;
end
function MVisual:GetVisualData()
	return self.Visual, self.Quad; --, self.SpriteID;
end

function MVisual:GetDimensions()
	local vis, quad = self:GetVisualData();
	if (quad) then
		local x, y, w, h = quad:getViewport();
		return w, h;
	elseif (type(vis) == "userdata") then
		if (vis:typeOf("Texture")) then
			return vis:getDimensions();
		--[[elseif (vis:typeOf("SpriteBatch")) then
			return vis:getTexture():getDimensions();]]
		elseif (vis:typeOf("ParticleSystem")) then
			local distribution, dx, dy = vis:getAreaSpread();
			local w, h = 1, 1;
			if (distribution ~= "none") then
				w = dx;
				h = dy;
			end
			return w*2, h*2;
		elseif (vis:typeOf("Mesh")) then
			local maxX, maxY, minX, minY = -1/0, -1/0, 1/0, 1/0;
			local verts = vis:getVertices();
			for i = 1, #verts, 8 do
				local x = verts[i];
				local y = verts[i+1]
				if x > maxX then
					maxX = x;
				elseif x < minX then
					minX = x;
				end
				if y > maxY then
					maxY = y;
				elseif y < minY then
					minY = y;
				end
			end
			return maxX - minX, maxY - minY;
		end
	end
	return 0, 0;
end

function MVisual:SetOrigin(x, y)
	self.Origin = {x, y};
end
function MVisual:GetOrigin()
	return unpack(self.Origin);
end
function MVisual:SetRotation(r)
	self.Rotation = r;
end
function MVisual:GetRotation()
	return self.Rotation;
end

function MVisual:Draw(attach)
	local vis, quad = self:GetVisualData(); --, spriteID
	local x, y = 0, 0;--attach:GetTranslation();
	local r = self:GetRotation(); --+ attach:GetRotation();
	local sx, sy = 1, 1; --attach:GetScale();
	local ox, oy = self:GetOrigin();
	local params = {x, y, r, sx, sy, ox, oy};
	if (quad) then
		table.insert(params, 1, quad);
	end
	--print(unpack(params));
	--[[if (vis.typeOf and vis:typeOf("SpriteBatch")) then
		if (not self.SpriteID) then
			self.SpriteID = vis:add(unpack(params));
		else
			vis:set(self.SpriteID, unpack(params));
		end
	else]]
		love.graphics.draw(vis, unpack(params));
	--end
end

return newVisual;
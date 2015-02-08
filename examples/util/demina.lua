local XmlParser = require("examples.util.XmlParser");
local boner = require(LIBNAME);
-- Debug
local function print_r(t, func, i, found)
	func = func or print;
	i = i or 1;
	if (i == 1) then
		func("{");
	end
	found = found or {};
	local tabs = string.rep("  ", i);
	found[t] = true;
	for k, v in pairs(t) do
		if (type(v) == "table") then
			if (found[v]) then
				func(tabs .. tostring(k) .. " : <parent>");
			else
				func(tabs .. tostring(k) .. " :");
				func(tabs .. "{");
				print_r(v, func, i + 1, found);
				func(tabs .. "}");
			end
		else
			func(tabs .. tostring(k) .. " : " .. tostring(v));
		end
	end
	if (i == 1) then
		func("}");
	end
end
local function getDirectory(filename)
	local lastSlash = string.find(filename, "([^/])/[^/]+$");
	local path = string.sub(filename, 1, lastSlash) or "";
	if (string.sub(path, -1) ~= '/' or string.sub(path, -1) ~= '\\') then
		path = path .. "/";
	end
	return path;
end
--[[
Demina XML file structure:
	Animation
		FrameRate : value=frameTime/sec
		LoopFrame : value=frameTime, default=-1
		Texture : value=file
		...
		KeyFrame : attrs={frame=frameTime,vflip=?,hflip=?,trigger=?}
			Bone : attrs={name=boneName}
				Hidden : ?
				TextureFlipHorizontal : ?
				TextureFlipVertical : ?
				ParentIndex : value=(childNode index of parent in KeyFrame, starting at 0. -1 means no parent.)
				TextureIndex : value=(textureNode index in Animation, starting at 0.)
				Position : 
					X : value=x
					Y : value=y
				Rotation : value=angle
				Scale : 
					X : value=x
					Y : value=y
			...
]]

local function ParseDeminaTextureDictionaryFile(xmlFile)
	local content, size = love.filesystem.read( xmlFile );
	local xml = XmlParser:ParseXmlText(content);
	--[[local str = "";
	print_r(xml, function(text)
		str = str .. text .. "\n";
	end);
	love.filesystem.write("test.txt", str);]]
	if (xml.Name ~= "TextureDictionary") then
		print("Invalid dictionary file - root node must be of type 'TextureDictionary' - given '" .. xml.Name .. "'");
		return;
	end
	local fileData = {};
	for i = 1, #xml.ChildNodes do
		local node = xml.ChildNodes[i];
		if (node.Name == "TexturePath") then
			fileData.image = love.graphics.newImage(getDirectory(xmlFile) .. node.Value);
		elseif (node.Name == "Texture") then
			local properties = {
				position = {0, 0},
				dimensions = {0, 0},
				origin = {0, 0}
			};
			for j = 1, #node.ChildNodes do
				local prop = node.ChildNodes[j];
				if (prop.Name == "X") then
					properties.position[1] = tonumber(prop.Value);
				elseif (prop.Name == "Y") then
					properties.position[2] = tonumber(prop.Value);
				elseif (prop.Name == "Width") then
					properties.dimensions[1] = tonumber(prop.Value);
				elseif (prop.Name == "Height") then
					properties.dimensions[2] = tonumber(prop.Value);
				elseif (prop.Name == "OriginX") then
					properties.origin[1] = tonumber(prop.Value);
				elseif (prop.Name == "OriginY") then
					properties.origin[2] = tonumber(prop.Value);
				end
			end
			fileData.quads = fileData.quads or {};
			fileData.quads[node.Attributes.name] = properties;
		end
	end
	-- Now we have data in a nicer form.
	-- From here, we could load it as a skin, a 
	return fileData;
end

local function RipBone(boneNode)
	local name = boneNode.Attributes.name;
	local parent = -1;
	local texture = -1;
	local position = {0,0};
	local rotation = 0;
	local scale = {1,1};
	for i = 1, #boneNode.ChildNodes do
		local node = boneNode.ChildNodes[i];
		if (node.Name == "ParentIndex") then
			parent = node.Value;
		elseif (node.Name == "TextureIndex") then
			texture = node.Value;
		elseif (node.Name == "Position") then
			for _, v in pairs(node.ChildNodes) do
				if (v.Name == "X") then
					position[1] = tonumber(v.Value);
				elseif (v.Name == "Y") then
					position[2] = tonumber(v.Value);
				end
			end
		elseif (node.Name == "Scale") then
			for _, v in pairs(node.ChildNodes) do
				if (v.Name == "X") then
					scale[1] = tonumber(v.Value);
				elseif (v.Name == "Y") then
					scale[2] = tonumber(v.Value);
				end
			end
		elseif (node.Name == "Rotation") then
			rotation = tonumber(node.Value);
		end
	end
	local boneData = {};
	boneData.boneName = name;
	boneData.parentIndex = parent + 1;
	boneData.textureIndex = texture + 1;
	boneData.rotation = rotation;
	boneData.position = position;
	boneData.scale = scale;
	return boneData;
end
local function RipKeyFrame(frameNode)
	local frameData = {};
	frameData.bones = {};
	frameData.frameTime = frameNode.Attributes.frame;
	if (frameNode.Attributes.trigger and string.len(frameNode.Attributes.trigger) > 0) then
		frameData.eventName = frameNode.Attributes.trigger
	end
	for i = 1, #frameNode.ChildNodes do
		local node = frameNode.ChildNodes[i];
		if (node.Name == "Bone") then
			local data = RipBone(node);
			table.insert(frameData.bones, data);
		end
	end
	return frameData;
end
local function ParseDeminaFile(xmlFile)
	local content, size = love.filesystem.read( xmlFile );
	local xml = XmlParser:ParseXmlText(content);
	--[[local str = "";
	print_r(xml, function(text)
		str = str .. text .. "\n";
	end);
	love.filesystem.write("test.txt", str);]]
	if (xml.Name ~= "Animation") then
		print("Invalid animation file - root node must be of type 'Animation' - given '" .. xml.Name .. "'");
		return;
	end
	local dictionaryData = {};
	local fileData = {};
	fileData.frameRate = -1;
	fileData.loopFrame = -1;
	fileData.textures = {};
	fileData.keyframes = {};
	for i = 1, #xml.ChildNodes do
		local node = xml.ChildNodes[i];
		if (node.Name == "FrameRate") then
			fileData.frameRate = node.Value;
		elseif (node.Name == "LoopFrame") then
			fileData.loopFrame = node.Value;
		elseif (node.Name == "Texture") then
			local texData = {};
			if (node.Attributes.dictionary) then
				texData.dictionaryPath = getDirectory(xmlFile) .. node.Attributes.dictionary;
			end
			texData.dictionaryRefName = node.Attributes.name
			texData.imagePath = node.Value;
			if (texData and texData.dictionaryPath and not dictionaryData[texData.dictionaryPath]) then
				dictionaryData[texData.dictionaryPath] = ParseDeminaTextureDictionaryFile(texData.dictionaryPath);
			end
			table.insert(fileData.textures, texData);
		elseif (node.Name == "Keyframe") then
			table.insert(fileData.keyframes, RipKeyFrame(node));
		end
	end
	fileData.textureDictionaries = dictionaryData;
	-- Now we have data in a nicer form.
	-- From here, we could load it as a skin, a 
	return fileData;
end

--[[
Parsed Data Structure:
	fileData
		frameRate
		loopFrame
		textures
			filename
			...
		keyframes
			frame
				frameTime
				bones
					boneName
						boneName
						parentIndex
						textureIndex
						position
						rotation
						scale
					...
			...

How we will interpret these:
	Split into multiple files:
		skeleton.anim - Contains the skeleton in its bind pose. Used for validating animation and skin files.
		animation.anim - Contains an animation.
		skin.anim - Contains a skin.
]]

local function MakeSkeleton(fileData)
	local skeleton = boner.newSkeleton();
	local bindData = fileData.keyframes[1];
	local layerData = {};
	for boneIndex, boneData in ipairs(bindData.bones) do
		local name, parent, layer, offset, defaultRotation, defaultTranslation, defaultScale;
		name = boneData.boneName;
		layer = boneIndex;
		offset = boneData.position;
		defaultRotation = boneData.rotation;
		defaultTranslation = nil;
		defaultScale = nil;
		if (boneData.parentIndex >= 1) then
			parent = bindData.bones[boneData.parentIndex].boneName;
		end
		local bone = boner.newBone(parent, layer, offset, defaultRotation, defaultTranslation, defaultScale);
		skeleton:SetBone(name, bone);
	end
	skeleton:Validate();
	--local bindAnim = boner.newAnimation("__bind__", skeleton);
	return skeleton;
end
local function MakeAnimation(fileData, skeleton)
	local anim = boner.newAnimation(skeleton);
	local firstFrame = {};
	for frameIndex, frameData in ipairs(fileData.keyframes) do
		local boneName, keyTime, rotation, translation, scale;
		keyTime = frameData.frameTime / fileData.frameRate;
		if (frameData.eventName) then
			anim:AddEvent(keyTime, frameData.eventName);
		end
		for boneIndex, boneData in ipairs(frameData.bones) do
			boneName = boneData.boneName;
			rotation = boneData.rotation;
			translation = boneData.position;
			scale = boneData.scale;
			local xOffset, yOffset = skeleton:GetBone(boneName):GetOffset();
			translation[1] = translation[1] - xOffset;
			translation[2] = translation[2] - yOffset;
			anim:AddKeyFrame(boneName, keyTime, rotation, translation, scale);
			if (not firstFrame[boneName]) then
				firstFrame[boneName] = {boneName, keyTime, rotation, translation, scale};
			end
		end
	end
	for name, data in pairs(firstFrame) do
		local boneName, keyTime, rotation, translation, scale = unpack(data);
		keyTime = fileData.loopFrame / fileData.frameRate;
		anim:AddKeyFrame(boneName, keyTime, rotation, translation, scale);
	end
	return anim;
end
local function MakeSkin(fileData, texturePath, skeleton)
	local skin = {};
	if (fileData.keyframes) then
		local bindData = fileData.keyframes[1];
		for boneIndex, boneData in ipairs(bindData.bones) do
			local boneName, image, origin, quad, angle, scale;
			boneName = boneData.boneName;
			origin = {0, 0};
			local texIndex = boneData.textureIndex;
			--print(texIndex, fileData.textures[texIndex])
			if (texIndex and fileData.textures[texIndex]) then
				local texData = fileData.textures[texIndex];
				if (texData.dictionaryPath) then
					local dict = fileData.textureDictionaries[texData.dictionaryPath];
					local quadData = dict.quads[texData.dictionaryRefName];
					local x, y = unpack(quadData.position);
					local width, height = unpack(quadData.dimensions);
					image = dict.image;
					quad = love.graphics.newQuad(x, y, width, height, image:getDimensions());
					origin = quadData.origin;
					scale = quadData.scale;
				elseif (texData.imagePath) then
					texData.imagePath = string.gsub(texData.imagePath, "\\", "/");
					image = love.graphics.newImage(texturePath .. texData.imagePath);
					origin = {image:getWidth()/2, image:getHeight()/2};
				end
			end
			if (image) then
				angle = 0;
				scale = boneData.scale;
				local vis = boner.newVisual(image, quad);
				vis:SetOrigin(unpack(origin));
				vis:SetRotation(angle);
				--vis:SetScale(scale);
				skin[boneName] = vis;
			end
		end
	end
	return skin;
end

local function ImportSkeleton(filename)
	local fileData = ParseDeminaFile(filename);
	return MakeSkeleton(fileData);
end
local function ImportAnimation(filename, skeleton)
	local fileData = ParseDeminaFile(filename);
	return MakeAnimation(fileData, skeleton);
end
local function ImportSkin(filename, skeleton)
	local fileData = ParseDeminaFile(filename);
	return MakeSkin(fileData, getDirectory(filename), skeleton);
end
return {ImportSkeleton = ImportSkeleton, ImportAnimation = ImportAnimation, ImportSkin = ImportSkin};
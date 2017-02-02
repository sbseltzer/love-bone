
-- Include the library
local boner = require(LIBNAME);

local myActor;
function love.load()
	-- Create the skeleton.
	local mySkeleton = boner.newSkeleton();

	-- Add bones to the skeleton
	local NUM_SEGMENTS = 9;
	local boneLength = 50;
	local boneName = "bone";
	for i = 1, NUM_SEGMENTS do
		local name = boneName .. i;
		local parent = boneName .. (i - 1);
		if (i == 1) then
			parent = nil; -- The first bone is the "root", so it shouldn't have a parent.
		end
		local offset = {boneLength, 0};
		if (i == 1) then
			offset[1] = 0; -- The first bone is the "root", so it doesn't need an offset.
		end
		local rotation = 0;
		local translation = {0, 0};
		local scale = {1, 1};
		local bone = boner.newBone(parent, i, offset, rotation, translation, scale);
		mySkeleton:SetBone(name, bone);
	end

	-- Validate the skeleton!
	mySkeleton:Validate();

	-- Create an animation.
	local myAnimation = boner.newAnimation(mySkeleton);
	for i = 1, NUM_SEGMENTS do
		local name = boneName .. i;
		myAnimation:AddKeyFrame(name, 2, math.rad(5*i), nil, nil);
		myAnimation:AddKeyFrame(name, 2.5, math.rad(0), nil, nil);
		myAnimation:AddKeyFrame(name, 4.5, -math.rad(5*i), nil, nil);
		myAnimation:AddKeyFrame(name, 5, math.rad(0), nil, nil);
	end

	-- Create an actor.
	myActor = boner.newActor(mySkeleton);

	-- Create the visual elements for the actor
	local boneVisuals = {};
	for i = 1, 3 do
		local imageData = love.image.newImageData(boneLength, 20);
		imageData:mapPixel(function(x, y, r, g, b, a)
			local hasRed = i == 1;
			local hasGreen = i == 2;
			local hasBlue = i == 3;
			if (hasRed) then r = 255; end
			if (hasGreen) then g = 255; end
			if (hasBlue) then b = 255; end
			return r, g, b, 255;
		end);
		boneVisuals[i] = boner.newVisual(imageData);
		local vw, vh = boneVisuals[i]:GetDimensions();
		boneVisuals[i]:SetOrigin(0, vh/2);
	end

	-- Add attachments to the actor using the visual elements.
	for i = 1, NUM_SEGMENTS do
		local name = boneName .. i;
		local vis = boneVisuals[((i - 1) % 3) + 1];
		local myAttachment = boner.newAttachment(vis);
		myActor:SetAttachment(name, "skin", myAttachment);
	end

	-- Register the animation as a transformation.
	myActor:GetTransformer():SetTransform("anim_curl", myAnimation);

	-- Move it toward the center and stand it upright.
	myActor:GetTransformer():GetRoot().rotation = math.rad(-90);
	myActor:GetTransformer():GetRoot().translation = {love.graphics.getWidth() / 2, love.graphics.getHeight() / 1.25};

	-- Intermediate code:

	-- Adding a reskin method
	myActor.SetSkin = function(self, skinData)
		for boneName, visual in pairs(skinData) do
			if (boner.isType(visual, "Visual")) then
				local attach = boner.newAttachment(visual);
				self:SetAttachment(boneName, "skin", attach);
			end
		end
	end

	-- Add event triggers
	myAnimation:AddEvent(2, "some_event");
	myAnimation:AddEvent(4, "some_event");

	-- Add event callbacks
	myActor:GetEventHandler():Register(myAnimation, "some_event", function(actor, animObj)
		if (actor:GetTransformer():GetPower("anim_spinr") == 0) then
			actor:GetTransformer():SetPower("anim_spinr", 1);
			actor:GetTransformer():SetPower("anim_spinl", 0);
		elseif (actor:GetTransformer():GetPower("anim_spinl") == 0) then
			actor:GetTransformer():SetPower("anim_spinr", 0);
			actor:GetTransformer():SetPower("anim_spinl", 1);
		end
	end);

	-- Animation Layering
	local spinRightAnim = boner.newAnimation(mySkeleton);
	local spinLeftAnim = boner.newAnimation(mySkeleton);
	local spinBone = boneName .. (NUM_SEGMENTS - 2);
	spinRightAnim:AddKeyFrame(spinBone, 1, math.pi * 2, nil, nil);
	spinLeftAnim:AddKeyFrame(spinBone, 1, math.pi * -2, nil, nil);
	local affectedBones = mySkeleton:GetBoneList(spinBone);
	myActor:GetTransformer():SetTransform("anim_spinr", spinRightAnim, affectedBones);
	myActor:GetTransformer():SetTransform("anim_spinl", spinLeftAnim, affectedBones);
	myActor:GetTransformer():SetPriority("anim_spinr", 1, affectedBones);
	myActor:GetTransformer():SetPriority("anim_spinl", 1, affectedBones);
end

function love.draw()
	myActor:Draw();
end
function love.update(dt)
	if (myActor:GetTransformer():GetPower("anim_curl") > 0) then
		local vars = myActor:GetTransformer():GetVariables();
		vars.anim_curl.time = vars.anim_curl.time + dt;
		if (myActor:GetTransformer():GetPower("anim_spinr") == 1) then
			vars.anim_spinr.time = vars.anim_spinr.time + dt;
		end
		if (myActor:GetTransformer():GetPower("anim_spinl") == 1) then
			vars.anim_spinl.time = vars.anim_spinl.time + dt;
		end
	end
	myActor:Update(dt);
end

-- Tell the animation to start.
function love.keypressed(key, isRepeat)
	if (key == 'space') then
		myActor:GetTransformer():SetPower("anim_curl", 1);
	end
end

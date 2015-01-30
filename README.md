# BÖNER [WIP]

A 2D Skeletal Animation framework for LÖVE.

## Table of Contents

* [Crash Course](#crash-course)
* [Objects](#objects)
  * [Actor](#actor)
  * [Skeleton](#skeleton)
  * [Bone](#bone)
  * [Animation](#animation)
  * [Visual](#visual)
  * [Attachment](#attachment)
  * [EventHandler](#event-handler)
  * [Transformer](#transformer)

## Crash Course

Require the [library](https://github.com/GeekWithALife/boner/tree/master/game/boner):

```lua
local boner = require 'boner'
```

Create a [Skeleton](#skeleton) out of [Bones](#bone):

```lua
-- Create the skeleton.
local mySkeleton = boner.newSkeleton();

-- Add bones to the skeleton
local boneLength = 50;
local boneName = "bone";
for i = 1, 10 do
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
	local bone = boner.newBone(name, parent, i, offset, rotation, translation, scale);
	mySkeleton:AddBone(bone);
end

-- Validate the skeleton!
mySkeleton:Validate();
```

Create an [Animation](#animation).

```lua
-- Create an animation.
local myAnimation = boner.newAnimation("curl", mySkeleton);
for i = 1, 10 do
	local name = boneName .. i;
	myAnimation:AddKeyFrame(name, 2, math.rad(5*i), nil, nil);
	myAnimation:AddKeyFrame(name, 2.5, math.rad(0), nil, nil);
	myAnimation:AddKeyFrame(name, 4.5, -math.rad(5*i), nil, nil);
	myAnimation:AddKeyFrame(name, 5, math.rad(0), nil, nil);
end
```

Create an [Actor](#actor).

```lua
-- Create an actor.
myActor = boner.newActor(mySkeleton);
```

But this actor will be invisible without a skin. Skins are really just a set of attachments.

We must first create a [Visual](#visual).

```lua
-- Create the visual elements for the actor
local boneVisuals = {};
for i = 1, 10 do
	local name = boneName .. i;
	local imageData = love.image.newImageData(boneLength, 20);
	imageData:mapPixel(function(x, y, r, g, b, a) 
		local hasRed = (i % 3) == 0;
		local hasGreen = (i % 3) == 1;
		local hasBlue = (i % 3) == 2;
		if (hasRed) then r = 255; end
		if (hasGreen) then g = 255; end
		if (hasBlue) then b = 255; end
		return r, g, b, 255;
	end);
	boneVisuals[i] = boner.newVisual(imageData);
	local vw, vh = boneVisuals[i]:GetDimensions();
	boneVisuals[i]:SetOrigin(0, vh/2);
end
```

Now we can make the attachments that will form the skin.

```lua
-- Add attachments to the actor using the visual elements.
for i = 1, 10 do
	local name = boneName .. i;
	local myAttachment = boner.newAttachment(boneVisuals[i]);
	myActor:SetAttachment(name, "skin", myAttachment);
end
```

Now we can look at our actor, but we can't look at this animation quite yet. First we need to register it with the actors transformer.

```lua
-- Register the animation as a transformation.
myActor:GetTransformer():Register("anim_curl", myAnimation, mySkeleton:GetBoneTree("bone1"));
```

```lua
function love.draw()
	myActor:Draw();
end
function love.update(dt)
	myActor:Update(dt);
end
function love.keypressed(key, isRepeat)
	if (key == ' ') then
		myActor:Start();
	elseif (key == 'p') then
		local power = myActor:GetTransformer():GetPower("anim_curl");
		if (power == 1) then
			power = 0;
		else 
			power = 1;
		end
		myActor:GetTransformer():SetPower("anim_curl", power);
	end
end
```

And the result:

<p align="center">
  <img src="https://github.com/geekwithalife/boner/blob/master/images/basic.gif?raw=true" alt="button"/>
</p>

## Objects

### Actor

Actors are what ties everything together.  They must hold a reference to a skeleton definition before they can be used.

```lua
local myActor = boner.newActor(skeleton);
...
myActor:SetAnimation(animName);
```

To use them, you must call their update and draw methods.

```lua
function love.update(dt)
	myActor:Update(dt);
end
function love.draw()
	myActor:Draw();
end
```

### Skeleton

Every actor needs a skeleton.  Skeletons never change state.  They are merely a reference for actors so they know what their bone structure looks like and what skins/animations are available to them.

```lua
local skeleton = boner.newSkeleton();
skeleton:AddBone(bone);
...
skeleton:Validate();
```

### Bone

Bones are objects that are used to create skeletons.

```lua
local bone = boner.newBone(name, parent, layer, offset, defaultRotation, defaultTranslation, defaultScale);
```

### Animation

Animations are a convenient way to apply transformations to your actors.

```lua
local animation = boner.newAnimation(animName, skeleton);
animation:AddKeyFrame(boneName, keyTime, rotation, translation, scale);
...
skeleton:AddAnimation(animation);
```

### Visual

Visuals are an abstraction for visible elements. They could be an image, a canvas, a particle emitter, and much more!

```lua
local visual;
visual = boner.newVisual(imagePath | imageData | image | canvas, quad | x, y, w, h)
visual = boner.newVisual(particleEmitter)
visual = boner.newVisual(mesh)

local vw, vh = visual:GetDimensions();
visual:SetOrigin(vw/2, vh/2);
```

### Attachment

Attachments are used to attach a Visual object to a bone on an Actor. Skins are simply attachments without any special transformations applied to them.

```lua
local attachment = boner.newAttachment(visual);
myActor:SetAttachment(boneName, attachName, attachment);
```

### EventHandler

Every actor has an EventHandler automatically created for them. You can use it to register event callbacks.

```lua
myActor:GetEventHandler():Register(animName, eventName, funcCallback);
```

### Transformer

Every actor has a Transformer automatically created for them. You use it to register bone transformations. This includes animations.

```lua
myActor:GetTransformer():Register(transformName, animName | transformTable | transformFunc, boneMask);
myActor:GetTransformer():SetPriotity(transformName, priority);
myActor:GetTransformer():SetPower(transformName, power);
```

The transformer is what represents the bone positions of an individual actor.
# BÖNER [WIP]

A 2D Skeletal Animation framework for LÖVE.

## Table of Contents
* [Introduction](#introduction)
  * [Vocabulary](#vocabulary)
* [Usage](#usage)
  * [Basic](#basic)
  * [Intermediate](#intermediate)
  * [Advanced](#advanced)
* [Objects](#objects)
  * [Actor](#actor)
  * [Skeleton](#skeleton)
  * [Bone](#bone)
  * [Animation](#animation)
  * [Visual](#visual)
  * [Attachment](#attachment)
  * [EventHandler](#eventhandler)
  * [Transformer](#transformer)

## Introduction

BÖNER is loosely modelled after advanced animation frameworks like ASSIMP.  It's designed to accommodate almost any animation scenario at the cost of being complex.

As such, BÖNER is meant to be used as the backbone (hehe) for animations in your game. It takes care of the hard stuff. If you want a skin manager or play/pause/stop methods, you need to add them yourself.

### Vocabulary

Coming soon.

## Usage

### Basic

In this use-case, we will build a skeleton, animation, and skin from scratch.

Require the [library](https://github.com/GeekWithALife/boner/tree/master/game/boner):

```lua
local boner = require("boner");
```

Create a [Skeleton](#skeleton) out of [Bones](#bone):

```lua
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
	local bone = boner.newBone(name, parent, i, offset, rotation, translation, scale);
	mySkeleton:AddBone(bone);
end
```
The skeleton will not be usable until it is validated:

```lua
-- Validate the skeleton!
mySkeleton:Validate();
```

Whenever you modify the bone structure of a skeleton, or bone properties of a bone in a skeleton, you must call `Validate`. This checks the bone hierarchy for inconsistencies (i.e. missing bones) and then builds the render order for the bones based on their layer.

Create an [Animation](#animation):

```lua
-- Create an animation.
local myAnimation = boner.newAnimation("curl", mySkeleton);
for i = 1, NUM_SEGMENTS do
	local name = boneName .. i;
	myAnimation:AddKeyFrame(name, 2, math.rad(5*i), nil, nil);
	myAnimation:AddKeyFrame(name, 2.5, math.rad(0), nil, nil);
	myAnimation:AddKeyFrame(name, 4.5, -math.rad(5*i), nil, nil);
	myAnimation:AddKeyFrame(name, 5, math.rad(0), nil, nil);
end
```

Create an [Actor](#actor):

```lua
-- Create an actor.
myActor = boner.newActor(mySkeleton);
```

Now we have an actor, but it's just a set of bones right now. We need to attach a skin to it.

Before we can create the skin, we must first create a [Visual](#visual) for each possible [Bone](#bone) appearance:

```lua
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
```

Using the visuals we just made, make an [Attachment](#attachment) for each [Bone](#bone):

```lua
-- Add attachments to the actor using the visual elements.
for i = 1, NUM_SEGMENTS do
	local name = boneName .. i;
	local vis = boneVisuals[((i - 1) % 3) + 1];
	local myAttachment = boner.newAttachment(vis);
	myActor:SetAttachment(name, "skin", myAttachment);
end
```

These attachments create the skin for our actor, who is now visible to us. However, we can't look at this animation quite yet. 

First we need to register the animation with the [Transformer](#transformer) of our actor:

```lua
-- Register the animation as a transformation.
myActor:GetTransformer():Register("anim_curl", myAnimation);
```

We're almost done, but before we finish up, we should reposition this actor so it's easier to see the full animation.

To do that, we use `GetRoot`, which returns the base transformation table for the the actor. Unless modified, it will always have a rotation of 0, translation of (0,0), and scale of (1,1).

This transformation table will modify the transformation of the root bone in the skeleton, so modifying the translation will move the actor. Likewise, you can use this to rotate and scale the actor as well.

```lua
-- Move it toward the center and stand it upright.
myActor:GetTransformer():GetRoot().rotation = math.rad(-90);
myActor:GetTransformer():GetRoot().translation = {love.graphics.getWidth() / 2, love.graphics.getHeight() / 1.25};
```

Tell the actor to update:

```lua
function love.update(dt)
	if (myActor:GetTransformer():GetPower("anim_curl") > 0) then
		local vars = myActor:GetTransformer():GetVariables("anim_curl");
		vars.time = vars.time + dt;
	end
	myActor:Update(dt);
end
```

Calling the `Update` method on the actor will not advance time for animations. Multiple animations could be playing at once. Animations could also be playing at different speeds with different start times.

To accommodate this, Animations make use of Transformer variables. Each registered transformation automatically gets its own table to keep track of its state. How that table is utilized is up to the programmer.

Animations automatically come with two state variables.

| Variable | Description |
| :------- | :---------- |
| time | the amount of time that has elapsed in seconds |
| speed | a speed multiplier for the animation (negative values make the animation play backwards) |

Tell the actor to draw:

```lua
function love.draw()
	myActor:Draw();
end

One last step. We need to tell the animation to start.

```lua
-- Tell the animation to start.
function love.keypressed(key, isRepeat)
	if (key == ' ') then
		myActor:GetTransformer():SetPower("anim_curl", 1);
	end
end
```

And the result:

<p align="center">
  <img src="https://github.com/geekwithalife/boner/blob/master/images/basic.gif?raw=true" alt="button"/>
</p>

[Full Code](https://github.com/GeekWithALife/boner/blob/master/game/examples/basic.lua)

### Intermediate

Coming soon.

### Advanced

Coming soon.

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
# BÖNER [WIP]

A 2D Skeletal Animation framework for LÖVE.

Edit main.lua to change which example you want to test.

## Table of Contents
* [Introduction](#introduction)
* [Usage](#usage)
  * [Basic](#basic)
  * [Intermediate](#intermediate)
  * [Advanced](#advanced)
* [Documentation](#documentation)
  * [Actor](#actor)
  * [Skeleton](#skeleton)
  * [Bone](#bone)
  * [Animation](#animation)
  * [Visual](#visual)
  * [Attachment](#attachment)
  * [EventHandler](#eventhandler)
  * [Transformer](#transformer)

## Introduction

BÖNER is loosely modelled after advanced animation frameworks like ASSIMP.  It's designed to accommodate almost any animation scenario, but it can be a little complicated to use.

You could say that BÖNER is meant to be used as the backbone for animations in your game. It takes care of the really hard stuff.

## Usage

### Basic

In this tutorial, we will go over the basics of the BÖNER API.
- Building a skeleton
- Making an animation for the skeleton
- Making an actor that uses the skeleton
- Making a visual appearance for the actor
- Making the actor play the animation

Require the [library](https://github.com/GeekWithALife/boner/tree/master/boner):

```lua
local boner = require("boner");
```

#### Making the skeleton

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
	local bone = boner.newBone(parent, i, offset, rotation, translation, scale);
	mySkeleton:SetBone(name, bone);
end
```

The skeleton will not be usable until it is validated:

```lua
-- Validate the skeleton!
mySkeleton:Validate();
```

Whenever you modify the bone structure of a skeleton, or bone properties of a bone in a skeleton, you must call `Validate`. This checks the bone hierarchy for inconsistencies (i.e. missing bones) and then builds the render order for the bones based on their layer.

#### Making the animation

Create an [Animation](#animation):

```lua
-- Create an animation.
local myAnimation = boner.newAnimation(mySkeleton);
for i = 1, NUM_SEGMENTS do
	local name = boneName .. i;
	myAnimation:AddKeyFrame(name, 2, math.rad(5*i), nil, nil);
	myAnimation:AddKeyFrame(name, 2.5, math.rad(0), nil, nil);
	myAnimation:AddKeyFrame(name, 4.5, -math.rad(5*i), nil, nil);
	myAnimation:AddKeyFrame(name, 5, math.rad(0), nil, nil);
end
```

When we play this animation, everything will be automatically interpolated for us.

#### Making the actor

Create an [Actor](#actor):

```lua
-- Create an actor.
myActor = boner.newActor(mySkeleton);
```

Now we have an actor, but it's just a set of bones right now. We need to attach a skin to it.

Before we can create the skin, we must first create a [Visual](#visual) object for each possible [Bone](#bone) appearance:

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

Attachments follow their assigned bone on an actor. Since bones are invisible, adding an attachment with no modifications to angle, position, or size, will appear wherever the bone is. This is how we make "skins" for our actors.

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

Our actor will be visible to us as soon as we call its `Draw` method. However, we can't look at this animation quite yet. 

#### Adding transformations

First we need to register the animation with the [Transformer](#transformer) of our actor:

```lua
-- Register the animation as a transformation.
myActor:GetTransformer():Register("anim_curl", myAnimation);
```

We're almost done, but before we finish up, we should reposition this actor so it's easier to see the full animation.

To do that, we use `GetRoot`, which returns table with orientation data for the actor.

```lua
-- Move it toward the center and stand it upright.
myActor:GetTransformer():GetRoot().rotation = math.rad(-90);
myActor:GetTransformer():GetRoot().translation = {love.graphics.getWidth() / 2, love.graphics.getHeight() / 1.25};
```

The table returned by `GetRoot` has the following values.

| Variable | Description |
| :------- | :---------- |
| rotation | Angle of the actor in radians. Default = 0 |
| translation | Position vector of the actor in pixels. Default = {0, 0} |
| scale | Scaling vector of the actor. Default = {1, 1} |

Modifying this table will directly affect the actor. The purpose is to provide an easy way to move the actor around. 


#### Playing the animation

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
| time | The amount of time that has elapsed since the start of the animation in seconds. Default = 0 |
| speed | Speed multiplier for the animation. Negative values make the animation play backwards. Default = 1 |

Tell the actor to draw:

```lua
function love.draw()
	myActor:Draw();
end
```

One last step. We need to tell the animation to start.

```lua
-- Tell the animation to start.
function love.keypressed(key, isRepeat)
	if (key == ' ') then
		myActor:GetTransformer():SetPower("anim_curl", 1);
	end
end
```

#### The Result

[Full Code](https://github.com/GeekWithALife/boner/blob/master/examples/basic/)

<p align="center">
  <img src="https://github.com/geekwithalife/boner/blob/master/images/basic.gif?raw=true" alt="button"/>
</p>

### Intermediate

This tutorial will show how to make a simple Actor wrapper for simpler animation playback. Coming soon.

### Advanced

Coming soon.

## Documentation

The object heirarchy is as follows.

<p align="center">
  <img src="https://github.com/geekwithalife/boner/blob/master/images/objects.png?raw=true" alt="button"/>
</p>

### Actor

Actors are what ties everything together.  They must hold a reference to a skeleton definition before they can be used.

```lua
local actor = boner.newActor(skeleton);
```

To use them, you must call their update and draw methods.

```lua
function love.update(dt)
	actor:Update();
end
function love.draw()
	actor:Draw();
end
```

#### Methods

---

**`SetSkeleton(skeleton):`** sets the skeleton reference to use.

**`GetSkeleton():`** returns a reference of the currently used skeleton. See [Skeleton](#skeleton) for more details.

```lua
skeleton = boner.newSkeleton();
...
actor:SetSkeleton(skeleton);
...
skeleton = actor:GetSkeleton();
```

---

**`GetTransformer():`** returns a reference to the actors unique transformer object. See [Transformer](#transformer) for more details.

```lua
transformer = actor:GetTransformer();
```

---

**`GetEventHandler():`** returns a reference to the actors unique event handler object. See [EventHandler](#eventhandler) for more details.

```lua
eventhandler = actor:GetEventHandler();
```

---

**`SetAttachment(boneName, attachName, attachment):`** puts an attachment in the attachName slot of the bone with name boneName. See [Attachment](#attachment) for more details.

**`GetAttachment(boneName, attachName):`** returns the attachment in the attachName slot of the bone with name boneName.

```lua
attachment = boner.newAttachment(boner.newVisual("images/gun.png"));
actor:SetAttachment("hand", "gun", attachment);
...
attachment = actor:GetAttachment("hand", "gun");
```

---

**`SetDebug(boneName|boneList, enabled, settings):`** enables or disables debug rendering for one or more bones. If enabled, debug rendering will use the provided settings.

**`GetDebug(boneName):`** returns the enabled status and the settings table for debug rendering of the named bone.

The `settings` table has the following values. Any nil values default to `{0, 0, 0, 0}`.

| Variable | Description |
| :------- | :---------- |
| boneLineColor | Color of bone lines. |
| boneTextColor | Color of bone name text. |
| attachmentLineColor | Color of attachment outlines. |
| attachmentTextColor | Color of attachment name text. |

In this case, colors are represented as tables with 4 numbers representing the RGBA values for the color.

```lua
settings = {};
settings.boneLineColor = {255, 0, 0, 255};
settings.boneTextColor = {0, 255, 0, 255};
settings.attachmentLineColor = {0, 0, 255, 255};
settings.attachmentTextColor = {255, 0, 255, 255};
actor:SetDebug({"head", "hand"}, true, settings);
...
enabled, settings = actor:GetDebug("head");
```

---

**`Draw():`** draws attachments according to their render order.

```lua
function love.draw()
	actor:Draw();
end
```

---

**`Update():`** updates the transformer for this actor.

```lua
function love.update(dt)
	actor:Update();
end
```

---

### Skeleton

Every actor needs a skeleton.  Skeletons never change state.  They are merely a reference for actors so they know what their bone structure looks like and what skins/animations are available to them.

```lua
local skeleton = boner.newSkeleton();
skeleton:SetBone(boneName, bone);
...
skeleton:Validate();
```

#### Methods

---

**`SetBone(boneName, bone):`** adds `bone` with name `boneName` to the skeleton bone structure. Adding bones to a valid skeleton invalidates the skeleton.

**`GetBone(boneName):`** returns the bone with name `boneName`.

---

**`GetBoneList(boneName):`** returns a list of bone names that are part of the bone hierarchy of `boneName`, including itself. If `boneName` is nil, it returns a list of all bone names.


---

**`BuildRenderOrder():`** rebuilds the render order of the bones for this skeleton based on their currently set layer number.

```lua
bone = skeleton:GetBone("head");
bone:SetLayer(bone:GetLayer() + 1);
skeleton:BuildRenderOrder();
```

---

**`Validate():`** checks the bone hierarchy and marks the skeleton as either valid or invalid.

**`IsValid():`** returns whether the skeleton has been marked as valid or not.

---

### Bone

Bones are objects that are used to create skeletons.

```lua
local bone = boner.newBone(parent, layer, offset, defaultRotation, defaultTranslation, defaultScale);
```

#### Methods

---

**`SetParent(parentName):`** sets the parent bone by bone name.

**`GetParent():`** returns the parent bone name.

---

**`SetLayer(layer):`** sets the layer number for this bone. Determines draw order.

**`GetLayer():`** returns the layer number for this bone.

---

**`SetOffset(x, y):`** sets the bone position relative to its parent.

**`GetOffset():`** returns the bone position relative to its parent.

---

The following are used to set the bind pose for the skeleton. These orientations are used to automatically generate a default keyframe at time 0 when creating new animations.

**`SetDefaultRotation(angle):`** sets the default rotation in radians of the bone relative to its parent.

**`GetDefaultRotation():`** returns the default rotation of the bone relative to its parent.

```lua
bone:SetDefaultRotation(math.rad(15));
...
angle = math.deg(bone:GetDefaultRotation());
```

**`SetDefaultTranslation(x, y):`** sets the default translation of the bone relative to its offset.

**`GetDefaultTranslation():`** returns the default translation of the bone relative to its offset.

```lua
bone:SetDefaultTranslation(10, 10);
...
x, y = bone:GetDefaultTranslation();
```

**`SetDefaultScale(x, y):`** sets the default scale of the bone relative to its parent.

**`GetDefaultScale():`** returns the default scale of the bone relative to its parent.

```lua
bone:SetDefaultScale(0.5, 0.5);
...
sx, sy = bone:GetDefaultScale();
```
---

### Animation

Animations are a convenient way to apply transformations to your actors.

```lua
local animation = boner.newAnimation(skeleton);
animation:AddKeyFrame(boneName, keyTime, rotation, translation, scale);
animation:AddEvent(keyTime, eventName);
```

#### Methods

---

**`AddKeyFrame(boneName, keyTime, rotation, translation, scale):`** adds a keyframe to the animation.

---

**`AddEvent(keyTime, eventName):`** adds an event trigger to the animation. For more information, see [EventHandler](#eventhandler);

---

**`GetDuration():`** returns the animation duration in seconds.

---

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
attachment:SetVisual(visual);
attachment:SetRotation(angle);
attachment:SetTranslation(x, y);
attachment:SetScale(x, y);
attachment:SetColor(r, g, b, a);
attachment:SetLayerOffset(n);
actor:SetAttachment(boneName, attachName, attachment);
```

### EventHandler

Every actor has an EventHandler automatically created for them. You can use it to register animation event callbacks.

```lua
local eventhandler = actor:GetEventHandler();
eventhandler:Register(animName, eventName, funcCallback);
```

### Transformer

Every actor has a Transformer automatically created for them. The transformer is what calculates and represents the bone orientations of an individual actor.

```lua
local transformer = actor:GetTransformer();
transformer:Register(transformName, animation | transformTable | transformFunc, boneMask);
transformer:SetPriotity(transformName, priority);
transformer:SetPower(transformName, power);
```

Three types of transformations are currently supported.

| Transformation | Description |
| :------------- | :---------- |
| Animation | Animation object. |
| Table | Raw transformation table reference to use. |
| Function | Function to call which returns a transformation table. |

Transformation tables have the following attributes:

| Variable | Description |
| :------- | :---------- |
| rotation | The angle to rotate by relative to its parent. |
| translation | The x/y coordinates to move by relative to its parent. |
| scale | The x/y scaling factors to scale by relative to its parent. |

Transformation functions return a transformation table, and take the following arguments:

| Variable | Description |
| :------- | :---------- |
| actor | Reference to the actor. |
| boneName | Name of the bone that's currently being transformed. |
| vars | Reference to the unique variable state table owned by this transformation. |

#### Methods

---

Before a transformation can be used, it must be registered with the transformer.

**`Register(name, transformation, boneMask):`** registers a transformation with an optional bone mask.

**`GetTransform(name):`** returns the transformation registed with `name`.

```lua
transformer = actor:GetTransformer();
transformer:Register("walk", myWalkAnim);
...
myWalkAnim = transformer:GetTransform("walk");
```

The `boneMask` allows you to tell the transformer the specific set of bones that the transformation should affect. If `boneMask` nil, it will default to the set of all bones.

For instance:

```lua
transformer:Register("fistpump", myFistPumpAnim, actor:GetSkeleton():GetBoneList("arm"));
```

This will register the animation `myFistPumpAnim` with a bone mask containing the list of all bones that are part of the arm bone hierarchy. This mean that the transformation will only affect the arm and its children.

---

Transformation power is a number between 0 and 1 that represents how strong of an effect the transformation has on bones, where 0 is not affecting the bone at all, and 1 is completely affecting the bone.

Power defaults to 0 for all transformations.

**`SetPower(name, power):`** sets the desired transformation power. Values given for `power` that are outside the range [0, 1] will be clamped.

**`GetPower(name):`** returns desired transformation power.

---

When multiple transformations affect the same bone, they will each apply their transformations according to their power with no regard for one another. This is not always the desired effect.

Since any number of transformations could be attempting to modify the same set of bones, there needs to be a way of telling the transformer about cases where a certain transformation should be prioritized.

To remedy this, each transformation has a priority level for modifying each bone. By default they all have a priority level of 0 (no priority).

**`SetPriority(name, boneList, priority):`** sets priority level of the named transformation for all bone names in `boneList`.

**`GetPriority(name, boneName):`** returns the priority level of the named transformation for bone with name `boneName`.

Whenever a bone has multiple transformations of varying priority levels acting on it, lower priority levels internally receive a modified transformation power that changes based on the average power of the next priority level up.

For example, if the average power of priority level 0 is 1 and the average power of priority level 1 and 0.7, the powers of priority level 0 will be modified such that their new average power is 0.3.

This means that if the average power of a priority level is 1, all priority levels below it will receive a modified power of 0.

---

**`GetVariables(name):`** returns a reference to the a persistent table owned by the transformation of name `name`. Intended to be used for keeping track of state.

---

**`GetRoot():`** returns a reference to the root transformation table. Modifying this table will apply changes to the root node of the actor.

```lua
rootRef = actor:GetTransformer():GetRoot();
-- Rotate the actor 90 degrees, translate 200 pixels to the right, and scale by 1/2. 
rootRef.rotation = math.rad(90);
rootRef.translation = {200, 0};
rootRef.scale = {0.5, 0.5}
---

The following methods return the absolute (world) orientation of a bone or attachment.  These can be very useful for game logic.

If `boneName` is nil, it will default to the root transformation bone.

If `attachName` is nil, the method will return bone orientation. Otherwise, it will return attachment orientation.

**`GetAngle(boneName, attachName):`** returns the current angle of a bone or attachment.

**`GetPosition(boneName, attachName):`** returns the current position of a bone or attachment.

**`GetScale(boneName, attachName):`** returns the current scale of a bone or attachment.

**`GetForward(boneName, attachName):`** returns the current forward vector of a bone or attachment.

**`GetUp(boneName, attachName):`** returns the current up vector of a bone or attachment.

---

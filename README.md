# BÖNER - WIP

A 2D Skeletal Animation framework for LÖVE.

## Usage

Require the [library](https://github.com/GeekWithALife/boner/tree/master/game/boner):

```lua
local boner = require 'boner'
```

And that's that.

## Table of Contents

* [Introduction](#introduction)
* [Objects](#objects)
  * [Actor](#actor)
  * [Skeleton](#skeleton)
  * [Bone](#bone)
  * [Animation](#animation)
  * [Visual](#visual)
  * [Attachment](#attachment)
  * [EventHandler](#event-handler)
  * [Transformer](#transformer)
## Introduction

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
# TweenService-Plus

**NOTE:** [rek_kie](https://devforum.roblox.com/u/rek_kie) is the original owner of this library!

Introducing **TweenService+**, a module that is focused solely on server and client tween replication! It lets you play tweens on the server, without them actually being on the server. It tells the clients to play that tween, and then sets the properties of the object instantly on the server once the tween time is finished.

## “Can’t I just use TweenService V2? What’s the point of this?”

This module has the same purpose as TweenService V2, but is vastly improved and comes with many more features to fully help you control your tweens on the server.

## Some features include:

- **Cancelled, Completed, Paused,** and **Resume** events
- **Tween ranges** (if a client is within the range, the tween will play.)
- **Client latency compensation** + client latency threshold (deeper explanation later)
- **Specific clients** you can specify to tween for.
- **PlaybackStates** are supported and behave like the regular TweenService.
- **:Pause** and **:Cancel** still behave like the normal TweenService.
- A **debug mode,** so that you fully know what is going on with your tweens. This prints out any critical info about the tween to the output (ex. a PlaybackState being changed, client latency, the distances of players found inside of a tween range, the server assignment of properties on an object)

## Client Latency Compensation and Threshold

**If enabled, this syncs the tween up based on latency.**

For example (without a specified threshold):

If the server told a client to do a 10 second tween and it took .7 seconds to get to the client, then the time for the client’s tween would be 10 - .7 = 9.3 seconds. I’m using @Quenty’s **TimeSyncManager module** to get a global timestamp, so that server and client time are synced. This results in a perfect sync between client and server tween completion. To better see this for yourself, **turn on debug mode** and look at the output to see how the server prints exactly when the client tween ends. (If you are in Studio, Make sure you stay watching only on the client though, because switching to the server view pauses the client’s game session on Play Solo, at least for me.)

Another visual example:
<br>![image|640x478](https://devforum-uploads.s3.dualstack.us-east-2.amazonaws.com/uploads/original/4X/7/1/c/71cfe3a375bef79aea6441a0238f419a0f836e2f.png)

Now, for example, let’s say we set a **threshold** for latency compensation **(defaults to 0)**. What this means is that if the new tween time after calculating latency isn’t greater than the threshold, then the tween won’t play for that client. **If I set a threshold of 2 seconds with latency compensation enabled, let’s think of this:**

The server tells the client to do a 5 second tween. _The client has very high ping_, so it takes a while for the client to receive the server request. The request finally gets to the client, and it took 3.7 seconds. With latency compensation, the client’s new tween time would be 5 - 3.7 = **1.3 seconds.** This is less than the 2 second threshold we set, **so the tween will not play for that client.**

Another visual example:
<br>![image|641x446](https://devforum-uploads.s3.dualstack.us-east-2.amazonaws.com/uploads/original/4X/4/d/7/4d740538e0d539d96e7d202cf6eb55c98a6df541.png)

## Tween Ranges

This concept behind this is a common practice for people that do some sort of optimizations for their games, including me. Dumbed down, the concept can be worded like this:

## If a player is within \_\_ studs of \_\_\_, then \_\_\_\_. Otherwise, don’t do anything.

If you specify a tween range, then it will only tell the clients (which you can specify) within the range of the object to play the tween. For example, if you specified a range of 50 studs to a part, then only players within its range would see the tween.

You can also specify the **rootPart** of the player to calculate the distance from the object from. This defaults to the `HumanoidRootPart.` For example, if you set the **rootPart** to the player’s head, then it would do `(ObjectToTween.Position - PlayerHead.Position).magnitude` to calculate the distance instead of using the player’s HumanoidRootPart.

> You are now able to set the object to calculate distance from by using the new `mainObject` parameter if you are using :Play() with a range. This is useful if you are trying to tween something that isn’t a BasePart, but you still need to calculate distance from something to tween the object.

`mainObject:` The object to calculate distance from if you are using :Play() with a range. Defaults to the original object you’re trying to tween. This is useful if you are trying to tween something that isn’t a BasePart, but you still need to calculate distance from something to tween the object. (Ex. You want to tween a pointlight and use a range of 50 studs, but a pointlight doesn’t have a workspace position. So, you can set the mainObject to a BasePart and then the range would be 50 studs within that part.)

Visual:
<br>![image](https://devforum-uploads.s3.dualstack.us-east-2.amazonaws.com/uploads/original/4X/d/0/d/d0d234399707b6ca35892764689fbbc6ed9c1b88.png)

## How do I use it?

API, instructions, and source code are here (Also inside of the module):

https://github.com/reklet/TweenService-Plus/wiki https://pastebin.com/4H278E17

**Example usage:**

Somewhere on a local script:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.Modules:WaitForChild("TweenServicePlus"))
```

Server script:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TSP = require(ReplicatedStorage.Modules:WaitForChild("TweenServicePlus"))

task.wait(15)

local tween = TSP:Construct(
	workspace.Part,
	TweenInfo.new(10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	{
		Size = workspace.Part.Size * 3,
		Position = workspace.Part.Position + Vector3.new(0, 10, 0)
	},
	.4,
	true)

tween:Play()
task.wait(5)
tween:Pause()
task.wait(5)
tween:Play()
```

## Where do I get it?

You can get this module right here!

https://www.roblox.com/library/5529592020/TweenService

Enjoy! If there are any bugs, please tell me! Have a good day.

Happy tweening!

https://devforum-uploads.s3.dualstack.us-east-2.amazonaws.com/uploads/original/4X/c/e/2/ce29cf2a6367e8d47b84e48f994a4557abb1b7cc.mp4

**Updates:**

<details>
  <summary>Update V1.1</summary>

`:Play()` now has a mainObject parameter

- You are now able to set the object to calculate distance from if you are using :Play() with a range. This is useful if you are trying to tween something that isn’t a BasePart, but you still need to calculate distance from something to tween the object.

`mainObject:` The object to calculate distance from if you are using :Play() with a range. Defaults to the original object you’re trying to tween. This is useful if you are trying to tween something that isn’t a BasePart, but you still need to calculate distance from something to tween the object. (Ex. You want to tween a pointlight and use a range of 50 studs, but a pointlight doesn’t have a workspace position. So, you can set the mainObject to a BasePart and then the range would be 50 studs within that part.)

</details>

<details>
	<summary>Update V1.2</summary>

- Add typing to the module
- Update dependencies
- Switch from [coroutine](https://create.roblox.com/docs/reference/engine/libraries/coroutine) to [task](https://create.roblox.com/docs/reference/engine/libraries/task)
</details>

**Minor Update:** Small bug fix with a conditional involving MainObject. It’s been fixed and updated for a couple of days now, but make sure you have the latest source. Check here:
<br>https://pastebin.com/4H278E17

or get the ROBLOX model again, everything should be updated.

--[[

TweenService+ V1.2
@hayper1919 on 03/18/23

Please read the devforum post here!
https://devforum.roblox.com/t/tweenservice-plus/716025

Update log [V1.1]: 

:Play() now has a mainObject parameter

 -- You are now able to set the object to calculate distance from if you are using :Play() with a range. This is useful if
    you are trying to tween something that isn't a BasePart, but you still need to calculate distance from something to tween 
    the object.

Setup instructions: 

	Put this module into REPLICATEDSTORAGE, nowhere else.
	To set up, all you have to do is require this module somewhere on a local script, and require it on a server script to be 
	ready for use on the server side.


Documentation:

=== FUNCTIONS ===

tweenServicePlus:Construct(instance Object, TweenInfo info, table Properties, number timeThreshold, bool debugMode, bool clientSync)

  Returns: tweenObject
	
- The "equivalent" to TweenService:Create(). The time threshold is the latency threshold if clientSync (latency compensation) 
  is enabled. The object is the object to tween, the TweenInfo is the info to use, the properties and are properties you 
  want to tween to.

 - debugMode defaults to false, and clientSync defaults to true.

tweenObject:Play(array/instance clients, number Range, string rootPart, BasePart mainObject)

- If clients are not specified, then the tween will play for all clients (the default setting). If you want to specify clients, either 
  pass in an ARRAY of clients, or pass in one individual client. These should be PLAYER INSTANCES.

- If a range (a NUMBER) is specified, then the tween will only play for clients (you can specify them as stated above) within the range 
  (in studs) of the object being tweened. EXTREMELY useful for optimization and reducing client load. You wouldn't need to tween 
  something for a client if they're somewhere like 1000 studs away from the object. 

- rootPart: Only works when a range is specified. Defaults to HumanoidRootPart. If you specify this (has to be a string) 
  then the distance calculations will be from the distance from the tweened object to the specified rootPart. This uses a 
  recursive :FindFirstChild(), so make sure that your rootPart has a unique name so it isn't mistaken for something else in the
  player. 

-- mainObject: The object to calculate distance from if you are using :Play() with a range. Defaults to the original object you're trying to tween.
   This is useful if you are trying to tween something that isn't a BasePart, but you still need to calculate distance from something 
   to tween the object. (Ex. You want to tween a pointlight and use a range of 50 studs, but a pointlight doesn't have a workspace 
   position. So, you can set the mainObject to a BasePart and then the range would be 50 studs within that part.)

tweenObject:Cancel(array/instance clients)

- This behaves like the normal TweenService. Documentation is on developer.roblox.com

- Cancels the tween. If clients are specified (either an ARRAY of player instances or one player instance), then the tween will only
  cancel for the specified clients. Otherwise, it cancels for all clients. 

- Always stays in sync with the server. If you cancel a tween and then call :Play() again, it will still have TweenService's normal
  behavior and take the initial tween time to finish.

Tip: Cancelling for specific clients is not reccommended, though. It only has a few use cases and could lead to things getting 
out of sync between your clients and the server.

tweenObject:Pause(array/instance clients)

- This also behaves like the normal TweenService. Documentation is on developer.roblox.com

- Pauses the tween. If clients are specified (either an ARRAY of player instances or one player instance), then the tween will only
  pause for the specified clients. Otherwise, it pauses for all clients. If a tween is paused while it wa

- Also always stays in sync with the server. If you pause a tween and then call :Play() again, it will still have TweenService's normal
  behavior and resumes where the tween had left off when it was paused.

=== EVENTS ===

- tweenObject.Cancelled -- Fires when a tween is cancelled.
- tweenObject.Resumed -- Fires when a tween is played after being paused.
- tweenObject.Paused -- Fires when a tween is paused.
- tweenObject.Completed -- Fires when a tween is completed.

]]
--

local tweenService = {}

local clock = require(script.SyncedTime)

local rs = game:GetService("RunService")
local ts = game:GetService("TweenService")
local http = game:GetService("HttpService")
local plrs = game:GetService("Players")

local tEvent = script:WaitForChild("TweenCommunication")

if rs:IsServer() then
	if not clock:IsSynced() then -- make sure our clock is synced
		repeat
			clock:Sync()
			task.wait(0.5)
		until clock:IsSynced()
	end
end

local function infoToTable(tInfo: TweenInfo): {
	Time: number,
	EasingStyle: Enum.EasingStyle,
	EasingDirection: Enum.EasingDirection,
	RepeatCount: number,
	Reverses: boolean,
	DelayTime: number,
}
	local info = {}
	info["Time"] = tInfo.Time or 1
	info["EasingStyle"] = tInfo.EasingStyle or Enum.EasingStyle.Quad
	info["EasingDirection"] = tInfo.EasingDirection or Enum.EasingDirection.Out
	info["RepeatCount"] = tInfo.RepeatCount or 0
	info["Reverses"] = tInfo.Reverses or false
	info["DelayTime"] = tInfo.DelayTime or 0
	return info
end

local function assign(object: Instance, properties: { [string]: any }, debugMode: boolean?)
	if not object or not properties then
		return
	end

	for property, value in pairs(properties) do
		(object :: any)[property] = value

		if debugMode then
			print(`Set {object.Name}'s {property} to {tostring(value)}.`)
		end
	end
end

function tweenService:Create(
	obj: Instance,
	info: TweenInfo,
	properties: { [string]: any },
	timeThreshold: number?,
	debugMode: boolean?,
	clientSync: boolean?
)
	return tweenService:Construct(obj, info, properties, timeThreshold, debugMode, clientSync)
end

function tweenService:Construct(
	obj: Instance,
	info: TweenInfo,
	properties: { [string]: any },
	timeThreshold: number?,
	debugMode: boolean?,
	clientSync: boolean?
)
	if not obj then
		warn("This object doesn't exist.")
		return
	end
	if not info then
		warn("Please provide some TweenInfo!")
		return
	end
	if not properties then
		warn("Please provide some properties to tween to!")
		return
	end

	if timeThreshold and type(timeThreshold) ~= "number" then
		warn("Latency threshold must be a number!")
		return
	end
	if debugMode and type(debugMode) ~= "boolean" then
		warn("The debugMode parameter must be true or false!")
		return
	end
	if clientSync and type(clientSync) ~= "boolean" then
		warn("The parameter clientSync must be true or false!")
		return
	end

	local startProperties = {}

	if info.Reverses then
		for property, _ in pairs(properties) do
			startProperties[property] = (obj :: any)[property]
		end
	end

	debugMode = debugMode or false
	clientSync = clientSync or true

	local events = {
		["Cancelled"] = true,
		["Completed"] = true,
		["Paused"] = true,
		["Resumed"] = true,
	}

	local tObject = {
		["PlaybackState"] = Enum.PlaybackState.Begin,
		["TweenId"] = http:GenerateGUID(false), -- so that we can identify each tween.
		["IsPaused"] = false,
		["IsCancelled"] = false,
		["LastPlay"] = clock:GetTime(),
		["TimeElapsed"] = 0,
	}

	local function changeState(state: Enum.PlaybackState)
		tObject.PlaybackState = state

		if debugMode then
			print(`Playback state changed. New playback state: {tostring(state)}`)
		end
	end

	for name, _ in pairs(events) do -- Setting up the events to connect to
		events[name] = Instance.new("BindableEvent")
		tObject[name] = events[name].Event
	end

	local tweenWait = function(n: number): boolean
		n = n or 1 / 30
		local now = tick()
		repeat
			rs.Heartbeat:Wait()
			if tObject.IsPaused == true or tObject.IsCancelled == true then
				if debugMode then
					print("Tween cancelled/paused server-side.")
				end
				return true
			end
		until tick() - now >= n
		return false
	end

	local function completionWait(t: number)
		task.spawn(function()
			if tObject.IsPaused then
				t = t - tObject.TimeElapsed

				if debugMode then
					print(`Tween is resuming from a pause. Length: {t}`)
				end

				events.Resumed:Fire()
				tObject.IsPaused = false
			end

			if tObject.IsCancelled then
				tObject.IsCancelled = false
			end

			if info.DelayTime > 0 then
				changeState(Enum.PlaybackState.Delayed)
				task.wait(info.DelayTime)
			end

			tObject.LastPlay = clock:GetTime()

			changeState(Enum.PlaybackState.Playing)
			local cancelled = tweenWait(t)

			if not cancelled then
				assign(obj, properties, debugMode)

				if not info.Reverses then
					changeState(Enum.PlaybackState.Completed)
					events.Completed:Fire()
				elseif info.Reverses then
					task.wait(t)

					if not tObject.IsPaused then
						assign(obj, startProperties, debugMode)
						changeState(Enum.PlaybackState.Completed)
						events.Completed:Fire()
					end
				end
			end
		end)
	end

	function tObject:Play(clients: ({ Player } | Player)?, range: number?, rootPart: string?, mainObject: BasePart?)
		rootPart = rootPart or "HumanoidRootPart"

		if mainObject then
			if not mainObject:IsA("BasePart") or not mainObject:IsDescendantOf(workspace) then
				warn("The mainObject must be a BasePart in the workspace.")
				return
			end
		end

        -- selene: allow(shadowing)
		local mainObject = (mainObject or obj) :: Instance

		if mainObject ~= obj and debugMode then
			print(`Set the main object to {mainObject.Name}`)
		end

		if clients then
			clients = (type(clients) == "table") and clients or { clients } -- If you only provide a single player, it turns it into a table for you

			if range then
				for _, player in ipairs(clients :: { Player }) do
					if player and player:IsA("Player") and player.Character then
						task.spawn(function()
							local root = player.Character:FindFirstChild(rootPart, true)

							if root then
								if debugMode then
									print(`Found root part of {player.Name}: rootPart`)
								end

								local dist = (mainObject.Position - root.Position).magnitude

								if dist <= range then -- Tween it only for clients in the range
									tEvent:FireClient(
										player,
										obj,
										infoToTable(info),
										properties,
										clock:GetTime(),
										tObject.TweenId,
										timeThreshold,
										debugMode,
										nil,
										clientSync
									) -- Tell the client to tween the object and the timestamp of when it was sent

									if debugMode then
										print(`Sent tween data to {player.Name}. Distance from object: {dist}`)
									end
								end
							end
						end)
					end
				end
			else
				for _, player in ipairs(clients :: { Player }) do
					if player and player:IsA("Player") and player.Character then
						task.spawn(function()
							tEvent:FireClient(
								player,
								obj,
								infoToTable(info),
								properties,
								clock:GetTime(),
								tObject.TweenId,
								timeThreshold,
								debugMode,
								nil,
								clientSync
							)
						end)
					end
				end
			end
		else
			if range then
				for _, player in ipairs(plrs:GetPlayers()) do
					if player and player:IsA("Player") and player.Character then
						task.spawn(function()
							local root = player.Character:FindFirstChild(rootPart, true)

							if root then
								if debugMode then
									print(`Found root part of {player.Name}: {rootPart}`)
								end

								local dist = (mainObject.Position - root.Position).magnitude

								if dist <= range then -- Tween it only for clients in the range
									tEvent:FireClient(
										player,
										obj,
										infoToTable(info),
										properties,
										clock:GetTime(),
										tObject.TweenId,
										timeThreshold,
										debugMode,
										nil,
										clientSync
									) -- Tell the client to tween the object and the timestamp of when it was sent

									if debugMode then
										print(`Sent tween data to {player.Name}. Distance from object: {dist}`)
									end
								end
							end
						end)
					end
				end
			else
				tEvent:FireAllClients(
					obj,
					infoToTable(info),
					properties,
					clock:GetTime(),
					tObject.TweenId,
					timeThreshold,
					debugMode,
					nil,
					clientSync
				)
			end
		end

		completionWait(info.Time)
	end

	function tObject:Cancel(clients: { Player } | Player)
		if clients then
			clients = (type(clients) == "table") and clients or { clients }

			for _, client in ipairs(clients :: { Player }) do
				tEvent:FireClient(client, nil, nil, nil, clock:GetTime(), tObject.TweenId, nil, debugMode, "Cancel")
			end
		else
			tEvent:FireAllClients(nil, nil, nil, clock:GetTime(), tObject.TweenId, nil, debugMode, "Cancel")
		end

		events.Cancelled:Fire()
		tObject.IsCancelled = true
		changeState(Enum.PlaybackState.Cancelled)
	end

	function tObject:Pause(clients: { Player } | Player)
		if clients then
			clients = (type(clients) == "table") and clients or { clients }

			for _, client in ipairs(clients :: { Player }) do
				tEvent:FireClient(client, nil, nil, nil, clock:GetTime(), tObject.TweenId, nil, debugMode, "Pause")
			end
		else
			tEvent:FireAllClients(nil, nil, nil, clock:GetTime(), tObject.TweenId, nil, debugMode, "Pause")
		end

		tObject.TimeElapsed = clock:GetTime() - tObject.LastPlay
		tObject.LastPlay = clock:GetTime()

		events.Paused:Fire()
		tObject.IsPaused = true
		changeState(Enum.PlaybackState.Paused)
	end

	return tObject
end

if rs:IsClient() then
	local player = plrs.LocalPlayer

	local tweens = {}

	tEvent.OnClientEvent:Connect(
		function(
			obj: Instance,
			info: TweenInfo,
			properties: { [string]: any },
			timestamp: number,
			tweenID: string,
			threshold: number?,
			debugMode: boolean?,
			modify: string?,
			sync: boolean?
		)
			if modify then
				local tweenToEdit = tweens[tweenID]

				if not tweenToEdit then -- if the tween doesn't exist, just return and give a warning
					warn("The tween you tried to modify does not exist.")
					return
				end

				if modify == "Cancel" then
					tweenToEdit:Cancel()

					if debugMode then
						local latency = clock:GetTime() - timestamp
						print(`Cancelled a tween. Latency: {latency}`)
					end

					return
				elseif modify == "Pause" then
					tweenToEdit:Pause()

					if debugMode then
						local latency = clock:GetTime() - timestamp
						print(`Paused a tween. Latency: {latency}`)
					end

					return
				end
			end

			local latency = clock:GetTime() - timestamp

			local newtime = sync and info.Time - latency or info.Time -- If enabled, this syncs the tween up based on latency.
			-- Ex. If the server told a client to do a 10 second tween and it
			-- took .7 seconds to get to the client, then the time for the
			-- client's tween would be 10 - .7 = 9.3 seconds.
			-- I'm using Quenty's module to get a global timestamp, so
			-- that server and client time are synced. This results in a
			-- perfect sync between client and server tween completion.
			-- To better see this for yourself, turn on debug mode and
			-- look at the output to see how the server prints exactly
			-- when the client tween ends. (If you are in Studio, Make sure you
			-- stay watching only on the client though, because switching to
			-- the server  view pauses the client's game session on Play Solo)

			if debugMode then
				print(`Approximate latency for {player.Name}: {latency} seconds.\nNew tween time: {newtime} seconds`)
			end

			threshold = threshold or 0 -- Defaults to 0. When you set this, this basically means the amount of time
			-- the new tween time (after calculating latency) needs to be greater than
			-- for the tween to play. If the new tween time after calculating latency is less than
			-- or equal to than the threshold, the tween will not play.

			if newtime > threshold and obj and properties and tweenID then -- some checks
				local newInfo = TweenInfo.new(
					newtime,
					info.EasingStyle,
					info.EasingDirection,
					info.RepeatCount,
					info.Reverses,
					info.DelayTime
				)

				task.spawn(function()
					if not tweens[tweenID] then
						tweens[tweenID] = ts:Create(obj, newInfo, properties)
					end

					tweens[tweenID]:Play()
					tweens[tweenID].Completed:Wait()
					tweens[tweenID] = nil
				end)

				if debugMode then
					task.spawn(function()
						print(`Currently tweening properties of {obj.Name}:`)

						for property, value in pairs(properties) do
							print(`{property} to {tostring(value)}`)
						end
					end)
				end
			end
		end
	)
end

return tweenService

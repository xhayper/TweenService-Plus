local RunService = game:GetService("RunService")

local MasterClock = require(script.Parent.MasterClock)
local SlaveClock = require(script.Parent.SlaveClock)

return (function()
	local remoteEvent = script:WaitForChild("TimeSyncEvent")
	local remoteFunction = script:WaitForChild("DelayedRequestEvent")

	if RunService:IsClient() and RunService:IsServer() then -- Solo test mode
		local clock = MasterClock.new(remoteEvent, remoteFunction)
		remoteEvent.OnClientEvent:Connect(function() end)
		return clock
	elseif RunService:IsClient() then
		return SlaveClock.new(remoteEvent, remoteFunction)
	else
		return MasterClock.new(remoteEvent, remoteFunction)
	end
end)()

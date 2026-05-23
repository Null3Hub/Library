--[[
    Apex UI Library - Window method: CreateDashboard
    Creates a "Dashboard" page as the first page in the sidebar with player info,
    server stats, executor status, and Discord link.

    Usage:
        window:CreateDashboard({
            SupportedExecutors = {"Delta", "Synapse Z", "Wave"},
            DiscordInvite = "abc123",  -- just the code, no discord.gg/
            Icon = 1,  -- 1 = home (default), 2 = dashboard
        })
]]

local Players            = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")
local RunService         = game:GetService("RunService")

local Util = require(script.Parent.Parent.Parent.Util)
local SafeCallback = Util.SafeCallback

local Dashboard = {}

function Dashboard:CreateDashboard(config)
	config = type(config) == "table" and config or {}
	local supportedExecutors = config.SupportedExecutors or {}
	local discordInvite = config.DiscordInvite or ""
	local iconChoice = config.Icon or 1

	local LocalPlayer = Players.LocalPlayer
	local pageName = "Dashboard"
	local pageIcon = iconChoice == 2 and "rbxassetid://94586681223401" or "rbxassetid://94586681223401"

	-- Create the page
	local page = self:Page({ Name = pageName, Icone = pageIcon })

	-- ===== Section: Player =====
	local playerSection = page:Section("Player", "Hello, " .. tostring(LocalPlayer.DisplayName))
	playerSection:Label("@" .. tostring(LocalPlayer.Name))

	-- ===== Section: Server =====
	local serverSection = page:Section("Server", "Live server information")
	local playersLabel = serverSection:Label(tostring(#Players:GetPlayers()) .. " / " .. tostring(Players.MaxPlayers) .. " players")
	local pingLabel = serverSection:Label("Ping: calculating...")
	local timeLabel = serverSection:Label("Uptime: 00:00:00")
	local regionLabel = serverSection:Label("Region: ...")

	-- Fetch region once
	task.spawn(function()
		local ok, region = pcall(function()
			return LocalizationService:GetCountryRegionForPlayerAsync(LocalPlayer)
		end)
		if ok and region then
			regionLabel:Set("Region: " .. tostring(region))
		else
			regionLabel:Set("Region: Unknown")
		end
	end)

	-- Live update loop
	local updateConn
	updateConn = RunService.Heartbeat:Connect(function()
		if not self.Window or not self.Window.Parent then
			updateConn:Disconnect()
			return
		end
	end)
	table.insert(self.Connections, updateConn)

	task.spawn(function()
		while self.Window and self.Window.Parent do
			-- Players
			playersLabel:Set(tostring(#Players:GetPlayers()) .. " / " .. tostring(Players.MaxPlayers) .. " players")

			-- Ping
			local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
			pingLabel:Set("Ping: " .. tostring(ping) .. "ms")

			-- Uptime
			local t = math.floor(time())
			local h = math.floor(t / 3600)
			local m = math.floor((t % 3600) / 60)
			local s = t % 60
			timeLabel:Set("Uptime: " .. string.format("%02d:%02d:%02d", h, m, s))

			task.wait(1)
		end
	end)

	-- ===== Section: Client =====
	local clientSection = page:Section("Client", "Executor information")

	local executorName = "Roblox Studio"
	pcall(function()
		if identifyexecutor then
			executorName = identifyexecutor() or "Unknown"
		end
	end)
	clientSection:Label("Executor: " .. executorName)

	-- Check if supported
	local isSupported = false
	for _, name in ipairs(supportedExecutors) do
		if string.lower(name) == string.lower(executorName) then
			isSupported = true
			break
		end
	end

	if #supportedExecutors > 0 then
		if isSupported then
			clientSection:Label("Your executor supports this script.")
		else
			clientSection:Label("Your executor isn't officially supported.")
		end
	end

	-- ===== Section: Links =====
	if discordInvite ~= "" then
		local linksSection = page:Section("Links", "Community")
		linksSection:Button("Copy Discord Invite", function()
			local link = "https://discord.gg/" .. discordInvite
			pcall(function()
				if setclipboard then
					setclipboard(link)
				elseif toclipboard then
					toclipboard(link)
				end
			end)
			-- Try to open Discord via RPC (like Luna does)
			pcall(function()
				local HttpService = game:GetService("HttpService")
				local request = (syn and syn.request) or (http and http.request) or http_request
				if request then
					request({
						Url = "http://127.0.0.1:6463/rpc?v=1",
						Method = "POST",
						Headers = {
							["Content-Type"] = "application/json",
							Origin = "https://discord.com",
						},
						Body = HttpService:JSONEncode({
							cmd = "INVITE_BROWSER",
							nonce = HttpService:GenerateGUID(false),
							args = { code = discordInvite },
						}),
					})
				end
			end)
		end)
	end

	return page
end

return Dashboard

-- flyfromspritiz.lua
-- Made by Spritiz | For Educational Purposes Only
-- Hybrid controls: C toggle, Q up, E down (PC) OR on-screen buttons (Mobile)
-- Place this LocalScript in StarterPlayer -> StarterPlayerScripts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local flying = false
local ascend = false
local descend = false
local flightObjects = nil
local gui = {}

-- Config (tweak for lessons)
local speed = 80
local verticalSpeed = 60
local accel = 3000

-- Helper: get HumanoidRootPart (waits if not present)
local function getHRP()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart")
end

-- Enable flight: create BodyVelocity + BodyGyro on HRP
local function enableFlight(hrp)
    if not hrp then return end
    local bv = Instance.new("BodyVelocity")
    bv.Name = "Flight_BodyVelocity"
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.P = accel
    bv.Velocity = Vector3.new()
    bv.Parent = hrp

    local bg = Instance.new("BodyGyro")
    bg.Name = "Flight_BodyGyro"
    bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bg.P = 3000
    bg.CFrame = hrp.CFrame
    bg.Parent = hrp

    flightObjects = { bv = bv, bg = bg }
end

-- Disable flight: clean up instances
local function disableFlight()
    if not flightObjects then return end
    if flightObjects.bv and flightObjects.bv.Parent then
        flightObjects.bv:Destroy()
    end
    if flightObjects.bg and flightObjects.bg.Parent then
        flightObjects.bg:Destroy()
    end
    flightObjects = nil
end

-- Toggle flight state and update GUI text/colors
local function toggleFlight()
    flying = not flying
    if flying then
        local ok, hrp = pcall(getHRP)
        if ok and hrp then
            enableFlight(hrp)
        else
            flying = false
            return
        end
        if gui.Toggle then gui.Toggle.Text = "Flight: ON" end
        if gui.Label then
            gui.Label.Text = "Flight: ON (C/Q/E or Buttons)\nMade by Spritiz | Educational"
            gui.Label.TextColor3 = Color3.fromRGB(0,170,255)
        end
    else
        disableFlight()
        if gui.Toggle then gui.Toggle.Text = "Flight: OFF" end
        if gui.Label then
            gui.Label.Text = "Flight: OFF (C/Q/E or Buttons)\nMade by Spritiz | Educational"
            gui.Label.TextColor3 = Color3.fromRGB(0,100,200)
        end
    end
end

-- Create the GUI (status label + mobile buttons). Label is draggable for PC.
local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HybridFlyGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    -- Status Label (top-left, draggable)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 380, 0, 60)
    label.Position = UDim2.new(0, 10, 0, 10)
    label.BackgroundTransparency = 0.2
    label.BackgroundColor3 = Color3.fromRGB(0, 50, 120)
    label.TextColor3 = Color3.fromRGB(0, 100, 200)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 18
    label.TextWrapped = true
    label.Text = "Flight: OFF (C/Q/E or Buttons)\nMade by Spritiz | Educational"
    label.Active = true
    label.Draggable = true
    label.Parent = screenGui
    gui.Label = label

    -- Toggle button (mobile-friendly) — bottom-right area
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 150, 0, 50)
    toggleBtn.Position = UDim2.new(1, -160, 1, -160)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 50, 120)
    toggleBtn.TextColor3 = Color3.fromRGB(0, 170, 255)
    toggleBtn.Font = Enum.Font.SourceSansBold
    toggleBtn.TextSize = 18
    toggleBtn.Text = "Flight: OFF"
    toggleBtn.Parent = screenGui
    toggleBtn.MouseButton1Click:Connect(toggleFlight)
    gui.Toggle = toggleBtn

    -- UP button
    local upBtn = Instance.new("TextButton")
    upBtn.Size = UDim2.new(0, 80, 0, 40)
    upBtn.Position = UDim2.new(1, -250, 1, -100)
    upBtn.BackgroundColor3 = Color3.fromRGB(0, 50, 120)
    upBtn.TextColor3 = Color3.fromRGB(0, 170, 255)
    upBtn.Font = Enum.Font.SourceSansBold
    upBtn.TextSize = 18
    upBtn.Text = "UP"
    upBtn.Parent = screenGui
    -- Use MouseButton1Down/Up so holding works on touch too
    upBtn.MouseButton1Down:Connect(function() ascend = true end)
    upBtn.MouseButton1Up:Connect(function() ascend = false end)
    gui.Up = upBtn

    -- DOWN button
    local downBtn = Instance.new("TextButton")
    downBtn.Size = UDim2.new(0, 80, 0, 40)
    downBtn.Position = UDim2.new(1, -160, 1, -100)
    downBtn.BackgroundColor3 = Color3.fromRGB(0, 50, 120)
    downBtn.TextColor3 = Color3.fromRGB(0, 170, 255)
    downBtn.Font = Enum.Font.SourceSansBold
    downBtn.TextSize = 18
    downBtn.Text = "DOWN"
    downBtn.Parent = screenGui
    downBtn.MouseButton1Down:Connect(function() descend = true end)
    downBtn.MouseButton1Up:Connect(function() descend = false end)
    gui.Down = downBtn
end

-- Initialize GUI
createGUI()

-- Keyboard input for PC
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.C then
        toggleFlight()
    elseif input.KeyCode == Enum.KeyCode.Q then
        ascend = true
    elseif input.KeyCode == Enum.KeyCode.E then
        descend = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Q then
        ascend = false
    elseif input.KeyCode == Enum.KeyCode.E then
        descend = false
    end
end)

-- Main update loop: apply velocities when flying
RunService.Heartbeat:Connect(function()
    if not flying or not flightObjects then return end
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not hrp then return end

    local cam = camera.CFrame
    local forward = Vector3.new(cam.LookVector.X, 0, cam.LookVector.Z)
    if forward.Magnitude == 0 then forward = Vector3.new(0,0,-1) end
    forward = forward.Unit
    local right = Vector3.new(cam.RightVector.X, 0, cam.RightVector.Z)
    if right.Magnitude == 0 then right = Vector3.new(1,0,0) end
    right = right.Unit

    local md = humanoid and humanoid.MoveDirection or Vector3.new()
    local horiz = (forward * md.Z + right * md.X) * speed

    local vert = 0
    if ascend then vert = verticalSpeed end
    if descend then vert = -verticalSpeed end

    local targetVel = Vector3.new(horiz.X, vert, horiz.Z)
    if flightObjects and flightObjects.bv then
        flightObjects.bv.Velocity = targetVel
    end

    if flightObjects and flightObjects.bg then
        local faceDir = Vector3.new(cam.LookVector.X, 0, cam.LookVector.Z)
        flightObjects.bg.CFrame = CFrame.new(hrp.Position, hrp.Position + faceDir)
    end
end)

-- Cleanup on respawn
player.CharacterAdded:Connect(function()
    flying = false
    disableFlight()
    if gui.Toggle then gui.Toggle.Text = "Flight: OFF" end
    if gui.Label then
        gui.Label.Text = "Flight: OFF (C/Q/E or Buttons)\nMade by Spritiz | Educational"
        gui.Label.TextColor3 = Color3.fromRGB(0,100,200)
    end
end)

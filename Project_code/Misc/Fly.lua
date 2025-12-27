-- Fly.lua
local Fly = {}
Fly.Enabled = false

local player = game:GetService("Players").LocalPlayer
local mouse = player:GetMouse()

local bodyGyro = Instance.new("BodyGyro")
bodyGyro.P = 500000
bodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
bodyGyro.cframe = CFrame.new()

local bodyVelocity = Instance.new("BodyVelocity")
bodyVelocity.velocity = Vector3.new(0, 0, 0)
bodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)

local moveVector = Vector3.new(0, 0, 0)
local speed = 100
local verticalSpeed = 50

local keys = {
    W = false,
    A = false,
    S = false,
    D = false,
    Space = false,
    LeftControl = false
}

function Fly:Toggle(enable)
    self.Enabled = enable
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character.HumanoidRootPart

    if self.Enabled then
        if humanoid then
            humanoid.PlatformStand = true
        end
        bodyGyro.Parent = rootPart
        bodyVelocity.Parent = rootPart
        bodyGyro.cframe = rootPart.CFrame
    else
        if humanoid then
            humanoid.PlatformStand = false
        end
        bodyGyro.Parent = nil
        bodyVelocity.Parent = nil
        for i,v in pairs(keys) do
            keys[i] = false
        end
    end
end

game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not Fly.Enabled then return end

    if input.KeyCode == Enum.KeyCode.W then keys.W = true
    elseif input.KeyCode == Enum.KeyCode.A then keys.A = true
    elseif input.KeyCode == Enum.KeyCode.S then keys.S = true
    elseif input.KeyCode == Enum.KeyCode.D then keys.D = true
    elseif input.KeyCode == Enum.KeyCode.Space then keys.Space = true
    elseif input.KeyCode == Enum.KeyCode.LeftControl then keys.LeftControl = true
    end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if not Fly.Enabled then return end

    if input.KeyCode == Enum.KeyCode.W then keys.W = false
    elseif input.KeyCode == Enum.KeyCode.A then keys.A = false
    elseif input.KeyCode == Enum.KeyCode.S then keys.S = false
    elseif input.KeyCode == Enum.KeyCode.D then keys.D = false
    elseif input.KeyCode == Enum.KeyCode.Space then keys.Space = false
    elseif input.KeyCode == Enum.KeyCode.LeftControl then keys.LeftControl = false
    end
end)

game:GetService("RunService").RenderStepped:Connect(function()
    if Fly.Enabled then
        local camera = workspace.CurrentCamera
        if not camera then return end

        local horizontalMove = Vector3.new(0, 0, 0)
        local verticalMove = Vector3.new(0, 0, 0)

        if keys.W then
            horizontalMove = horizontalMove + camera.cframe.LookVector
        end
        if keys.S then
            horizontalMove = horizontalMove - camera.cframe.LookVector
        end
        if keys.D then
            horizontalMove = horizontalMove + camera.cframe.RightVector
        end
        if keys.A then
            horizontalMove = horizontalMove - camera.cframe.RightVector
        end
        
        if keys.Space then
            verticalMove = Vector3.new(0, 1, 0)
        end
        if keys.LeftControl then
            verticalMove = Vector3.new(0, -1, 0)
        end

        local finalVelocity = Vector3.new(0, 0, 0)
        if horizontalMove.Magnitude > 0 then
            finalVelocity = finalVelocity + horizontalMove.Unit * speed
        end
        if verticalMove.Magnitude > 0 then
            finalVelocity = finalVelocity + verticalMove * verticalSpeed
        end

        bodyVelocity.Velocity = finalVelocity
        
        bodyGyro.cframe = camera.cframe
    end
end)


return Fly

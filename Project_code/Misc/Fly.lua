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

function Fly:Toggle(enable)
    self.Enabled = enable
    if self.Enabled then
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                bodyGyro.Parent = humanoid.RootPart
                bodyVelocity.Parent = humanoid.RootPart
                humanoid.PlatformStand = true
            end
        end
    else
        bodyGyro.Parent = nil
        bodyVelocity.Parent = nil
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.PlatformStand = false
            end
        end
    end
end

game:GetService("UserInputService").InputBegan:Connect(function(input)
    if not Fly.Enabled then return end
    if input.KeyCode == Enum.KeyCode.W then
        bodyVelocity.velocity = workspace.CurrentCamera.cframe.lookVector * 100
    elseif input.KeyCode == Enum.KeyCode.S then
        bodyVelocity.velocity = -workspace.CurrentCamera.cframe.lookVector * 100
    elseif input.KeyCode == Enum.KeyCode.Space then
        bodyVelocity.velocity = Vector3.new(0, 50, 0)
    end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if not Fly.Enabled then return end
    if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.Space then
        bodyVelocity.velocity = Vector3.new(0, 0, 0)
    end
end)

mouse.Move:Connect(function()
    if Fly.Enabled then
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.RootPart then
                bodyGyro.cframe = workspace.CurrentCamera.cframe
            end
        end
    end
end)

return Fly

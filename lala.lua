-- ZhonyaLib example usage
-- Replace the URL with the raw link to your (mobile-fixed) UI_Lib.lua
local ZhonyaLib = loadstring(game:HttpGet("YOUR_RAW_URL"))()

local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local lp      = Players.LocalPlayer

-- ── Window ────────────────────────────────────────────────────────────────────
local win = ZhonyaLib:CreateWindow({
    Title = "My Hub",
})

-- ── Tab 1: Player ─────────────────────────────────────────────────────────────
local player = win:CreateTab("Player")

player:CreateSection("Info")
player:CreateParagraph({
    Title   = "Welcome",
    Content = "Walk speed, jump power and infinite jump. Drag the title bar to move the window.",
})

player:CreateSection("Movement")

local walkSpeed = 16
player:CreateSlider({
    Name      = "Walk Speed",
    Min       = 16,
    Max       = 200,
    Default   = 16,
    Increment = 1,
    Suffix    = " sp",
    Callback  = function(v)
        walkSpeed = v
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end,
})

player:CreateSlider({
    Name      = "Jump Power",
    Min       = 50,
    Max       = 300,
    Default   = 50,
    Increment = 5,
    Callback  = function(v)
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = v
        end
    end,
})

-- Infinite jump: toggle + connection that is cleaned up when switched off
local jumpConn
player:CreateToggle({
    Name         = "Infinite Jump",
    CurrentValue = false,
    Callback     = function(on)
        if on then
            jumpConn = UIS.JumpRequest:Connect(function()
                local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        elseif jumpConn then
            jumpConn:Disconnect()
            jumpConn = nil
        end
    end,
})

player:CreateDivider()

player:CreateButton({
    Name     = "Reset Character",
    Callback = function()
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
        ZhonyaLib:Notify({ Content = "Character reset", Duration = 2 })
    end,
})

player:CreateButtonSecondary({
    Name     = "Show Walk Speed",
    Callback = function()
        ZhonyaLib:Notify({ Content = "Walk speed target: " .. walkSpeed, Duration = 3 })
    end,
})

-- ── Tab 2: Misc ───────────────────────────────────────────────────────────────
local misc = win:CreateTab("Misc")

misc:CreateSection("Inputs")

misc:CreateInput({
    Name        = "Chat Message",
    Placeholder = "type something...",
    Callback    = function(text)
        print("You typed:", text)
        ZhonyaLib:Notify({ Content = "Got: " .. text, Duration = 3 })
    end,
})

local modeDropdown = misc:CreateDropdown({
    Name          = "Mode",
    Options       = { "Legit", "Normal", "Rage" },
    CurrentOption = "Normal",
    Callback      = function(choice)
        ZhonyaLib:Notify({ Content = "Mode: " .. choice, Duration = 2 })
    end,
})

misc:CreateLabel("Tip: dropdown can also be set from code")
misc:CreateButtonSecondary({
    Name     = "Set Mode to Legit",
    Callback = function() modeDropdown:Set("Legit") end,
})

misc:CreateSection("Menu")

-- NOTE: in this library any keybind you create also becomes the menu hide/show key
-- (the lib stores the last key you pick). Keybinds need a keyboard, so on phones
-- use the round "Z" button instead.
misc:CreateKeybind({
    Name           = "Toggle Menu Key",
    CurrentKeybind = "RightShift",
    Callback       = function(keyName)
        ZhonyaLib:Notify({ Content = "Menu key set to " .. keyName, Duration = 3 })
    end,
})

misc:CreateSection("Warnings")
misc:CreateButton({
    Name     = "Show Warning",
    Callback = function()
        ZhonyaLib:Notify({ Content = "This is a warning!", Warn = true, Duration = 5 })
    end,
})

-- ── Tab 3: Credits ────────────────────────────────────────────────────────────
local credits = win:CreateTab("Credits")
credits:CreateCredit({
    Name = "Your Name",
    Role = "Scripting",
    Id   = "rbxassetid://0", -- put a real image asset id here
})

-- Done loading
ZhonyaLib:Notify({ Content = "Loaded!", Duration = 3 })

-- To remove the whole UI later:
-- ZhonyaLib:Destroy()

--[[
    ZhonyaLib — Standalone UI Library
    Extracted & cleaned from ZhonyaHub source.
    All game-specific logic removed. Pure reusable library.

    ── USAGE ────────────────────────────────────────────────────────────────────

    local ZhonyaLib = loadstring(game:HttpGet("YOUR_RAW_URL"))()

    local win = ZhonyaLib:CreateWindow({
        Title = "My Hub",
    })

    local tab = win:CreateTab("General")

    tab:CreateSection("Info")
    tab:CreateParagraph({ Title = "Hello", Content = "Some description text." })
    tab:CreateLabel("this is a small note")
    tab:CreateDivider()

    tab:CreateSection("Actions")
    tab:CreateButton({ Name = "Click Me", Callback = function() print("clicked") end })
    tab:CreateButtonSecondary({ Name = "Secondary", Callback = function() end })

    local tog = tab:CreateToggle({ Name = "Enable", CurrentValue = false, Callback = function(v) print(v) end })
    tog:Set(true)  -- set from outside

    local sld = tab:CreateSlider({ Name = "Speed", Min = 0, Max = 100, Default = 50, Increment = 1, Suffix = " sp", Callback = function(v) end })
    sld:Set(75)

    local inp = tab:CreateInput({ Name = "Username", Placeholder = "type here...", Callback = function(t) end })

    local dd = tab:CreateDropdown({ Name = "Mode", Options = {"A","B","C"}, CurrentOption = "A", Callback = function(v) end })

    local kb = tab:CreateKeybind({ Name = "Hotkey", CurrentKeybind = "LeftControl", Callback = function(key) end })

    tab:CreateCredit({ Name = "author", Role = "scripting", Id = "rbxassetid://..." })

    ZhonyaLib:Notify({ Content = "Hello World!", Duration = 3 })
    ZhonyaLib:Notify({ Content = "Warning!", Warn = true, Duration = 5 })

    ZhonyaLib:OnUnload(function() end)   -- cleanup hook: runs when the UI gets unloaded
    ZhonyaLib:Destroy()                  -- unload everything (the red button does this after a Yes/No prompt)

    ─────────────────────────────────────────────────────────────────────────────
]]

-- ── Services ──────────────────────────────────────────────────────────────────

local ts  = game:GetService("TweenService")
local uis = game:GetService("UserInputService")
local rs  = game:GetService("RunService")
local plr = game:GetService("Players")
local lp  = plr.LocalPlayer

-- ── Touch helpers ─────────────────────────────────────────────────────────────
-- TOUCH = phone/tablet (touch, no mouse). Used for sizing only; input code below
-- handles mouse AND touch the same way so hybrid devices work too.
-- every connection made on a global service goes through bind() so Destroy() can disconnect it
local conns     = {}
local unloadCbs = {}
local function bind(sig, fn)
    local cn = sig:Connect(fn)
    table.insert(conns, cn)
    return cn
end

local TOUCH    = uis.TouchEnabled and not uis.MouseEnabled
local TS_BOOST = TOUCH and 2 or 0          -- bump every text size a little on phones
local RH       = TOUCH and 38 or 32        -- row height (bigger touch targets)

local function isPointer(i)
    return i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch
end
-- hover events misfire on touch (MouseEnter on tap, MouseLeave never) -> mouse only
local function hoverConn(sig, fn)
    if uis.MouseEnabled then return sig:Connect(fn) end
end

-- ── Fonts ─────────────────────────────────────────────────────────────────────

local fn = {
    bd  = Enum.Font.GothamBold,
    sb  = Enum.Font.GothamSemibold,
    reg = Enum.Font.Gotham,
}

-- ── Colour palette ────────────────────────────────────────────────────────────

local c = {
    win    = Color3.fromRGB(10,  11,  15),
    bar    = Color3.fromRGB(14,  15,  21),
    side   = Color3.fromRGB(12,  13,  18),
    card   = Color3.fromRGB(18,  20,  28),
    cardHv = Color3.fromRGB(24,  26,  36),
    bdr    = Color3.fromRGB(36,  40,  56),
    bdrBt  = Color3.fromRGB(52,  58,  80),
    t0     = Color3.fromRGB(218, 220, 230),
    t1     = Color3.fromRGB(130, 136, 158),
    t2     = Color3.fromRGB(60,  66,  90),
    acc    = Color3.fromRGB(99,  155, 255),
    accDm  = Color3.fromRGB(10,  20,  48),
    accHv  = Color3.fromRGB(140, 185, 255),
    red    = Color3.fromRGB(239, 68,  68),
    redDm  = Color3.fromRGB(40,  10,  10),
    grn    = Color3.fromRGB(52,  211, 153),
    dotR   = Color3.fromRGB(255, 95,  87),
    dotY   = Color3.fromRGB(255, 189, 46),
    dotG   = Color3.fromRGB(40,  200, 64),
    wht    = Color3.fromRGB(255, 255, 255),
    blk    = Color3.fromRGB(0,   0,   0),
    sld    = Color3.fromRGB(30,  34,  50),
}

-- ── Utility helpers ───────────────────────────────────────────────────────────

local function tw(obj, props, t)
    ts:Create(obj, TweenInfo.new(t or 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
end

local function ni(cls, props, par)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do o[k] = v end
    if TS_BOOST ~= 0 and props and props.TextSize
       and (cls == "TextLabel" or cls == "TextButton" or cls == "TextBox") then
        o.TextSize = props.TextSize + TS_BOOST
    end
    if par then o.Parent = par end
    return o
end

local function rnd(r, p)    ni("UICorner",   { CornerRadius = UDim.new(0, r) }, p) end
local function stk(col,t,p) return ni("UIStroke", { Color = col, Thickness = t or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p) end
local function vls(gap, p)  ni("UIListLayout",{ SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, gap or 0) }, p) end

local function pad(t, r, b, l, p)
    ni("UIPadding", {
        PaddingTop    = UDim.new(0, t),
        PaddingRight  = UDim.new(0, r or t),
        PaddingBottom = UDim.new(0, b or t),
        PaddingLeft   = UDim.new(0, l or r or t),
    }, p)
end

local function lbl(props, par)
    local o = ni("TextLabel", {
        BackgroundTransparency = 1,
        Font                   = fn.reg,
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextColor3             = c.t0,
        TextSize               = 13,
        TextWrapped            = false,
    }, par)
    for k, v in pairs(props) do o[k] = v end
    o.BackgroundTransparency = 1
    if TS_BOOST ~= 0 then o.TextSize = (props.TextSize or 13) + TS_BOOST end
    return o
end

-- ── ScreenGui parent ──────────────────────────────────────────────────────────

local gpar
do
    if gethui then
        gpar = gethui()
    else
        local ok, cg = pcall(function() return game:GetService("CoreGui") end)
        if ok then
            if syn and syn.protect_gui then
                gpar = cg
            elseif cg:FindFirstChild("RobloxGui") then
                gpar = cg.RobloxGui
            else
                gpar = cg
            end
        else
            gpar = lp:WaitForChild("PlayerGui")
        end
    end
end

-- ── Library ───────────────────────────────────────────────────────────────────

local ZhonyaLib = {}
ZhonyaLib.__index = ZhonyaLib

-- Destroy any previous instance
do
    local env = (getgenv and getgenv()) or _G
    if env.__ZhonyaLibUnload then pcall(env.__ZhonyaLibUnload) end
end
local prev = gpar:FindFirstChild("ZhonyaLib_GUI")
if prev then prev:Destroy() end

-- Root ScreenGui
local sg = ni("ScreenGui", {
    Name            = "ZhonyaLib_GUI",
    ResetOnSpawn    = false,
    IgnoreGuiInset  = false,
    ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
}, gpar)
if syn and syn.protect_gui then pcall(function() syn.protect_gui(sg) end) end

-- ── Notification holder ───────────────────────────────────────────────────────

local nHolder = ni("Frame", {
    Size             = UDim2.fromOffset(260, 0),
    AnchorPoint      = Vector2.new(1, 1),
    Position         = UDim2.new(1, -16, 1, -16),
    BackgroundTransparency = 1,
    BorderSizePixel  = 0,
    ZIndex           = 99,
    AutomaticSize    = Enum.AutomaticSize.Y,
    ClipsDescendants = false,
}, sg)
ni("UIListLayout", {
    SortOrder          = Enum.SortOrder.LayoutOrder,
    VerticalAlignment  = Enum.VerticalAlignment.Bottom,
    Padding            = UDim.new(0, 6),
}, nHolder)

local nc = 0

-- ── ZhonyaLib:Notify ──────────────────────────────────────────────────────────

function ZhonyaLib:Notify(opts)
    nc = nc + 1
    local msg    = opts.Content or opts.Title or "notification"
    local dur    = opts.Duration or 3
    local isWarn = opts.Warn or false

    local wrap = ni("Frame", {
        Size             = UDim2.fromOffset(260, 34),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        ZIndex           = 99,
        ClipsDescendants = false,
        LayoutOrder      = nc,
    }, nHolder)

    local nf = ni("Frame", {
        Size             = UDim2.fromOffset(260, 34),
        Position         = UDim2.fromOffset(320, 0),
        BackgroundColor3 = isWarn and c.redDm or c.card,
        BorderSizePixel  = 0,
        ZIndex           = 99,
    }, wrap)
    rnd(5, nf)
    stk(isWarn and c.red or c.acc, 1, nf)

    if isWarn then
        local bar = ni("Frame", {
            Size             = UDim2.fromOffset(3, 34),
            BackgroundColor3 = c.red,
            BorderSizePixel  = 0,
            ZIndex           = 100,
        }, nf)
        rnd(3, bar)
    end

    ni("TextLabel", {
        Size               = UDim2.new(1, isWarn and -12 or 0, 1, 0),
        Position           = isWarn and UDim2.fromOffset(10, 0) or UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1,
        Text               = msg,
        TextColor3         = isWarn and c.red or c.t0,
        TextSize           = 11,
        Font               = isWarn and fn.sb or fn.reg,
        TextXAlignment     = Enum.TextXAlignment.Center,
        ZIndex             = 99,
    }, nf)

    tw(nf, { Position = UDim2.fromOffset(0, 0) }, 0.3)
    task.delay(dur, function()
        tw(nf, { Position = UDim2.fromOffset(320, 0) }, 0.3)
        task.delay(0.35, function() wrap:Destroy() end)
    end)
end

-- ── ZhonyaLib:CreateWindow ────────────────────────────────────────────────────

function ZhonyaLib:CreateWindow(opts)
    opts = opts or {}
    local title = opts.Title or "HUB"
    if opts.OnUnload then table.insert(unloadCbs, opts.OnUnload) end

    local activeBk = Enum.KeyCode.LeftControl

    -- ── Dynamic sizing ────────────────────────────────────────────────────────

    local isMobile = TOUCH
    local function getHubSize()
        local ss = sg.AbsoluteSize
        if isMobile then
            local w = math.floor(ss.X * 0.92)
            local h = math.floor(ss.Y * 0.82)
            return w, h
        else
            local w = math.clamp(math.floor(ss.X * 0.60), 460, 620)
            local h = math.clamp(math.floor(ss.Y * 0.65), 360, 480)
            return w, h
        end
    end

    local HUB_W, HUB_H = getHubSize()
    local SB_W = isMobile and math.floor(HUB_W * 0.27) or 152

    -- ── Main hub window ───────────────────────────────────────────────────────

    local hub = ni("Frame", {
        Size             = UDim2.fromOffset(HUB_W, HUB_H),
        AnchorPoint      = Vector2.new(0, 0),
        Position         = UDim2.fromOffset(0, 0),
        BackgroundColor3 = c.win,
        Visible          = false,
        BorderSizePixel  = 0,
        Active           = true,
        ClipsDescendants = true,
    }, sg)
    rnd(7, hub)
    ni("UIStroke", { Color = c.bdr, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, hub)

    -- Top accent bar
    local accentBar = ni("Frame", {
        Size             = UDim2.new(1, 0, 0, 7),
        Position         = UDim2.fromOffset(0, 0),
        BackgroundColor3 = c.acc,
        BorderSizePixel  = 0,
        ZIndex           = 10,
    }, hub)
    rnd(7, accentBar)
    ni("Frame", {
        Size             = UDim2.new(1, 0, 0, 4),
        Position         = UDim2.new(0, 0, 1, -4),
        BackgroundColor3 = c.acc,
        BorderSizePixel  = 0,
        ZIndex           = 10,
    }, accentBar)

    -- ── Smooth drag ───────────────────────────────────────────────────────────

    local drag    = false
    local dragObj = nil
    local dStart  = Vector2.zero   -- pointer position when the drag started
    local dPos0   = Vector2.zero   -- window position when the drag started
    local dTgt    = Vector2.zero
    local hTw     = nil

    -- keep at least part of the window on screen so it can never be lost
    local function clampPos(x, y)
        local ss = sg.AbsoluteSize
        x = math.clamp(x, 60 - hub.AbsoluteSize.X, ss.X - 60)
        y = math.clamp(y, 0, ss.Y - 44)
        return x, y
    end

    bind(uis.InputEnded, function(i)
        if not drag then return end
        if i == dragObj
        or (dragObj.UserInputType == Enum.UserInputType.MouseButton1
            and i.UserInputType == Enum.UserInputType.MouseButton1) then
            drag = false
        end
    end)
    bind(uis.InputChanged, function(i)
        if not drag then return end
        if i == dragObj
        or (dragObj.UserInputType == Enum.UserInputType.MouseButton1
            and i.UserInputType == Enum.UserInputType.MouseMovement) then
            local dx = i.Position.X - dStart.X
            local dy = i.Position.Y - dStart.Y
            dTgt = Vector2.new(clampPos(dPos0.X + dx, dPos0.Y + dy))
        end
    end)
    bind(rs.Heartbeat, function(dt)
        if not drag then return end
        local cx = hub.Position.X.Offset
        local cy = hub.Position.Y.Offset
        local sp = 1 - math.pow(0.01, dt * 7)
        hub.Position = UDim2.fromOffset(cx + (dTgt.X - cx) * sp, cy + (dTgt.Y - cy) * sp)
    end)

    -- ── Titlebar ──────────────────────────────────────────────────────────────

    local tb = ni("Frame", {
        Size             = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = c.bar,
        BorderSizePixel  = 0,
        ZIndex           = 2,
    }, hub)
    rnd(7, tb)
    ni("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = c.bdr,
        BorderSizePixel  = 0,
        ZIndex           = 3,
    }, tb)

    -- Title + game name
    lbl({ Size = UDim2.new(1, -100, 1, 0), Position = UDim2.fromOffset(12, 0), Text = string.upper(title), TextSize = 11, Font = fn.sb, TextColor3 = c.acc, ZIndex = 3 }, tb)

    -- Try to get game name for subtitle
    local gnOk, gn = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end)
    gn = (gnOk and gn) and gn or tostring(game.PlaceId)
    lbl({ Size = UDim2.new(0, 160, 1, 0), Position = UDim2.fromOffset(128, 0), Text = "// " .. gn, Visible = not isMobile, TextSize = 9, Font = fn.reg, TextColor3 = c.t2, ZIndex = 3 }, tb)

    -- Drag zone
    local dz = ni("TextButton", {
        Size             = UDim2.new(1, isMobile and -96 or -88, 1, 0),
        BackgroundTransparency = 1,
        Text             = "",
        AutoButtonColor  = false,
        ZIndex           = 4,
    }, tb)
    dz.InputBegan:Connect(function(i)
        if not isPointer(i) then return end
        if hTw then hTw:Cancel(); hTw = nil end
        drag    = true
        dragObj = i
        dStart  = Vector2.new(i.Position.X, i.Position.Y)
        dPos0   = Vector2.new(hub.Position.X.Offset, hub.Position.Y.Offset)
        dTgt    = dPos0
    end)

    -- macOS-style traffic light dots
    local mini = false
    local function mkDot(col, rx)
        local dot = ni("Frame", {
            Size             = UDim2.fromOffset(10, 10),
            AnchorPoint      = Vector2.new(1, 0.5),
            Position         = UDim2.new(1, -rx, 0.5, 0),
            BackgroundColor3 = col,
            BorderSizePixel  = 0,
            ZIndex           = 5,
        }, tb)
        rnd(99, dot)
        local hit = isMobile and 28 or 10
        local b = ni("TextButton", {
            Size             = UDim2.fromOffset(hit, hit),
            AnchorPoint      = Vector2.new(0.5, 0.5),
            Position         = UDim2.fromScale(0.5, 0.5),
            BackgroundTransparency = 1,
            Text             = "",
            AutoButtonColor  = false,
            ZIndex           = 6,
        }, dot)
        -- (hit area is bigger than the visible dot on phones)
        hoverConn(b.MouseEnter, function() tw(dot, { Size = UDim2.fromOffset(12, 12) }, 0.08) end)
        hoverConn(b.MouseLeave, function() tw(dot, { Size = UDim2.fromOffset(10, 10) }, 0.08) end)
        return b
    end

    local DOT_B, DOT_S = 16, (isMobile and 28 or 15)   -- base offset / spacing
    local bClose = mkDot(c.dotR, DOT_B + DOT_S * 2)
    local bMin   = mkDot(c.dotY, DOT_B + DOT_S)
    local bMax   = mkDot(c.dotG, DOT_B)

    local confirm   -- unload confirmation panel (created below, after the content area)
    bClose.MouseButton1Click:Connect(function()
        if confirm then confirm.Visible = true end
    end)

    -- ── Sidebar ───────────────────────────────────────────────────────────────

    local sb = ni("Frame", {
        Size             = UDim2.new(0, SB_W, 1, -88),
        Position         = UDim2.new(0, 0, 0, 40),
        BackgroundColor3 = c.side,
        BorderSizePixel  = 0,
        ZIndex           = 1,
        ClipsDescendants = true,
    }, hub)
    rnd(7, sb)
    ni("Frame", {
        Size             = UDim2.new(0, 1, 1, 0),
        Position         = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = c.bdr,
        BorderSizePixel  = 0,
        ZIndex           = 2,
    }, sb)

    -- Sidebar icon + greeting
    local h = tonumber(os.date("%H"))
    local gr = h >= 5 and h < 12 and "good morning"
            or h >= 12 and h < 18 and "good afternoon"
            or h >= 18 and h < 22 and "good evening"
            or "good night"

    local sbIco = ni("Frame", {
        Size             = UDim2.fromOffset(26, 26),
        Position         = UDim2.fromOffset(10, 10),
        BackgroundColor3 = c.accDm,
        BorderSizePixel  = 0,
        ZIndex           = 2,
    }, sb)
    rnd(4, sbIco); stk(c.acc, 1, sbIco)
    ni("TextLabel", {
        Size               = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text               = "Z",
        TextColor3         = c.acc,
        TextSize           = 13,
        Font               = fn.bd,
        TextXAlignment     = Enum.TextXAlignment.Center,
        ZIndex             = 3,
    }, sbIco)
    lbl({ Size = UDim2.new(1, -44, 0, 14), Position = UDim2.fromOffset(42, 8),  Text = gr,   TextSize = 10, Font = fn.sb,  TextColor3 = c.acc, ZIndex = 2 }, sb)
    lbl({ Size = UDim2.new(1, -44, 0, 12), Position = UDim2.fromOffset(42, 23), Text = "ZhonyaUI v1.0", TextSize = 8, Font = fn.reg, TextColor3 = c.t2,  ZIndex = 2 }, sb)
    ni("Frame", { Size = UDim2.new(1, -16, 0, 1), Position = UDim2.new(0, 8, 0, 46), BackgroundColor3 = c.bdr, BorderSizePixel = 0, ZIndex = 2 }, sb)

    local tabScroll = ni("ScrollingFrame", {
        Size                 = UDim2.new(1, -1, 1, -48),
        Position             = UDim2.fromOffset(0, 48),
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        Active               = true,
        ScrollingDirection   = Enum.ScrollingDirection.Y,
        ScrollBarThickness   = 0,
        CanvasSize           = UDim2.new(0, 0, 0, 0),
        ZIndex               = 2,
    }, sb)

    -- ── Bottom user chip ──────────────────────────────────────────────────────

    local chipF = ni("Frame", {
        Size             = UDim2.fromOffset(SB_W, 48),
        Position         = UDim2.new(0, 0, 1, -48),
        BackgroundColor3 = c.side,
        BorderSizePixel  = 0,
        ZIndex           = 4,
        ClipsDescendants = true,
    }, hub)
    ni("Frame", { Size = UDim2.new(1, -16, 0, 1), Position = UDim2.fromOffset(8, 0), BackgroundColor3 = c.bdr, BorderSizePixel = 0, ZIndex = 4 }, chipF)
    ni("Frame", { Size = UDim2.new(0, 1, 1, 0),   Position = UDim2.new(1, -1, 0, 0), BackgroundColor3 = c.bdr, BorderSizePixel = 0, ZIndex = 4 }, chipF)

    local avF = ni("Frame", {
        Size             = UDim2.fromOffset(26, 26),
        Position         = UDim2.fromOffset(10, 11),
        BackgroundColor3 = c.accDm,
        BorderSizePixel  = 0,
        ZIndex           = 5,
        ClipsDescendants = true,
    }, chipF)
    rnd(4, avF); stk(c.acc, 1, avF)
    local avLt = ni("TextLabel", {
        Size               = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text               = string.upper(string.sub(lp.Name, 1, 1)),
        TextColor3         = c.acc,
        TextSize           = 12,
        Font               = fn.bd,
        TextXAlignment     = Enum.TextXAlignment.Center,
        ZIndex             = 6,
    }, avF)
    local avIm = ni("ImageLabel", {
        Size              = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Image             = "",
        ScaleType         = Enum.ScaleType.Crop,
        ImageTransparency = 1,
        ZIndex            = 7,
    }, avF)
    rnd(4, avIm)
    task.spawn(function()
        local ok, thumb = pcall(function()
            return plr:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
        end)
        if ok and thumb and #thumb > 0 then
            avIm.Image = thumb
            tw(avIm, { ImageTransparency = 0 }, 0.2)
            tw(avLt, { TextTransparency  = 1 }, 0.2)
        end
    end)
    lbl({ Size = UDim2.new(1, -46, 0, 14), Position = UDim2.fromOffset(42, 8),  Text = lp.Name,                    TextSize = 10, Font = fn.sb,  TextColor3 = c.t0, ZIndex = 5 }, chipF)
    lbl({ Size = UDim2.new(1, -46, 0, 12), Position = UDim2.fromOffset(42, 23), Text = "@" .. string.lower(lp.Name), TextSize = 9,  Font = fn.reg, TextColor3 = c.t2, ZIndex = 5 }, chipF)

    -- ── Content scroll frame ──────────────────────────────────────────────────

    local scr = ni("ScrollingFrame", {
        Size                = UDim2.new(1, -SB_W, 1, -40),
        Position            = UDim2.new(0, SB_W, 0, 40),
        BackgroundTransparency = 1,
        BorderSizePixel     = 0,
        Active              = true,
        ScrollingDirection  = Enum.ScrollingDirection.Y,
        ScrollBarThickness  = TOUCH and 4 or 2,
        ScrollBarImageColor3 = c.bdr,
        CanvasSize          = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex              = 1,
    }, hub)

    -- Yellow = minimize to the bubble, Green = collapse / expand to the title bar
    local function collapse()
        if mini then return end
        mini = true
        chipF.Visible = false; sb.Visible = false; scr.Visible = false
        if hTw then hTw:Cancel() end
        hTw = ts:Create(hub, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(HUB_W, 40) })
        hTw:Play(); hTw.Completed:Connect(function() hTw = nil end)
    end
    local function expand()
        if not mini then return end
        mini = false
        if hTw then hTw:Cancel() end
        hTw = ts:Create(hub, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(HUB_W, HUB_H) })
        hTw:Play(); hTw.Completed:Connect(function()
            hTw = nil
            task.delay(0.01, function() chipF.Visible = true; sb.Visible = true; scr.Visible = true end)
        end)
    end
    bMin.MouseButton1Click:Connect(function() hub.Visible = false end)
    bMax.MouseButton1Click:Connect(function() if mini then expand() else collapse() end end)

    -- ── Bubble (PC + mobile): tap = show/hide the window, drag = move it ──────
    local BUB = 52
    local mbtn = ni("TextButton", {
        Size             = UDim2.fromOffset(BUB, BUB),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.fromOffset(16 + BUB / 2, 200),
        BackgroundColor3 = c.accDm,
        BorderSizePixel  = 0,
        Text             = "",
        AutoButtonColor  = false,
        ZIndex           = 95,
    }, sg)
    rnd(99, mbtn); stk(c.acc, 1.5, mbtn)
    ni("TextLabel", {
        Size               = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text               = string.upper(string.sub(title, 1, 1)),
        TextColor3         = c.acc,
        TextSize           = 22,
        Font               = fn.bd,
        TextXAlignment     = Enum.TextXAlignment.Center,
        ZIndex             = 96,
    }, mbtn)

    local function clampBubble(x, y)
        local ss = sg.AbsoluteSize
        return math.clamp(x, BUB / 2, math.max(BUB / 2, ss.X - BUB / 2)),
               math.clamp(y, BUB / 2, math.max(BUB / 2, ss.Y - BUB / 2))
    end

    local bObj, bMoved = nil, false
    local bStart, bPos0 = Vector2.zero, Vector2.zero

    mbtn.InputBegan:Connect(function(i)
        if bObj or not isPointer(i) then return end
        bObj, bMoved = i, false
        bStart = Vector2.new(i.Position.X, i.Position.Y)
        bPos0  = Vector2.new(mbtn.Position.X.Offset, mbtn.Position.Y.Offset)
        tw(mbtn, { Size = UDim2.fromOffset(BUB - 6, BUB - 6) }, 0.08)
    end)
    bind(uis.InputChanged, function(i)
        if not bObj then return end
        if i == bObj
        or (bObj.UserInputType == Enum.UserInputType.MouseButton1
            and i.UserInputType == Enum.UserInputType.MouseMovement) then
            local d = Vector2.new(i.Position.X, i.Position.Y) - bStart
            if not bMoved and d.Magnitude > 8 then bMoved = true end   -- small wiggle still counts as a tap
            if bMoved then
                mbtn.Position = UDim2.fromOffset(clampBubble(bPos0.X + d.X, bPos0.Y + d.Y))
            end
        end
    end)
    bind(uis.InputEnded, function(i)
        if not bObj then return end
        if i == bObj
        or (bObj.UserInputType == Enum.UserInputType.MouseButton1
            and i.UserInputType == Enum.UserInputType.MouseButton1) then
            local wasTap = not bMoved
            bObj = nil
            tw(mbtn, { Size = UDim2.fromOffset(BUB, BUB) }, 0.12)
            if wasTap then hub.Visible = not hub.Visible end
        end
    end)

    -- start on the left edge, vertically centred; keep on screen when the screen changes
    task.defer(function()
        local ss = sg.AbsoluteSize
        mbtn.Position = UDim2.fromOffset(clampBubble(16 + BUB / 2, ss.Y * 0.5))
    end)
    sg:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        mbtn.Position = UDim2.fromOffset(clampBubble(mbtn.Position.X.Offset, mbtn.Position.Y.Offset))
    end)

    -- ── Unload confirmation (opened by the red button) ────────────────────────
    confirm = ni("Frame", {
        Size                   = UDim2.fromScale(1, 1),
        BackgroundColor3       = c.blk,
        BackgroundTransparency = 0.45,
        BorderSizePixel        = 0,
        Visible                = false,
        Active                 = true,       -- swallow clicks so nothing behind it can be pressed
        ZIndex                 = 150,
    }, sg)

    local cCard = ni("Frame", {
        Size             = UDim2.new(0.9, 0, 0, 176),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.fromScale(0.5, 0.5),
        BackgroundColor3 = c.card,
        BorderSizePixel  = 0,
        ZIndex           = 151,
    }, confirm)
    ni("UISizeConstraint", { MaxSize = Vector2.new(320, 176) }, cCard)
    rnd(8, cCard); stk(c.bdrBt, 1, cCard)

    lbl({
        Size           = UDim2.new(1, -24, 0, 20),
        Position       = UDim2.fromOffset(12, 14),
        Text           = "UNLOAD " .. string.upper(title) .. "?",
        TextSize       = 12,
        Font           = fn.bd,
        TextColor3     = c.red,
        ZIndex         = 152,
    }, cCard)
    lbl({
        Size           = UDim2.new(1, -24, 0, 60),
        Position       = UDim2.fromOffset(12, 40),
        Text           = "This removes the UI and stops everything it started. You will need to execute the script again to use it.",
        TextSize       = 11,
        Font           = fn.reg,
        TextColor3     = c.t1,
        TextWrapped    = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex         = 152,
    }, cCard)

    local btnH = TOUCH and 42 or 36
    local noBtn = ni("TextButton", {
        Size             = UDim2.new(0.5, -18, 0, btnH),
        AnchorPoint      = Vector2.new(0, 1),
        Position         = UDim2.new(0, 12, 1, -12),
        BackgroundColor3 = c.cardHv,
        Text             = "No",
        TextColor3       = c.t0,
        TextSize         = 12,
        Font             = fn.sb,
        AutoButtonColor  = false,
        BorderSizePixel  = 0,
        ZIndex           = 152,
    }, cCard)
    rnd(5, noBtn); stk(c.bdr, 1, noBtn)

    local yesBtn = ni("TextButton", {
        Size             = UDim2.new(0.5, -18, 0, btnH),
        AnchorPoint      = Vector2.new(1, 1),
        Position         = UDim2.new(1, -12, 1, -12),
        BackgroundColor3 = c.red,
        Text             = "Yes, unload",
        TextColor3       = c.wht,
        TextSize         = 12,
        Font             = fn.bd,
        AutoButtonColor  = false,
        BorderSizePixel  = 0,
        ZIndex           = 152,
    }, cCard)
    rnd(5, yesBtn)

    noBtn.MouseButton1Click:Connect(function() confirm.Visible = false end)
    yesBtn.MouseButton1Click:Connect(function() ZhonyaLib:Destroy() end)

    -- ── Open hub ─────────────────────────────────────────────────────────────

    local function openHub()
        local ss = sg.AbsoluteSize
        -- Recalculate in case screen rotated on mobile
        HUB_W, HUB_H = getHubSize()
        hub.Size = UDim2.fromOffset(HUB_W, HUB_H)
        local tx = math.floor(ss.X / 2 - HUB_W / 2)
        local ty = math.floor(ss.Y / 2 - HUB_H / 2)
        hub.Position = UDim2.fromOffset(tx, ss.Y + 20)
        hub.Visible  = true
        hTw = ts:Create(hub, TweenInfo.new(0.36, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(tx, ty) })
        hTw:Play(); hTw.Completed:Connect(function() hTw = nil end)
    end

    task.defer(openHub)

    sg:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if not hub.Visible or mini then return end
        HUB_W, HUB_H = getHubSize()
        SB_W = isMobile and math.floor(HUB_W * 0.27) or 152
        hub.Size    = UDim2.fromOffset(HUB_W, HUB_H)
        sb.Size     = UDim2.new(0, SB_W, 1, -88)
        chipF.Size  = UDim2.fromOffset(SB_W, 48)
        scr.Size    = UDim2.new(1, -SB_W, 1, -40)
        scr.Position = UDim2.new(0, SB_W, 0, 40)
        local ss = sg.AbsoluteSize
        hub.Position = UDim2.fromOffset(math.floor(ss.X / 2 - HUB_W / 2), math.floor(ss.Y / 2 - HUB_H / 2))
    end)

    -- ── Keybind toggle ────────────────────────────────────────────────────────

    bind(uis.InputBegan, function(i, gpe)
        if gpe then return end
        if i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode == activeBk then
            if hub then hub.Visible = not hub.Visible end
        end
    end)

    -- ── Win object (returned to caller) ───────────────────────────────────────

    local Win    = {}
    local tabs   = {}
    local actTab = nil
    local tabIdx = 0

    -- ── Win:CreateTab ─────────────────────────────────────────────────────────

    function Win:CreateTab(name)
        tabIdx = tabIdx + 1
        local idx = tabIdx
        local yp  = 7 + (idx - 1) * 34
        tabScroll.CanvasSize = UDim2.fromOffset(0, yp + 34 + 6)

        -- Sidebar button
        local nb = ni("TextButton", {
            Size             = UDim2.new(1, -10, 0, isMobile and 32 or 28),
            Position         = UDim2.new(0, 5, 0, yp),
            BackgroundColor3 = c.side,
            Text             = "",
            AutoButtonColor  = false,
            BorderSizePixel  = 0,
            ZIndex           = 2,
        }, tabScroll)
        rnd(3, nb)

        -- Left accent bar (shown when active)
        local nbBar = ni("Frame", {
            Size             = UDim2.fromOffset(2, 13),
            AnchorPoint      = Vector2.new(0, 0.5),
            Position         = UDim2.new(0, 0, 0.5, 0),
            BackgroundColor3 = c.acc,
            BackgroundTransparency = 1,
            BorderSizePixel  = 0,
            ZIndex           = 3,
        }, nb)

        local nbLbl = lbl({
            Size       = UDim2.new(1, -14, 1, 0),
            Position   = UDim2.fromOffset(8, 0),
            Text       = name,
            TextSize   = 10,
            Font       = fn.sb,
            TextColor3 = c.t2,
            ZIndex     = 3,
        }, nb)

        -- Content page (inside scroll frame)
        local pg = ni("Frame", {
            Size             = UDim2.new(1, 0, 0, 0),
            AutomaticSize    = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Visible          = false,
            Position         = UDim2.new(0, 0, 0, 10),
        }, scr)
        vls(7, pg); pad(12, 10, 12, 10, pg)

        local function showPg()
            pg.Position = UDim2.new(0, 0, 0, 10)
            pg.Visible  = true
            ts:Create(pg, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.new(0, 0, 0, 0) }):Play()
        end

        local function setAct(on)
            if on then
                tw(nb,    { BackgroundColor3 = c.card }, 0.15)
                tw(nbLbl, { TextColor3 = c.acc },        0.15)
                tw(nbBar, { BackgroundTransparency = 0 }, 0.15)
            else
                tw(nb,    { BackgroundColor3 = c.side }, 0.15)
                tw(nbLbl, { TextColor3 = c.t2 },         0.15)
                tw(nbBar, { BackgroundTransparency = 1 }, 0.15)
            end
        end

        hoverConn(nb.MouseEnter, function()    if actTab ~= name then tw(nb, { BackgroundColor3 = c.card }, 0.1) end end)
        hoverConn(nb.MouseLeave, function()    if actTab ~= name then tw(nb, { BackgroundColor3 = c.side }, 0.1) end end)
        nb.MouseButton1Click:Connect(function()
            if actTab == name then return end
            if tabs[actTab] then tabs[actTab].sa(false); tabs[actTab].pg.Visible = false end
            actTab = name; setAct(true); showPg()
        end)

        tabs[name] = { sa = setAct, pg = pg }
        if idx == 1 then actTab = name; setAct(true); showPg() end

        -- ── Tab component API ─────────────────────────────────────────────────

        local lo = 0
        local function nlo() lo = lo + 1; return lo end

        local Tab = {}

        function Tab:CreateSection(txt)
            lbl({
                Size       = UDim2.new(1, 0, 0, 16),
                Text       = string.upper(txt),
                TextSize   = 9,
                Font       = fn.sb,
                TextColor3 = c.acc,
                LayoutOrder = nlo(),
            }, pg)
            ni("Frame", {
                Size             = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = c.bdr,
                BorderSizePixel  = 0,
                LayoutOrder      = nlo(),
            }, pg)
        end

        function Tab:CreateLabel(txt)
            lbl({
                Size        = UDim2.new(1, 0, 0, 14),
                Text        = txt,
                TextSize    = 11,
                Font        = fn.reg,
                TextColor3  = c.t1,
                LayoutOrder = nlo(),
                TextWrapped = true,
            }, pg)
        end

        function Tab:CreateDivider()
            ni("Frame", {
                Size             = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = c.bdr,
                BorderSizePixel  = 0,
                LayoutOrder      = nlo(),
            }, pg)
        end

        function Tab:CreateButton(s)
            local btn = ni("TextButton", {
                Size             = UDim2.new(1, 0, 0, RH),
                BackgroundColor3 = c.acc,
                Text             = s.Name or "Button",
                TextColor3       = c.blk,
                TextSize         = 11,
                Font             = fn.sb,
                AutoButtonColor  = false,
                BorderSizePixel  = 0,
                LayoutOrder      = nlo(),
            }, pg)
            rnd(4, btn)
            hoverConn(btn.MouseEnter, function()   tw(btn, { BackgroundColor3 = c.accHv }, 0.12) end)
            hoverConn(btn.MouseLeave, function()   tw(btn, { BackgroundColor3 = c.acc   }, 0.12) end)
            btn.MouseButton1Click:Connect(function()
                if s.Callback then task.spawn(s.Callback) end
            end)
            local o = {}
            function o:Set(v) btn.Text = v end
            return o
        end

        function Tab:CreateButtonSecondary(s)
            local btn = ni("TextButton", {
                Size             = UDim2.new(1, 0, 0, RH),
                BackgroundColor3 = c.card,
                Text             = s.Name or "Button",
                TextColor3       = c.t1,
                TextSize         = 11,
                Font             = fn.reg,
                AutoButtonColor  = false,
                BorderSizePixel  = 0,
                LayoutOrder      = nlo(),
            }, pg)
            rnd(4, btn); stk(c.bdr, 1, btn)
            hoverConn(btn.MouseEnter, function() tw(btn, { BackgroundColor3 = c.cardHv, TextColor3 = c.t0 }, 0.12) end)
            hoverConn(btn.MouseLeave, function() tw(btn, { BackgroundColor3 = c.card,   TextColor3 = c.t1 }, 0.12) end)
            btn.MouseButton1Click:Connect(function()
                if s.Callback then task.spawn(s.Callback) end
            end)
            return btn
        end

        function Tab:CreateToggle(s)
            local st = s.CurrentValue == true

            local row = ni("Frame", {
                Size             = UDim2.new(1, 0, 0, RH),
                BackgroundColor3 = c.card,
                BorderSizePixel  = 0,
                LayoutOrder      = nlo(),
            }, pg)
            rnd(4, row); stk(c.bdr, 1, row)

            lbl({
                Size       = UDim2.new(1, -52, 1, 0),
                Position   = UDim2.fromOffset(10, 0),
                Text       = s.Name or "Toggle",
                TextSize   = 11,
                Font       = fn.reg,
                TextColor3 = c.t1,
            }, row)

            local trk = ni("Frame", {
                Size             = UDim2.fromOffset(30, 15),
                AnchorPoint      = Vector2.new(1, 0.5),
                Position         = UDim2.new(1, -10, 0.5, 0),
                BackgroundColor3 = st and c.acc or c.bdr,
                BorderSizePixel  = 0,
            }, row)
            rnd(99, trk)

            local knb = ni("Frame", {
                Size             = UDim2.fromOffset(11, 11),
                AnchorPoint      = Vector2.new(0, 0.5),
                Position         = UDim2.new(0, st and 17 or 2, 0.5, 0),
                BackgroundColor3 = c.wht,
                BorderSizePixel  = 0,
            }, trk)
            rnd(99, knb)

            local z = ni("TextButton", {
                Size             = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text             = "",
                AutoButtonColor  = false,
                ZIndex           = 2,
            }, row)

            z.MouseButton1Click:Connect(function()
                st = not st
                tw(trk, { BackgroundColor3 = st and c.acc or c.bdr }, 0.15)
                tw(knb, { Position = UDim2.new(0, st and 17 or 2, 0.5, 0) }, 0.15)
                if s.Callback then task.spawn(function() s.Callback(st) end) end
            end)

            local o = {}
            function o:Set(v)
                st = v
                tw(trk, { BackgroundColor3 = st and c.acc or c.bdr }, 0.15)
                tw(knb, { Position = UDim2.new(0, st and 17 or 2, 0.5, 0) }, 0.15)
            end
            function o:Get() return st end
            return o
        end

        function Tab:CreateSlider(s)
            local mn  = s.Min or 0
            local mx  = s.Max or 100
            local inc = s.Increment or 1
            local cur = math.clamp(s.Default or mn, mn, mx)
            local suf = s.Suffix or ""

            local wrap = ni("Frame", {
                Size             = UDim2.new(1, 0, 0, 54),
                BackgroundColor3 = c.card,
                BorderSizePixel  = 0,
                LayoutOrder      = nlo(),
            }, pg)
            rnd(4, wrap); stk(c.bdr, 1, wrap)

            lbl({
                Size       = UDim2.new(1, -60, 0, 16),
                Position   = UDim2.fromOffset(10, 6),
                Text       = s.Name or "Slider",
                TextSize   = 11,
                Font       = fn.reg,
                TextColor3 = c.t1,
            }, wrap)

            local vLbl = ni("TextLabel", {
                Size               = UDim2.new(0, 50, 0, 16),
                AnchorPoint        = Vector2.new(1, 0),
                Position           = UDim2.new(1, -8, 0, 6),
                BackgroundTransparency = 1,
                Text               = tostring(cur) .. suf,
                TextColor3         = c.acc,
                TextSize           = 10,
                Font               = fn.sb,
                TextXAlignment     = Enum.TextXAlignment.Right,
            }, wrap)

            local trk = ni("Frame", {
                Size             = UDim2.new(1, -24, 0, 4),
                AnchorPoint      = Vector2.new(0.5, 0),
                Position         = UDim2.new(0.5, 0, 0, 34),
                BackgroundColor3 = c.sld,
                BorderSizePixel  = 0,
            }, wrap)
            rnd(99, trk)

            local fl = ni("Frame", {
                Size             = UDim2.new((cur - mn) / (mx - mn), 0, 1, 0),
                BackgroundColor3 = c.acc,
                BorderSizePixel  = 0,
            }, trk)
            rnd(99, fl)

            local thumb = ni("Frame", {
                Size             = UDim2.fromOffset(16, 16),
                AnchorPoint      = Vector2.new(0.5, 0.5),
                Position         = UDim2.new((cur - mn) / (mx - mn), 0, 0.5, 0),
                BackgroundColor3 = c.wht,
                BorderSizePixel  = 0,
                ZIndex           = 3,
            }, trk)
            rnd(99, thumb); stk(c.acc, 1.5, thumb)

            -- Full-width invisible hit zone
            local iz = ni("TextButton", {
                Size             = UDim2.new(1, 0, 0, 40),
                Position         = UDim2.new(0, 0, 0, -20),
                BackgroundTransparency = 1,
                Text             = "",
                AutoButtonColor  = false,
                ZIndex           = 4,
            }, trk)

            local ds  = false
            local dsObj = nil
            local lastVal = cur

            local function applyPos(screenX)
                local ax  = trk.AbsolutePosition.X
                local aw  = trk.AbsoluteSize.X
                if aw <= 0 then return end
                local rel = math.clamp((screenX - ax) / aw, 0, 1)
                local snp = math.clamp(math.floor((mn + rel * (mx - mn)) / inc + 0.5) * inc, mn, mx)
                snp = math.floor(snp * 1000 + 0.5) / 1000
                cur = snp
                fl.Size        = UDim2.new(rel, 0, 1, 0)
                thumb.Position = UDim2.new(rel, 0, 0.5, 0)
                vLbl.Text      = tostring(snp) .. suf
                if snp ~= lastVal then
                    lastVal = snp
                    if s.Callback then task.spawn(function() s.Callback(snp) end) end
                end
            end

            local function releaseSlider()
                if not ds then return end
                ds, dsObj = false, nil
                scr.ScrollingEnabled = true
                tw(thumb, { Size = UDim2.fromOffset(16, 16) }, 0.1)
            end

            iz.InputBegan:Connect(function(i)
                if ds or not isPointer(i) then return end
                ds, dsObj = true, i
                scr.ScrollingEnabled = false       -- don't scroll the page while sliding
                tw(thumb, { Size = UDim2.fromOffset(18, 18) }, 0.1)
                applyPos(i.Position.X)
                i.Changed:Connect(function()
                    if i.UserInputState == Enum.UserInputState.End then releaseSlider() end
                end)
            end)

            bind(uis.InputChanged, function(i)
                if not ds then return end
                if i == dsObj
                or (dsObj.UserInputType == Enum.UserInputType.MouseButton1
                    and i.UserInputType == Enum.UserInputType.MouseMovement) then
                    applyPos(i.Position.X)
                end
            end)

            local o = {}
            function o:Set(v)
                cur = math.clamp(v, mn, mx)
                local rel = (cur - mn) / (mx - mn)
                fl.Size        = UDim2.new(rel, 0, 1, 0)
                thumb.Position = UDim2.new(rel, 0, 0.5, 0)
                vLbl.Text      = tostring(cur) .. suf
            end
            function o:Get() return cur end
            return o
        end

        function Tab:CreateInput(s)
            local wrap = ni("Frame", {
                Size             = UDim2.new(1, 0, 0, RH),
                BackgroundColor3 = c.blk,
                BorderSizePixel  = 0,
                LayoutOrder      = nlo(),
            }, pg)
            rnd(4, wrap)
            local wStk = stk(c.bdr, 1, wrap)

            lbl({
                Size           = UDim2.fromOffset(14, 1),
                Position       = UDim2.fromOffset(7, 0),
                Text           = "_",
                TextSize       = 11,
                Font           = fn.sb,
                TextColor3     = c.acc,
                TextXAlignment = Enum.TextXAlignment.Center,
            }, wrap)

            local box = ni("TextBox", {
                Size             = UDim2.new(1, -28, 1, 0),
                Position         = UDim2.fromOffset(22, 0),
                BackgroundTransparency = 1,
                PlaceholderText  = s.Placeholder or s.Name or "type here...",
                PlaceholderColor3 = c.t2,
                Text             = s.CurrentValue or "",
                TextColor3       = c.t0,
                TextSize         = 11,
                Font             = fn.reg,
                ClearTextOnFocus = false,
                TextXAlignment   = Enum.TextXAlignment.Left,
            }, wrap)

            box.Focused:Connect(function()   tw(wStk, { Color = c.acc, Thickness = 1.5 }, 0.15) end)
            box.FocusLost:Connect(function(enter)
                tw(wStk, { Color = c.bdr, Thickness = 1 }, 0.15)
                if (enter or not s.RemoveTextAfterFocusLost) and s.Callback and #box.Text > 0 then
                    task.spawn(function() s.Callback(box.Text) end)
                end
                if s.RemoveTextAfterFocusLost then box.Text = "" end
            end)

            local o = {}
            function o:Set(v) box.Text = v end
            function o:Get() return box.Text end
            return o
        end

        function Tab:CreateDropdown(s)
            local opts  = s.Options or {}
            local cur   = s.CurrentOption or opts[1] or "None"
            local isOp  = false

            local wrap = ni("Frame", {
                Size             = UDim2.new(1, 0, 0, 32),
                BackgroundColor3 = c.card,
                BorderSizePixel  = 0,
                LayoutOrder      = nlo(),
                ClipsDescendants = true,
            }, pg)
            rnd(4, wrap); stk(c.bdr, 1, wrap)

            lbl({
                Size       = UDim2.new(0.55, 0, 0, 16),
                Position   = UDim2.fromOffset(10, 8),
                Text       = s.Name or "Dropdown",
                TextSize   = 11,
                Font       = fn.reg,
                TextColor3 = c.t1,
            }, wrap)

            local sLbl = ni("TextLabel", {
                Size               = UDim2.new(0.4, 0, 0, 16),
                AnchorPoint        = Vector2.new(1, 0),
                Position           = UDim2.new(1, -10, 0, 8),
                BackgroundTransparency = 1,
                Text               = tostring(cur),
                TextColor3         = c.acc,
                TextSize           = 10,
                Font               = fn.sb,
                TextXAlignment     = Enum.TextXAlignment.Right,
            }, wrap)

            local arr = lbl({
                Size           = UDim2.fromOffset(14, 14),
                AnchorPoint    = Vector2.new(1, 0.5),
                Position       = UDim2.new(1, -8, 0, 22),
                Text           = "▾",
                TextSize       = 10,
                Font           = fn.bd,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextColor3     = c.t2,
            }, wrap)

            local lstF = ni("Frame", {
                Size             = UDim2.new(1, 0, 0, 0),
                Position         = UDim2.new(0, 0, 0, 32),
                BackgroundTransparency = 1,
                BorderSizePixel  = 0,
                ZIndex           = 2,
            }, wrap)
            vls(1, lstF)

            for _, opt in ipairs(opts) do
                local ob = ni("TextButton", {
                    Size             = UDim2.new(1, 0, 0, 26),
                    BackgroundColor3 = c.cardHv,
                    Text             = opt,
                    TextColor3       = c.t1,
                    TextSize         = 10,
                    Font             = fn.reg,
                    AutoButtonColor  = false,
                    BorderSizePixel  = 0,
                    ZIndex           = 3,
                }, lstF)
                hoverConn(ob.MouseEnter, function()  tw(ob, { TextColor3 = c.t0 }, 0.1) end)
                hoverConn(ob.MouseLeave, function()  tw(ob, { TextColor3 = c.t1 }, 0.1) end)
                ob.MouseButton1Click:Connect(function()
                    cur = opt; sLbl.Text = opt; isOp = false
                    tw(wrap, { Size = UDim2.new(1, 0, 0, 32) }, 0.18)
                    tw(arr,  { Rotation = 0 }, 0.15)
                    if s.Callback then task.spawn(function() s.Callback(opt) end) end
                end)
            end

            local iz = ni("TextButton", {
                Size             = UDim2.new(1, 0, 0, 32),
                BackgroundTransparency = 1,
                Text             = "",
                AutoButtonColor  = false,
                ZIndex           = 4,
            }, wrap)
            iz.MouseButton1Click:Connect(function()
                isOp = not isOp
                tw(wrap, { Size = UDim2.new(1, 0, 0, isOp and 32 + #opts * 27 or 32) }, 0.2)
                tw(arr,  { Rotation = isOp and 180 or 0 }, 0.15)
            end)

            local o = {}
            function o:Set(v) cur = v; sLbl.Text = v end
            function o:Get() return cur end
            return o
        end

        function Tab:CreateKeybind(s)
            local cur  = s.CurrentKeybind or "None"
            local lstn = false

            local row = ni("Frame", {
                Size             = UDim2.new(1, 0, 0, RH),
                BackgroundColor3 = c.card,
                BorderSizePixel  = 0,
                LayoutOrder      = nlo(),
            }, pg)
            rnd(4, row); stk(c.bdr, 1, row)

            lbl({
                Size       = UDim2.new(1, -104, 1, 0),
                Position   = UDim2.fromOffset(10, 0),
                Text       = s.Name or "Keybind",
                TextSize   = 11,
                Font       = fn.reg,
                TextColor3 = c.t1,
            }, row)

            local bdg = ni("Frame", {
                Size             = UDim2.fromOffset(88, 20),
                AnchorPoint      = Vector2.new(1, 0.5),
                Position         = UDim2.new(1, -8, 0.5, 0),
                BackgroundColor3 = c.blk,
                BorderSizePixel  = 0,
            }, row)
            rnd(3, bdg); stk(c.bdrBt, 1, bdg)

            local bLbl = ni("TextLabel", {
                Size               = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text               = cur,
                TextColor3         = c.acc,
                TextSize           = 9,
                Font               = fn.sb,
                TextXAlignment     = Enum.TextXAlignment.Center,
            }, bdg)

            local z = ni("TextButton", {
                Size             = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text             = "",
                AutoButtonColor  = false,
                ZIndex           = 2,
            }, bdg)

            z.MouseButton1Click:Connect(function()
                lstn = true
                bLbl.Text = "..."
                tw(bdg, { BackgroundColor3 = c.accDm }, 0.1)
            end)

            bind(uis.InputBegan, function(inp, gp2)
                if not lstn then return end
                if gp2 then return end
                if inp.KeyCode ~= Enum.KeyCode.Unknown then
                    lstn = false
                    cur  = inp.KeyCode.Name
                    bLbl.Text = cur
                    tw(bdg, { BackgroundColor3 = c.blk }, 0.1)

                    -- Also update the window hide keybind if this is the settings keybind
                    local ok, kc = pcall(function() return Enum.KeyCode[cur] end)
                    if ok and kc then activeBk = kc end

                    if s.Callback then task.spawn(function() s.Callback(cur) end) end
                end
            end)

            local o = {}
            function o:Set(v) cur = v; bLbl.Text = v end
            function o:Get() return cur end
            return o
        end

        function Tab:CreateParagraph(s)
            local card = ni("Frame", {
                Size             = UDim2.new(1, 0, 0, 0),
                AutomaticSize    = Enum.AutomaticSize.Y,
                BackgroundColor3 = c.card,
                BorderSizePixel  = 0,
                LayoutOrder      = nlo(),
            }, pg)
            rnd(4, card); stk(c.bdr, 1, card); pad(8, 10, 8, 10, card); vls(4, card)

            ni("TextLabel", {
                Size               = UDim2.new(1, 0, 0, 0),
                AutomaticSize      = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Text               = s.Title or "",
                TextColor3         = c.t0,
                TextSize           = 12,
                Font               = fn.sb,
                TextXAlignment     = Enum.TextXAlignment.Left,
                TextWrapped        = true,
                LayoutOrder        = 1,
            }, card)

            ni("TextLabel", {
                Size               = UDim2.new(1, 0, 0, 0),
                AutomaticSize      = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Text               = s.Content or "",
                TextColor3         = c.t1,
                TextSize           = 11,
                Font               = fn.reg,
                TextXAlignment     = Enum.TextXAlignment.Left,
                TextWrapped        = true,
                LayoutOrder        = 2,
            }, card)

            local o = {}
            function o:Set(ns)
                card:FindFirstChild("TextLabel").Text = ns.Title or ""
                -- find second TextLabel
                local found = 0
                for _, ch in ipairs(card:GetChildren()) do
                    if ch:IsA("TextLabel") then
                        found = found + 1
                        if found == 2 then ch.Text = ns.Content or "" break end
                    end
                end
            end
            return o
        end

        function Tab:CreateCredit(s)
            local card = ni("Frame", {
                Size             = UDim2.new(1, 0, 0, 46),
                BackgroundColor3 = c.card,
                BorderSizePixel  = 0,
                LayoutOrder      = nlo(),
            }, pg)
            rnd(4, card); stk(c.bdr, 1, card)

            local row2 = ni("Frame", {
                Size             = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
            }, card)
            ni("UIListLayout", {
                FillDirection       = Enum.FillDirection.Horizontal,
                VerticalAlignment   = Enum.VerticalAlignment.Center,
                Padding             = UDim.new(0, 10),
            }, row2)
            ni("UIPadding", { PaddingLeft = UDim.new(0, 10) }, row2)

            local avF2 = ni("Frame", {
                Size             = UDim2.fromOffset(30, 30),
                BackgroundColor3 = c.accDm,
                BorderSizePixel  = 0,
            }, row2)
            rnd(4, avF2); stk(c.acc, 1, avF2)
            local img = ni("ImageLabel", {
                Size             = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Image            = s.Id or "",
                ScaleType        = Enum.ScaleType.Crop,
            }, avF2)
            rnd(4, img)

            local info = ni("Frame", {
                Size             = UDim2.new(1, -50, 1, 0),
                BackgroundTransparency = 1,
            }, row2)
            ni("TextLabel", {
                Size               = UDim2.new(1, 0, 0, 14),
                Position           = UDim2.fromOffset(0, 6),
                BackgroundTransparency = 1,
                Text               = s.Name or "",
                TextColor3         = c.t0,
                TextSize           = 11,
                Font               = fn.sb,
                TextXAlignment     = Enum.TextXAlignment.Left,
            }, info)
            ni("TextLabel", {
                Size               = UDim2.new(1, 0, 0, 12),
                Position           = UDim2.fromOffset(0, 22),
                BackgroundTransparency = 1,
                Text               = s.Role or "",
                TextColor3         = c.acc,
                TextSize           = 9,
                Font               = fn.reg,
                TextXAlignment     = Enum.TextXAlignment.Left,
            }, info)
        end

        return Tab
    end

    return Win
end

-- ── ZhonyaLib:Destroy ─────────────────────────────────────────────────────────

function ZhonyaLib:OnUnload(fn)
    if type(fn) == "function" then table.insert(unloadCbs, fn) end
end

local unloaded = false
function ZhonyaLib:Destroy()
    if unloaded then return end
    unloaded = true
    for _, fn in ipairs(unloadCbs) do pcall(fn) end      -- your own cleanup first
    for _, cn in ipairs(conns) do pcall(function() cn:Disconnect() end) end
    table.clear(conns)
    pcall(function() sg:Destroy() end)
    local env = (getgenv and getgenv()) or _G
    if env.__ZhonyaLibUnload then env.__ZhonyaLibUnload = nil end
end

do
    local env = (getgenv and getgenv()) or _G
    env.__ZhonyaLibUnload = function() ZhonyaLib:Destroy() end
end

return ZhonyaLib

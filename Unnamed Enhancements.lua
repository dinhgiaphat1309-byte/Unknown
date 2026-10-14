--By Đinh Thái Hòa Rivals
local arguments = table.pack(...)
local sharedEnv = getgenv and getgenv() or _G
local previous = rawget(sharedEnv, 'Unnamed Enhancements - Cracked')

if type(previous) == 'table' and (previous.status == 'starting' or previous.status == 'entry_returned') then
    return previous
end
if rawget(sharedEnv, 'UE_LOADED') == true then
    return previous
end

local control = {
    status = 'starting',
    started = os.clock(),
    error = nil,
    stopped = false,
}

sharedEnv['Unnamed Enhancements - Cracked'] = control

local previousLoaded = rawget(sharedEnv, 'UE_LOADED')
local previousLibrary = rawget(sharedEnv, 'Library')
local previousOptions = rawget(sharedEnv, 'Options')
local previousToggles = rawget(sharedEnv, 'Toggles')
local budgets = setmetatable({}, {
    __mode = 'k',
})
local schedulerFrame = 0
local heartbeatConnection

local function __step(id)
    if control.stopped then
        error('execution stopped', 0)
    end

    local thread = coroutine.running()
    local state = budgets[thread]

    if not state then
        local now = os.clock()

        state = {
            ticks = 0,
            frame = schedulerFrame,
            started = now,
        }
        budgets[thread] = state
    end

    state.ticks += 1

    if state.ticks % 4096 ~= 0 then
        return
    end

    local now = os.clock()

    if state.frame ~= schedulerFrame then
        state.started = now
        state.ticks = 0
        state.frame = schedulerFrame
    end
    if state.ticks > 50000000 or now - state.started > 20 then
        control.error = 'Execution made no progress: loop ' .. tostring(id)
        control.status = 'error'
        control.stopped = true

        if heartbeatConnection then
            heartbeatConnection:Disconnect()
        end

        error(control.error, 0)
    end
    if state.ticks > 0 and state.ticks % 262144 == 0 and coroutine.isyieldable() then
        task.wait()

        state.frame = schedulerFrame
    end
end

local Native = {}
local Backend = {}

local function buildApplication()
    local runtime = Backend.createRuntime()
    local state = Backend.bindPrimitives(runtime)
    local data = Backend.loadProgramData()

    Backend.initialize(data)

    return state[56](data[1], state[2])
end
local function runApplication()
    local function traceback(err)
        local text = tostring(err)

        return debug and debug.traceback and debug.traceback(text, 2) or text
    end

    local ok, result = xpcall(function()
        assert(type(getgenv) == 'function', 'This file needs a Roblox executor with getgenv.')
        assert(game ~= nil and type(loadstring) == 'function', 'Roblox and loadstring are required.')
        assert(type(buffer) == 'table' and type(bit32) == 'table', 'buffer and bit32 are required.')

        heartbeatConnection = game:GetService('RunService').Heartbeat:Connect(function()
            schedulerFrame += 1
        end)

        local entry = buildApplication()

        return table.pack(entry(table.unpack(arguments, 1, arguments.n)))
    end, traceback)

    if not ok then
        control.error = result
        control.status = 'error'
        control.stopped = true

        if heartbeatConnection then
            heartbeatConnection:Disconnect()
        end

        local failedLibrary = rawget(sharedEnv, 'Library')

        if type(failedLibrary) == 'table' and failedLibrary ~= previousLibrary then
            if type(failedLibrary.Signals) == 'table' then
                for _, signal in failedLibrary.Signals do
                    if typeof(signal) == 'RBXScriptConnection' then
                        signal:Disconnect()
                    end
                end
            end
            if typeof(failedLibrary.ScreenGui) == 'Instance' then
                failedLibrary.ScreenGui:Destroy()
            end
        end

        sharedEnv.Library = previousLibrary
        sharedEnv.Options = previousOptions
        sharedEnv.Toggles = previousToggles
        sharedEnv.UE_LOADED = previousLoaded

        return control
    end

    control.status = 'entry_returned'
    control.elapsed = os.clock() - control.started

    local applicationLibrary = rawget(sharedEnv, 'Library')

    if type(applicationLibrary) == 'table' and applicationLibrary ~= previousLibrary and typeof(applicationLibrary.ScreenGui) == 'Instance' then
        applicationLibrary.ScreenGui.Destroying:Connect(function()
            control.status = 'unloaded'
            control.stopped = true

            if heartbeatConnection then
                heartbeatConnection:Disconnect()
            end

            sharedEnv.UE_LOADED = previousLoaded

            if rawget(sharedEnv, 'Library') == applicationLibrary then
                sharedEnv.Library = previousLibrary
                sharedEnv.Options = previousOptions
                sharedEnv.Toggles = previousToggles
            end
        end)
    end

    return control
end

function Backend.initialize(data)
    local root = data[1]
    local opcodes, destinations, jumpOperands, constantValues, globalNames, memberKeys, sourceRegisters = root[3], root[4], root[5], root[7], root[8], root[9], root[10]

    assert(opcodes[1] == 7 and jumpOperands[1] == 17364, 'Unexpected input version')
    assert(opcodes[17366] == 213 and opcodes[17880] == 42, 'Application boundary changed')

    -- Keep this standalone file from scheduling the old key-protected loader.
    assert(opcodes[20172] == 213 and jumpOperands[20172] == 24
        and globalNames[20172] == 'queue_on_teleport', 'Teleport boundary changed')
    opcodes[20172] = 167
    destinations[20172] = 24
    rawset(constantValues, 20172, function() end)

    opcodes[17366] = 7
    jumpOperands[17366] = 20413
    opcodes[20414] = 213
    jumpOperands[20414] = 2

    rawset(globalNames, 20414, 'os')

    opcodes[20415] = 116
    destinations[20415] = 2
    sourceRegisters[20415] = 2

    rawset(memberKeys, 20415, 'clock')

    opcodes[20416] = 171
    sourceRegisters[20416] = 2
    opcodes[20417] = 7
    jumpOperands[20417] = 2752
    opcodes[20418] = 167
    destinations[20418] = 12

    rawset(constantValues, 20418, 9395)

    local function integrityProduct(inputValue)
        return (inputValue + 63) % 100 * (inputValue % 32)
    end
    local function integrityModulo(inputValue)
        return 327 * inputValue % 10000
    end
    local function integrityOffset(inputValue)
        return 3650 * inputValue % 7115 + 3 * inputValue
    end

    opcodes[20419] = 167
    destinations[20419] = 5

    rawset(constantValues, 20419, integrityProduct)

    opcodes[20420] = 167
    destinations[20420] = 4

    rawset(constantValues, 20420, integrityModulo)

    opcodes[20421] = 167
    destinations[20421] = 3

    rawset(constantValues, 20421, integrityOffset)

    opcodes[20422] = 167
    destinations[20422] = 11

    rawset(constantValues, 20422, 964)

    opcodes[20423] = 167
    destinations[20423] = 6

    rawset(constantValues, 20423, 'Frame')

    opcodes[20424] = 167
    destinations[20424] = 7

    rawset(constantValues, 20424, 'OutlineColor')

    opcodes[20425] = 167
    destinations[20425] = 8

    rawset(constantValues, 20425, 'BindableEvent')

    opcodes[20426] = 167
    destinations[20426] = 9

    rawset(constantValues, 20426, false)

    opcodes[20427] = 167
    destinations[20427] = 10

    rawset(constantValues, 20427, true)

    opcodes[20428] = 7
    jumpOperands[20428] = 1128
    opcodes[17880] = 7
    jumpOperands[17880] = 20417
end
function Native.library(captures)
    local capture09 = captures[9]
    local capture11 = captures[11]
    local uiLibrary = captures[0]
    local capture10 = captures[10]
    local capture17 = captures[17]
    local playersService = captures[22]
    local capture12 = captures[12]
    local capture19 = captures[19]
    local textService = captures[18]
    local userInputService = captures[6]
    local capture08 = captures[8]
    local capture14 = captures[14]
    local capture02 = captures[2]
    local teamsService = captures[21]
    local contextActionService = captures[13]
    local capture01 = captures[1]
    local capture05 = captures[5]
    local capture03 = captures[3]
    local capture16 = captures[16]
    local capture20 = captures[20]
    local capture04 = captures[4]
    local capture07 = captures[7]
    local capture23 = captures[23]
    local capture15 = captures[15]

    return function()
        capture08[3][capture08[2] ] = function()
            local players = playersService:GetPlayers()

            for index = 1, #players do
                __step(5)

                players[index] = players[index].Name
            end

            table.sort(players, function(value028, value029)
                return value028 < value029
            end)

            return players
        end
        capture11[3][capture11[2] ] = function()
            local teams = teamsService:GetTeams()

            for index2 = 1, #teams do
                __step(6)

                teams[index2] = teams[index2].Name
            end

            table.sort(teams, function(value032, value033)
                return value032 < value033
            end)

            return teams
        end

        function uiLibrary:SafeCallback(callback, ...)
            if not callback then
                return
            end
            if not uiLibrary.NotifyOnError then
                return callback(...)
            end

            local success, resultOrError = pcall(callback, ...)

            if not success then
                local matchStart, matchEnd = resultOrError:find(':%d+: ')

                if not matchEnd then
                    return uiLibrary:Notify(resultOrError)
                end

                return uiLibrary:Notify(resultOrError:sub(matchEnd + 1), 3)
            end
        end
        function uiLibrary:AttemptSave()
            if uiLibrary.SaveManager then
                uiLibrary.SaveManager:Save()
            end
        end
        function uiLibrary:Create(classOrInstance, properties)
            local instance3 = classOrInstance

            if typeof(classOrInstance) == 'string' then
                instance3 = Instance.new(classOrInstance)
            end

            for key, value in next, properties do
                __step(7)

                local success2, resultOrError2 = pcall(function()
                    instance3[key] = value
                end)

                if not success2 then
                    capture17(resultOrError2)
                end
            end

            return instance3
        end
        function uiLibrary:EnableFlagCopying(enabled)
            uiLibrary.FlagCopying = enabled
        end
        function uiLibrary:ApplyTextStroke(label)
            label.TextStrokeTransparency = 1

            return uiLibrary:Create('UIStroke', {
                Color = Color3.new(0, 0, 0),
                Thickness = 1,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Parent = label,
            })
        end
        function uiLibrary:CreateLabel(properties2, isHud)
            local textLabel = uiLibrary:Create('TextLabel', {
                BackgroundTransparency = 1,
                Font = uiLibrary.Font,
                TextColor3 = uiLibrary.FontColor,
                TextSize = 16,
                TextStrokeTransparency = 0,
            })

            uiLibrary:ApplyTextStroke(textLabel)
            uiLibrary:AddToRegistry(textLabel, {
                TextColor3 = 'FontColor',
            }, isHud)

            return uiLibrary:Create(textLabel, properties2)
        end
        function uiLibrary:MakeDraggable(frame, dragHeight, respectDragLock)
            frame.Active = true

            frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    if respectDragLock == true and uiLibrary.CantDragForced == true then
                        return
                    end

                    local dragOffset = Vector2.new(capture03.X - frame.AbsolutePosition.X, capture03.Y - frame.AbsolutePosition.Y)

                    if dragOffset.Y > (dragHeight or 40) then
                        return
                    end

                    while userInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                        __step(8)

                        frame.Position = UDim2.new(0, capture03.X - dragOffset.X + frame.Size.X.Offset * frame.AnchorPoint.X, 0, capture03.Y - dragOffset.Y + frame.Size.Y.Offset * frame.AnchorPoint.Y)

                        capture04:Wait()
                    end
                end
            end)
        end

        local screenGui = Instance.new('ScreenGui', capture10)

        function uiLibrary:MakeDraggableOutline(frame2, dragHeight2, respectDragLock2)
            frame2.Active = true

            frame2.InputBegan:Connect(function(input2)
                if input2.UserInputType == Enum.UserInputType.MouseButton1 then
                    if respectDragLock2 == true and uiLibrary.CantDragForced == true then
                        return
                    end

                    local dragOffset2 = Vector2.new(capture03.X - frame2.AbsolutePosition.X, capture03.Y - frame2.AbsolutePosition.Y)

                    if dragOffset2.Y > (dragHeight2 or 40) then
                        return
                    end

                    local value070 = uiLibrary:Create(capture01[3][capture01[2] ], {
                        Parent = screenGui,
                        AnchorPoint = frame2.AnchorPoint,
                        BackgroundTransparency = 1,
                        Size = frame2.Size,
                        Position = frame2.Position,
                    })
                    local uIStroke = uiLibrary:Create('UIStroke', {
                        Parent = value070,
                        Color = uiLibrary.AccentColor or Color3.new(0, 0, 0),
                    })

                    uiLibrary.IsDragging = true

                    while(userInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)) do
                        __step(9)

                        value070.Position = UDim2.new(0, capture03.X - dragOffset2.X + frame2.Size.X.Offset * frame2.AnchorPoint.X, 0, capture03.Y - dragOffset2.Y + frame2.Size.Y.Offset * frame2.AnchorPoint.Y)
                        uIStroke.Color = uiLibrary.AccentColor or Color3.new(0, 0, 0)

                        capture04:Wait()
                    end

                    frame2.Position = value070.Position

                    value070:Destroy()

                    uiLibrary.IsDragging = false
                end
                if input2.UserInputType == Enum.UserInputType.Touch then
                    if respectDragLock2 == true and uiLibrary.CantDragForced == true then
                        return
                    end

                    local value072 = Vector2.new(input2.Position.X - frame2.AbsolutePosition.X, input2.Position.Y - frame2.AbsolutePosition.Y)

                    if value072.Y > (dragHeight2 or 40) then
                        return
                    end

                    local value073 = uiLibrary:Create(capture01[3][capture01[2] ], {
                        Parent = screenGui,
                        AnchorPoint = frame2.AnchorPoint,
                        BackgroundTransparency = 1,
                        Size = frame2.Size,
                        Position = frame2.Position,
                    })
                    local uIStroke2 = uiLibrary:Create('UIStroke', {
                        Parent = value073,
                        Color = uiLibrary.AccentColor or Color3.new(0, 0, 0),
                    })

                    uiLibrary.IsDragging = true

                    local value075 = true
                    local value076

                    value076 = input2.Changed:Connect(function()
                        if input2.UserInputState == Enum.UserInputState.End then
                            value075 = false
                        end
                    end)

                    while value075 do
                        __step(10)

                        value073.Position = UDim2.new(0, input2.Position.X - value072.X + frame2.Size.X.Offset * frame2.AnchorPoint.X, 0, input2.Position.Y - value072.Y + frame2.Size.Y.Offset * frame2.AnchorPoint.Y)
                        uIStroke2.Color = uiLibrary.AccentColor or Color3.new(0, 0, 0)

                        capture04:Wait()
                    end

                    frame2.Position = value073.Position

                    if value076 then
                        value076:Disconnect()
                    end

                    value073:Destroy()

                    uiLibrary.IsDragging = false
                end
            end)
        end
        function uiLibrary:MakeDraggableUsingParent(handle, frame3, dragHeight3, respectDragLock3)
            handle.Active = true

            if uiLibrary.IsMobile == false then
                handle.InputBegan:Connect(function(input3)
                    if input3.UserInputType == Enum.UserInputType.MouseButton1 or input3.UserInputType == Enum.UserInputType.Touch then
                        if respectDragLock3 == true and uiLibrary.CantDragForced == true then
                            return
                        end

                        local dragOffset3 = Vector2.new(capture03.X - frame3.AbsolutePosition.X, capture03.Y - frame3.AbsolutePosition.Y)

                        if dragOffset3.Y > (dragHeight3 or 40) then
                            return
                        end

                        while userInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                            __step(11)

                            frame3.Position = UDim2.new(0, capture03.X - dragOffset3.X + frame3.Size.X.Offset * frame3.AnchorPoint.X, 0, capture03.Y - dragOffset3.Y + frame3.Size.Y.Offset * frame3.AnchorPoint.Y)

                            capture04:Wait()
                        end
                    end
                end)
            else
                uiLibrary:MakeDraggable(frame3, dragHeight3, respectDragLock3)
            end
        end
        function uiLibrary:MakeResizable(value085, value086)
            value085.Active = true

            local value087 = 25
            local value088 = 0.5
            local value089 = uiLibrary:Create(capture01[3][capture01[2] ], {
                SizeConstraint = Enum.SizeConstraint.RelativeXX,
                BackgroundColor3 = Color3.new(0, 0, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 30, 0, 30),
                Position = UDim2.new(1, -30, 1, -30),
                Visible = true,
                ClipsDescendants = true,
                ZIndex = 1,
                Parent = value085,
            })
            local imageButton = uiLibrary:Create('ImageButton', {
                BackgroundColor3 = uiLibrary.AccentColor,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(2, 0, 2, 0),
                Position = UDim2.new(1, -30, 1, -30),
                ZIndex = 2,
                Parent = value089,
            })
            local uICorner = uiLibrary:Create('UICorner', {
                CornerRadius = UDim.new(0.5, 0),
                Parent = imageButton,
            })

            uiLibrary:AddToRegistry(imageButton, {
                BackgroundColor3 = 'AccentColor',
            })

            value089.Size = UDim2.fromOffset(value087, value087)
            value089.Position = UDim2.new(1, -value087, 1, -value087)
            value086 = value086 or uiLibrary.MinSize

            local value092
            local value093, uIStroke3 = nil, uiLibrary:Create('UIStroke', {
                Color = uiLibrary.AccentColor or Color3.new(0, 0, 0),
            })

            uIStroke3.Color = uiLibrary.AccentColor or Color3.new(0, 0, 0)

            local function value095(value096)
                imageButton.Position = UDim2.new()
                imageButton.Size = UDim2.new(2, 0, 2, 0)
                imageButton.Parent = value089
                imageButton.BackgroundTransparency = value096
                uICorner.Parent = imageButton
                value092 = nil

                if value093 then
                    uIStroke3.Parent = nil
                    value085.Size = value093.Size

                    value093:Destroy()
                end
            end

            if uiLibrary.IsMobile ~= true then
                imageButton.MouseButton1Down:Connect(function()
                    if value092 then
                        return
                    end

                    value092 = Vector2.new(capture03.X - (value085.AbsolutePosition.X + value085.AbsoluteSize.X), capture03.Y - (value085.AbsolutePosition.Y + value085.AbsoluteSize.Y))
                    value093 = uiLibrary:Create(capture01[3][capture01[2] ], {
                        Parent = screenGui,
                        AnchorPoint = value085.AnchorPoint,
                        BackgroundTransparency = 1,
                        Size = value085.Size,
                        Position = value085.Position,
                    })
                    uIStroke3.Parent = value093
                    imageButton.BackgroundTransparency = 1
                    imageButton.Size = UDim2.fromOffset(uiLibrary.ScreenGui.AbsoluteSize.X, uiLibrary.ScreenGui.AbsoluteSize.Y)
                    imageButton.Position = UDim2.new()
                    uICorner.Parent = nil
                    imageButton.Parent = uiLibrary.ScreenGui
                end)
                imageButton.MouseMoved:Connect(function()
                    if not value092 then
                        return
                    end

                    local value097 = Vector2.new(capture03.X - value092.X, capture03.Y - value092.Y)
                    local value098 = Vector2.new(math.clamp(value097.X - value085.AbsolutePosition.X, value086.X, math.huge), math.clamp(value097.Y - value085.AbsolutePosition.Y, value086.Y, math.huge))

                    value093.Size = UDim2.fromOffset(value098.X, value098.Y)
                end)
                imageButton.MouseButton1Up:Connect(function()
                    value095(value088)
                end)
            else
                imageButton.InputBegan:Connect(function(input4)
                    if input4.UserInputType ~= Enum.UserInputType.Touch then
                        return
                    end
                    if value092 then
                        return
                    end

                    value092 = Vector2.new(input4.Position.X - (value085.AbsolutePosition.X + value085.AbsoluteSize.X), input4.Position.Y - (value085.AbsolutePosition.Y + value085.AbsoluteSize.Y))
                    value093 = uiLibrary:Create(capture01[3][capture01[2] ], {
                        Parent = screenGui,
                        AnchorPoint = value085.AnchorPoint,
                        BackgroundTransparency = 1,
                        Size = value085.Size,
                        Position = value085.Position,
                    })
                    uIStroke3.Parent = value093
                end)
                imageButton.InputChanged:Connect(function(input5)
                    if input5.UserInputType ~= Enum.UserInputType.Touch then
                        return
                    end
                    if not value092 then
                        return
                    end

                    local value101 = Vector2.new(input5.Position.X - value092.X, input5.Position.Y - value092.Y)
                    local value102 = Vector2.new(math.clamp(value101.X - value085.AbsolutePosition.X, value086.X, math.huge), math.clamp(value101.Y - value085.AbsolutePosition.Y, value086.Y, math.huge))

                    value093.Size = UDim2.fromOffset(value102.X, value102.Y)
                end)
                imageButton.InputEnded:Connect(function(input6)
                    if input6.UserInputType ~= Enum.UserInputType.Touch then
                        return
                    end

                    value095(value088)
                end)
            end

            value095(value088)
        end
        function uiLibrary:AddToolTip(text, target)
            local textWidth, textHeight = uiLibrary:GetTextBounds(text, uiLibrary.Font, 14)
            local value109 = uiLibrary:Create(capture01[3][capture01[2] ], {
                BackgroundColor3 = uiLibrary.MainColor,
                BorderColor3 = uiLibrary.OutlineColor,
                Size = UDim2.fromOffset(textWidth + 5, textHeight + 4),
                ZIndex = 100,
                Parent = uiLibrary.ScreenGui,
                Visible = false,
            })
            local value110 = uiLibrary:CreateLabel({
                Position = UDim2.fromOffset(3, 1),
                Size = UDim2.fromOffset(textWidth, textHeight),
                TextSize = 14,
                Text = text,
                TextColor3 = uiLibrary.FontColor,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = value109.ZIndex + 1,
                Parent = value109,
            })

            uiLibrary:AddToRegistry(value109, {
                BackgroundColor3 = 'MainColor',
                BorderColor3 = capture15[3][capture15[2] ],
            })
            uiLibrary:AddToRegistry(value110, {
                TextColor3 = 'FontColor',
            })

            local value111 = false

            target.MouseEnter:Connect(function()
                if uiLibrary:MouseIsOverOpenedFrame() then
                    return
                end

                value111 = true
                value109.Position = UDim2.fromOffset(capture03.X + 15, capture03.Y + 12)
                value109.Visible = true

                while value111 do
                    __step(12)
                    capture19.Heartbeat:Wait()

                    value109.Position = UDim2.fromOffset(capture03.X + 15, capture03.Y + 12)
                end
            end)
            target.MouseLeave:Connect(function()
                value111 = false
                value109.Visible = false
            end)

            if capture12[3][capture12[2] ] then
                capture12[3][capture12[2] ]:GetPropertyChangedSignal('Visible'):Connect(function()
                    if capture12[3][capture12[2] ].Visible == false then
                        value111 = false
                        value109.Visible = false
                    end
                end)
            end
        end
        function uiLibrary:OnHighlight(target2, styledInstance, highlightProperties, normalProperties, canHighlight)
            local function value118()
                local registryEntry = uiLibrary.RegistryMap[styledInstance]

                for key2, value2 in next, normalProperties do
                    __step(13)

                    styledInstance[key2] = uiLibrary[value2] or value2

                    if registryEntry and registryEntry.Properties[key2] then
                        registryEntry.Properties[key2] = value2
                    end
                end
            end
            local function value122()
                if canHighlight and not canHighlight() then
                    value118()

                    return
                end

                local registryEntry2 = uiLibrary.RegistryMap[styledInstance]

                for key3, value3 in next, highlightProperties do
                    __step(14)

                    styledInstance[key3] = uiLibrary[value3] or value3

                    if registryEntry2 and registryEntry2.Properties[key3] then
                        registryEntry2.Properties[key3] = value3
                    end
                end
            end

            target2.MouseEnter:Connect(function()
                value122()
            end)
            target2.MouseMoved:Connect(function()
                value122()
            end)
            target2.MouseLeave:Connect(function()
                value118()
            end)
        end
        function uiLibrary:MouseIsOverOpenedFrame()
            for key4, value4 in next, uiLibrary.OpenedFrames do
                __step(15)

                local absolutePosition, absoluteSize = key4.AbsolutePosition, key4.AbsoluteSize

                if capture03.X >= absolutePosition.X and capture03.X <= absolutePosition.X + absoluteSize.X and capture03.Y >= absolutePosition.Y and capture03.Y <= absolutePosition.Y + absoluteSize.Y then
                    return true
                end
            end
        end
        function uiLibrary:IsMouseOverFrame(frame4)
            local absolutePosition2, absoluteSize2 = frame4.AbsolutePosition, frame4.AbsoluteSize

            if capture03.X >= absolutePosition2.X and capture03.X <= absolutePosition2.X + absoluteSize2.X and capture03.Y >= absolutePosition2.Y and capture03.Y <= absolutePosition2.Y + absoluteSize2.Y then
                return true
            end
        end
        function uiLibrary:UpdateDependencyBoxes()
            for key5, value5 in next, uiLibrary.DependencyBoxes do
                __step(16)
                value5:Update()
            end
        end
        function uiLibrary:MapValue(inputValue, inputMin, inputMax, outputMin, outputMax)
            return (1 - (inputValue - inputMin) / (inputMax - inputMin)) * outputMin + (inputValue - inputMin) / (inputMax - inputMin) * outputMax
        end
        function uiLibrary:GetTextBounds(text2, font, fontSize, bounds)
            local textSize = textService:GetTextSize(text2, fontSize, font, bounds or Vector2.new(1920, 1080))

            return textSize.X, textSize.Y
        end
        function uiLibrary:GetDarkerColor(color)
            local hue, saturation, brightness = Color3.toHSV(color)

            return Color3.fromHSV(hue, saturation, brightness / 1.5)
        end

        uiLibrary.AccentColorDark = uiLibrary:GetDarkerColor(uiLibrary.AccentColor)

        function uiLibrary:AddToRegistry(instance, properties3, isHud2)
            local registryIndex = #uiLibrary.Registry + 1
            local registryEntry3 = {
                Instance = instance,
                Properties = properties3,
                Idx = registryIndex,
            }

            table.insert(uiLibrary.Registry, registryEntry3)

            uiLibrary.RegistryMap[instance] = registryEntry3

            if isHud2 then
                table.insert(uiLibrary.HudRegistry, registryEntry3)
            end
        end
        function uiLibrary:RemoveFromRegistry(instance2)
            local registryEntry4 = uiLibrary.RegistryMap[instance2]

            if registryEntry4 then
                for index3 = #uiLibrary.Registry, 1, -1 do
                    __step(17)

                    if uiLibrary.Registry[index3] == registryEntry4 then
                        table.remove(uiLibrary.Registry, index3)
                    end
                end
                for index4 = #uiLibrary.HudRegistry, 1, -1 do
                    __step(18)

                    if uiLibrary.HudRegistry[index4] == registryEntry4 then
                        table.remove(uiLibrary.HudRegistry, index4)
                    end
                end

                uiLibrary.RegistryMap[instance2] = nil
            end
        end
        function uiLibrary:UpdateColorsUsingRegistry()
            for key6, value6 in next, uiLibrary.Registry do
                __step(19)

                for key7, value7 in next, value6.Properties do
                    __step(20)

                    if typeof(value7) == 'string' then
                        value6.Instance[key7] = uiLibrary[value7]
                    elseif typeof(value7) == 'function' then
                        value6.Instance[key7] = value7()
                    end
                end
            end
        end
        function uiLibrary:GiveSignal(connection)
            table.insert(uiLibrary.Signals, connection)
        end
        function uiLibrary:Unload()
            for index5 = #uiLibrary.Signals, 1, -1 do
                __step(21)

                local connection2 = table.remove(uiLibrary.Signals, index5)

                connection2:Disconnect()
            end

            if uiLibrary.OnUnload then
                uiLibrary.OnUnload()
            end

            contextActionService:UnbindAction('Freeze')
            capture16:Destroy()
            capture20:Destroy()
            capture05:Destroy()
            capture09:Destroy()
        end
        function uiLibrary:CreateEvent(eventName)
            self.Events[eventName] = Instance.new(capture02[3][capture02[2] ])
        end
        function uiLibrary:FireEvent(eventName2, ...)
            self.Events[eventName2]:Fire(...)
        end
        function uiLibrary:OnEvent(eventName3)
            return self.Events[eventName3].Event
        end
        function uiLibrary:OnUnload(callback2)
            uiLibrary.OnUnload = callback2
        end

        local inputCallbacks = {}

        function uiLibrary:BindToInput(inputType, callback3)
            inputCallbacks[inputType] = inputCallbacks[inputType] or {}

            table.insert(inputCallbacks[inputType], callback3)
        end

        uiLibrary:GiveSignal(userInputService.InputBegan:Connect(function(input7, ...)
            if not capture07[3][capture07[2] ] then
                return
            end

            local value189 = inputCallbacks[input7.KeyCode] or inputCallbacks[input7.UserInputType]

            if value189 then
                for key8, value8 in pairs(value189)do
                    __step(22)
                    task.spawn(value8, input7, ...)
                end
            end
        end))

        function uiLibrary:AddContextMenu(value193, value194)
            local panel = {Visible = false}

            panel.Options = {}
            panel.Container = uiLibrary:Create('ImageButton', {
                BorderColor3 = Color3.new(),
                ZIndex = 14,
                Visible = false,
                Parent = capture09,
                Image = '',
                Active = false,
                AutoButtonColor = false,
            })
            panel.Inner = uiLibrary:Create(capture01[3][capture01[2] ], {
                BackgroundColor3 = uiLibrary.BackgroundColor,
                BorderColor3 = uiLibrary.OutlineColor,
                BorderMode = Enum.BorderMode.Inset,
                Size = UDim2.fromScale(1, 1),
                ZIndex = 15,
                Parent = panel.Container,
            })

            uiLibrary:Create('UIListLayout', {
                Name = 'Layout',
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = panel.Inner,
            })
            uiLibrary:Create('UIPadding', {
                Name = 'Padding',
                PaddingLeft = UDim.new(0, 0),
                Parent = panel.Inner,
            })

            local function value196()
                panel.Container.Position = UDim2.fromOffset(value193.AbsolutePosition.X + value193.AbsoluteSize.X + 4, value193.AbsolutePosition.Y + 1)
            end
            local function value197()
                local value198 = 60

                for key9, value9 in next, panel.Inner:GetChildren()do
                    __step(23)

                    if value9:IsA('TextLabel') then
                        value198 = math.max(value198, value9.TextBounds.X)
                    end
                end

                panel.Container.Size = UDim2.fromOffset(value198 + 8, panel.Inner.Layout.AbsoluteContentSize.Y + 4)
            end

            local value201 = false

            (value194 or value193).InputBegan:Connect(function(input8)
                if input8.UserInputType == Enum.UserInputType.MouseButton1 and not uiLibrary:MouseIsOverOpenedFrame() then
                    return panel:Hide()
                elseif input8.UserInputType == Enum.UserInputType.MouseButton2 and not uiLibrary:MouseIsOverOpenedFrame() then
                    return panel:Show()
                end
            end)
            uiLibrary:BindToInput(Enum.UserInputType.MouseButton1, function()
                if value201 and not uiLibrary:IsMouseOverFrame(panel.Container) then
                    panel:Hide()
                end
            end)
            uiLibrary:BindToInput(Enum.UserInputType.MouseButton2, function()
                if value201 and not uiLibrary:IsMouseOverFrame(panel.Container) and not uiLibrary:IsMouseOverFrame(value193) then
                    panel:Hide()
                end
            end)
            task.spawn(value196)
            task.spawn(value197)
            uiLibrary:AddToRegistry(panel.Inner, {
                BackgroundColor3 = 'BackgroundColor',
                BorderColor3 = capture15[3][capture15[2] ],
            })

            function panel:Show()
                value196()
                value197()

                value201 = true

                for key10, value10 in next, uiLibrary.OpenedFrames do
                    __step(24)

                    if key10.Name == 'Color' then
                        key10.Visible = false
                        uiLibrary.OpenedFrames[key10] = nil
                    end
                end

                self.Container.Visible = true
                uiLibrary.OpenedFrames[panel.Container] = true
            end
            function panel:Hide()
                value201 = false
                self.Container.Visible = false

                task.wait()

                uiLibrary.OpenedFrames[panel.Container] = nil
            end
            function panel:AddOption(text3, callback4)
                if type(callback4) ~= 'function' then
                    callback4 = function() end
                end

                local value210 = uiLibrary:CreateLabel({
                    Active = false,
                    Size = UDim2.new(1, 0, 0, 15),
                    TextSize = 13,
                    Text = text3,
                    ZIndex = 16,
                    Parent = self.Inner,
                    TextXAlignment = Enum.TextXAlignment.Center,
                })

                uiLibrary:OnHighlight(value210, value210, {
                    TextColor3 = 'AccentColor',
                }, {
                    TextColor3 = 'FontColor',
                })
                value210.InputBegan:Connect(function(input9)
                    if input9.UserInputType ~= Enum.UserInputType.MouseButton1 then
                        return
                    end

                    callback4()
                end)

                return value210
            end

            return panel
        end

        uiLibrary:GiveSignal(capture09.DescendantRemoving:Connect(function(value212)
            if capture07[3][capture07[2] ] and uiLibrary.RegistryMap[value212] then
                uiLibrary:RemoveFromRegistry(value212)
            end
        end))

        function uiLibrary:SetWatermarkVisibility(visible)
            uiLibrary.Watermark.Visible = visible
        end
        function uiLibrary:SetWatermark(text4)
            local textWidth2, textHeight2 = uiLibrary:GetTextBounds(text4, uiLibrary.Font, 14)

            uiLibrary.Watermark.Size = UDim2.new(0, textWidth2 + 15, 0, textHeight2 * 1.5 + 3)
            uiLibrary.WatermarkText.Text = text4
        end

        local value219 = {
            BarPosition = {
                Top = UDim2.new(0, -1, 0, 0),
                Left = UDim2.new(0, -1, 0, -1),
                Right = UDim2.new(1, -2, 0, -1),
                Bottom = UDim2.new(0, -1, 1, -2),
            },
            BarSize = {
                Top = UDim2.new(1, 3, 0, 2),
                Left = UDim2.new(0, 3, 1, 2),
                Right = UDim2.new(0, 3, 1, 2),
                Bottom = UDim2.new(1, 3, 0, 2),
            },
        }
        local notificationStyle = uiLibrary.NotificationStyle
        local charFn, maxFn = string.char, math.max
        local value223 = function()
            local overrideColor = notificationStyle.OverrideColor

            if overrideColor then
                return overrideColor()
            end

            return uiLibrary.MainColor, uiLibrary.AccentColor, uiLibrary.OutlineColor, uiLibrary.FontColor
        end
        local value225

        do
            local value226 = uiLibrary:Create(capture01[3][capture01[2] ], {
                BorderColor3 = Color3.new(0, 0, 0),
                Position = UDim2.new(0, 100, 0, 10),
                ClipsDescendants = true,
                ZIndex = 100,
            })
            local value227 = uiLibrary:Create(capture01[3][capture01[2] ], {
                BorderMode = Enum.BorderMode.Inset,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 101,
                Parent = value226,
                Name = 'inner',
            })
            local value228 = uiLibrary:Create(capture01[3][capture01[2] ], {
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 1, -2),
                ZIndex = 102,
                Parent = value227,
                Name = 'inner',
            })
            local uIGradient = uiLibrary:Create('UIGradient', {
                Rotation = -90,
                Parent = value228,
            })
            local value230 = uiLibrary:CreateLabel({
                Position = UDim2.new(0, 4, 0, 0),
                Size = UDim2.new(1, -4, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                TextSize = 14,
                ZIndex = 103,
                Name = 'label',
                Parent = value228,
            })
            local value231 = uiLibrary:Create(capture01[3][capture01[2] ], {
                BorderSizePixel = 0,
                ZIndex = 104,
                Name = 'bar',
                Parent = value226,
            })

            value225 = value226
        end

        function uiLibrary:CreatePopout(settings)
            if type(settings.Title) ~= 'string' then
                settings.Title = 'No title'
            end
            if typeof(settings.Position) ~= 'UDim2' then
                settings.Position = UDim2.fromOffset(175, 50)
            end

            local screenGui2 = Instance.new('ScreenGui')

            capture23(screenGui2)

            screenGui2.ZIndexBehavior = Enum.ZIndexBehavior.Global
            screenGui2.Parent = capture10
            screenGui2.DisplayOrder = (settings.ZIndex or 0) + 19

            if settings.Center then
                settings.AnchorPoint = Vector2.new(0.5, 0.5)
                settings.Position = UDim2.fromScale(0.5, 0.5)
            end

            local popout = {}
            local value236 = uiLibrary:Create(capture01[3][capture01[2] ], {
                AnchorPoint = settings.AnchorPoint,
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderSizePixel = 0,
                Position = settings.Position,
                Size = UDim2.fromOffset(settings.Size.X, settings.Size.Y),
                Visible = settings.AutoShow,
                ZIndex = 1,
                Parent = screenGui2,
            })

            if not settings.RemoveTopbar then
                uiLibrary:MakeDraggableOutline(value236, 25)
            end

            local value237 = uiLibrary:Create(capture01[3][capture01[2] ], {
                BackgroundColor3 = uiLibrary.MainColor,
                BorderColor3 = uiLibrary.OutlineColor,
                BorderMode = Enum.BorderMode.Inset,
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 1, -2),
                ZIndex = 1,
                Parent = value236,
            })

            uiLibrary:AddToRegistry(value237, {
                BackgroundColor3 = 'MainColor',
                BorderColor3 = capture15[3][capture15[2] ],
            })

            if not settings.RemoveTopbar then
                local value238 = uiLibrary:CreateLabel({
                    Position = UDim2.new(0, 0, 0, 0),
                    Size = UDim2.new(1, 0, 0, 25),
                    Text = settings.Title or '',
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 1,
                    Font = uiLibrary.Font,
                    Parent = value237,
                })
                local textLabel2 = uiLibrary:Create('TextLabel', {
                    BackgroundTransparency = 1,
                    Font = uiLibrary.Font,
                    TextColor3 = uiLibrary.AccentColor,
                    TextSize = 16,
                    TextStrokeTransparency = 0,
                    Position = UDim2.new(0, -8, 0, 0),
                    Size = UDim2.new(1, 0, 0, 25),
                    Text = settings.Version or '',
                    RichText = true,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    ZIndex = 1,
                    Parent = value237,
                })

                uiLibrary:AddToRegistry(textLabel2, {
                    TextColor3 = 'AccentColor',
                })
            end

            local value240 = settings.RemoveTopbar and 8 or 25
            local value241 = settings.RemoveTopbar and -16 or -33
            local value242 = uiLibrary:Create(capture01[3][capture01[2] ], {
                BackgroundColor3 = uiLibrary.BackgroundColor,
                BorderColor3 = uiLibrary.OutlineColor,
                Position = UDim2.new(0, 8, 0, value240),
                Size = UDim2.new(1, -16, 1, value241),
                ZIndex = 1,
                Parent = value237,
            })

            uiLibrary:AddToRegistry(value242, {
                BackgroundColor3 = 'BackgroundColor',
                BorderColor3 = capture15[3][capture15[2] ],
            })

            local value243 = uiLibrary:Create(capture01[3][capture01[2] ], {
                BackgroundColor3 = uiLibrary.BackgroundColor,
                BorderColor3 = Color3.new(0, 0, 0),
                BorderMode = Enum.BorderMode.Inset,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 1,
                Parent = value242,
            })

            uiLibrary:AddToRegistry(value243, {
                BackgroundColor3 = 'BackgroundColor',
            })

            local value244 = uiLibrary:Create(capture01[3][capture01[2] ], {
                BackgroundColor3 = uiLibrary.BackgroundColor,
                BorderColor3 = uiLibrary.OutlineColor,
                Position = UDim2.new(0, 8, 0, 8),
                Size = UDim2.new(1, -16, 1, -16),
                ZIndex = 2,
                Visible = true,
                Parent = value243,
            })
            local value245 = uiLibrary:Create(capture01[3][capture01[2] ], {
                BackgroundTransparency = 1,
                Parent = value244,
                Size = UDim2.fromScale(1, 1),
                Position = UDim2.fromOffset(2, 2),
            })

            uiLibrary:Create('UIListLayout', {
                Padding = UDim.new(0, 0),
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                Parent = value245,
            })
            uiLibrary:AddToRegistry(value244, {
                BackgroundColor3 = 'BackgroundColor',
                BorderColor3 = capture15[3][capture15[2] ],
            })
            uiLibrary:AddToRegistry(value245, {
                BackgroundColor3 = 'MainColor',
                BorderColor3 = capture15[3][capture15[2] ],
            })

            popout.Holder = value236
            popout.Container = value245

            function popout:Resize()
                local contentHeight = 0

                for key11, value11 in next, value245:GetChildren()do
                    __step(25)

                    if not value11:IsA('UIListLayout') and value11.Visible then
                        contentHeight = contentHeight + value11.AbsoluteSize.Y
                    end
                end

                value236.Size = UDim2.fromOffset(settings.Size.X, 16 + contentHeight + (value245.AbsolutePosition.Y - value236.AbsolutePosition.Y))
            end
            function popout:Toggle()
                value236.Visible = not value236.Visible
            end
            function popout:GetSize()
                return value245.AbsoluteSize
            end

            value245:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
                task.wait()
                popout:Resize()
            end)
            popout:Resize()
            setmetatable(popout, capture14)

            return popout
        end

        local newFn, newFn2, newFn3 = UDim2.new, ColorSequence.new, ColorSequenceKeypoint.new

        function uiLibrary:Notify(text5, duration)
            local textWidth3, textHeight3 = uiLibrary:GetTextBounds(text5, uiLibrary.Font, 14)

            textHeight3 = textHeight3 + 7

            local transparency = notificationStyle.Transparency
            local value261, value262, value263, value264 = value223()
            local value265 = value225:Clone()

            value265.BackgroundColor3 = value261
            value265.Name = charFn(256 - maxFn(1, #text5 % 256))
            value265.Size = newFn(0, 0, 0, textHeight3)
            value265.Transparency = transparency

            local value266 = value265.inner

            value266.BackgroundColor3 = value261
            value266.BorderColor3 = value263
            value266.Transparency = transparency

            local value267 = value266.inner

            value267.Transparency = transparency

            local uIGradient2 = value267.UIGradient

            uIGradient2.Color = newFn2({
                newFn3(0, uiLibrary:GetDarkerColor(value261)),
                newFn3(1, value261),
            })

            local value269 = value267.label

            value269.Text = text5
            value269.TextColor3 = value264

            local value270 = value265.bar

            value270.BackgroundColor3 = value262
            value270.Size = value219.BarSize[notificationStyle.BarSide] or newFn(0, 3, 1, 2)
            value270.Position = value219.BarPosition[notificationStyle.BarSide]
            value265.Parent = uiLibrary.NotificationArea

            pcall(value265.TweenSize, value265, UDim2.new(0, textWidth3 + 8 + 4, 0, textHeight3), 'Out', 'Quad', 0.4, true)
            task.spawn(function()
                wait(duration or 5)
                pcall(value265.TweenSize, value265, UDim2.new(0, 0, 0, textHeight3), 'Out', 'Quad', 0.4, true)
                wait(0.4)
                value265:Destroy()
            end)
        end
        function uiLibrary:IsVisible()
            return capture07[3][capture07[2] ]
        end

        uiLibrary:CreateEvent('VisibilityChanged')
    end
end
function Native.configuration(captures)
    local toggles = captures[2]
    local options = captures[1]
    local capture03 = captures[3]
    local configManager = captures[0]

    return function()
        local cloneReference = cloneref or function(value007)
            return value007
        end
        local httpService = cloneReference(game:GetService('HttpService'))
        local isfolderFn, isfileFn, listfilesFn = isfolder, isfile, listfiles

        do
            configManager.Folder = ''
            configManager.Ignore = {}
            configManager.Parser = {
                Toggle = {
                    Save = function(optionId, option)
                        return {
                            type = 'Toggle',
                            idx = optionId,
                            value = option.Value,
                        }
                    end,
                    Load = function(optionId2, savedValue)
                        if toggles[optionId2] then
                            toggles[optionId2]:SetValue(savedValue.value)
                        end
                    end,
                },
                Slider = {
                    Save = function(optionId3, option2)
                        return {
                            type = 'Slider',
                            idx = optionId3,
                            value = tostring(option2.Value),
                        }
                    end,
                    Load = function(optionId4, savedValue2)
                        if options[optionId4] then
                            options[optionId4]:SetValue(savedValue2.value)
                        end
                    end,
                },
                Dropdown = {
                    Save = function(optionId5, option3)
                        return {
                            type = 'Dropdown',
                            idx = optionId5,
                            value = option3.Value,
                            mutli = option3.Multi,
                        }
                    end,
                    Load = function(optionId6, savedValue3)
                        if options[optionId6] then
                            options[optionId6]:SetValue(savedValue3.value)
                        end
                    end,
                },
                ColorPicker = {
                    Save = function(optionId7, option4)
                        return {
                            type = 'ColorPicker',
                            idx = optionId7,
                            value = option4.Value:ToHex(),
                            transparency = option4.Transparency,
                        }
                    end,
                    Load = function(optionId8, savedValue4)
                        if options[optionId8] then
                            options[optionId8]:SetValueRGB(Color3.fromHex(savedValue4.value), savedValue4.transparency)
                        end
                    end,
                },
                KeyPicker = {
                    Save = function(optionId9, option5)
                        return {
                            type = 'KeyPicker',
                            idx = optionId9,
                            mode = option5.Mode,
                            key = option5.Value,
                        }
                    end,
                    Load = function(optionId10, savedValue5)
                        if options[optionId10] then
                            options[optionId10]:SetValue({
                                savedValue5.key,
                                savedValue5.mode,
                            })
                        end
                    end,
                },
                Input = {
                    Save = function(optionId11, option6)
                        return {
                            type = 'Input',
                            idx = optionId11,
                            text = option6.Value,
                        }
                    end,
                    Load = function(optionId12, savedValue6)
                        if options[optionId12] and type(savedValue6.text) == 'string' then
                            options[optionId12]:SetValue(savedValue6.text)
                        end
                    end,
                },
            }

            function configManager:BuildFolderTree()
                local folders = {
                    self.Folder,
                    self.Folder .. '/settings',
                    self.Folder .. '/themes',
                }

                for index = 1, #folders do
                    __step(41)

                    local folderPath = folders[index]

                    if not isfolderFn(folderPath) then
                        makefolder(folderPath)
                    end
                end
            end
            function configManager:CheckFolderTree()
                if not isfolderFn(self.Folder) then
                    configManager:BuildFolderTree()
                    task.wait()
                end
            end
            function configManager:SetIgnoreIndexes(indexes)
                for key, value in next, indexes do
                    __step(42)

                    self.Ignore[value] = true
                end
            end
            function configManager:SetFolder(folder)
                self.Folder = folder

                self:BuildFolderTree()
            end
            function configManager:Save(configName, value049)
                if not configName then
                    return false, 'no config file is selected'
                end

                configManager:CheckFolderTree()

                local configPath = self.Folder .. '/settings/' .. configName .. '.json'
                local savedConfig = {objects = {}}

                for key2, value2 in next, toggles do
                    __step(43)

                    if self.Ignore[key2] then
                        continue
                    end

                    table.insert(savedConfig.objects, self.Parser[value2.Type].Save(key2, value2))
                end
                for key3, value3 in next, options do
                    __step(44)

                    if not self.Parser[value3.Type] then
                        continue
                    end
                    if self.Ignore[key3] then
                        continue
                    end

                    table.insert(savedConfig.objects, self.Parser[value3.Type].Save(key3, value3))
                end

                local success, resultOrError = pcall(httpService.JSONEncode, httpService, savedConfig)

                if not success then
                    return false, 'failed to encode data'
                end
                if not value049 then
                    writefile(configPath, resultOrError)
                end

                return true, resultOrError
            end
            function configManager:Load(configOrName)
                if not configOrName then
                    return false, 'no config file is selected'
                end
                if type(configOrName) == 'table' then
                    for key4, value4 in next, configOrName.objects do
                        __step(45)

                        if self.Parser[value4.type] then
                            task.spawn(function()
                                self.Parser[value4.type].Load(value4.idx, value4)
                            end)
                        end
                    end

                    return true
                end

                configManager:CheckFolderTree()

                local configPath2 = self.Folder .. '/settings/' .. configOrName .. '.json'

                if not isfileFn(configPath2) then
                    return false, 'invalid file'
                end

                local success2, resultOrError2 = pcall(httpService.JSONDecode, httpService, readfile(configPath2))

                if not success2 then
                    return false, 'decode error'
                end

                for key5, value5 in next, resultOrError2.objects do
                    __step(46)

                    if self.Parser[value5.type] then
                        task.spawn(function()
                            self.Parser[value5.type].Load(value5.idx, value5)
                        end)
                    end
                end

                return true
            end
            function configManager:Delete(configName2)
                if not configName2 then
                    return false, 'no config file is selected'
                end

                local configPath3 = self.Folder .. '/settings/' .. configName2 .. '.json'

                if not isfileFn(configPath3) then
                    return false, 'invalid file'
                end

                local success3, resultOrError3 = pcall(delfile, configPath3)

                if not success3 then
                    return false, 'delete file error'
                end

                return true
            end
            function configManager:IgnoreThemeSettings()
                self:SetIgnoreIndexes({
                    'ThemeManager_ThemeList',
                    'ThemeManager_CustomThemeList',
                    'ThemeManager_CustomThemeName',
                    'VideoLink',
                    'Brightness',
                    'Contrast',
                    'Saturation',
                    'Brightness',
                    'BlurSize',
                    'FontColor',
                    'RiskColor',
                    'MainColor',
                    'AccentColor',
                    'BackgroundColor',
                    capture03[3][capture03[2] ],
                    'SwordColor',
                    'ItemType',
                    'BackTransparency',
                    'BackColor',
                    'SwordTransparency',
                    'SwordReflectance',
                    'SwordMaterial',
                    'SwordSpeed',
                })
            end
            function configManager:RefreshConfigList()
                local value074 = listfilesFn(self.Folder .. '/settings')
                local value075 = {}

                for index2 = 1, #value074 do
                    __step(47)

                    local value077 = value074[index2]

                    if value077:sub(-5) == '.json' then
                        local matchStart = value077:find('.json', 1, true)
                        local value079 = matchStart
                        local value080 = value077:sub(matchStart, matchStart)

                        while value080 ~= '/' and value080 ~= '\\' and value080 ~= '' do
                            __step(48)

                            matchStart = matchStart - 1
                            value080 = value077:sub(matchStart, matchStart)
                        end

                        if value080 == '/' or value080 == '\\' then
                            table.insert(value075, value077:sub(matchStart + 1, value079 - 1))
                        end
                    end
                end

                return value075
            end
            function configManager:SetLibrary(library)
                self.Library = library
            end
            function configManager:LoadAutoloadConfig()
                configManager:CheckFolderTree()

                if isfileFn(self.Folder .. '/settings/autoload.txt') then
                    local value084 = readfile(self.Folder .. '/settings/autoload.txt')
                    local value085, value086 = self:Load(value084)

                    if not value085 then
                        return self.Library:Notify('Failed to load autoload config: ' .. value086)
                    end
                    if not SILENT then
                        self.Library:Notify(string.format('Auto loaded config %q', value084))
                    end
                end
            end
        end

        getgenv().SaveManager = configManager
    end
end
function Native.themes(captures)
    local themeManager = captures[1]
    local capture02 = captures[2]
    local capture00 = captures[0]

    return function()
        local value005 = cloneref or function(value006)
            return value006
        end
        local httpService = value005(game:GetService('HttpService'))
        local value008 = syn and syn.request or http and http.request or http_request or fluxus and fluxus.request or request
        local value009 = getcustomasset or getsynasset

        do
            themeManager.Folder = ''
            themeManager.Library = nil
            themeManager.BuiltInThemes = {
                Default = {
                    1,
                    httpService:JSONDecode('{\n\t\t\t\t"FontColor":"ffffff",\n\t\t\t\t"MainColor":"131313",\n\t\t\t\t"AccentColor":"a2cdff",\n\t\t\t\t"BackgroundColor":"151515",\n\t\t\t\t"OutlineColor":"212121",\n\t\t\t\t"RiskColor":"ff7425",\n\n\t\t\t\t"ItemType":"Unnamed Enhancements - Cracked",\n\t\t\t\t"SwordColor":"ffffff",\n\t\t\t\t"SwordTransparency":"0",\n\t\t\t\t"SwordReflectance":"0",\n\t\t\t\t"SwordSpeed":"0.15",\n\t\t\t\t"SwordMaterial":"Neon",\n\n\t\t\t\t"Contrast":"0",\n\t\t\t\t"Saturation":"0",\n\t\t\t\t"Brightness":"0",\n\n\t\t\t\t"BackColor":"000000",\n\t\t\t\t"BlurSize":"15",\n\t\t\t\t"BackTransparency":"0.7"\n\t\t\t}'),
                },
                ['Tokyo Night'] = {
                    1,
                    httpService:JSONDecode('{\n\t\t\t\t"FontColor":"ffffff",\n\t\t\t\t"MainColor":"191925",\n\t\t\t\t"AccentColor":"6956cb",\n\t\t\t\t"BackgroundColor":"15151e",\n\t\t\t\t"OutlineColor":"272727",\n\t\t\t\t"RiskColor":"fb5f5f",\n\n\t\t\t\t"ItemType":"Unnamed Enhancements - Cracked",\n\t\t\t\t"SwordColor":"ffffff",\n\t\t\t\t"SwordTransparency":"0",\n\t\t\t\t"SwordReflectance":"0",\n\t\t\t\t"SwordSpeed":"0.15",\n\t\t\t\t"SwordMaterial":"Neon",\n\n\t\t\t\t"Contrast":"0",\n\t\t\t\t"Saturation":"0",\n\t\t\t\t"Brightness":"0",\n\n\n\t\t\t\t"BackColor":"000000",\n\t\t\t\t"BlurSize":"15",\n\t\t\t\t"BackTransparency":"0.7"\n\t\t\t}'),
                },
                Nord = {
                    1,
                    httpService:JSONDecode('{\n\t\t\t\t"FontColor":"ffffff",\n\t\t\t\t"MainColor":"1c1e20",\n\t\t\t\t"AccentColor":"9effc8",\n\t\t\t\t"BackgroundColor":"1c1e20",\n\t\t\t\t"OutlineColor":"24282d",\n\t\t\t\t"RiskColor":"ff7a00",\n\n\t\t\t\t"ItemType":"Unnamed Enhancements - Cracked",\n\t\t\t\t"SwordColor":"ffffff",\n\t\t\t\t"SwordTransparency":"0",\n\t\t\t\t"SwordReflectance":"0",\n\t\t\t\t"SwordSpeed":"0.15",\n\t\t\t\t"SwordMaterial":"Neon",\n\n\t\t\t\t"Contrast":"0",\n\t\t\t\t"Saturation":"0",\n\t\t\t\t"Brightness":"0",\n\n\n\t\t\t\t"BackColor":"000000",\n\t\t\t\t"BlurSize":"15",\n\t\t\t\t"BackTransparency":"0.7"\n\t\t\t}'),
                },
                Skeet = {
                    1,
                    httpService:JSONDecode('{\n\t\t\t\t"FontColor":"ffffff",\n\t\t\t\t"MainColor":"131313",\n\t\t\t\t"AccentColor":"81ff54",\n\t\t\t\t"BackgroundColor":"151515",\n\t\t\t\t"OutlineColor":"2a2a2a",\n\t\t\t\t"RiskColor":"e50000",\n\n\t\t\t\t"ItemType":"Unnamed Enhancements - Cracked",\n\t\t\t\t"SwordColor":"ffffff",\n\t\t\t\t"SwordTransparency":"0",\n\t\t\t\t"SwordReflectance":"0",\n\t\t\t\t"SwordSpeed":"0.15",\n\t\t\t\t"SwordMaterial":"Neon",\n\n\t\t\t\t"Contrast":"0",\n\t\t\t\t"Saturation":"0",\n\t\t\t\t"Brightness":"0",\n\n\n\t\t\t\t"BackColor":"000000",\n\t\t\t\t"BlurSize":"15",\n\t\t\t\t"BackTransparency":"0.7"\n\t\t\t}'),
                },
                Fatality = {
                    1,
                    httpService:JSONDecode('{\n\t\t\t\t"FontColor":"ffffff",\n\t\t\t\t"MainColor":"181537",\n\t\t\t\t"AccentColor":"ca0756",\n\t\t\t\t"BackgroundColor":"201c46",\n\t\t\t\t"OutlineColor":"39335a",\n\t\t\t\t"RiskColor":"e50000",\n\n\t\t\t\t"ItemType":"Unnamed Enhancements - Cracked",\n\t\t\t\t"SwordColor":"ffffff",\n\t\t\t\t"SwordTransparency":"0",\n\t\t\t\t"SwordReflectance":"0",\n\t\t\t\t"SwordSpeed":"0.15",\n\t\t\t\t"SwordMaterial":"Neon",\n\n\t\t\t\t"Contrast":"0",\n\t\t\t\t"Saturation":"0",\n\t\t\t\t"Brightness":"0",\n\n\n\t\t\t\t"BackColor":"000000",\n\t\t\t\t"BlurSize":"15",\n\t\t\t\t"BackTransparency":"0.7"\n\t\t\t}'),
                },
                Neverlose = {
                    1,
                    httpService:JSONDecode('{\n\t\t\t\t"FontColor":"ffffff",\n\t\t\t\t"MainColor":"0c1014",\n\t\t\t\t"AccentColor":"01a3f1",\n\t\t\t\t"BackgroundColor":"0c0f14",\n\t\t\t\t"OutlineColor":"191919",\n\t\t\t\t"RiskColor":"e50000",\n\n\t\t\t\t"ItemType":"Unnamed Enhancements - Cracked",\n\t\t\t\t"SwordColor":"ffffff",\n\t\t\t\t"SwordTransparency":"0",\n\t\t\t\t"SwordReflectance":"0",\n\t\t\t\t"SwordSpeed":"0.15",\n\t\t\t\t"SwordMaterial":"Neon",\n\n\t\t\t\t"Contrast":"0",\n\t\t\t\t"Saturation":"0",\n\t\t\t\t"Brightness":"0",\n\n\n\t\t\t\t"BackColor":"000000",\n\t\t\t\t"BlurSize":"15",\n\t\t\t\t"BackTransparency":"0.7"\n\t\t\t}'),
                },
                Onetap = {
                    1,
                    httpService:JSONDecode('{\n\t\t\t\t"FontColor":"ffffff",\n\t\t\t\t"MainColor":"1e1d22",\n\t\t\t\t"AccentColor":"faa614",\n\t\t\t\t"BackgroundColor":"18181c",\n\t\t\t\t"OutlineColor":"313033",\n\t\t\t\t"RiskColor":"e50000",\n\n\t\t\t\t"ItemType":"Unnamed Enhancements - Cracked",\n\t\t\t\t"SwordColor":"ffffff",\n\t\t\t\t"SwordTransparency":"0",\n\t\t\t\t"SwordReflectance":"0",\n\t\t\t\t"SwordSpeed":"0.15",\n\t\t\t\t"SwordMaterial":"Neon",\n\n\t\t\t\t"Contrast":"0",\n\t\t\t\t"Saturation":"0",\n\t\t\t\t"Brightness":"0",\n\n\n\t\t\t\t"BackColor":"000000",\n\t\t\t\t"BlurSize":"15",\n\t\t\t\t"BackTransparency":"0.7"\n\t\t\t}'),
                },
                Imgui = {
                    1,
                    httpService:JSONDecode('{\n\t\t\t\t"FontColor":"ffffff",\n\t\t\t\t"MainColor":"151617",\n\t\t\t\t"AccentColor":"406ba8",\n\t\t\t\t"BackgroundColor":"151617",\n\t\t\t\t"OutlineColor":"242424",\n\t\t\t\t"RiskColor":"e50000",\n\n\t\t\t\t"ItemType":"Unnamed Enhancements - Cracked",\n\t\t\t\t"SwordColor":"ffffff",\n\t\t\t\t"SwordTransparency":"0",\n\t\t\t\t"SwordReflectance":"0",\n\t\t\t\t"SwordSpeed":"0.15",\n\t\t\t\t"SwordMaterial":"Neon",\n\n\t\t\t\t"Contrast":"0",\n\t\t\t\t"Saturation":"0",\n\t\t\t\t"Brightness":"0",\n\n\n\t\t\t\t"BackColor":"000000",\n\t\t\t\t"BlurSize":"15",\n\t\t\t\t"BackTransparency":"0.7"\n\t\t\t}'),
                },
                Iniuria = {
                    1,
                    httpService:JSONDecode('{\n\t\t\t\t"FontColor":"ffffff",\n\t\t\t\t"MainColor":"1e1d1e",\n\t\t\t\t"AccentColor":"c41275",\n\t\t\t\t"BackgroundColor":"1e1d1e",\n\t\t\t\t"OutlineColor":"33252b",\n\t\t\t\t"RiskColor":"e50000",\n\n\t\t\t\t"ItemType":"Unnamed Enhancements - Cracked",\n\t\t\t\t"SwordColor":"ffffff",\n\t\t\t\t"SwordTransparency":"0",\n\t\t\t\t"SwordReflectance":"0",\n\t\t\t\t"SwordSpeed":"0.15",\n\t\t\t\t"SwordMaterial":"Neon",\n\n\t\t\t\t"Contrast":"0",\n\t\t\t\t"Saturation":"0",\n\t\t\t\t"Brightness":"0",\n\n\n\t\t\t\t"BackColor":"000000",\n\t\t\t\t"BlurSize":"15",\n\t\t\t\t"BackTransparency":"0.7"\n\t\t\t}'),
                },
                Primordial = {
                    1,
                    httpService:JSONDecode('{\n\t\t\t\t"FontColor":"ffffff",\n\t\t\t\t"MainColor":"181818",\n\t\t\t\t"AccentColor":"d7a6b0",\n\t\t\t\t"BackgroundColor":"1f1f1f",\n\t\t\t\t"OutlineColor":"2a2a2a",\n\t\t\t\t"RiskColor":"e50000",\n\n\t\t\t\t"ItemType":"Unnamed Enhancements - Cracked",\n\t\t\t\t"SwordColor":"ffffff",\n\t\t\t\t"SwordTransparency":"0",\n\t\t\t\t"SwordReflectance":"0",\n\t\t\t\t"SwordSpeed":"0.15",\n\t\t\t\t"SwordMaterial":"Neon",\n\n\t\t\t\t"Contrast":"0",\n\t\t\t\t"Saturation":"0",\n\t\t\t\t"Brightness":"0",\n\n\n\t\t\t\t"BackColor":"000000",\n\t\t\t\t"BlurSize":"15",\n\t\t\t\t"BackTransparency":"0.7"\n\t\t\t}'),
                },
                Monolith = {
                    1,
                    httpService:JSONDecode('{\n\t\t\t\t"FontColor":"ffffff",\n\t\t\t\t"MainColor":"141115",\n\t\t\t\t"AccentColor":"c707bd",\n\t\t\t\t"BackgroundColor":"171417",\n\t\t\t\t"OutlineColor":"272427",\n\t\t\t\t"RiskColor":"e50000",\n\n\t\t\t\t"ItemType":"Unnamed Enhancements - Cracked",\n\t\t\t\t"SwordColor":"ffffff",\n\t\t\t\t"SwordTransparency":"0",\n\t\t\t\t"SwordReflectance":"0",\n\t\t\t\t"SwordSpeed":"0.15",\n\t\t\t\t"SwordMaterial":"Neon",\n\n\t\t\t\t"Contrast":"0",\n\t\t\t\t"Saturation":"0",\n\t\t\t\t"Brightness":"0",\n\n\n\t\t\t\t"BackColor":"000000",\n\t\t\t\t"BlurSize":"15",\n\t\t\t\t"BackTransparency":"0.7"\n\t\t\t}'),
                },
                V3rmillion = {
                    1,
                    httpService:JSONDecode('{\n\t\t\t\t"FontColor":"ffffff",\n\t\t\t\t"MainColor":"202020",\n\t\t\t\t"AccentColor":"cd1818",\n\t\t\t\t"BackgroundColor":"202020",\n\t\t\t\t"OutlineColor":"2a2a2a",\n\t\t\t\t"RiskColor":"e50000",\n\n\t\t\t\t"ItemType":"Unnamed Enhancements - Cracked",\n\t\t\t\t"SwordColor":"ffffff",\n\t\t\t\t"SwordTransparency":"0",\n\t\t\t\t"SwordReflectance":"0",\n\t\t\t\t"SwordSpeed":"0.15",\n\t\t\t\t"SwordMaterial":"Neon",\n\n\t\t\t\t"Contrast":"0",\n\t\t\t\t"Saturation":"0",\n\t\t\t\t"Brightness":"0",\n\n\n\t\t\t\t"BackColor":"000000",\n\t\t\t\t"BlurSize":"15",\n\t\t\t\t"BackTransparency":"0.7"\n\t\t\t}'),
                },
                Dark = {
                    1,
                    httpService:JSONDecode('{\n\t\t\t\t"FontColor":"ffffff",\n\t\t\t\t"MainColor":"0a0a0a",\n\t\t\t\t"AccentColor":"5945ff",\n\t\t\t\t"BackgroundColor":"0a0a0a",\n\t\t\t\t"OutlineColor":"171717",\n\t\t\t\t"RiskColor":"e50000",\n\n\t\t\t\t"ItemType":"Unnamed Enhancements - Cracked",\n\t\t\t\t"SwordColor":"ffffff",\n\t\t\t\t"SwordTransparency":"0",\n\t\t\t\t"SwordReflectance":"0",\n\t\t\t\t"SwordSpeed":"0.15",\n\t\t\t\t"SwordMaterial":"Neon",\n\n\t\t\t\t"Contrast":"0",\n\t\t\t\t"Saturation":"0",\n\t\t\t\t"Brightness":"0",\n\n\n\t\t\t\t"BackColor":"000000",\n\t\t\t\t"BlurSize":"15",\n\t\t\t\t"BackTransparency":"0.7"\n\t\t\t}'),
                },
            }

            function themeManager:ApplyTheme(themeName)
                if not themeName then
                    return
                end

                local value012 = self:GetCustomTheme(themeName)
                local value013 = value012 or self.BuiltInThemes[themeName]

                if not value013 then
                    return
                end
                if self.Library.InnerVideoBackground ~= nil then
                    self.Library.InnerVideoBackground.Visible = false
                end

                local value014 = value013[2]

                for key, value in next, value012 or value014 do
                    __step(2052)

                    if key:find('Color') then
                        self.Library[key] = Color3.fromHex(value)

                        if capture00[key] then
                            capture00[key]:SetValueRGB(Color3.fromHex(value))
                        end
                    else
                        self.Library[key] = value

                        if capture00[key] then
                            capture00[key]:SetValue(value)
                        end
                    end
                end

                self:ThemeUpdate()
            end
            function themeManager:ThemeUpdate()
                if self.Library.InnerVideoBackground ~= nil then
                    self.Library.InnerVideoBackground.Visible = false
                end

                local value018 = {
                    'Contrast',
                    'Saturation',
                    'Brightness',
                    'BlurSize',
                    'FontColor',
                    'RiskColor',
                    'MainColor',
                    'AccentColor',
                    'BackgroundColor',
                    capture02[3][capture02[2] ],
                    'SwordColor',
                    'ItemType',
                    'BackTransparency',
                    'BackColor',
                    'SwordTransparency',
                    'SwordReflectance',
                    'SwordMaterial',
                    'SwordSpeed',
                }

                for key2, value2 in next, value018 do
                    __step(2053)

                    if capture00 and capture00[value2] then
                        self.Library[value2] = capture00[value2].Value
                    end
                end

                self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor)

                self.Library:UpdateColorsUsingRegistry()
            end
            function themeManager:LoadDefault()
                local value022 = 'Default'
                local value023 = isfile(self.Folder .. '/themes/default.txt') and readfile(self.Folder .. '/themes/default.txt')
                local value024 = true

                if value023 then
                    if self.BuiltInThemes[value023] then
                        value022 = value023
                    elseif self:GetCustomTheme(value023) then
                        value022 = value023
                        value024 = false
                    end
                elseif self.BuiltInThemes[self.DefaultTheme] then
                    value022 = self.DefaultTheme
                end
                if value024 then
                    capture00.ThemeManager_ThemeList:SetValue(value022)
                else
                    self:ApplyTheme(value022)
                end
            end
            function themeManager:SaveDefault(themeName2)
                writefile(self.Folder .. '/themes/default.txt', themeName2)
            end
            function themeManager:Delete(fileName)
                if not fileName then
                    return false, 'no config file is selected'
                end

                local value029 = self.Folder .. '/themes/' .. fileName

                if not isfile(value029) then
                    return false, 'invalid file'
                end

                local success, resultOrError = pcall(delfile, value029)

                if not success then
                    return false, 'delete file error'
                end

                return true
            end
            function themeManager:GetCustomTheme(fileName2)
                if not fileName2 then
                    return
                end

                local value034 = self.Folder .. '/themes/' .. fileName2

                if not isfile(value034) then
                    return nil
                end

                local value035 = readfile(value034)
                local success2, resultOrError2 = pcall(httpService.JSONDecode, httpService, value035)

                if not success2 then
                    return nil
                end

                return resultOrError2
            end
            function themeManager:SaveCustomTheme(fileName3)
                if not fileName3 or fileName3:gsub(' ', '') == '' then
                    return self.Library:Notify('Invalid file name for theme (empty)', 3)
                end

                local value040 = {}
                local value041 = {
                    'Contrast',
                    'Saturation',
                    'Brightness',
                    'BlurSize',
                    'FontColor',
                    'RiskColor',
                    'MainColor',
                    'AccentColor',
                    'BackgroundColor',
                    capture02[3][capture02[2] ],
                    'ItemType',
                    'SwordColor',
                    'BackTransparency',
                    'BackColor',
                    'SwordTransparency',
                    'SwordReflectance',
                    'SwordMaterial',
                    'SwordSpeed',
                }

                for key3, value3 in next, value041 do
                    __step(2054)

                    if capture00[value3] then
                        if not value3:find('Color') then
                            value040[value3] = capture00[value3].Value
                        else
                            value040[value3] = capture00[value3].Value:ToHex()
                        end
                    end
                end

                writefile(self.Folder .. '/themes/' .. fileName3, httpService:JSONEncode(value040))
            end
            function themeManager:ReloadCustomThemes()
                local value045 = listfiles(self.Folder .. '/themes')
                local value046 = {}

                for index = 1, #value045 do
                    __step(2055)

                    local value048 = value045[index]

                    if value048:sub(-5) == '.json' then
                        local matchStart = value048:find('.json', 1, true)
                        local value050 = value048:sub(matchStart, matchStart)

                        while value050 ~= '/' and value050 ~= '\\' and value050 ~= '' do
                            __step(2056)

                            matchStart = matchStart - 1
                            value050 = value048:sub(matchStart, matchStart)
                        end

                        if value050 == '/' or value050 == '\\' then
                            table.insert(value046, value048:sub(matchStart + 1))
                        end
                    end
                end

                return value046
            end
            function themeManager:SetLibrary(library)
                self.Library = library
            end
            function themeManager:BuildFolderTree()
                local value054 = {}
                local value055 = self.Folder:split('/')

                for index2 = 1, #value055 do
                    __step(2057)

                    value054[#value054 + 1] = table.concat(value055, '/', 1, index2)
                end

                table.insert(value054, self.Folder .. '/themes')

                for index3 = 1, #value054 do
                    __step(2058)

                    local value058 = value054[index3]

                    if not isfolder(value058) then
                        makefolder(value058)
                    end
                end
            end
            function themeManager:SetFolder(folder)
                self.Folder = folder

                self:BuildFolderTree()
            end
            function themeManager:CreateGroupBox(tab)
                assert(self.Library, 'Must set ThemeManager.Library first!')

                return tab:AddLeftTabbox()
            end
            function themeManager:ApplyToTab(tab2)
                assert(self.Library, 'Must set ThemeManager.Library first!')

                local value065 = self:CreateGroupBox(tab2)

                self:CreateThemeManager(value065)
            end
            function themeManager:ApplyToGroupbox(groupbox)
                assert(self.Library, 'Must set ThemeManager.Library first!')
                self:CreateThemeManager(groupbox)
            end
        end

        getgenv().ThemeManager = themeManager
    end
end
function Native.keyPicker(captures)
    local capture07 = captures[7]
    local capture09 = captures[9]
    local capture03 = captures[3]
    local capture02 = captures[2]
    local capture08 = captures[8]
    local capture00 = captures[0]
    local capture06 = captures[6]
    local capture05 = captures[5]
    local capture04 = captures[4]
    local capture10 = captures[10]
    local capture01 = captures[1]

    return function()
        local value013 = capture03.Modes or {
            'Always',
            'Toggle',
            'Hold',
        }
        local value014 = capture04:AddContextMenu(capture02)
        local value015 = {}

        for key, value in value013 do
            __step(49)

            local value018

            value018 = value014:AddOption(value, function()
                capture00.Mode = value
                value018.TextColor3 = capture04.AccentColor

                for key2, value2 in value015 do
                    __step(50)

                    if value2 ~= value018 then
                        value2.TextColor3 = key2 == capture00.Mode and capture04.AccentColor or capture04.FontColor
                    end
                end

                capture04:AttemptSave()
            end)

            value018:GetPropertyChangedSignal('TextColor3'):Connect(function()
                if value == capture00.Mode then
                    value018.TextColor3 = capture04.AccentColor
                else
                    value018.TextColor3 = capture04.FontColor
                end
            end)

            value015[value] = value018
        end

        if capture04.FlagCopying then
            value014:AddOption('Copy Flag', function()
                pcall(setclipboard, capture00.Idx)
                task.wait()
                capture04:Notify('Copied flag to clipboard!', 2)
                value014:Hide()
            end)
        end

        for key3, value3 in value015 do
            __step(51)

            value3.TextColor3 = key3 == capture00.Mode and capture04.AccentColor or capture04.FontColor
        end

        local value023 = function(value024)
            local mode = capture00.Mode

            mode = mode ~= 'Always' and capture00.Override and 'Override' or mode
            capture05.Text = string.format('[%s] %s (%s)', capture00.Value, capture03.Text, mode)
            capture05.Visible = true
            capture05.TextColor3 = value024 and capture04.AccentColor or capture04.FontColor
            capture04.RegistryMap[capture05].Properties.TextColor3 = value024 and 'AccentColor' or 'FontColor'
        end

        function capture00:Update()
            if not capture00.NoUI then
                local keypickerListMode = capture04.KeypickerListMode
                local value028 = capture00:GetState()

                if keypickerListMode == 'Active' and capture00.Parent.Type == 'Toggle' and (not value028 or not capture00.Parent.Value) then
                    capture05.Visible = false
                elseif keypickerListMode == 'Toggled' and capture00.Parent.Type == 'Toggle' and not capture00.Parent.Value then
                    capture05.Visible = false
                else
                    value023(value028)
                end
            else
                capture05.Visible = false
            end

            local value029 = 0
            local value030 = 0

            for key4, value4 in next, capture04.KeybindContainer:GetChildren()do
                __step(52)

                if value4:IsA('TextLabel') and value4.Visible then
                    value029 = value029 + 18

                    if value4.TextBounds.X > value030 then
                        value030 = value4.TextBounds.X
                    end
                end
            end

            capture04.KeybindFrame.Size = UDim2.new(0, math.max(value030 + 10, 210), 0, value029 + 23)
            capture04.KeybindFrame.Visible = capture04.KeypickerListVisible and value029 ~= 0
        end
        function capture00:OverrideState(overrideState)
            if self.Override == overrideState then
                return
            end

            self.Override = overrideState
            capture00.Toggled = false

            capture00:Update()
        end

        local isMouseButtonPressed, isKeyDown = capture01.IsMouseButtonPressed, capture01.IsKeyDown
        local mouseButton1, mouseButton2 = Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2
        local keyCode = Enum.KeyCode

        function capture00:GetState()
            local mode2 = capture00.Mode

            if mode2 == 'Always' then
                return true
            end

            local value7 = capture00.Value

            if value7 == '...' then
                return true
            end

            local value043 = nil

            if mode2 == 'Hold' then
                if value7 == 'MB1' or value7 == 'MB2' then
                    value043 = value7 == 'MB1' and isMouseButtonPressed(capture01, mouseButton1) or value7 == 'MB2' and isMouseButtonPressed(capture01, mouseButton2)
                else
                    value043 = isKeyDown(capture01, keyCode[value7])
                end
            else
                value043 = capture00.Toggled
            end
            if value043 and self.Override then
                capture00:OverrideState(false)
            end

            return value043 or self.Override
        end
        function capture00:SetValue(newValue)
            local value046, value047 = newValue[1], newValue[2]

            capture07.Text = value046
            capture00.Value, capture00.Mode = value046, value047

            for key5, value5 in value015 do
                __step(53)

                value5.TextColor3 = key5 == capture00.Mode and capture04.AccentColor or capture04.FontColor
            end

            capture00:Update()
        end
        function capture00:OnClick(callback)
            capture00.Clicked = callback
        end
        function capture00:OnChanged(callback2)
            capture00.Changed = callback2

            callback2(capture00.Value)
        end

        if capture08.Addons then
            table.insert(capture08.Addons, capture00)
        end

        function capture00:DoClick()
            if capture00.Override then
                capture00.Override = false
                capture00.Toggled = false
            end
            if capture08.Type == 'Toggle' and capture00.SyncToggleState then
                capture08:SetValue(not capture08.Value)
            end

            capture04:SafeCallback(capture00.Callback, capture00.Toggled)
            capture04:SafeCallback(capture00.Clicked, capture00.Toggled)
        end
        function capture00:SetupConnection(connection)
            table.insert(self.Connections, connection)
            capture04:GiveSignal(connection)
        end
        function capture00:Remove()
            capture10[capture06] = nil

            for key6, value6 in capture00.Connections do
                __step(54)
                value6:Disconnect()
            end

            table.clear(capture00)
            capture02:Destroy()
            capture05:Destroy()
        end
        function capture00:SetModePickerVisibility(visible)
            capture09.Visible = visible
        end
        function capture00:GetModePickerVisibility()
            return capture09.Visible
        end

        local value063 = false
        local value064 = {
            [Enum.KeyCode.Escape] = true,
            [Enum.KeyCode.Backspace] = true,
        }

        capture02.InputBegan:Connect(function(input)
            if not value063 and input.UserInputType == Enum.UserInputType.MouseButton1 and not capture04:MouseIsOverOpenedFrame() then
                value063 = true
                capture07.Text = ''

                local value066
                local value067 = ''

                task.spawn(function()
                    while not value066 do
                        __step(55)

                        if value067 == '...' then
                            value067 = ''
                        end

                        value067 = value067 .. '.'
                        capture07.Text = value067

                        wait(0.4)
                    end
                end)
                wait(0.2)

                local value068

                value068 = capture01.InputBegan:Connect(function(input2)
                    local value070

                    if input2.UserInputType == Enum.UserInputType.Keyboard then
                        value070 = value064[input2.KeyCode] and '...' or input2.KeyCode.Name
                    elseif input2.UserInputType == Enum.UserInputType.MouseButton1 then
                        value070 = 'MB1'
                    elseif input2.UserInputType == Enum.UserInputType.MouseButton2 then
                        value070 = 'MB2'
                    end

                    value066 = true
                    value063 = false
                    capture07.Text = value070
                    capture00.Value = value070

                    capture04:SafeCallback(capture00.ChangedCallback, input2.KeyCode or input2.UserInputType)
                    capture04:SafeCallback(capture00.Changed, input2.KeyCode or input2.UserInputType)
                    capture04:AttemptSave()
                    value068:Disconnect()
                end)
            end
        end)
        capture00:SetupConnection(capture01.InputBegan:Connect(function(input3, gameProcessed)
            if not value063 and not gameProcessed then
                if capture00.Mode == 'Toggle' then
                    local value8 = capture00.Value

                    if value8 == 'MB1' or value8 == 'MB2' then
                        if value8 == 'MB1' and input3.UserInputType == Enum.UserInputType.MouseButton1 or value8 == 'MB2' and input3.UserInputType == Enum.UserInputType.MouseButton2 then
                            capture00.Toggled = not capture00.Toggled

                            capture00:DoClick()
                        end
                    elseif input3.UserInputType == Enum.UserInputType.Keyboard then
                        if input3.KeyCode.Name == value8 then
                            capture00.Toggled = not capture00.Toggled

                            capture00:DoClick()
                        end
                    end
                end

                capture00:Update()
            end
        end))
        capture00:SetupConnection(capture01.InputEnded:Connect(function(input4)
            if not value063 then
                capture00:Update()
            end
        end))
        capture00:Update()

        capture10[capture06] = capture00
    end
end
function Native.toggle(captures)
    local capture10 = captures[10]
    local capture01 = captures[1]
    local capture06 = captures[6]
    local capture12 = captures[12]
    local capture11 = captures[11]
    local capture13 = captures[13]
    local capture09 = captures[9]
    local capture07 = captures[7]
    local capture05 = captures[5]
    local capture02 = captures[2]
    local capture03 = captures[3]
    local capture04 = captures[4]
    local capture14 = captures[14]
    local capture08 = captures[8]
    local capture00 = captures[0]

    return function()
        function capture00:Display()
            capture02.BackgroundColor3 = capture00.Value and capture03.AccentColor or capture03.MainColor
            capture02.BorderColor3 = capture00.Value and capture03.AccentColorDark or capture03.OutlineColor
            capture03.RegistryMap[capture02].Properties.BackgroundColor3 = capture00.Value and 'AccentColor' or 'MainColor'
            capture03.RegistryMap[capture02].Properties.BorderColor3 = capture00.Value and 'AccentColorDark' or capture13[3][capture13[2] ]
        end

        capture00.UpdateColors = capture00.Display

        function capture00:OnChanged(callback)
            table.insert(capture00.ChangedFuncs, callback)
            callback(capture00.Value)
        end
        function capture00:SetValue(newValue)
            if capture00.SettingValue then
                return
            end

            capture00.SettingValue = true
            newValue = not not newValue
            capture00.Value = newValue

            capture00:Display()

            for key, value in next, capture00.Addons do
                __step(26)

                if value.Type == 'KeyPicker' and value.SyncToggleState then
                    value.Toggled = newValue

                    value:Update()
                end
            end

            capture03:SafeCallback(capture00.Callback, newValue)

            for key2, value2 in capture00.ChangedFuncs do
                __step(27)
                capture03:SafeCallback(value2, newValue)
            end

            capture03:UpdateDependencyBoxes()

            capture00.SettingValue = false
        end
        function capture00:SetVisible(visible)
            capture00.Visible = visible
            capture04.Visible = capture00.Visible

            if Blank then
                Blank.Visible = capture00.Visible
            end

            capture01:Resize()
        end
        function capture00:Remove()
            for key3, value3 in capture07 do
                __step(28)
                value3:Destroy()
            end

            capture09[capture05] = nil

            capture06:Destroy()
            table.clear(capture00)
            capture01:Resize()
        end

        capture10.InputBegan:Connect(function(input)
            if capture03.IsDragging then
                return
            end
            if input.UserInputType == Enum.UserInputType.MouseButton1 and not capture03:MouseIsOverOpenedFrame() or input.UserInputType == Enum.UserInputType.Touch then
                capture00:SetValue(not capture00.Value)
                capture03:AttemptSave()
            end
        end)

        if capture03.FlagCopying then
            local value032 = capture03:AddContextMenu(capture04, capture10)

            value032:AddOption('Copy Flag', function()
                pcall(setclipboard, capture00.Idx)
                task.wait()
                capture03:Notify('Copied flag to clipboard!', 2)
                value032:Hide()
            end)
        end
        if capture00.Risky then
            capture03:RemoveFromRegistry(capture08)

            capture08.TextColor3 = capture03.RiskColor

            capture03:AddToRegistry(capture08, {
                TextColor3 = 'RiskColor',
            })
        end

        capture00:Display()
        table.insert(capture07, capture01:AddBlank(capture11.BlankSize or 7))
        capture01:Resize()

        capture00.ColorPickerCount = 0
        capture00.ToggleRegion = capture10
        capture00.TextLabel = capture08
        capture00.Container = capture12

        setmetatable(capture00, capture14)

        capture09[capture05] = capture00

        capture03:UpdateDependencyBoxes()
    end
end
function Native.slider(captures)
    local capture04 = captures[4]
    local capture03 = captures[3]
    local capture06 = captures[6]
    local capture11 = captures[11]
    local capture02 = captures[2]
    local capture08 = captures[8]
    local userInputService = captures[16]
    local capture10 = captures[10]
    local capture07 = captures[7]
    local capture00 = captures[0]
    local capture13 = captures[13]
    local slider = captures[1]
    local capture05 = captures[5]
    local capture12 = captures[12]
    local capture15 = captures[15]
    local capture17 = captures[17]
    local capture14 = captures[14]
    local capture09 = captures[9]

    return function()
        function slider:UpdateColors()
            capture03.BackgroundColor3 = capture07.AccentColor
            capture03.BorderColor3 = capture07.AccentColorDark
        end
        function slider:Display()
            local value022 = capture04.Suffix or ''

            if capture04.Compact then
                capture10.Text = capture04.Text .. ': ' .. slider.Value .. value022
            elseif capture04.HideMax then
                capture10.Text = string.format('%s', slider.Value .. value022)
            else
                capture10.Text = string.format('%s/%s', slider.Value .. value022, slider.Max .. value022)
            end

            local value023 = capture07:MapValue(slider.Value, slider.Min, slider.Max, 0, 1)

            if capture05[3][capture05[2] ] then
                capture05[3][capture05[2] ]:Cancel()
            end

            capture05[3][capture05[2] ] = capture09:Create(capture03, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(value023, 0, 1, 0),
            })

            capture05[3][capture05[2] ]:Play()

            capture08.Visible = not (value023 == 1 or value023 == 0)
        end
        function slider:OnChanged(callback)
            table.insert(slider.ChangedFuncs, callback)
            callback(slider.Value)
        end

        local function value026(value027)
            if slider.Increment then
                local value028 = math.round(value027 / slider.Increment) * slider.Increment

                return tonumber(string.format('%.10f', value028))
            elseif slider.Rounding == 0 then
                return math.floor(value027)
            end

            return tonumber(string.format('%.' .. slider.Rounding .. 'f', value027))
        end

        function slider:GetValueFromXOffset(offsetX)
            return value026(capture07:MapValue(offsetX, 0, slider.MaxSize, slider.Min, slider.Max)) + 0
        end
        function slider:Remove()
            for key, value in capture15 do
                __step(32)
                value:Destroy()
            end

            capture14[capture13] = nil

            slider.HolderFrame:Destroy()
            table.clear(slider)
            capture00:Resize()
        end
        function slider:SetValue(newValue)
            local value036 = tonumber(newValue)

            if not value036 then
                return
            end

            value036 = math.clamp(value036, slider.Min, slider.Max)
            slider.Value = value036

            slider:Display()
            capture07:SafeCallback(slider.Callback, slider.Value)

            for key2, value2 in self.ChangedFuncs do
                __step(33)
                capture07:SafeCallback(value2, value036)
            end
        end
        function slider:AddSlider(value040, value041)
            return capture11.AddSlider(capture00, value040, value041, slider)
        end

        capture12.InputBegan:Connect(function(input)
            if capture07.IsDragging then
                return
            end
            if input.UserInputType == Enum.UserInputType.MouseButton1 and not capture07:MouseIsOverOpenedFrame() then
                local value043 = capture06.X
                local offset = capture03.Size.X.Offset
                local value045 = value043 - (capture03.AbsolutePosition.X + offset)

                while(userInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)) do
                    __step(34)

                    local value046 = capture06.X
                    local value047 = math.clamp(offset + (value046 - value043) + value045, 0, slider.MaxSize)
                    local value048 = slider:GetValueFromXOffset(value047)
                    local value5 = slider.Value

                    slider.Value = value048

                    slider:Display()

                    if value048 ~= value5 then
                        capture07:SafeCallback(slider.Callback, slider.Value)

                        for key3, value3 in slider.ChangedFuncs do
                            __step(35)
                            capture07:SafeCallback(value3, value048)
                        end
                    end

                    capture17:Wait()
                end

                capture07:AttemptSave()
            end
            if input.UserInputType == Enum.UserInputType.Touch and not capture07:MouseIsOverOpenedFrame() then
                local value052 = input.Position.X
                local offset2 = capture03.Size.X.Offset
                local value054 = value052 - (capture03.AbsolutePosition.X + offset2)
                local value055 = true
                local value056

                value056 = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        value055 = false
                    end
                end)

                while value055 do
                    __step(36)

                    local value057 = input.Position.X
                    local value058 = math.clamp(offset2 + (value057 - value052) + value054, 0, slider.MaxSize)
                    local value059 = slider:GetValueFromXOffset(value058)
                    local value6 = slider.Value

                    slider.Value = value059

                    slider:Display()

                    if value059 ~= value6 then
                        capture07:SafeCallback(slider.Callback, slider.Value)

                        for key4, value4 in slider.ChangedFuncs do
                            __step(37)
                            capture07:SafeCallback(value4, value059)
                        end
                    end

                    capture17:Wait()
                end

                if value056 then
                    value056:Disconnect()
                end

                capture07:AttemptSave()
            end
        end)

        if capture07.FlagCopying then
            local value063 = capture07:AddContextMenu(capture12)

            value063:AddOption('Copy Flag', function()
                pcall(setclipboard, slider.Idx)
                task.wait()
                capture07:Notify('Copied flag to clipboard!', 2)
                value063:Hide()
            end)
        end

        slider:Display()

        if not capture02 then
            table.insert(capture15, capture00:AddBlank(capture04.BlankSize or 6))
            capture00:Resize()
        end

        capture14[capture13] = slider
    end
end
function Native.dropdown(captures)
    local capture07 = captures[7]
    local capture06 = captures[6]
    local dropdown = captures[0]
    local capture02 = captures[2]
    local capture09 = captures[9]
    local capture13 = captures[13]
    local capture14 = captures[14]
    local capture10 = captures[10]
    local capture04 = captures[4]
    local capture11 = captures[11]
    local capture15 = captures[15]
    local capture12 = captures[12]
    local capture08 = captures[8]
    local capture03 = captures[3]
    local capture05 = captures[5]
    local capture01 = captures[1]

    return function()
        local function value018()
            capture02.Position = UDim2.fromOffset(capture08.AbsolutePosition.X, capture08.AbsolutePosition.Y + capture08.Size.Y.Offset + 1)
        end
        local function value019(value020)
            local value021 = value020 or math.clamp(#dropdown.Values * 20, 0, capture07 * 20) + 1

            capture02.Size = UDim2.fromOffset(capture08.AbsoluteSize.X + 0.5, value021)
        end

        value018()
        value019()
        capture08:GetPropertyChangedSignal('AbsolutePosition'):Connect(value018)

        local value022 = capture01:Create(capture15[3][capture15[2] ], {
            BackgroundColor3 = capture01.MainColor,
            BorderColor3 = capture01.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 21,
            Parent = capture02,
        })

        capture01:AddToRegistry(value022, {
            BackgroundColor3 = 'MainColor',
            BorderColor3 = capture04[3][capture04[2] ],
        })

        local scrollingFrame = capture01:Create('ScrollingFrame', {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 21,
            Parent = value022,
            TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ScrollBarThickness = capture01.IsMobile and 15 or 3,
            ScrollBarImageColor3 = capture01.AccentColor,
        })

        capture01:AddToRegistry(scrollingFrame, {
            ScrollBarImageColor3 = 'AccentColor',
        })
        capture01:Create('UIListLayout', {
            Padding = UDim.new(0, 0),
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = scrollingFrame,
        })

        function dropdown:Display()
            local values = dropdown.Values
            local value026 = ''

            if capture03.Multi then
                for key, value in next, values do
                    __step(111)

                    if dropdown.Value[value] then
                        value026 = value026 .. value .. ', '
                    end
                end

                value026 = value026:sub(1, #value026 - 2)
            else
                value026 = dropdown.Value or ''
            end

            capture11.Text = value026 == '' and '...' or value026
        end
        function dropdown:GetActiveValues()
            if capture03.Multi then
                local value030 = {}

                for key2, value2 in next, dropdown.Value do
                    __step(112)
                    table.insert(value030, key2)
                end

                return value030
            else
                return dropdown.Value and 1 or 0
            end
        end
        function dropdown:BuildDropdownList()
            local values2 = dropdown.Values
            local value035 = {}

            for key3, value3 in next, scrollingFrame:GetChildren()do
                __step(113)

                if not value3:IsA('UIListLayout') then
                    value3:Destroy()
                end
            end

            local value038 = 0

            for key4, value4 in next, values2 do
                __step(114)

                local value041 = {}

                value038 = value038 + 1

                local imageButton = capture01:Create('ImageButton', {
                    BackgroundColor3 = capture01.MainColor,
                    BorderColor3 = capture01.OutlineColor,
                    BorderMode = Enum.BorderMode.Middle,
                    Size = UDim2.new(1, -1, 0, 20),
                    ZIndex = 23,
                    Active = true,
                    Parent = scrollingFrame,
                    Image = '',
                    Active = false,
                    AutoButtonColor = false,
                })

                capture01:AddToRegistry(imageButton, {
                    BackgroundColor3 = 'MainColor',
                    BorderColor3 = capture04[3][capture04[2] ],
                })

                local value043 = capture01:CreateLabel({
                    Active = false,
                    Size = UDim2.new(1, -6, 1, 0),
                    Position = UDim2.new(0, 6, 0, 0),
                    TextSize = 14,
                    Text = value4,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 25,
                    Parent = imageButton,
                })

                capture01:OnHighlight(imageButton, imageButton, {
                    BorderColor3 = capture04[3][capture04[2] ],
                    ZIndex = 24,
                }, {
                    BorderColor3 = capture04[3][capture04[2] ],
                    ZIndex = 23,
                })

                local value044

                if capture03.Multi then
                    value044 = dropdown.Value[value4]
                else
                    value044 = dropdown.Value == value4
                end

                function value041:UpdateButton()
                    if capture03.Multi then
                        value044 = dropdown.Value[value4]
                    else
                        value044 = dropdown.Value == value4
                    end

                    value043.TextColor3 = value044 and capture01.AccentColor or capture01.FontColor
                    capture01.RegistryMap[value043].Properties.TextColor3 = value044 and 'AccentColor' or 'FontColor'
                end

                value043.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        local value047 = not value044

                        if dropdown:GetActiveValues() == 1 and not value047 and not capture03.AllowNull then
                        else
                            if capture03.Multi then
                                value044 = value047

                                if value044 then
                                    dropdown.Value[value4] = true
                                else
                                    dropdown.Value[value4] = nil
                                end
                            else
                                value044 = value047

                                if value044 then
                                    dropdown.Value = value4
                                else
                                    dropdown.Value = nil
                                end

                                for key5, value5 in next, value035 do
                                    __step(115)
                                    value5:UpdateButton()
                                end
                            end

                            value041:UpdateButton()
                            dropdown:Display()
                            capture01:UpdateDependencyBoxes()
                            capture01:SafeCallback(dropdown.Callback, dropdown.Value)
                            capture01:SafeCallback(dropdown.Changed, dropdown.Value)
                            capture01:AttemptSave()
                        end
                    end
                end)
                value041:UpdateButton()

                value035[imageButton] = value041
            end

            dropdown:Display()

            scrollingFrame.CanvasSize = UDim2.fromOffset(0, value038 * 20 + 1)
            scrollingFrame.Visible = false
            scrollingFrame.Visible = true

            local value050 = math.clamp(value038 * 20, 0, capture07 * 20) + 1

            value019(value050)
        end
        function dropdown:SetValues(values3)
            if values3 then
                dropdown.Values = values3
            end

            dropdown:BuildDropdownList()
        end
        function dropdown:OpenDropdown()
            if capture01.IsMobile then
                capture01.CanDrag = false
            end

            capture02.Visible = true
            capture01.OpenedFrames[capture02] = true
            capture10.Rotation = 90

            value019()
        end
        function dropdown:CloseDropdown()
            if capture01.IsMobile then
                capture01.CanDrag = true
            end

            capture02.Visible = false
            capture01.OpenedFrames[capture02] = nil
            capture10.Rotation = 0
        end
        function dropdown:OnChanged(callback)
            dropdown.Changed = callback

            callback(dropdown.Value)
        end
        function dropdown:SetValue(newValue)
            if dropdown.Multi then
                local value059 = {}

                for key6, value6 in next, newValue do
                    __step(116)

                    if dropdown.Illegal or table.find(dropdown.Values, key6) then
                        value059[key6] = true
                    end
                end

                dropdown.Value = value059
            elseif not newValue then
                dropdown.Value = nil
            elseif dropdown.Illegal or table.find(dropdown.Values, newValue) then
                dropdown.Value = newValue
            end

            dropdown:BuildDropdownList()
            capture01:SafeCallback(dropdown.Callback, dropdown.Value)
            capture01:SafeCallback(dropdown.Changed, dropdown.Value)
        end
        function dropdown:Remove()
            for key7, value7 in capture13 do
                __step(117)
                value7:Destroy()
            end

            capture06[capture12] = nil

            capture08:Destroy()
            table.clear(dropdown)
        end

        capture08.InputBegan:Connect(function(input2)
            if capture01.IsDragging then
                return
            end
            if input2.UserInputType == Enum.UserInputType.MouseButton1 and not capture01:MouseIsOverOpenedFrame() or input2.UserInputType == Enum.UserInputType.Touch then
                if capture02.Visible then
                    dropdown:CloseDropdown()
                else
                    dropdown:OpenDropdown()
                end
            end
        end)
        capture14.InputBegan:Connect(function(input3)
            if capture01.IsDragging then
                return
            end
            if input3.UserInputType == Enum.UserInputType.MouseButton1 or input3.UserInputType == Enum.UserInputType.Touch then
                local absolutePosition, absoluteSize = capture02.AbsolutePosition, capture02.AbsoluteSize

                if capture09.X < absolutePosition.X or capture09.X > absolutePosition.X + absoluteSize.X or capture09.Y < absolutePosition.Y - 20 - 1 or capture09.Y > absolutePosition.Y + absoluteSize.Y then
                    dropdown:CloseDropdown()
                end
            end
        end)

        if capture01.FlagCopying then
            local value069 = capture01:AddContextMenu(capture08)

            value069:AddOption('Copy Flag', function()
                pcall(setclipboard, dropdown.Idx)
                task.wait()
                capture01:Notify('Copied flag to clipboard!', 2)
                value069:Hide()
            end)
        end

        dropdown:BuildDropdownList()
        dropdown:Display()

        local value070 = {}

        if typeof(capture03.Default) == 'string' then
            local matchStart = table.find(dropdown.Values, capture03.Default)

            if matchStart then
                table.insert(value070, matchStart)
            end
        elseif typeof(capture03.Default) == 'table' then
            for key8, value8 in next, capture03.Default do
                __step(118)

                local matchStart2 = table.find(dropdown.Values, value8)

                if matchStart2 then
                    table.insert(value070, matchStart2)
                end
            end
        elseif typeof(capture03.Default) == 'number' and dropdown.Values[capture03.Default] ~= nil then
            table.insert(value070, capture03.Default)
        end
        if next(value070) then
            for index = 1, #value070 do
                __step(119)

                local value076 = value070[index]

                if capture03.Multi then
                    dropdown.Value[dropdown.Values[value076] ] = true
                else
                    dropdown.Value = dropdown.Values[value076]
                end
                if not capture03.Multi then
                    break
                end
            end

            dropdown:BuildDropdownList()
            dropdown:Display()
        end

        table.insert(capture13, capture05:AddBlank(capture03.BlankSize or 5))
        capture05:Resize()

        capture06[capture12] = dropdown
    end
end
function Native.colorPicker(captures)
    local colorPicker = captures[0]
    local capture06 = captures[6]
    local capture10 = captures[10]
    local capture23 = captures[23]
    local capture07 = captures[7]
    local capture20 = captures[20]
    local capture01 = captures[1]
    local capture21 = captures[21]
    local capture08 = captures[8]
    local capture22 = captures[22]
    local capture18 = captures[18]
    local capture13 = captures[13]
    local userInputService = captures[17]
    local capture12 = captures[12]
    local capture11 = captures[11]
    local capture02 = captures[2]
    local capture09 = captures[9]
    local capture04 = captures[4]
    local capture15 = captures[15]
    local capture16 = captures[16]
    local capture14 = captures[14]
    local capture19 = captures[19]
    local capture05 = captures[5]
    local capture24 = captures[24]
    local capture03 = captures[3]

    return function()
        local value027 = capture03:AddContextMenu(capture15)

        value027:AddOption('Make gradient', function()
            local value028 = {}

            for key, value in capture18.Addons do
                __step(131)

                if value.Type == 'ColorPicker' then
                    table.insert(value028, value)
                end
            end

            if #value028 < 3 then
                value027:Hide()

                return capture03:Notify('not enough colors for a gradient.', 2)
            end

            local value6, value7 = value028[1].Value, value028[#value028].Value

            for index = 2, #value028 - 1 do
                __step(132)

                local value034 = value028[index]

                value034:SetValueRGB(value6:Lerp(value7, index / #value028), value034.Transparency)
            end

            capture03:Notify('created gradient!', 2)
            value027:Hide()
        end)
        value027:AddOption('Match color', function()
            local value035 = {}

            for key2, value2 in capture18.Addons do
                __step(133)

                if value2.Type == 'ColorPicker' then
                    table.insert(value035, value2)
                end
            end
            for key3, value3 in value035 do
                __step(134)
                value3:SetValueRGB(colorPicker.Value, value3.Transparency)
            end

            capture03:Notify('matched all colors!', 2)
            value027:Hide()
        end)
        value027:AddOption('Copy color', function()
            capture03.ColorClipboard = colorPicker

            capture03:Notify('Copied color!', 2)
            value027:Hide()
        end)
        value027:AddOption('Paste color', function()
            if not capture03.ColorClipboard then
                return capture03:Notify('You have not copied a color!', 2)
            end

            colorPicker:SetValueRGB(capture03.ColorClipboard.Value, capture03.ColorClipboard.Transparency)
            value027:Hide()
        end)

        if capture03.FlagCopying then
            value027:AddOption('Copy Flag', function()
                pcall(setclipboard, colorPicker.Idx)
                task.wait()
                capture03:Notify('Copied flag to clipboard!', 2)
                value027:Hide()
            end)
        end

        capture03:AddToRegistry(capture13, {
            BackgroundColor3 = 'BackgroundColor',
            BorderColor3 = capture02[3][capture02[2] ],
        })
        capture03:AddToRegistry(capture16, {
            BackgroundColor3 = 'AccentColor',
        })
        capture03:AddToRegistry(capture21, {
            BackgroundColor3 = 'BackgroundColor',
            BorderColor3 = capture02[3][capture02[2] ],
        })
        capture03:AddToRegistry(capture20, {
            BackgroundColor3 = 'MainColor',
            BorderColor3 = capture02[3][capture02[2] ],
        })
        capture03:AddToRegistry(capture24.Frame, {
            BackgroundColor3 = 'MainColor',
            BorderColor3 = capture02[3][capture02[2] ],
        })
        capture03:AddToRegistry(capture06, {
            TextColor3 = 'FontColor',
        })
        capture03:AddToRegistry(capture07, {
            TextColor3 = 'FontColor',
        })

        local value040 = {}

        for index2 = 0, 1, 0.1 do
            __step(135)
            table.insert(value040, ColorSequenceKeypoint.new(index2, Color3.fromHSV(index2, 1, 1)))
        end

        local uIGradient = capture03:Create('UIGradient', {
            Color = ColorSequence.new(value040),
            Rotation = 90,
            Parent = capture11,
        })

        capture07.FocusLost:Connect(function(value043)
            if value043 then
                local success, resultOrError = pcall(Color3.fromHex, capture07.Text)

                if success and typeof(resultOrError) == 'Color3' then
                    colorPicker.Hue, colorPicker.Sat, colorPicker.Vib = Color3.toHSV(resultOrError)
                end
            end

            colorPicker:Display()
        end)
        capture06.FocusLost:Connect(function(value046)
            if value046 then
                local value047, value048, value049 = capture06.Text:match('(%d+),%s*(%d+),%s*(%d+)')

                if value047 and value048 and value049 then
                    colorPicker.Hue, colorPicker.Sat, colorPicker.Vib = Color3.toHSV(Color3.fromRGB(value047, value048, value049))
                end
            end

            colorPicker:Display()
        end)

        function colorPicker:Display()
            colorPicker.Value = Color3.fromHSV(colorPicker.Hue, colorPicker.Sat, colorPicker.Vib)
            capture12.BackgroundColor3 = Color3.fromHSV(colorPicker.Hue, 1, 1)

            capture03:Create(capture15, {
                BackgroundColor3 = colorPicker.Value,
                BackgroundTransparency = colorPicker.Transparency,
                BorderColor3 = capture03:GetDarkerColor(colorPicker.Value),
            })

            if capture14[3][capture14[2] ] then
                capture14[3][capture14[2] ].BackgroundColor3 = colorPicker.Value
                capture23[3][capture23[2] ].Position = UDim2.new(1 - colorPicker.Transparency, 0, 0, 0)
            end

            capture09.Position = UDim2.new(colorPicker.Sat, 0, 1 - colorPicker.Vib, 0)
            capture22.Position = UDim2.new(0, 0, colorPicker.Hue, 0)
            capture07.Text = '#' .. colorPicker.Value:ToHex()
            capture06.Text = table.concat({
                math.floor(colorPicker.Value.R * 255),
                math.floor(colorPicker.Value.G * 255),
                math.floor(colorPicker.Value.B * 255),
            }, ', ')

            capture03:SafeCallback(colorPicker.Callback, colorPicker.Value)
            capture03:SafeCallback(colorPicker.Changed, colorPicker.Value)
        end
        function colorPicker:OnChanged(callback)
            colorPicker.Changed = callback

            callback(colorPicker.Value)
        end

        local value053 = false

        function colorPicker:Show()
            value053 = true

            for key4, value4 in next, capture03.OpenedFrames do
                __step(136)

                if key4.Name == 'Color' then
                    key4.Visible = false
                    capture03.OpenedFrames[key4] = nil
                end
            end

            capture10.Visible = true
            capture03.OpenedFrames[capture10] = true
        end
        function colorPicker:Hide()
            value053 = false
            capture10.Visible = false
            capture03.OpenedFrames[capture10] = nil
        end
        function colorPicker:SetValue(newValue, value060)
            local value061 = Color3.fromHSV(newValue[1], newValue[2], newValue[3])

            colorPicker.Transparency = value060 or 0

            colorPicker:SetHSVFromRGB(value061)
            colorPicker:Display()
        end
        function colorPicker:Remove()
            capture08[capture19] = nil

            table.clear(colorPicker)
        end
        function colorPicker:SetValueRGB(color, transparency)
            colorPicker.Transparency = transparency or 0

            colorPicker:SetHSVFromRGB(color)
            colorPicker:Display()
        end

        capture12.InputBegan:Connect(function(input)
            if capture03.IsDragging then
                return
            end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                local value067 = true
                local value068

                if input.UserInputType == Enum.UserInputType.Touch then
                    value068 = input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            value067 = false
                        end
                    end)
                end

                while value067 and (input.UserInputType == Enum.UserInputType.MouseButton1 and userInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or input.UserInputType == Enum.UserInputType.Touch) do
                    __step(137)

                    local value069 = input.UserInputType == Enum.UserInputType.MouseButton1 and capture05.X or input.Position.X
                    local value070 = input.UserInputType == Enum.UserInputType.MouseButton1 and capture05.Y or input.Position.Y
                    local value071, value072 = capture12.AbsolutePosition.X, capture12.AbsolutePosition.X + capture12.AbsoluteSize.X
                    local value073, value074 = capture12.AbsolutePosition.Y, capture12.AbsolutePosition.Y + capture12.AbsoluteSize.Y
                    local value075 = math.clamp(value069, value071, value072)
                    local value076 = math.clamp(value070, value073, value074)

                    colorPicker.Sat = (value075 - value071) / (value072 - value071)
                    colorPicker.Vib = 1 - (value076 - value073) / (value074 - value073)

                    colorPicker:Display()
                    capture01:Wait()
                end

                if value068 then
                    value068:Disconnect()
                end

                capture03:AttemptSave()
            end
        end)
        capture11.InputBegan:Connect(function(input2)
            if capture03.IsDragging then
                return
            end
            if input2.UserInputType == Enum.UserInputType.MouseButton1 or input2.UserInputType == Enum.UserInputType.Touch then
                local value078 = true
                local value079

                if input2.UserInputType == Enum.UserInputType.Touch then
                    value079 = input2.Changed:Connect(function()
                        if input2.UserInputState == Enum.UserInputState.End then
                            value078 = false
                        end
                    end)
                end

                while value078 and (input2.UserInputType == Enum.UserInputType.MouseButton1 and userInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or input2.UserInputType == Enum.UserInputType.Touch) do
                    __step(138)

                    local value080 = input2.UserInputType == Enum.UserInputType.MouseButton1 and capture05.Y or input2.Position.Y
                    local value081, value082 = capture11.AbsolutePosition.Y, capture11.AbsolutePosition.Y + capture11.AbsoluteSize.Y
                    local value083 = math.clamp(value080, value081, value082)

                    colorPicker.Hue = (value083 - value081) / (value082 - value081)

                    colorPicker:Display()
                    capture01:Wait()
                end

                if value079 then
                    value079:Disconnect()
                end

                capture03:AttemptSave()
            end
        end)
        capture15.InputBegan:Connect(function(input3)
            if capture03.IsDragging then
                return
            end
            if input3.UserInputType == Enum.UserInputType.MouseButton1 or input3.UserInputType == Enum.UserInputType.Touch then
                if not capture03:MouseIsOverOpenedFrame() then
                    if capture10.Visible then
                        colorPicker:Hide()
                    else
                        colorPicker:Show()
                    end
                end
            elseif input3.UserInputType == Enum.UserInputType.MouseButton2 and not capture03:MouseIsOverOpenedFrame() then
                colorPicker:Hide()
            end
        end)

        if capture14[3][capture14[2] ] then
            capture14[3][capture14[2] ].InputBegan:Connect(function(input4)
                if capture03.IsDragging then
                    return
                end
                if input4.UserInputType == Enum.UserInputType.MouseButton1 or input4.UserInputType == Enum.UserInputType.Touch then
                    local value086 = true
                    local value087

                    if input4.UserInputType == Enum.UserInputType.Touch then
                        value087 = input4.Changed:Connect(function()
                            if input4.UserInputState == Enum.UserInputState.End then
                                value086 = false
                            end
                        end)
                    end

                    while value086 and (input4.UserInputType == Enum.UserInputType.MouseButton1 and userInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or input4.UserInputType == Enum.UserInputType.Touch) do
                        __step(139)

                        local value088 = input4.UserInputType == Enum.UserInputType.MouseButton1 and capture05.X or input4.Position.X
                        local value089, value090 = capture14[3][capture14[2] ].AbsolutePosition.X, capture14[3][capture14[2] ].AbsolutePosition.X + capture14[3][capture14[2] ].AbsoluteSize.X
                        local value091 = math.clamp(value088, value089, value090)

                        colorPicker.Transparency = 1 - (value091 - value089) / (value090 - value089)

                        colorPicker:Display()
                        capture01:Wait()
                    end

                    if value087 then
                        value087:Disconnect()
                    end

                    capture03:AttemptSave()
                end
            end)
        end

        local value092 = function()
            if not value053 then
                return
            end

            local absolutePosition, absoluteSize = capture10.AbsolutePosition, capture10.AbsoluteSize

            if capture05.X < absolutePosition.X or capture05.X > absolutePosition.X + absoluteSize.X or capture05.Y < absolutePosition.Y - 20 - 1 or capture05.Y > absolutePosition.Y + absoluteSize.Y then
                colorPicker:Hide()
            end
        end

        for key5, value5 in {
            Enum.UserInputType.MouseButton1,
            Enum.UserInputType.MouseButton2,
        }do
            __step(140)
            capture03:BindToInput(value5, value092)
        end

        colorPicker:Display()

        colorPicker.DisplayFrame = capture15
        capture08[capture19] = colorPicker
        capture04.Addons = capture04.Addons or {}

        table.insert(capture04.Addons, colorPicker)

        if capture04.ToggleRegion then
            capture04.ColorPickerCount = capture04.ColorPickerCount + 1

            if capture04.ColorPickerCount > 2 then
                capture04.ToggleRegion.Size = capture04.ToggleRegion.Size - UDim2.new(0, 32, 0, 0)
            end
        end
    end
end
function Native.tabBox(captures)
    local capture04 = captures[4]
    local tabContainer = captures[3]
    local capture08 = captures[8]
    local capture01 = captures[1]
    local capture07 = captures[7]
    local capture06 = captures[6]
    local capture00 = captures[0]
    local capture02 = captures[2]
    local capture05 = captures[5]
    local capture09 = captures[9]

    return function()
        local tabboxes = capture08.Tabboxes

        function tabContainer:Remove()
            capture04:Destroy()
            table.clear(tabContainer)

            tabboxes[capture06.Name or ''] = nil
        end
        function tabContainer:AddTab(value015, value016)
            local panel = {}
            local value018 = capture00:Create(capture01[3][capture01[2] ], {
                BackgroundColor3 = capture00.MainColor,
                BorderSizePixel = 1,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                Size = UDim2.new(0.5, 0, 1, 0),
                ZIndex = 6,
                Parent = capture02,
            })
            local value019 = capture00:Create(capture01[3][capture01[2] ], {
                BackgroundColor3 = capture00.AccentColor,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, 1),
                ZIndex = 8,
                Visible = value016 or false,
                Parent = value018,
            })

            capture00:AddToRegistry(value019, {
                BackgroundColor3 = 'AccentColor',
            })

            local value020 = value016 and UDim2.new(1, -1, 1, 0) or UDim2.new(1, 0, 1, 0)
            local value021 = capture00:Create(capture01[3][capture01[2] ], {
                BackgroundTransparency = 0,
                BackgroundColor3 = capture00.MainColor,
                BorderSizePixel = 1,
                BorderColor3 = capture00.OutlineColor,
                BorderMode = Enum.BorderMode.Inset,
                Size = value020,
                ZIndex = 7,
                Parent = value018,
            })

            capture00:AddToRegistry(value018, {
                BackgroundColor3 = 'MainColor',
            })
            capture00:AddToRegistry(value021, {
                BackgroundColor3 = 'MainColor',
                BorderColor3 = capture09[3][capture09[2] ],
            })

            local value022 = capture00:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0),
                TextSize = 14,
                Text = value015,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 7,
                Parent = value018,
            })
            local value023 = capture00:Create(capture01[3][capture01[2] ], {
                BackgroundColor3 = capture00.BackgroundColor,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 1, 0),
                Size = UDim2.new(1, 0, 0, 1),
                Visible = false,
                ZIndex = 9,
                Parent = value018,
            })

            capture00:AddToRegistry(value023, {
                BackgroundColor3 = 'BackgroundColor',
            })

            local value024 = capture00:Create(capture01[3][capture01[2] ], {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 4, 0, 20),
                Size = UDim2.new(1, -4, 1, -20),
                ZIndex = 1,
                Visible = false,
                Parent = capture07,
            })

            capture00:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = value024,
            })

            function panel:Show()
                for key, value in next, tabContainer.Tabs do
                    __step(56)
                    value:Hide()
                end

                value024.Visible = true
                value023.Visible = true
                value021.Visible = false
                value019.Visible = true
                value018.BackgroundColor3 = capture00.BackgroundColor
                capture00.RegistryMap[value018].Properties.BackgroundColor3 = 'BackgroundColor'

                panel:Resize()
            end
            function panel:Hide()
                value024.Visible = false
                value023.Visible = false
                value021.Visible = true
                value019.Visible = false
                value018.BackgroundColor3 = capture00.MainColor
                capture00.RegistryMap[value018].Properties.BackgroundColor3 = 'MainColor'
            end
            function panel:Resize()
                local value030 = 0

                for key2, value2 in next, tabContainer.Tabs do
                    __step(57)

                    value030 = value030 + 1
                end
                for key3, value3 in next, capture02:GetChildren()do
                    __step(58)

                    if not value3:IsA('UIListLayout') then
                        value3.Size = UDim2.new(1 / value030, 0, 1, 0)
                    end
                end

                if not value024.Visible then
                    return
                end

                local value035 = 0

                for key4, value4 in next, panel.Container:GetChildren()do
                    __step(59)

                    if not value4:IsA('UIListLayout') and value4.Visible then
                        value035 = value035 + value4.Size.Y.Offset
                    end
                end

                capture04.Size = UDim2.new(1, 0, 0, 20 + value035 + 2 + 2)
            end

            value018.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and not capture00:MouseIsOverOpenedFrame() or input.UserInputType == Enum.UserInputType.Touch then
                    panel:Show()
                    panel:Resize()
                end
            end)

            panel.Container = value024
            tabContainer.Tabs[value015] = panel

            setmetatable(panel, capture05)
            panel:AddBlank(3)
            panel:Resize()

            if #capture02:GetChildren() == 2 then
                panel:Show()
            end

            return panel
        end

        tabboxes[capture06.Name or ''] = tabContainer
    end
end
function Native.tab(captures)
    local capture15 = captures[15]
    local capture00 = captures[0]
    local capture10 = captures[10]
    local capture12 = captures[12]
    local capture03 = captures[3]
    local tab = captures[2]
    local capture13 = captures[13]
    local capture07 = captures[7]
    local capture04 = captures[4]
    local capture11 = captures[11]
    local capture05 = captures[5]
    local capture01 = captures[1]
    local capture06 = captures[6]
    local capture08 = captures[8]
    local capture14 = captures[14]
    local capture09 = captures[9]

    return function()
        if capture01.IsMobile then
            local value018 = {
                Left = tick(),
                Right = tick(),
            }

            capture03:GetPropertyChangedSignal('CanvasPosition'):Connect(function()
                capture01.CanDrag = false

                local value019 = tick()

                value018.Left = value019

                task.wait(0.15)

                if value018.Left == value019 then
                    capture01.CanDrag = true
                end
            end)
            capture05:GetPropertyChangedSignal('CanvasPosition'):Connect(function()
                capture01.CanDrag = false

                local value020 = tick()

                value018.Right = value020

                task.wait(0.15)

                if value018.Right == value020 then
                    capture01.CanDrag = true
                end
            end)
        end

        for key, value in next, {capture03, capture05}do
            __step(143)
            value:WaitForChild('UIListLayout'):GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                value.CanvasSize = UDim2.fromOffset(0, value.UIListLayout.AbsoluteContentSize.Y)
            end)
        end

        function tab:Resize()
            if capture04[3][capture04[2] ].Visible == true then
                local value024 = 10

                for key2, value2 in next, capture14[3][capture14[2] ]:GetChildren()do
                    __step(144)

                    if not value2:IsA('UIListLayout') and value2.Visible then
                        value024 = value024 + value2.Size.Y.Offset
                    end
                end

                capture04[3][capture04[2] ].Size = UDim2.new(1, -10, 0, value024)
                value024 = value024 + 10
                capture03.Position = UDim2.new(0, 7, 0, 7 + value024)
                capture03.Size = UDim2.new(0.5, -10, 1, -14 - value024)
                capture05.Position = UDim2.new(0.5, 5, 0, 7 + value024)
                capture05.Size = UDim2.new(0.5, -10, 1, -14 - value024)
            else
                capture03.Position = UDim2.new(0, 7, 0, 7)
                capture03.Size = UDim2.new(0.5, -10, 1, -14)
                capture05.Position = UDim2.new(0.5, 5, 0, 7)
                capture05.Size = UDim2.new(0.5, -10, 1, -14)
            end
        end
        function tab:UpdateWarningBox(value028)
            if typeof(value028.Visible) == 'boolean' then
                capture04[3][capture04[2] ].Visible = value028.Visible

                tab:Resize()
            end
            if typeof(value028.Title) == 'string' then
                capture11[3][capture11[2] ].Text = value028.Title
            end
            if typeof(value028.Text) == 'string' then
                capture09[3][capture09[2] ].Text = value028.Text

                local value029 = select(2, capture01:GetTextBounds(value028.Text, capture01.Font, 14, Vector2.new(capture09[3][capture09[2] ].AbsoluteSize.X, math.huge)))

                capture09[3][capture09[2] ].Size = UDim2.new(1, -4, 0, value029)

                tab:Resize()
            end
        end
        function tab:ShowTab()
            capture01.ActiveTab = capture10

            for key3, value3 in next, capture12.Tabs do
                __step(145)
                value3:HideTab()
            end

            capture01.RegistryMap[capture06].Properties.BackgroundColor3 = 'BackgroundColor'
            capture06.BackgroundColor3 = capture01.MainColor
            capture13.Visible = true
            capture15.Color = Color3.fromRGB(0, 0, 0)
            capture07.TextColor3 = capture01.FontColor
            capture08.Visible = true

            tab:Resize()
        end
        function tab:HideTab()
            capture06.BackgroundColor3 = capture01.BackgroundColor
            capture01.RegistryMap[capture06].Properties.BackgroundColor3 = 'MainColor'
            capture15.Color = Color3.fromRGB(25, 25, 25)
            capture07.TextColor3 = capture01:GetDarkerColor(capture01.FontColor)
            capture08.Visible = false
            capture13.Visible = false
        end
        function tab:SetLayoutOrder(order)
            capture06.LayoutOrder = order

            capture00:ApplyLayout()
        end
        function tab:GetSides()
            return {
                Left = capture03,
                Right = capture05,
            }
        end
        function tab:AddLeftGroupbox(value038)
            return self:AddGroupbox({
                Side = 1,
                Name = value038,
            })
        end
        function tab:AddRightGroupbox(value040)
            return self:AddGroupbox({
                Side = 2,
                Name = value040,
            })
        end
        function tab:AddLeftTabbox(value042)
            return tab:AddTabbox({
                Name = value042,
                Side = 1,
            })
        end
        function tab:AddRightTabbox(value044)
            return tab:AddTabbox({
                Name = value044,
                Side = 2,
            })
        end
        function tab:Remove()
            table.clear(tab)
            capture13:Destroy()
            capture06:Destroy()

            capture12.Tabs[capture10] = nil
        end

        capture06.InputBegan:Connect(function(input)
            if capture01.IsDragging then
                return
            end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                tab:ShowTab()
            end
        end)
        capture04[3][capture04[2] ]:GetPropertyChangedSignal('Visible'):Connect(function()
            tab:Resize()
        end)

        capture01.TotalTabs = capture01.TotalTabs + 1

        if capture01.TotalTabs == 1 then
            tab:ShowTab()
        end

        capture12.Tabs[capture10] = tab
    end
end
function Native.dependencies(captures)
    local capture00 = captures[0]
    local capture05 = captures[5]
    local capture04 = captures[4]
    local capture02 = captures[2]
    local capture06 = captures[6]
    local capture03 = captures[3]
    local capture01 = captures[1]

    return function()
        function capture01:Resize()
            capture03.Size = UDim2.new(1, 0, 0, capture06.AbsoluteContentSize.Y)

            capture04:Resize()
        end

        capture06:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
            capture01:Resize()
        end)
        capture03:GetPropertyChangedSignal('Visible'):Connect(function()
            capture01:Resize()
        end)

        function capture01:Update()
            local value011 = false

            for key, value in next, capture01.Dependencies do
                __step(99)

                if value[1].Value == value[2] then
                    value011 = true

                    break
                end
            end

            capture03.Visible = value011

            capture01:Resize()
        end
        function capture01:SetupDependencies(value015)
            for key2, value2 in next, value015 do
                __step(100)
                assert(type(value2) == 'table', 'SetupDependencies: Dependency is not of type `table`.')
                assert(value2[1], 'SetupDependencies: Dependency is missing element argument.')
                assert(value2[2] ~= nil, 'SetupDependencies: Dependency is missing value argument.')
            end

            capture01.Dependencies = value015

            capture01:Update()
        end
        function capture01:Remove()
            table.remove(capture00.DependencyBoxes, table.find(capture00.DependencyBoxes, capture01))
            table.clear(capture01)
            capture03:Destroy()
            capture04:Resize()
        end

        capture01.Container = capture05

        setmetatable(capture01, capture02)
        table.insert(capture00.DependencyBoxes, capture01)
    end
end
function Native.valueCallbacks(captures)
    local capture03 = captures[3]
    local capture10 = captures[10]
    local capture00 = captures[0]
    local capture05 = captures[5]
    local capture07 = captures[7]
    local capture09 = captures[9]
    local capture01 = captures[1]
    local capture04 = captures[4]
    local textService = captures[8]
    local capture02 = captures[2]
    local capture06 = captures[6]

    return function()
        function capture00:SetValue(newValue)
            if capture02.MaxLength and #newValue > capture02.MaxLength then
                newValue = newValue:sub(1, capture02.MaxLength)
            end
            if capture00.Numeric then
                if not tonumber(newValue) and newValue:len() > 0 then
                    newValue = capture00.Value
                end
            end

            capture00.Value = newValue
            capture01.Text = newValue

            capture04:SafeCallback(capture00.Callback, capture00.Value)
            capture04:SafeCallback(capture00.Changed, capture00.Value)
        end
        function capture00:Remove()
            for key, value in capture07 do
                __step(146)
                value:Destroy()
            end

            capture03[capture05] = nil

            capture09:Destroy()
            table.clear(capture00)
            capture06:Resize()
        end

        if capture00.Finished then
            capture01.FocusLost:Connect(function(value018)
                capture00:SetValue(capture01.Text)
                capture04:AttemptSave()
            end)
        else
            capture01:GetPropertyChangedSignal('Text'):Connect(function()
                capture00:SetValue(capture01.Text)
                capture04:AttemptSave()
            end)
        end

        local function value019()
            local value020 = 2
            local value021 = capture10.AbsoluteSize.X

            if not capture01:IsFocused() or capture01.TextBounds.X <= value021 - 2 * value020 then
                capture01.Position = UDim2.new(0, value020, 0, 0)
            else
                local cursorPosition = capture01.CursorPosition

                if cursorPosition ~= -1 then
                    local value023 = string.sub(capture01.Text, 1, cursorPosition - 1)
                    local value024 = textService:GetTextSize(value023, capture01.TextSize, capture01.Font, Vector2.new(math.huge, math.huge)).X
                    local value025 = capture01.Position.X.Offset + value024

                    if value025 < value020 then
                        capture01.Position = UDim2.fromOffset(value020 - value024, 0)
                    elseif value025 > value021 - value020 - 1 then
                        capture01.Position = UDim2.fromOffset(value021 - value024 - value020 - 1, 0)
                    end
                end
            end
        end

        task.spawn(value019)
        capture01:GetPropertyChangedSignal('Text'):Connect(value019)
        capture01:GetPropertyChangedSignal('CursorPosition'):Connect(value019)
        capture01.FocusLost:Connect(value019)
        capture01.Focused:Connect(value019)

        if capture04.FlagCopying then
            local value026 = capture04:AddContextMenu(capture09)

            value026:AddOption('Copy Flag', function()
                pcall(setclipboard, capture00.Idx)
                task.wait()
                capture04:Notify('Copied flag to clipboard!', 2)
                value026:Hide()
            end)
        end

        capture04:AddToRegistry(capture01, {
            TextColor3 = 'FontColor',
        })

        function capture00:OnChanged(callback)
            capture00.Changed = callback

            callback(capture00.Value)
        end

        table.insert(capture07, capture06:AddBlank(5))
        capture06:Resize()

        capture03[capture05] = capture00
    end
end
function Native.buttons(captures)
    local capture03 = captures[3]
    local capture01 = captures[1]
    local capture00 = captures[0]
    local capture02 = captures[2]
    local capture04 = captures[4]

    return function()
        function capture01:AddButton(...)
            local value008 = typeof(select(1, ...)) == 'table' and select(1, ...) or {
                Text = select(1, ...),
                Func = select(2, ...),
            }

            assert(typeof(value008.Func) == 'function', 'AddButton: `Func` callback is missing.')

            self.Outer.Size = UDim2.new(0.5, -2, 0, 20)
            value008.Outer, value008.Inner, value008.Label = capture03(value008)
            value008.Outer.Position = UDim2.new(1, 3, 0, 0)
            value008.Outer.Size = UDim2.new(1, -3, 1, 0)
            value008.Outer.Parent = self.Outer

            function value008:AddTooltip(value010)
                if typeof(value010) == 'string' then
                    capture04:AddToolTip(value010, self.Outer)
                end

                return value008
            end

            if typeof(value008.Tooltip) == 'string' then
                value008:AddTooltip(value008.Tooltip)
            end

            capture00(value008)

            return value008
        end

        local value011 = {}

        function capture01:Remove()
            for key, value in value011 do
                __step(156)
                value:Destroy()
            end

            capture01.Outer:Destroy()
            table.clear(capture01)
            capture02:Resize()
        end

        if typeof(capture01.Tooltip) == 'string' then
            capture01:AddTooltip(capture01.Tooltip)
        end

        table.insert(value011, capture02:AddBlank(5))
        capture02:Resize()
    end
end
function Native.textLabel(captures)
    local capture00 = captures[0]
    local capture05 = captures[5]
    local capture02 = captures[2]
    local capture04 = captures[4]
    local capture01 = captures[1]
    local capture03 = captures[3]

    return function()
        function capture04:SetText(text)
            capture03.Text = text

            if capture05 then
                local value010 = select(2, capture02:GetTextBounds(text, capture02.Font, 14, Vector2.new(capture03.AbsoluteSize.X, math.huge)))

                capture03.Size = UDim2.new(1, -4, 0, value010)
            end

            capture00:Resize()
        end

        local value011 = {}

        function capture04:Remove()
            for key, value in value011 do
                __step(185)
                value:Destroy()
            end

            capture03:Destroy()
            table.clear(capture04)
            capture00:Resize()
        end

        if not capture05 then
            setmetatable(capture04, capture01)
        end

        table.insert(value011, capture00:AddBlank(5))
        capture00:Resize()
    end
end
function Native.containerSize(captures)
    local capture01 = captures[1]
    local capture00 = captures[0]
    local capture03 = captures[3]
    local capture02 = captures[2]
    local capture04 = captures[4]

    return function()
        function capture03:SetSize(value008)
            capture01.Size = UDim2.new(1, -4, 0, value008)

            capture04:Resize()
        end
        function capture03:GetOuter()
            return capture01
        end
        function capture03:GetInner()
            return capture00
        end
        function capture03:GetSize()
            return capture00.AbsoluteSize
        end

        local value012 = {}

        table.insert(value012, capture02:AddBlank(5))
        capture02:Resize()
    end
end
function Native.drawing(captures)
    local integrityProductRef = captures[2]
    local smallIntegrityRef = captures[4]
    local integrityOffsetRef = captures[0]
    local outlineColorNameRef = captures[8]
    local largeIntegrityRef = captures[6]
    local frameClassRef = captures[1]
    local integrityModuloRef = captures[5]
    local cloneFunctionRef = captures[3]
    local enabledRef = captures[7]

    return function()
        if integrityOffsetRef[3][integrityOffsetRef[2] ](1386) ~= 4293 then
            while true do
                __step(68)
            end
        else
            local textService = cloneref(game:GetService('TextService'))
            local value012 = {
                Fonts = {
                    UI = 0,
                    System = 1,
                    Plex = 2,
                    Monospace = 3,
                },
            }
            local value013 = getrenv()
            local value014 = value013.math.pi
            local value015 = value013.math.huge
            local value016 = cloneFunctionRef[3][cloneFunctionRef[2] ](value013.assert)
            local value017 = cloneFunctionRef[3][cloneFunctionRef[2] ](value013.Color3.new)
            local value018 = cloneFunctionRef[3][cloneFunctionRef[2] ](value013.Instance.new)
            local value019 = cloneFunctionRef[3][cloneFunctionRef[2] ](value013.math.atan2)
            local value020 = cloneFunctionRef[3][cloneFunctionRef[2] ](value013.math.clamp)
            local value021 = cloneFunctionRef[3][cloneFunctionRef[2] ](value013.math.max)
            local value022 = cloneFunctionRef[3][cloneFunctionRef[2] ](value013.setmetatable)
            local value023 = cloneFunctionRef[3][cloneFunctionRef[2] ](value013.string.format)
            local value024 = cloneFunctionRef[3][cloneFunctionRef[2] ](value013.task.spawn)
            local value025 = cloneFunctionRef[3][cloneFunctionRef[2] ](value013.UDim.new)
            local value026 = cloneFunctionRef[3][cloneFunctionRef[2] ](value013.UDim2.fromOffset)
            local value027 = cloneFunctionRef[3][cloneFunctionRef[2] ](value013.UDim2.new)
            local value028 = cloneFunctionRef[3][cloneFunctionRef[2] ](value013.Vector2.new)
            local value029 = cloneFunctionRef[3][cloneFunctionRef[2] ](game.Destroy)
            local value030 = cloneFunctionRef[3][cloneFunctionRef[2] ](textService.GetTextBoundsAsync)
            local value031 = cloneFunctionRef[3][cloneFunctionRef[2] ](game.HttpGet)
            local value032 = writecustomasset and cloneFunctionRef[3][cloneFunctionRef[2] ](writecustomasset)
            local value033 = protectinstance and cloneFunctionRef[3][cloneFunctionRef[2] ](protectinstance)

            local function value034(value035, value036, value037)
                local value038 = value018(value035)

                for key, value in value036 do
                    __step(69)

                    if key ~= 'Parent' then
                        value038[key] = value
                    end
                end

                if value037 then
                    for key2, value2 in value037 do
                        __step(70)

                        value2.Parent = value038
                    end
                end
                if value033 then
                    if 15746 ~= integrityOffsetRef[3][integrityOffsetRef[2] ](3592) then
                        while true do
                            __step(71)
                        end
                    else
                        value033(value038)
                    end
                end

                value038.Parent = value036.Parent

                return value038
            end

            do
                local value043 = {
                    Font.new('rbxasset://fonts/families/Arial.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                    Font.new('rbxasset://fonts/families/HighwayGothic.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                    Font.new('rbxasset://fonts/families/Roboto.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                    Font.new('rbxasset://fonts/families/Ubuntu.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                }

                for key3, value3 in value043 do
                    __step(72)
                    game:GetService('TextService'):GetTextBoundsAsync(value034('GetTextBoundsParams', {
                        Text = '\\\\',
                        Size = 12,
                        Font = value3,
                        Width = value015,
                    }))
                end
            end
            do
                local value046 = value034('ScreenGui', {
                    DisplayOrder = 15,
                    IgnoreGuiInset = true,
                    Name = 'drawingDirectory',
                    Parent = cloneref(game:GetService('CoreGui')),
                    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
                })

                local function value047(value048, value049, value050, value051)
                    local value052 = (value049 + value050) / 2
                    local value053 = value050 - value049

                    value048.Position = value026(value052.X, value052.Y)
                    value048.Rotation = value019(value053.Y, value053.X) * 180 / value014
                    value048.Size = value026(value053.Magnitude, value051)
                end

                if largeIntegrityRef[3][largeIntegrityRef[2] ] + 8181 ~= 17576 then
                    while true do
                        __step(73)
                    end
                end

                local value054 = 0
                local value055 = {}
                local value056 = {}

                do
                    if smallIntegrityRef[3][smallIntegrityRef[2] ] - 610 ~= 354 then
                        if integrityOffsetRef[3][integrityOffsetRef[2] ](5140) <= 21280 and 21280 >= integrityOffsetRef[3][integrityOffsetRef[2] ](5140) then
                            while true do
                                __step(74)
                            end
                        else
                            while true do
                                __step(75)
                            end
                        end
                    end

                    local drawingClass = {}

                    function drawingClass.new()
                        value054 = value054 + 1

                        if largeIntegrityRef[3][largeIntegrityRef[2] ] + 3788 ~= 13183 then
                            while true do
                                __step(76)
                            end
                        end

                        local value058 = value054
                        local value059 = value022({
                            _id = value058,
                            __OBJECT_EXISTS = true,
                            _properties = {
                                Color = value017(),
                                From = value028(),
                                Thickness = 1,
                                To = value028(),
                                Transparency = 1,
                                Visible = false,
                                ZIndex = 0,
                            },
                            _frame = value034(frameClassRef[3][frameClassRef[2] ], {
                                Name = value058,
                                AnchorPoint = value028(0.5, 0.5),
                                BackgroundColor3 = value017(),
                                BorderSizePixel = 0,
                                Parent = value046,
                                Position = value027(),
                                Size = value027(),
                                Visible = false,
                                ZIndex = 0,
                            }),
                        }, drawingClass)

                        value055[value058] = value059

                        return value059
                    end
                    function drawingClass:__index(value061)
                        local value062 = self._properties[value061]

                        if value062 ~= nil then
                            return value062
                        end

                        return drawingClass[value061]
                    end
                    function drawingClass:__newindex(value064, value065)
                        if enabledRef[3][enabledRef[2] ] and self.__OBJECT_EXISTS == true then
                            if 26282 >= integrityOffsetRef[3][integrityOffsetRef[2] ](8694) and 26282 <= integrityOffsetRef[3][integrityOffsetRef[2] ](8694) then
                                local value066 = self._properties

                                if enabledRef[3][enabledRef[2] ] and (value066[value064] == nil or value066[value064] == value065 or typeof(value066[value064]) ~= typeof(value065)) then
                                    return
                                end

                                value066[value064] = value065

                                if value064 == 'Color' then
                                    self._frame.BackgroundColor3 = value065
                                elseif value064 == 'From' then
                                    self:_updatePosition()
                                elseif value064 == 'Thickness' then
                                    self._frame.Size = value026(self._frame.AbsoluteSize.X, value021(value065, 1))
                                elseif value064 == 'To' then
                                    self:_updatePosition()
                                elseif value064 == 'Transparency' then
                                    if integrityOffsetRef[3][integrityOffsetRef[2] ](3864) ~= 13262 then
                                        while true do
                                            __step(77)
                                        end
                                    else
                                        self._frame.BackgroundTransparency = value020(1 - value065, 0, 1)
                                    end
                                elseif value064 == 'Visible' then
                                    self._frame.Visible = value065
                                elseif value064 == 'ZIndex' then
                                    self._frame.ZIndex = value065
                                end
                            else
                                while true do
                                    __step(78)
                                end
                            end
                        end
                    end
                    function drawingClass:__iter()
                        return next, self._properties
                    end
                    function drawingClass:__tostring()
                        return 'Drawing'
                    end
                    function drawingClass:Destroy()
                        value055[self._id] = nil
                        self.__OBJECT_EXISTS = false

                        value029(self._frame)
                    end
                    function drawingClass:_updatePosition()
                        local value071 = self._properties

                        value047(self._frame, value071.From, value071.To, value071.Thickness)
                    end

                    drawingClass.Remove = drawingClass.Destroy
                    value056.Line = drawingClass
                end
                do
                    local drawingClass2 = {}

                    function drawingClass2.new()
                        if integrityOffsetRef[3][integrityOffsetRef[2] ](1085) >= 7565 and 7565 <= integrityOffsetRef[3][integrityOffsetRef[2] ](1085) then
                            value054 = value054 + 1

                            local value073 = value054
                            local value074 = value022({
                                _id = value073,
                                __OBJECT_EXISTS = true,
                                _properties = {
                                    Color = value017(),
                                    Filled = false,
                                    NumSides = 0,
                                    Position = value028(),
                                    Radius = 0,
                                    Thickness = 1,
                                    Transparency = 1,
                                    Visible = false,
                                    ZIndex = 0,
                                },
                                _frame = value034(frameClassRef[3][frameClassRef[2] ], {
                                    Name = value073,
                                    AnchorPoint = value028(0.5, 0.5),
                                    BackgroundColor3 = value017(),
                                    BackgroundTransparency = 1,
                                    BorderSizePixel = 0,
                                    Parent = value046,
                                    Position = value027(),
                                    Size = value027(),
                                    Visible = false,
                                    ZIndex = 0,
                                }, {
                                    value034('UICorner', {
                                        Name = '_corner',
                                        CornerRadius = value025(1, 0),
                                    }),
                                    value034('UIStroke', {
                                        Name = '_stroke',
                                        Color = value017(),
                                        Thickness = 1,
                                    }),
                                }),
                            }, drawingClass2)

                            value055[value073] = value074

                            return value074
                        else
                            while true do
                                __step(79)
                            end
                        end
                    end
                    function drawingClass2:__index(value076)
                        local value077 = self._properties[value076]

                        if value077 ~= nil then
                            return value077
                        end

                        return drawingClass2[value076]
                    end
                    function drawingClass2:__newindex(value079, value080)
                        if self.__OBJECT_EXISTS == true then
                            if integrityOffsetRef[3][integrityOffsetRef[2] ](1603) == 7229 then
                                local value081 = self._properties

                                if value081[value079] == nil or value081[value079] == value080 or typeof(value081[value079]) ~= typeof(value080) then
                                    return
                                end

                                value081[value079] = value080

                                if value079 == 'Color' then
                                    if 9871 == integrityModuloRef[3][integrityModuloRef[2] ](8073) then
                                        self._frame.BackgroundColor3 = value080
                                        self._frame._stroke.Color = value080
                                    else
                                        while true do
                                            __step(80)
                                        end
                                    end
                                elseif value079 == 'Filled' then
                                    if 738 <= integrityProductRef[3][integrityProductRef[2] ](6578) and integrityProductRef[3][integrityProductRef[2] ](6578) >= 738 then
                                        self._frame.BackgroundTransparency = value080 and 1 - value081.Transparency or 1
                                    else
                                        while true do
                                            __step(81)
                                        end
                                    end
                                elseif value079 == 'Position' then
                                    self._frame.Position = value026(value080.X, value080.Y)
                                elseif value079 == 'Radius' then
                                    self:_updateRadius()
                                elseif value079 == 'Thickness' then
                                    self._frame._stroke.Thickness = value021(value080, 1)

                                    self:_updateRadius()
                                elseif value079 == 'Transparency' then
                                    self._frame._stroke.Transparency = 1 - value080

                                    if value081.Filled then
                                        self._frame.BackgroundTransparency = 1 - value080
                                    end
                                elseif value079 == 'Visible' then
                                    self._frame.Visible = value080
                                elseif value079 == 'ZIndex' then
                                    self._frame.ZIndex = value080
                                end
                            else
                                while true do
                                    __step(82)
                                end
                            end
                        end
                    end
                    function drawingClass2:__iter()
                        return next, self._properties
                    end
                    function drawingClass2:__tostring()
                        return 'Drawing'
                    end
                    function drawingClass2:Destroy()
                        value055[self._id] = nil
                        self.__OBJECT_EXISTS = false

                        value029(self._frame)
                    end
                    function drawingClass2:_updateRadius()
                        if 30197 >= integrityOffsetRef[3][integrityOffsetRef[2] ](8884) and 30197 <= integrityOffsetRef[3][integrityOffsetRef[2] ](8884) then
                            local value086 = self._properties
                            local value087 = value086.Radius * 2 - value086.Thickness * 2

                            self._frame.Size = value026(value087, value087)
                        else
                            while true do
                                __step(83)
                            end
                        end
                    end

                    drawingClass2.Remove = drawingClass2.Destroy
                    value056.Circle = drawingClass2
                end
                do
                    if integrityProductRef[3][integrityProductRef[2] ](7049) >= 108 and integrityProductRef[3][integrityProductRef[2] ](7049) <= 108 then
                        local value088 = {
                            [value012.Fonts.UI] = Font.new('rbxasset://fonts/families/Arial.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                            [value012.Fonts.System] = Font.new('rbxasset://fonts/families/HighwayGothic.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                            [value012.Fonts.Plex] = Font.new('rbxasset://fonts/families/Roboto.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                            [value012.Fonts.Monospace] = Font.new('rbxasset://fonts/families/Ubuntu.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                        }
                        local drawingClass3 = {}

                        function drawingClass3.new()
                            value054 = value054 + 1

                            local value090 = value054
                            local value091 = value022({
                                _id = value090,
                                __OBJECT_EXISTS = true,
                                _properties = {
                                    Center = false,
                                    RichText = false,
                                    Color = value017(),
                                    FontFace = value088[0],
                                    Outline = false,
                                    OutlineColor = value017(),
                                    Position = value028(),
                                    Size = 12,
                                    TextSize = 12,
                                    Text = '',
                                    TextBounds = value028(),
                                    Transparency = 1,
                                    Visible = false,
                                    ZIndex = 0,
                                },
                                _frame = value034('TextLabel', {
                                    Name = value090,
                                    BackgroundTransparency = 1,
                                    FontFace = value088[0],
                                    Parent = value046,
                                    Position = value027(),
                                    Size = value027(),
                                    Text = '',
                                    TextColor3 = value017(),
                                    TextSize = 12,
                                    TextXAlignment = Enum.TextXAlignment.Left,
                                    TextYAlignment = Enum.TextYAlignment.Top,
                                    Visible = false,
                                    ZIndex = 0,
                                }, {
                                    value034('UIStroke', {
                                        Name = '_stroke',
                                        Color = value017(),
                                        Enabled = false,
                                        Thickness = 1,
                                        LineJoinMode = Enum.LineJoinMode.Miter,
                                    }),
                                }),
                            }, drawingClass3)

                            value055[value090] = value091

                            return value091
                        end
                        function drawingClass3:__index(value093)
                            local value094 = self._properties[value093]

                            if value094 ~= nil then
                                if integrityProductRef[3][integrityProductRef[2] ](7282) ~= 810 then
                                    while true do
                                        __step(84)
                                    end
                                else
                                    return value094
                                end
                            end

                            return drawingClass3[value093]
                        end
                        function drawingClass3:__newindex(value096, value097)
                            if self.__OBJECT_EXISTS == true then
                                if integrityProductRef[3][integrityProductRef[2] ](6820) >= 332 and integrityProductRef[3][integrityProductRef[2] ](6820) <= 332 then
                                    local value098 = self._properties

                                    if value096 == 'TextBounds' or value098[value096] == nil or value098[value096] == value097 or typeof(value098[value096]) ~= typeof(value097) then
                                        return
                                    end

                                    value098[value096] = value097

                                    if value096 == 'Position' then
                                        self._frame.Position = value026(value097.X, value097.Y)
                                    elseif value096 == 'Text' then
                                        self._frame.Text = value097

                                        self:_updateTextBounds()
                                    elseif value096 == 'Transparency' then
                                        self._frame.TextTransparency = 1 - value097
                                        self._frame._stroke.Transparency = 1 - value097
                                    elseif value096 == 'Size' or value096 == 'TextSize' then
                                        if 7594 <= integrityModuloRef[3][integrityModuloRef[2] ](5222) and 7594 >= integrityModuloRef[3][integrityModuloRef[2] ](5222) then
                                            self._frame.TextSize = value097

                                            self:_updateTextBounds()
                                        else
                                            while true do
                                                __step(85)
                                            end
                                        end
                                    elseif value096 == 'Visible' then
                                        self._frame.Visible = value097
                                    elseif value096 == 'Center' then
                                        self._frame.TextXAlignment = value097 and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
                                    elseif value096 == 'Color' then
                                        self._frame.TextColor3 = value097
                                    elseif value096 == 'Font' then
                                        local value099 = value088[value097]

                                        self._frame.FontFace, value098.FontFace = value099, value099

                                        self:_updateTextBounds()
                                    elseif value096 == 'Outline' then
                                        self._frame._stroke.Enabled = value097
                                    elseif value096 == outlineColorNameRef[3][outlineColorNameRef[2] ] then
                                        self._frame._stroke.Color = value097
                                    elseif value096 == 'ZIndex' then
                                        self._frame.ZIndex = value097
                                    elseif value096 == 'FontFace' then
                                        if integrityModuloRef[3][integrityModuloRef[2] ](6592) == 5584 then
                                            self._frame.FontFace = value097

                                            self:_updateTextBounds()
                                        else
                                            while true do
                                                __step(86)
                                            end
                                        end
                                    elseif value096 == 'RichText' then
                                        self._frame.RichText = value097
                                    end
                                else
                                    while true do
                                        __step(87)
                                    end
                                end
                            end
                        end
                        function drawingClass3:__iter()
                            return next, self._properties
                        end
                        function drawingClass3:__tostring()
                            return 'Drawing'
                        end
                        function drawingClass3:Destroy()
                            value055[self._id] = nil
                            self.__OBJECT_EXISTS = false

                            value029(self._frame)
                        end
                        function drawingClass3:_updateTextBounds()
                            local value104 = self._properties

                            value104.TextBounds = value030(textService, value034('GetTextBoundsParams', {
                                Text = value104.Text,
                                Size = value104.Size,
                                Font = value104.FontFace,
                                Width = value015,
                            }))
                        end

                        drawingClass3.Remove = drawingClass3.Destroy
                        value056.Text = drawingClass3
                    else
                        while true do
                            __step(88)
                        end
                    end
                end
                do
                    local drawingClass4 = {}

                    function drawingClass4.new()
                        value054 = value054 + 1

                        local value106 = value054
                        local value107 = value022({
                            _id = value106,
                            __OBJECT_EXISTS = true,
                            _properties = {
                                Color = value017(),
                                Filled = false,
                                Position = value028(),
                                Size = value028(),
                                Thickness = 1,
                                Transparency = 1,
                                Visible = false,
                                ZIndex = 0,
                            },
                            _frame = value034(frameClassRef[3][frameClassRef[2] ], {
                                BackgroundColor3 = value017(),
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                Parent = value046,
                                Position = value027(),
                                Size = value027(),
                                Visible = false,
                                ZIndex = 0,
                            }, {
                                value034('UIStroke', {
                                    Name = '_stroke',
                                    Color = value017(),
                                    Thickness = 1,
                                    LineJoinMode = Enum.LineJoinMode.Miter,
                                }),
                            }),
                        }, drawingClass4)

                        value055[value106] = value107

                        return value107
                    end
                    function drawingClass4:__index(value109)
                        local value110 = self._properties[value109]

                        if value110 ~= nil then
                            return value110
                        end

                        return drawingClass4[value109]
                    end
                    function drawingClass4:__newindex(value112, value113)
                        if self.__OBJECT_EXISTS == true then
                            local value114 = self._properties

                            if value114[value112] == nil or value114[value112] == value113 or typeof(value114[value112]) ~= typeof(value113) then
                                return
                            end

                            value114[value112] = value113

                            if value112 == 'Position' then
                                self:_updateScale()
                            elseif value112 == 'Size' then
                                self:_updateScale()
                            elseif value112 == 'Color' then
                                self._frame.BackgroundColor3 = value113
                                self._frame._stroke.Color = value113
                            elseif value112 == 'Filled' then
                                if -1118 == integrityProductRef[3][integrityProductRef[2] ](5065) then
                                    while true do
                                        __step(89)
                                    end
                                else
                                    self._frame.BackgroundTransparency = value113 and 1 - value114.Transparency or 1
                                end
                            elseif value112 == 'Thickness' then
                                self._frame._stroke.Thickness = value113

                                self:_updateScale()
                            elseif value112 == 'Transparency' then
                                self._frame._stroke.Transparency = 1 - value113

                                if value114.Filled then
                                    if integrityOffsetRef[3][integrityOffsetRef[2] ](7134) ~= 26717 then
                                        while true do
                                            __step(90)
                                        end
                                    else
                                        self._frame.BackgroundTransparency = 1 - value113
                                    end
                                end
                            elseif value112 == 'Visible' then
                                self._frame.Visible = value113
                            elseif value112 == 'ZIndex' then
                                self._frame.ZIndex = value113
                            end
                        end
                    end
                    function drawingClass4:__iter()
                        return next, self._properties
                    end
                    function drawingClass4:__tostring()
                        return 'Drawing'
                    end
                    function drawingClass4:Destroy()
                        value055[self._id] = nil
                        self.__OBJECT_EXISTS = false

                        value029(self._frame)
                    end
                    function drawingClass4:_updateScale()
                        local value119 = self._properties

                        self._frame.Position = value026(value119.Position.X + value119.Thickness, value119.Position.Y + value119.Thickness)

                        local thickness = value119.Thickness

                        self._frame.Size = value026(value119.Size.X - thickness * 2, value119.Size.Y - thickness * 2)
                    end

                    drawingClass4.Remove = drawingClass4.Destroy
                    value056.Square = drawingClass4
                end
                do
                    local drawingClass5 = {}

                    function drawingClass5.new()
                        value054 = value054 + 1

                        local value122 = value054
                        local value123 = value022({
                            _id = value122,
                            _imageId = 0,
                            __OBJECT_EXISTS = true,
                            _properties = {
                                Color = value017(1, 1, 1),
                                Data = '',
                                Position = value028(),
                                Rounding = 0,
                                Size = value028(),
                                Transparency = 1,
                                Uri = '',
                                Visible = false,
                                ZIndex = 0,
                            },
                            _frame = value034('ImageLabel', {
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                Image = '',
                                ImageColor3 = value017(1, 1, 1),
                                Parent = value046,
                                Position = value027(),
                                Size = value027(),
                                Visible = false,
                                ZIndex = 0,
                            }, {
                                value034('UICorner', {
                                    Name = '_corner',
                                    CornerRadius = value025(),
                                }),
                            }),
                        }, drawingClass5)

                        value055[value122] = value123

                        return value123
                    end
                    function drawingClass5:__index(value125)
                        if 108 == integrityProductRef[3][integrityProductRef[2] ](6249) then
                            value016(value125 ~= 'Data', value023("Attempt to read writeonly property '%s'", value125))

                            if value125 == 'Loaded' then
                                return self._frame.IsLoaded
                            end

                            local value126 = self._properties[value125]

                            if value126 ~= nil then
                                return value126
                            end

                            return drawingClass5[value125]
                        else
                            while true do
                                __step(91)
                            end
                        end
                    end
                    function drawingClass5:__newindex(value128, value129)
                        if integrityProductRef[3][integrityProductRef[2] ](2673) == 3516 then
                            while true do
                                __step(92)
                            end
                        elseif self.__OBJECT_EXISTS == true then
                            local value130 = self._properties

                            if value130[value128] == nil or value130[value128] == value129 or typeof(value130[value128]) ~= typeof(value129) then
                                return
                            end

                            value130[value128] = value129

                            if value128 == 'Color' then
                                self._frame.ImageColor3 = value129
                            elseif value128 == 'Data' then
                                self:_newImage(value129)
                            elseif value128 == 'Position' then
                                self._frame.Position = value026(value129.X, value129.Y)
                            elseif value128 == 'Rounding' then
                                self._frame._corner.CornerRadius = value025(0, value129)
                            elseif value128 == 'Size' then
                                if 27215 ~= integrityOffsetRef[3][integrityOffsetRef[2] ](8145) then
                                    while true do
                                        __step(93)
                                    end
                                else
                                    self._frame.Size = value026(value129.X, value129.Y)
                                end
                            elseif value128 == 'Transparency' then
                                self._frame.ImageTransparency = 1 - value129
                            elseif value128 == 'Uri' then
                                self:_newImage(value129, true)
                            elseif value128 == 'Visible' then
                                self._frame.Visible = value129
                            elseif value128 == 'ZIndex' then
                                self._frame.ZIndex = value129
                            end
                        end
                    end
                    function drawingClass5:__iter()
                        return next, self._properties
                    end
                    function drawingClass5:__tostring()
                        return 'Drawing'
                    end
                    function drawingClass5:Destroy()
                        value055[self._id] = nil
                        self.__OBJECT_EXISTS = false

                        value029(self._frame)
                    end
                    function drawingClass5:_newImage(value135, value136)
                        value024(function()
                            self._imageId = self._imageId + 1

                            local value137 = value023('%s-%s.png', self._id, self._imageId)

                            if value136 then
                                local value138

                                while value138 == nil do
                                    __step(94)

                                    local success, resultOrError = pcall(value031, game, value135, true)

                                    if success then
                                        value138 = resultOrError
                                    elseif string.find(string.lower(resultOrError), 'too many requests') then
                                        task.wait(3)
                                    else
                                        error(resultOrError, 2)

                                        return
                                    end
                                end

                                self._properties.Data = value135
                            else
                                self._properties.Uri = ''
                            end

                            self._frame.Image = value032(value137, value135)
                        end)
                    end

                    drawingClass5.Remove = drawingClass5.Destroy
                    value056.Image = drawingClass5
                end

                value012.new = newcclosure(function(value141)
                    return value016(value056[value141], value023("Invalid drawing type '%s'", value141)).new()
                end)
                value012.clear = newcclosure(function()
                    for key4, value4 in value055 do
                        __step(95)

                        if value4.__OBJECT_EXISTS then
                            value4:Destroy()
                        end
                    end
                end)
                value012.cache = value055
            end

            setreadonly(value012, true)
            setreadonly(value012.Fonts, true)

            return value012
        end
    end
end
function Native.emptyCallback()
    return function() end
end
function Native.recovered01_Sw(captures)
    local capture01 = captures[1]
    local capture03 = captures[3]
    local capture00 = captures[0]
    local capture02 = captures[2]

    return function(value006)
        local value007 = value006 and capture02(value006) == 'table' and capture00(value006, capture01)

        capture03:Fire(capture02(value007) == 'string' and value007)
    end
end
function Native.recovered02_iw(captures)
    local capture25 = captures[25]
    local capture03 = captures[3]
    local capture07 = captures[7]
    local capture22 = captures[22]
    local capture11 = captures[11]
    local capture04 = captures[4]
    local capture26 = captures[26]
    local capture05 = captures[5]
    local capture15 = captures[15]
    local capture17 = captures[17]
    local capture20 = captures[20]
    local capture19 = captures[19]
    local capture13 = captures[13]
    local capture10 = captures[10]
    local capture01 = captures[1]
    local capture27 = captures[27]
    local capture06 = captures[6]
    local capture21 = captures[21]
    local capture12 = captures[12]
    local capture16 = captures[16]
    local capture24 = captures[24]
    local capture02 = captures[2]
    local capture23 = captures[23]
    local capture09 = captures[9]
    local capture18 = captures[18]
    local capture08 = captures[8]
    local capture00 = captures[0]
    local capture14 = captures[14]

    return function(value030)
        if not capture16[3][capture16[2] ][capture18] then
            return capture17()
        end
        if not capture06[3][capture06[2] ] then
            capture12[3][capture12[2] ] = capture24:GetPivot().Position
        end

        local value031, value032 = capture09[3][capture09[2] ](capture12[3][capture12[2] ])

        if not value032 then
            return capture17()
        end

        capture00[3][capture00[2] ], capture07.Visible = false, true

        local value033, value034 = capture19[3][capture19[2] ].font, capture19[3][capture19[2] ].size

        capture13.FontFace, capture13.TextSize = value033, value034
        capture01.FontFace, capture01.TextSize = value033, value034

        local value035 = capture26((capture11.CFrame.Position - capture12[3][capture12[2] ]).Magnitude)

        if capture21[3][capture21[2] ] then
            capture13.Text, capture13.Visible = value035 .. 's', true
            capture13.TextColor3 = capture04[3][capture04[2] ]
        else
            capture13.Visible = false
        end

        capture01.Visible, capture01.TextColor3 = capture20[3][capture20[2] ], capture02[3][capture02[2] ]
        capture07.Position, capture07.ZIndex = capture05(value031.X, value031.Y), -value035

        if capture06[3][capture06[2] ] then
            capture06[3][capture06[2] ] = capture06[3][capture06[2] ] + value030

            local value036 = capture22(capture06[3][capture06[2] ] / capture23[3][capture23[2] ], 0, 1)

            for key, value in capture03 do
                __step(4)

                key[value] = value036
            end
        end
        if not capture27[3][capture27[2] ] then
            capture07.Size, capture10[3][capture10[2] ] = capture05(), 0

            return
        end

        local value039, value040

        if capture25[3][capture25[2] ] and capture06[3][capture06[2] ] then
            value039, value040 = 1, capture14[3][capture14[2] ] * (1 - capture22(capture06[3][capture06[2] ] / capture23[3][capture23[2] ], 0, 1))
        else
            value039, value040 = capture08[3][capture08[2] ], capture14[3][capture14[2] ]
        end
        if capture10[3][capture10[2] ] == value040 then
            return
        end

        capture10[3][capture10[2] ] = capture15(capture10[3][capture10[2] ], value040, value039)
        capture07.Size = capture05(capture10[3][capture10[2] ], capture10[3][capture10[2] ])
    end
end
function Native.recovered03_Q(captures)
    local capture00 = captures[0]

    return function()
        capture00.Enabled = Toggles.color_correction_enabled.Value

        if not capture00.Enabled then
            return
        end

        capture00.TintColor = Options.color_correction_tint.Value
        capture00.Saturation = Options.color_correction_saturation.Value
        capture00.Contrast = Options.color_correction_contrast.Value
        capture00.Brightness = Options.color_correction_brightness.Value
    end
end
function Native.recovered05_K(captures)
    local capture01 = captures[1]
    local capture00 = captures[0]

    return function(value004, value005, value006)
        local value007 = capture00[value004]

        return value007 .. capture01[3][capture01[2] ](value005) .. '</font>' .. (value006 and '\n' or '')
    end
end
function Native.recovered07_h(captures)
    local capture00 = captures[0]
    local capture01 = captures[1]

    return function(...)
        capture00(capture01, ...)
    end
end
function Native.recovered09_g(captures)
    local capture10 = captures[10]
    local capture04 = captures[4]
    local capture11 = captures[11]
    local capture07 = captures[7]
    local capture03 = captures[3]
    local capture01 = captures[1]
    local capture12 = captures[12]
    local capture08 = captures[8]
    local capture05 = captures[5]
    local capture09 = captures[9]
    local capture00 = captures[0]
    local capture02 = captures[2]
    local capture06 = captures[6]

    return function(value015, value016, value017)
        local value018, value019 = capture11('Attachment', capture03), capture11('Attachment', capture03)

        value018.WorldPosition, value019.WorldPosition = value015, value015

        local value020 = capture05:Clone()
        local value2 = capture08.Value

        value020.Width0, value020.Width1 = value2, value2
        value020.LightEmission = capture10.Value
        value020.TextureSpeed = capture02.Value
        value020.TextureLength = capture01.Value
        value020.Parent = value018
        value020.Color = value017
        value020.Attachment0 = value018
        value020.Attachment1 = value019

        local value022 = {value020}

        for index = 1, capture09.Value - 1 do
            __step(38)

            local value024 = value020:Clone()

            value024.Parent = value020.Parent

            table.insert(value022, value024)
        end

        capture12:Create(value019, capture00(capture04.Value), {WorldPosition = value016}):Play()
        task.delay(capture07.Value, function()
            local value025

            for key, value in value022 do
                __step(39)

                value025 = capture12:Create(value, capture00(capture06.Value), {
                    Width0 = 0,
                    Width1 = 0,
                })

                value025:Play()
            end

            value025.Completed:Wait()
            value018:Destroy()
            value019:Destroy()
        end)
    end
end
function Native.recovered10_S(captures)
    local capture00 = captures[0]
    local capture01 = captures[1]

    return function()
        local value2 = Toggles.sunrays_enabled.Value

        if value2 then
            capture00.Enabled = true
            capture00.Spread = Options.sunrays_spread.Value
            capture00.Intensity = Options.sunrays_intensity.Value
        else
            for key, value in capture01 do
                __step(40)

                capture00[key] = value
            end
        end
    end
end
function Native.recovered13_k()
    return function(...)
        return call(...)
    end
end
function Native.recovered14_O(captures)
    local capture00 = captures[0]
    local capture01 = captures[1]

    return function(value004, value005)
        if capture00[3][capture00[2] ] then
            capture01[3][capture01[2] ] = capture01[3][capture01[2] ] + value005
        end
    end
end
function Native.recovered15_E(captures)
    local capture01 = captures[1]
    local capture00 = captures[0]

    return function()
        local unpackFn = unpack

        capture01[3][capture01[2] ] = function()
            return unpackFn(capture00)
        end
    end
end
function Native.recovered16_j(captures)
    local capture00 = captures[0]

    return function()
        return capture00
    end
end
function Native.recovered18_z(captures)
    local capture03 = captures[3]
    local capture01 = captures[1]
    local capture00 = captures[0]
    local capture04 = captures[4]
    local capture05 = captures[5]
    local capture06 = captures[6]
    local capture02 = captures[2]

    return function(value009, value010, value011, value012)
        capture03(capture04, value012 and value009 or capture05[3][capture05[2] ](value009), nil)

        if value010 then
            capture00[3][capture00[2] ] = true

            if capture01[3][capture01[2] ] then
                capture06(capture01[3][capture01[2] ])
            end

            capture01[3][capture01[2] ] = capture02(value011 or 1, function()
                capture00[3][capture00[2] ] = nil
            end)
        end
    end
end
function Native.recovered20_W(captures)
    local capture00 = captures[0]

    return function()
        capture00:Fire()
    end
end
function Native.recovered21_vw(captures)
    local capture03 = captures[3]
    local capture01 = captures[1]
    local capture00 = captures[0]
    local userInputService = captures[2]

    return function()
        local mousePosition = userInputService:GetMouseLocation()
        local value007 = (mousePosition - capture01[3][capture01[2] ]) / capture03

        capture00.Position = capture00.Position + UDim2.fromScale(value007.X, value007.Y)
        capture01[3][capture01[2] ] = mousePosition
    end
end
function Native.recovered22_ow()
    return function()
        return base64_decode([[T1RUTwALAIAAAwAwQ0ZGIMpb/7kAAErwAAB83kdQT1OBOkhVAAExkAAAgrxHU1VCoGbdmQAA0QwAAGCCT1MvMmy5LoEAAAEgAAAAYGNtYXAedo8DAABGuAAABBZoZWFk5gwBYwAAALwAAAA2aGhlYQZ3BJIAAAD0AAAAJGhtdHi3rBYzAADH0AAACTxtYXhwAk9QAAAAARgAAAAGbmFtZVEfsp4AAAGAAABFNXBvc3T/uAAyAABK0AAAACAAAQAAAAEAAHsq5slfDzz1AAMD6AAAAADBt17iAAAAAMG3XuL/q/75A9sDxgAAAAMAAgAAAAAAAAABAAAC7v8GAAAD4P+r/1wD2wABAAAAAAAAAAAAAAAAAAACTwAAUAACTwAAAAIBnAK8AAUABAK8AooAAACMArwCigAAAd0AMgD6AAAAAAAAAAAAAAAAgAAAL0AABEoAAAAAAAAAAEhPVVMAAAAg+wQC7v8GAAAC7gD6IAAAmwAAAAAB7ALuAAAAIAADAAAAHgFuAAEAAAAAAAAASwAAAAEAAAAAAAEAFQBLAAEAAAAAAAIABQBgAAEAAAAAAAMAMABlAAEAAAAAAAQAGwCVAAEAAAAAAAUAJwCwAAEAAAAAAAYAGQDXAAEAAAAAAAcAQQDwAAEAAAAAAAgAEAExAAEAAAAAAAkACgFBAAEAAAAAAAsAHgFLAAEAAAAAAAwAGAFpAAEAAAAAAA0U4gGBAAEAAAAAAA4AJhZjAAMAAQQJAAAAlhaJAAMAAQQJAAEAIhcfAAMAAQQJAAIADhdBAAMAAQQJAAMAYBdPAAMAAQQJAAQAMhevAAMAAQQJAAUAThfhAAMAAQQJAAYAMhevAAMAAQQJAAcAghgvAAMAAQQJAAgAIBixAAMAAQQJAAkAFBjRAAMAAQQJAAsAPBjlAAMAAQQJAAwAMBkhAAMAAQQJAA0p9hlRAAMAAQQJAA4ATENHAAMAAQQJABAAKkOTAAMAAQQJABEACkO9Q29weXJpZ2h0IDIwMDYgSG91c2UgSW5kdXN0cmllcy9CcmFuZCBEZXNpZ24gQ28uLCBJbmMuIEFsbCBSaWdodHMgUmVzZXJ2ZWQuQnVyYmFuayBCaWcgQ29uZGVuc2VkQmxhY2tIb3VzZUluZHVzdHJpZXM6QnVyYmFuayBCaWcgQ29uZGVuc2VkIEJsYWNrOjIwMDZCdXJiYW5rIEJpZyBDb25kZW5zZWQgQmxhY2tWZXJzaW9uIDEuMDAwO1BTIDAwMS4wMDE7aG90Y29nvSAxLjAuMzhCdXJiYW5rQmlnQ29uZGVuc2VkLUJsYWNrQnVyYmFuayBpcyBhIHRyYWRlbWFyayBvZiBIb3VzZSBJbmR1c3RyaWVzL0JyYW5kIERlc2lnbiBDby4sIEluYy5Ib3VzZSBJbmR1c3RyaWVzVGFsIExlbWluZ2h0dHA6Ly93d3cuaG91c2VpbmR1c3RyaWVzLmNvbWh0dHA6Ly93d3cudGFsbGVtaW5nLmNvbUhvdXNlIEluZHVzdHJpZXMgRm9udCBTb2Z0d2FyZSBMaWNlbnNlIEFncmVlbWVudAoKSE9VU0UgSU5EVVNUUklFUyBQUk9EVUNUUyBNQVkgTk9UIEJFIFJFVFVSTkEDIE9SIEVYQ0hBTkdFRCBBRlRFUiBUSEUgRk9OVFMgSEFWRESBJjUgIEVOIElOU1RBTExFRC4gCgpQbGVhc2UgcmVhZCB0aGlzIGFncmVlbWVudCBjYXJlZnVsbHkhIEJ5IGluc3RhbGxpbmcgSG91c2UgSW5kdXN0cmllcyBmb250IHNvZnR3YXJlLCB5b3UgYXJlIGFncmVlaW5nIHRvIHRoZSB0ZXJtcyBvZiB0aGlzIGxpY2Vuc2UuIEhvdXNlIEluZHVzdHJpZXMgZm9udHMgYW5kIGFydHdvcmsgYXJlIGxpY2Vuc2VkIGZvciB1c2Ugb24gNiByYXN0ZXJpemluZyBkZXZpY2VzIGNvbm5lY3RlZCB0byB0aGUgc2FtZSBuZXR3b3JrLiBBIGRldmljZSBtYXkgYmUsIGJ1dCBpcyBub3QgbGltaXRlZCB0bywgYSBwcmludGVyLCByYXN0ZXJpemVyLCB2aWRlbyBkaXNwbGF5IHRlcm1pbmFsLCBDUFUsIHdvcmtzdGF0aW9uIG9yIGFueSBkZXZpY2Ugd2hlcmUgdGhlIGZvbnQgc29mdHdhcmUgaXMgcmFzdGVyaXplZCBvciBkaXNwbGF5IG9mIHRoZSBIb3VzZSBJbmR1c3RyaWVzIEZvbnQgaXMgZ2VuZXJhdGVkIGZyb20gZm9udCBzb2Z0d2FyZSBvdXRsaW5lcy4gSWYgeW91ciBjb25maWd1cmF0aW9uIGV4Y2VlZHMgdGhpcyBmb3JtYXQsIHlvdSBtdXN0IGNhbGwgSG91c2UgSW5kdXN0cmllcyBhdCAzMDItMjM0LTIzNTYgdG8gZXhwYW5kIHlvdXIgc2l0ZSBsaWNlbnNlLiBJZiB5b3UgZG8gbm90IGFncmVlIHRvIHRoZSB0ZXJtcyBvZiB0aGlzIHNvZnR3YXJlIGxpY2Vuc2UsIHBsZWFzZSByZXR1cm4gdGhlIHNvZnR3YXJlIGVudmVsb3BlIHVub3BlbmVkIHRvIEhvdXNlIEluZHVzdHJpZXMsIDExNDUgWW9ya2x5biBSb2FkLCBQb3N0IE9mZmljZSBCb3ggMTY2LCBZb3JrbHluLCBEZWxhd2FyZSwgMTk3MzYtMDE2NiwgVS5TLkEuCgoxLiBFYWNoIEhvdXNlIEluZHVzdHJpZXMgZm9udCBpcyBsaWNlbnNlZCBmb3IgdXNlIG9uIGEgbWF4aW11bSBvZiBzaXggcmFzdGVyaXppنج

-- 
local Rayfield = loadstring(readfile("C:/Users/mouki/Downloads/BloxStrike-main/BloxStrike-main/Source/UI/source.lua"))()

--// Window creation
local Window = Rayfield:CreateWindow({
    Name = "404 Scripts",
    Icon = 0,
    LoadingTitle = "loading 404 Scripts (Blox Strike)",
    LoadingSubtitle = "by 404 Scripts",
    ShowText = "Menu",
    Theme = "DarkBlue",
    ToggleUIKeybind = Enum.KeyCode.RightShift,
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "404 Scripts",
        FileName = "404 Scripts_config"
    }
})

--// Services & Globals
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CAS = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local CharactersFolder = Workspace:WaitForChild("Characters", 10)

--// TABS
local Tab_Combat = Window:CreateTab("Combat", "crosshair")
local Tab_Skins = Window:CreateTab("Skins", "swords")
local Tab_Visuals = Window:CreateTab("Visuals", "eye")

Tab_Skins:CreateLabel("skin changerby twistedk1d (not made by me)", "code", Color3.fromRGB(80,80,80), false)

--// SHARED LOGIC
local function getTFolder() return CharactersFolder:FindFirstChild("Terrorists") end
local function getCTFolder() return CharactersFolder:FindFirstChild("Counter-Terrorists") end
local function isAlive()
    local t, ct = getTFolder(), getCTFolder()
    return (t and t:FindFirstChild(player.Name)) or (ct and ct:FindFirstChild(player.Name))
end
local function getEnemyFolder()
    if not isAlive() then return nil end
    local t, ct = getTFolder(), getCTFolder()
    if t and t:FindFirstChild(player.Name) then return ct end
    if ct and ct:FindFirstChild(player.Name) then return t end
    return nil
end

--// AIMBOT (unchanged)
local AimbotEnabled = false
local ShowFOV = false
local FOV_Radius = 100
local Smoothing = 3
local AimKey = Enum.UserInputType.MouseButton2
local isAiming = false
local FOVCircle = Drawing.new("Circle")
FOVCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
FOVCircle.Radius = FOV_Radius
FOVCircle.Filled = false
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Visible = false
FOVCircle.Thickness = 1

local function getClosestEnemyToMouse()
    local closestEnemy = nil
    local shortestDistance = FOV_Radius
    local enemyFolder = getEnemyFolder()
    if not enemyFolder or not AimbotEnabled then return nil end
   
    local mousePos = UserInputService:GetMouseLocation()
   
    for _, enemy in ipairs(enemyFolder:GetChildren()) do
        local hum = enemy:FindFirstChildOfClass("Humanoid")
        local head = enemy:FindFirstChild("Head")
        if hum and hum.Health > 0 and head then
            local headPos, onScreen = camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local distance = (Vector2.new(headPos.X, headPos.Y) - mousePos).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestEnemy = head
                end
            end
        end
    end
    return closestEnemy
end

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == AimKey then isAiming = true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == AimKey then isAiming = false end
end)

RunService.RenderStepped:Connect(function()
    if ShowFOV then
        FOVCircle.Position = UserInputService:GetMouseLocation()
        FOVCircle.Radius = FOV_Radius
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end
    if not isAiming or not isAlive() or not AimbotEnabled then return end
   
    local targetHead = getClosestEnemyToMouse()
    if targetHead then
        local headPos = camera:WorldToViewportPoint(targetHead.Position)
        local mousePos = UserInputService:GetMouseLocation()
        local moveX = (headPos.X - mousePos.X) / Smoothing
        local moveY = (headPos.Y - mousePos.Y) / Smoothing
        if mousemoverel then mousemoverel(moveX, moveY) end
    end
end)

Tab_Combat:CreateSection("Aimbot Settings")
Tab_Combat:CreateToggle({Name = "Enable Aimbot (Hold Right Click)", CurrentValue = false, Flag = "AimbotToggle", Callback = function(Value) AimbotEnabled = Value end})
Tab_Combat:CreateToggle({Name = "Show FOV Circle", CurrentValue = false, Flag = "FOVToggle", Callback = function(Value) ShowFOV = Value end})
Tab_Combat:CreateSlider({Name = "FOV Radius", Range = {10, 500}, Increment = 10, Suffix = "px", CurrentValue = 100, Flag = "FOVSlider", Callback = function(Value) FOV_Radius = Value end})
Tab_Combat:CreateSlider({Name = "Aimbot Smoothing", Range = {1, 10}, Increment = 1, Suffix = " (Lower is faster)", CurrentValue = 3, Flag = "AimbotSmoothing", Callback = function(Value) Smoothing = Value end})

--// TriggerBot, Hitbox, Bhop (unchanged)
local TriggerBotEnabled = false
local TriggerBotDelay = 0
Tab_Combat:CreateSection("TriggerBot Settings")
Tab_Combat:CreateToggle({Name = "Enable TriggerBot", CurrentValue = false, Flag = "TriggerBotToggle", Callback = function(Value) TriggerBotEnabled = Value end})
Tab_Combat:CreateSlider({Name = "Shot Delay", Range = {0, 500}, Increment = 10, Suffix = "ms", CurrentValue = 0, Flag = "TriggerBotDelay", Callback = function(Value) TriggerBotDelay = Value end})

task.spawn(function()
    while task.wait(0.01) do
        if TriggerBotEnabled and isAlive() then
            local viewportSize = camera.ViewportSize
            local ray = camera:ViewportPointToRay(viewportSize.X / 2, viewportSize.Y / 2)
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            local ignoreList = {camera}
            if player.Character then table.insert(ignoreList, player.Character) end
            raycastParams.FilterDescendantsInstances = ignoreList
            local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
            if result and result.Instance then
                local hitPart = result.Instance
                local model = hitPart:FindFirstAncestorOfClass("Model")
                if model and model:FindFirstChildOfClass("Humanoid") then
                    local enemyFolder = getEnemyFolder()
                    if enemyFolder and model.Parent == enemyFolder then
                        local hum = model:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then
                            if TriggerBotDelay > 0 then task.wait(TriggerBotDelay / 1000) end
                            if mouse1click then mouse1click() end
                            task.wait(0.05)
                        end
                    end
                end
            end
        end
    end
end)

local HitboxEnabled = false
local HitboxSize = 3
local originalHeadSizes = {}
Tab_Combat:CreateSection("Simple Hitbox (Max 3)")
Tab_Combat:CreateToggle({Name = "Enable Hitbox", CurrentValue = false, Flag = "HitboxToggle", Callback = function(Value) HitboxEnabled = Value end})
Tab_Combat:CreateSlider({Name = "Hitbox Size", Range = {1, 3}, Increment = 0.1, Suffix = " Studs", CurrentValue = 3, Flag = "HitboxSize", Callback = function(Value) HitboxSize = Value end})

task.spawn(function()
    while task.wait(0.5) do
        local enemyFolder = getEnemyFolder()
        if enemyFolder then
            for _, enemy in ipairs(enemyFolder:GetChildren()) do
                local head = enemy:FindFirstChild("Head")
                local hum = enemy:FindFirstChildOfClass("Humanoid")
                if head and hum and hum.Health > 0 then
                    if not originalHeadSizes[head] then originalHeadSizes[head] = head.Size end
                    if HitboxEnabled then
                        head.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                        head.CanCollide = false
                        head.Transparency = 0.5
                    else
                        if originalHeadSizes[head] and head.Size ~= originalHeadSizes[head] then
                            head.Size = originalHeadSizes[head]
                            head.Transparency = 0
                        end
                    end
                end
            end
        end
    end
end)

local BhopEnabled = false
Tab_Combat:CreateSection("Movement Settings")
Tab_Combat:CreateToggle({Name = "Enable Bunny Hop (Hold Space)", CurrentValue = false, Flag = "BhopToggle", Callback = function(Value) BhopEnabled = Value end})

RunService.RenderStepped:Connect(function()
    if BhopEnabled and UserInputService:IsKeyDown(Enum.KeyCode.Space) and isAlive() then
        if player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum:GetState() ~= Enum.HumanoidStateType.Jumping and hum:GetState() ~= Enum.HumanoidStateType.Freefall then
                hum.Jump = true
            end
        end
    end
end)

--// SKINS TAB (unchanged)
local scriptRunning = false
local selectedKnife = "Butterfly Knife"
local spawned = false
local inspecting = false
local swinging = false
local lastAttackTime = 0
local ATTACK_COOLDOWN = 1
local ACTION_INSPECT = "InspectKnifeAction"
local ACTION_ATTACK = "AttackKnifeAction"

pcall(function() RS.Assets.Weapons.Karambit.Camera.ViewmodelLight.Transparency = 1 end)

local knives = {
    ["Karambit"] = {Offset = CFrame.new(0, -1.5, 1.5)},
    ["Butterfly Knife"] = {Offset = CFrame.new(0, -1.5, 1.5)},
    ["M9 Bayonet"] = {Offset = CFrame.new(0, -1.5, 1)},
    ["Flip Knife"] = {Offset = CFrame.new(0, -1.5, 1.25)},
    ["Gut Knife"] = {Offset = CFrame.new(0, -1.5, 0.5)},
}

local vm, animator
local equipAnim, idleAnim, inspectAnim, HeavySwingAnim, Swing1Anim, Swing2Anim

local function getKnifeInCamera() return camera:FindFirstChild("T Knife") or camera:FindFirstChild("CT Knife") end
local function cleanPart(part)
    if not part:IsA("BasePart") then return end
    part.CanCollide, part.Anchored, part.CastShadow, part.CanTouch, part.CanQuery = false, false, false, false, false
end
local function disableCollisions(model)
    for _, part in model:GetDescendants() do cleanPart(part) end
end
local function hideOriginalKnife(knife)
    for _, part in knife:GetDescendants() do
        if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("Texture") then part.Transparency = 1 end
    end
end
local function playSound(folder, name)
    local weaponSounds = RS.Sounds:FindFirstChild(selectedKnife)
    if not weaponSounds then return end
    local sound = weaponSounds:WaitForChild(folder):WaitForChild(name):Clone()
    sound.Parent = camera
    sound:Play()
    sound.Ended:Once(function() sound:Destroy() end)
    return sound
end

local function attachAsset(folder, armPartName, assetModelName, finalName, offset)
    local targetArm = vm:FindFirstChild(armPartName)
    if not targetArm then return end
    local assetMesh = folder:WaitForChild(assetModelName):Clone()
    cleanPart(assetMesh)
    assetMesh.Name = finalName
    assetMesh.Parent = targetArm
    local motor = Instance.new("Motor6D")
    motor.Part0, motor.Part1, motor.C0, motor.Parent = targetArm, assetMesh, offset, targetArm
end

local function handleAction(actionName, inputState, inputObject)
    if inputState ~= Enum.UserInputState.Begin or not spawned or not animator or not isAlive() then return Enum.ContextActionResult.Pass end
    if actionName == ACTION_INSPECT then
        if (equipAnim and equipAnim.IsPlaying) or inspecting or swinging then return Enum.ContextActionResult.Pass end
        inspecting = true
        if idleAnim then idleAnim:Stop() end
        inspectAnim:Play()
        inspectAnim.Stopped:Once(function() inspecting = false end)
    elseif actionName == ACTION_ATTACK then
        local currentTime = os.clock()
        if (equipAnim and equipAnim.IsPlaying) or (currentTime - lastAttackTime < ATTACK_COOLDOWN) then return Enum.ContextActionResult.Pass end
        lastAttackTime = currentTime
        if inspecting then inspecting = false; if inspectAnim then inspectAnim:Stop() end end
        swinging = true
        if idleAnim then idleAnim:Stop() end
        local anims = {HeavySwingAnim, Swing1Anim, Swing2Anim}
        local chosenAnim = anims[math.random(1, #anims)]
        local soundFolder = (chosenAnim == HeavySwingAnim and "HitOne") or (chosenAnim == Swing1Anim and "HitTwo") or "HitThree"
        chosenAnim:Play()
        local s = playSound(soundFolder, "1")
        if s then s.Volume = 5 end
        chosenAnim.Stopped:Once(function() swinging = false end)
    end
    return Enum.ContextActionResult.Pass
end

local function removeViewmodel()
    spawned = false
    CAS:UnbindAction(ACTION_INSPECT)
    CAS:UnbindAction(ACTION_ATTACK)
    if vm then vm:Destroy() vm = nil end
    animator, inspecting, swinging = nil, false, false
end

local function spawnViewmodel(knife)
    if spawned or not scriptRunning then return end
    local myModel = isAlive()
    if not myModel then return end
    spawned = true
    local knifeTemplate = RS.Assets.Weapons:WaitForChild(selectedKnife)
    local knifeOffset = knives[selectedKnife].Offset
    vm = knifeTemplate:WaitForChild("Camera"):Clone()
    vm.Name, vm.Parent = selectedKnife, camera
    disableCollisions(vm)
    hideOriginalKnife(knife)
    if myModel.Parent.Name == "Terrorists" then
        local tGloves = RS.Assets.Weapons:WaitForChild("T Glove")
        attachAsset(tGloves, "Left Arm", "Left Arm", "Glove", CFrame.new(0, 0, -1.5))
        attachAsset(tGloves, "Right Arm", "Right Arm", "Glove", CFrame.new(0, 0, -1.5))
    else
        local sleeves = RS.Assets.Sleeves:WaitForChild("IDF")
        local ctGloves = RS.Assets.Weapons:WaitForChild("CT Glove")
        attachAsset(sleeves, "Left Arm", "Left Arm", "Sleeve", CFrame.new(0, 0, 0.5))
        attachAsset(ctGloves, "Left Arm", "Left Arm", "Glove", CFrame.new(0, 0, -1.5))
        attachAsset(sleeves, "Right Arm", "Right Arm", "Sleeve", CFrame.new(0, 0, 0.5))
        attachAsset(ctGloves, "Right Arm", "Right Arm", "Glove", CFrame.new(0, 0, -1.5))
    end
    local animController = vm:FindFirstChildOfClass("AnimationController") or vm:FindFirstChildOfClass("Animator")
    animator = animController:FindFirstChildWhichIsA("Animator") or animController
    local animFolder = RS.Assets.WeaponAnimations:WaitForChild(selectedKnife):WaitForChild("CameraAnimations")
    equipAnim = animator:LoadAnimation(animFolder:WaitForChild("Equip"))
    idleAnim = animator:LoadAnimation(animFolder:WaitForChild("Idle"))
    inspectAnim = animator:LoadAnimation(animFolder:WaitForChild("Inspect"))
    HeavySwingAnim = animator:LoadAnimation(animFolder:WaitForChild("Heavy Swing"))
    Swing1Anim = animator:LoadAnimation(animFolder:WaitForChild("Swing1"))
    Swing2Anim = animator:LoadAnimation(animFolder:WaitForChild("Swing2"))
    vm:SetPrimaryPartCFrame(camera.CFrame * CFrame.new(0, -1.5, 5))
    TweenService:Create(vm.PrimaryPart, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        CFrame = camera.CFrame * knifeOffset
    }):Play()
    equipAnim:Play()
    playSound("Equip", "1")
    CAS:BindAction(ACTION_INSPECT, handleAction, false, Enum.KeyCode.F)
    CAS:BindAction(ACTION_ATTACK, handleAction, false, Enum.UserInputType.MouseButton1)
end

RunService.RenderStepped:Connect(function()
    if not scriptRunning or not vm or not vm.PrimaryPart then return end
    vm.PrimaryPart.CFrame = camera.CFrame * knives[selectedKnife].Offset
    if not (equipAnim and equipAnim.IsPlaying) and not inspecting and not swinging then
        if idleAnim and not idleAnim.IsPlaying then idleAnim:Play() end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        local living = isAlive()
        local currentKnife = getKnifeInCamera()
        if scriptRunning and living and currentKnife and not spawned then
            spawnViewmodel(currentKnife)
        elseif (not scriptRunning or not currentKnife or not living) and spawned then
            removeViewmodel()
        end
    end
end)

local SkinChangerEnabled = false
local SelectedSkins = {}
local DropdownObjects = {}
local SkinOptions = {}
local COOLDOWN = 0.1
local WEAR = "Factory New"
local CT_ONLY = {["USP-S"]=true, ["Five-SeveN"]=true, ["MP9"]=true, ["FAMAS"]=true, ["M4A1-S"]=true, ["M4A4"]=true, ["AUG"]=true}
local SHARED = {["P250"]=true, ["Desert Eagle"]=true, ["Dual Berettas"]=true, ["Negev"]=true, ["P90"]=true, ["Nova"]=true, ["XM1014"]=true, ["AWP"]=true, ["SSG 08"]=true}
local KNIVES = {["Karambit"]=true, ["Butterfly Knife"]=true, ["M9 Bayonet"]=true, ["Flip Knife"]=true, ["Gut Knife"]=true, ["T Knife"]=true, ["CT Knife"]=true}
local GLOVES = {["Sports Gloves"]=true}
local SkinsFolder = RS:WaitForChild("Assets"):WaitForChild("Skins")
local IgnoreFolders = {["HE Grenade"]=true, ["Incendiary Grenade"]=true, ["Molotov"]=true, ["Smoke Grenade"]=true, ["Flashbang"]=true, ["Decoy Grenade"]=true, ["C4"]=true, ["CT Glove"]=true, ["T Glove"]=true}

local function applyWeaponSkin(model)
    if not model or not SkinChangerEnabled or not isAlive() then return end
    local skinName = SelectedSkins[model.Name]
    if not skinName then return end
    pcall(function()
        local skinFolder = SkinsFolder:FindFirstChild(model.Name)
        if not skinFolder then return end
        local skinType = skinFolder:FindFirstChild(skinName)
        local sourceFolder = skinType and skinType:FindFirstChild("Camera") and skinType.Camera:FindFirstChild(WEAR)
        if not sourceFolder then return end
        for _, obj in camera:GetChildren() do
            local left, right = obj:FindFirstChild("Left Arm"), obj:FindFirstChild("Right Arm")
            if left or right then
                local gloveFolder = SkinsFolder:FindFirstChild("Sports Gloves")
                local gloveSkin = gloveFolder and gloveFolder:FindFirstChild(SelectedSkins["Sports Gloves"])
                local gloveSource = gloveSkin and gloveSkin:FindFirstChild("Camera") and gloveSkin.Camera:FindFirstChild(WEAR)
                if gloveSource then
                    for _, side in {"Left Arm", "Right Arm"} do
                        local arm, src = obj:FindFirstChild(side), gloveSource:FindFirstChild(side)
                        if arm and src then
                            local gloveMesh = arm:FindFirstChild("Glove")
                            if gloveMesh then
                                local existing = gloveMesh:FindFirstChildOfClass("SurfaceAppearance")
                                if existing then existing:Destroy() end
                                local clone = src:Clone()
                                clone.Name, clone.Parent = "SurfaceAppearance", gloveMesh
                            end
                        end
                    end
                end
            end
        end
        if not GLOVES[model.Name] then
            local weaponFolder = model:FindFirstChild("Weapon")
            if weaponFolder then
                for _, part in weaponFolder:GetDescendants() do
                    if part:IsA("BasePart") then
                        local newSkin = sourceFolder:FindFirstChild(part.Name)
                        if newSkin then
                            local existing = part:FindFirstChildOfClass("SurfaceAppearance")
                            if existing then existing:Destroy() end
                            local clone = newSkin:Clone()
                            clone.Name, clone.Parent = "SurfaceAppearance", part
                        end
                    end
                end
            end
        end
        model:SetAttribute("SkinApplied", skinName)
    end)
end

Tab_Skins:CreateToggle({Name = "Enable Skin Changer", CurrentValue = false, Flag = "SkinChangerToggle", Callback = function(Value) SkinChangerEnabled = Value; if not Value then for _, obj in camera:GetChildren() do obj:SetAttribute("SkinApplied", nil) end end end})
Tab_Skins:CreateButton({Name = "🎲 Randomize All Skins", Callback = function()
    for weaponName, optionsList in pairs(SkinOptions) do
        if #optionsList > 0 then
            local randomSkin = optionsList[math.random(1, #optionsList)]
            if DropdownObjects[weaponName] then
                for _, dropdown in ipairs(DropdownObjects[weaponName]) do dropdown:Set({randomSkin}) end
            end
        end
    end
end})

local function CreateSkinDropdown(weaponName)
    local folder = SkinsFolder:FindFirstChild(weaponName)
    if not folder then return end
    local options = {}
    for _, skin in folder:GetChildren() do table.insert(options, skin.Name) end
    SkinOptions[weaponName] = options
    if not SelectedSkins[weaponName] then SelectedSkins[weaponName] = options[1] end
    local dp = Tab_Skins:CreateDropdown({
        Name = weaponName,
        Options = options,
        CurrentOption = {SelectedSkins[weaponName]},
        Flag = "Skin_" .. weaponName,
        Callback = function(opt)
            local newSkin = opt[1]
            SelectedSkins[weaponName] = newSkin
            if DropdownObjects[weaponName] then
                for _, other in DropdownObjects[weaponName] do
                    if other.CurrentOption[1] ~= newSkin then other:Set({newSkin}) end
                end
            end
            for _, obj in camera:GetChildren() do obj:SetAttribute("SkinApplied", nil); applyWeaponSkin(obj) end
        end
    })
    DropdownObjects[weaponName] = DropdownObjects[weaponName] or {}
    table.insert(DropdownObjects[weaponName], dp)
end

Tab_Skins:CreateToggle({Name = "Enable Custom Knife", CurrentValue = false, Flag = "KnifeToggle", Callback = function(Value) scriptRunning = Value; if not Value then removeViewmodel() end end})
Tab_Skins:CreateDropdown({Name = "Selected Custom Knife", Options = {"Butterfly Knife", "Karambit", "M9 Bayonet", "Flip Knife", "Gut Knife"}, CurrentOption = {"Butterfly Knife"}, MultipleOptions = false, Flag = "KnifeDropdown", Callback = function(Options) selectedKnife = Options[1]; if spawned then removeViewmodel() end end})

Tab_Skins:CreateSection("Knives Skins")
for name in pairs(KNIVES) do CreateSkinDropdown(name) end
Tab_Skins:CreateSection("Gloves")
for name in pairs(GLOVES) do CreateSkinDropdown(name) end
Tab_Skins:CreateSection("CT Weapons")
for name in pairs(CT_ONLY) do CreateSkinDropdown(name) end
Tab_Skins:CreateSection("T Weapons")
for name in pairs(SHARED) do CreateSkinDropdown(name) end
for _, folder in SkinsFolder:GetChildren() do
    local n = folder.Name
    if not IgnoreFolders[n] and not KNIVES[n] and not GLOVES[n] and not CT_ONLY[n] and not SHARED[n] then CreateSkinDropdown(n) end
end

camera.ChildAdded:Connect(function(obj)
    if not SkinChangerEnabled or not isAlive() then return end
    task.wait(COOLDOWN); applyWeaponSkin(obj)
end)

task.spawn(function()
    while task.wait(0.5) do
        if SkinChangerEnabled and isAlive() then
            for _, obj in camera:GetChildren() do
                if SelectedSkins[obj.Name] and obj:GetAttribute("SkinApplied") ~= SelectedSkins[obj.Name] then applyWeaponSkin(obj) end
            end
        end
    end
end)

--// ESP + CHAMS
local EspEnabled = false
local EspBox = true
local EspName = true
local EspHealth = true
local EspDistance = true
local EspSkeleton = false
local EspHeadDot = false
local EspTracers = false
local EspMaxDistance = 0

local RainbowESP = false
local RainbowESP_Speed = 2.0
local RainbowChams = false
local RainbowChams_Speed = 2.0

local BoxColor = Color3.fromRGB(255, 50, 50)
local TextColor = Color3.fromRGB(255, 255, 255)
local SkeletonColor = Color3.fromRGB(255, 255, 255)
local TracerColor = Color3.fromRGB(255, 50, 50)
local HeadDotColor = Color3.fromRGB(255, 255, 255)
local EspTextSize = 15
local BoxThickness = 1.5

local ChamsEnabled = false
local ChamsColor = Color3.fromRGB(255, 0, 255)
local ChamsFillTransparency = 0.7
local ChamsOutlineTransparency = 0

local WeaponChamsEnabled = false
local WeaponChamsColor = Color3.fromRGB(0, 255, 255)
local WeaponChamsFillTransparency = 0.5
local WeaponChamsOutlineTransparency = 0.0

local espCache = {}
local chamsCache = {}
local weaponChamsCache = {}

--------------------------------------------------
-- RAINBOW
--------------------------------------------------

local function getRainbowColor(speed)
    return Color3.fromHSV((tick() * speed) % 1, 1, 1)
end

--------------------------------------------------
-- ESP CREATION
--------------------------------------------------

local function createESP()
    local esp = {
        boxOutline = Drawing.new("Square"),
        box = Drawing.new("Square"),

        name = Drawing.new("Text"),
        distance = Drawing.new("Text"),

        healthOutline = Drawing.new("Line"),
        healthBackground = Drawing.new("Line"),
        healthBar = Drawing.new("Line"),

        headDot = Drawing.new("Circle"),
        tracer = Drawing.new("Line"),

        skeleton = {
            headToNeck = Drawing.new("Line"),
            neckToTorso = Drawing.new("Line"),

            torsoToLeftUpper = Drawing.new("Line"),
            torsoToRightUpper = Drawing.new("Line"),

            leftUpperToLower = Drawing.new("Line"),
            rightUpperToLower = Drawing.new("Line"),

            leftLowerToFoot = Drawing.new("Line"),
            rightLowerToFoot = Drawing.new("Line")
        }
    }

    -- Box
    esp.boxOutline.Thickness = 3
    esp.boxOutline.Filled = false
    esp.boxOutline.Color = Color3.new(0, 0, 0)

    esp.box.Thickness = BoxThickness
    esp.box.Filled = false

    -- Name
    esp.name.Center = true
    esp.name.Outline = true
    esp.name.Size = EspTextSize

    -- Distance
    esp.distance.Center = true
    esp.distance.Outline = true
    esp.distance.Size = EspTextSize - 2

    -- Health
    esp.healthOutline.Thickness = 3
    esp.healthOutline.Color = Color3.new(0, 0, 0)

    esp.healthBackground.Thickness = 4
    esp.healthBackground.Color = Color3.new(0, 0, 0)
    esp.healthBackground.Transparency = 0.7

    esp.healthBar.Thickness = 2

    -- Head dot
    esp.headDot.Radius = 3
    esp.headDot.Filled = true
    esp.headDot.Transparency = 1

    -- Tracer
    esp.tracer.Thickness = 1.5
    esp.tracer.Transparency = 0.8

    -- Skeleton
    for _, line in pairs(esp.skeleton) do
        line.Thickness = 1.5
        line.Transparency = 0.9
    end

    return esp
end

--------------------------------------------------
-- HIDE ESP
--------------------------------------------------

local function hideESP(esp)
    if not esp then
        return
    end

    esp.boxOutline.Visible = false
    esp.box.Visible = false

    esp.name.Visible = false
    esp.distance.Visible = false

    esp.healthOutline.Visible = false
    esp.healthBackground.Visible = false
    esp.healthBar.Visible = false

    esp.headDot.Visible = false
    esp.tracer.Visible = false

    for _, line in pairs(esp.skeleton) do
        line.Visible = false
    end
end

--------------------------------------------------
-- REMOVE ESP COMPLETELY
--------------------------------------------------

local function removeESP(esp)
    if not esp then
        return
    end

    hideESP(esp)

    pcall(function()
        esp.boxOutline:Remove()
    end)

    pcall(function()
        esp.box:Remove()
    end)

    pcall(function()
        esp.name:Remove()
    end)

    pcall(function()
        esp.distance:Remove()
    end)

    pcall(function()
        esp.healthOutline:Remove()
    end)

    pcall(function()
        esp.healthBackground:Remove()
    end)

    pcall(function()
        esp.healthBar:Remove()
    end)

    pcall(function()
        esp.headDot:Remove()
    end)

    pcall(function()
        esp.tracer:Remove()
    end)

    for _, line in pairs(esp.skeleton) do
        pcall(function()
            line:Remove()
        end)
    end
end

--------------------------------------------------
-- SKELETON
--------------------------------------------------

local function updateSkeleton(esp, enemy, headPos, rootPos, color)
    if not EspSkeleton then
        for _, line in pairs(esp.skeleton) do
            line.Visible = false
        end
        return
    end

    local head = enemy:FindFirstChild("Head")

    local neck = enemy:FindFirstChild("Neck")
        or head

    local torso = enemy:FindFirstChild("UpperTorso")
        or enemy:FindFirstChild("Torso")

    local leftUpper = enemy:FindFirstChild("LeftUpperArm")
    local rightUpper = enemy:FindFirstChild("RightUpperArm")

    local leftLower = enemy:FindFirstChild("LeftLowerArm")
    local rightLower = enemy:FindFirstChild("RightLowerArm")

    local leftFoot = enemy:FindFirstChild("LeftFoot")
        or enemy:FindFirstChild("Left Leg")

    local rightFoot = enemy:FindFirstChild("RightFoot")
        or enemy:FindFirstChild("Right Leg")

    local function w2s(part)
        if not part then
            return rootPos
        end

        local pos, visible = camera:WorldToViewportPoint(part.Position)

        return Vector2.new(pos.X, pos.Y)
    end

    local lines = esp.skeleton

    for _, line in pairs(lines) do
        line.Color = color
        line.Visible = true
    end

    local headScreen = Vector2.new(headPos.X, headPos.Y)
    local neckScreen = w2s(neck)
    local torsoScreen = w2s(torso)

    lines.headToNeck.From = headScreen
    lines.headToNeck.To = neckScreen

    lines.neckToTorso.From = neckScreen
    lines.neckToTorso.To = torsoScreen

    lines.torsoToLeftUpper.From = torsoScreen
    lines.torsoToLeftUpper.To = w2s(leftUpper)

    lines.torsoToRightUpper.From = torsoScreen
    lines.torsoToRightUpper.To = w2s(rightUpper)

    lines.leftUpperToLower.From = w2s(leftUpper)
    lines.leftUpperToLower.To = w2s(leftLower)

    lines.rightUpperToLower.From = w2s(rightUpper)
    lines.rightUpperToLower.To = w2s(rightLower)

    lines.leftLowerToFoot.From = w2s(leftLower)
    lines.leftLowerToFoot.To = w2s(leftFoot)

    lines.rightLowerToFoot.From = w2s(rightLower)
    lines.rightLowerToFoot.To = w2s(rightFoot)
end

--------------------------------------------------
-- MAIN ESP LOOP
--------------------------------------------------

RunService.RenderStepped:Connect(function()
    -- ESP désactivé ou joueur local mort
    if not EspEnabled or not isAlive() then
        for _, esp in pairs(espCache) do
            hideESP(esp)
        end

        return
    end

    local enemyFolder = getEnemyFolder()

    if not enemyFolder then
        for _, esp in pairs(espCache) do
            hideESP(esp)
        end

        return
    end

    local currentAlive = {}

    local screenBottom = Vector2.new(
        camera.ViewportSize.X / 2,
        camera.ViewportSize.Y
    )

    local rainbowColor =
        RainbowESP
        and getRainbowColor(RainbowESP_Speed)
        or nil

    --------------------------------------------------
    -- UPDATE ENEMIES
    --------------------------------------------------

    for _, enemy in ipairs(enemyFolder:GetChildren()) do
        local hum = enemy:FindFirstChildOfClass("Humanoid")
        local root = enemy:FindFirstChild("HumanoidRootPart")
        local head = enemy:FindFirstChild("Head")

        -- Ennemi invalide / mort
        if not hum
            or hum.Health <= 0
            or not root
            or not head then

            if espCache[enemy] then
                removeESP(espCache[enemy])
                espCache[enemy] = nil
            end

            continue
        end

        currentAlive[enemy] = true

        --------------------------------------------------
        -- CREATE CACHE
        --------------------------------------------------

        local esp = espCache[enemy]

        if not esp then
            esp = createESP()
            espCache[enemy] = esp
        end

        --------------------------------------------------
        -- POSITION
        --------------------------------------------------

        local rootPos, rootVisible =
            camera:WorldToViewportPoint(root.Position)

        local headPos =
            camera:WorldToViewportPoint(
                head.Position + Vector3.new(0, 0.4, 0)
            )

        local legPos =
            camera:WorldToViewportPoint(
                root.Position - Vector3.new(0, 3.2, 0)
            )

        local distance =
            (camera.CFrame.Position - root.Position).Magnitude

        --------------------------------------------------
        -- DISTANCE CHECK
        --------------------------------------------------

        if EspMaxDistance > 0
            and distance > EspMaxDistance then

            hideESP(esp)
            continue
        end

        --------------------------------------------------
        -- OFF SCREEN
        --------------------------------------------------

        if not rootVisible
            or rootPos.Z <= 0 then

            hideESP(esp)
            continue
        end

        --------------------------------------------------
        -- BOX SIZE
        --------------------------------------------------

        local boxHeight =
            math.abs(headPos.Y - legPos.Y) * 1.05

        if boxHeight <= 1 then
            hideESP(esp)
            continue
        end

        local boxWidth = boxHeight * 0.55

        local boxX =
            rootPos.X - boxWidth / 2

        local boxY =
            headPos.Y

        --------------------------------------------------
        -- COLORS
        --------------------------------------------------

        local currentBoxColor =
            RainbowESP
            and rainbowColor
            or BoxColor

        local currentTextColor =
            RainbowESP
            and rainbowColor
            or TextColor

        local currentSkeletonColor =
            RainbowESP
            and rainbowColor
            or SkeletonColor

        local currentTracerColor =
            RainbowESP
            and rainbowColor
            or TracerColor

        local currentHeadDotColor =
            RainbowESP
            and rainbowColor
            or HeadDotColor

        --------------------------------------------------
        -- BOX
        --------------------------------------------------

        if EspBox then
            esp.boxOutline.Size =
                Vector2.new(boxWidth, boxHeight)

            esp.boxOutline.Position =
                Vector2.new(boxX, boxY)

            esp.boxOutline.Visible = true

            esp.box.Size =
                Vector2.new(boxWidth, boxHeight)

            esp.box.Position =
                Vector2.new(boxX, boxY)

            esp.box.Color =
                currentBoxColor

            esp.box.Thickness =
                BoxThickness

            esp.box.Visible = true
        else
            esp.boxOutline.Visible = false
            esp.box.Visible = false
        end

        --------------------------------------------------
        -- HEALTH
        --------------------------------------------------

        if EspHealth then
            local maxHealth =
                math.max(hum.MaxHealth, 1)

            local hpPct =
                math.clamp(
                    hum.Health / maxHealth,
                    0,
                    1
                )

            local barX =
                boxX - 7

            local barTop =
                boxY

            local barBottom =
                boxY + boxHeight

            esp.healthBackground.From =
                Vector2.new(barX, barTop)

            esp.healthBackground.To =
                Vector2.new(barX, barBottom)

            esp.healthBackground.Visible = true

            esp.healthOutline.From =
                Vector2.new(
                    barX - 1,
                    barTop - 1
                )

            esp.healthOutline.To =
                Vector2.new(
                    barX + 1,
                    barBottom + 1
                )

            esp.healthOutline.Visible = true

            esp.healthBar.From =
                Vector2.new(
                    barX,
                    barBottom
                )

            esp.healthBar.To =
                Vector2.new(
                    barX,
                    barBottom -
                    (boxHeight * hpPct)
                )

            esp.healthBar.Color =
                Color3.fromHSV(
                    hpPct * 0.33,
                    1,
                    1
                )

            esp.healthBar.Visible = true
        else
            esp.healthBackground.Visible = false
            esp.healthOutline.Visible = false
            esp.healthBar.Visible = false
        end

        --------------------------------------------------
        -- NAME
        --------------------------------------------------

        if EspName then
            esp.name.Text =
                enemy.Name

            esp.name.Position =
                Vector2.new(
                    rootPos.X,
                    headPos.Y - 22
                )

            esp.name.Color =
                currentTextColor

            esp.name.Size =
                EspTextSize

            esp.name.Visible = true
        else
            esp.name.Visible = false
        end

        --------------------------------------------------
        -- DISTANCE
        --------------------------------------------------

        if EspDistance then
            esp.distance.Text =
                string.format(
                    "[%d studs]",
                    math.floor(distance)
                )

            esp.distance.Position =
                Vector2.new(
                    rootPos.X,
                    boxY + boxHeight + 4
                )

            esp.distance.Color =
                currentTextColor

            esp.distance.Size =
                math.max(EspTextSize - 2, 1)

            esp.distance.Visible = true
        else
            esp.distance.Visible = false
        end

        --------------------------------------------------
        -- HEAD DOT
        --------------------------------------------------

        if EspHeadDot then
            esp.headDot.Position =
                Vector2.new(
                    headPos.X,
                    headPos.Y
                )

            esp.headDot.Color =
                currentHeadDotColor

            esp.headDot.Visible = true
        else
            esp.headDot.Visible = false
        end

        --------------------------------------------------
        -- TRACER
        --------------------------------------------------

        if EspTracers then
            esp.tracer.From =
                screenBottom

            esp.tracer.To =
                Vector2.new(
                    rootPos.X,
                    rootPos.Y + boxHeight / 2
                )

            esp.tracer.Color =
                currentTracerColor

            esp.tracer.Visible = true
        else
            esp.tracer.Visible = false
        end

        --------------------------------------------------
        -- SKELETON
        --------------------------------------------------

        updateSkeleton(
            esp,
            enemy,
            headPos,
            Vector2.new(rootPos.X, rootPos.Y),
            currentSkeletonColor
        )
    end

    --------------------------------------------------
    -- CLEAN OLD ESP
    --------------------------------------------------

    for enemy, esp in pairs(espCache) do
        local valid =
            currentAlive[enemy]
            and enemy.Parent
            and enemy:IsDescendantOf(enemyFolder)

        local hum =
            enemy.Parent
            and enemy:FindFirstChildOfClass("Humanoid")

        if not valid
            or not hum
            or hum.Health <= 0 then

            removeESP(esp)
            espCache[enemy] = nil
        end
    end
end)

--------------------------------------------------
-- PLAYER CHAMS
--------------------------------------------------

local function updatePlayerChams()
    local enemyFolder = getEnemyFolder()

    if not enemyFolder then
        for model, hl in pairs(chamsCache) do
            if hl then
                hl:Destroy()
            end

            chamsCache[model] = nil
        end

        return
    end

    local rainbowColor =
        RainbowChams
        and getRainbowColor(RainbowChams_Speed)
        or ChamsColor

    local activeModels = {}

    for _, enemy in ipairs(enemyFolder:GetChildren()) do
        local hum =
            enemy:FindFirstChildOfClass("Humanoid")

        if hum and hum.Health > 0 then
            activeModels[enemy] = true

            local highlight =
                chamsCache[enemy]

            if not highlight
                or not highlight.Parent then

                highlight =
                    Instance.new("Highlight")

                highlight.Adornee = enemy
                highlight.Parent = enemy

                chamsCache[enemy] = highlight
            end

            highlight.FillColor =
                rainbowColor

            highlight.OutlineColor =
                rainbowColor

            highlight.FillTransparency =
                ChamsFillTransparency

            highlight.OutlineTransparency =
                ChamsOutlineTransparency

            highlight.DepthMode =
                Enum.HighlightDepthMode.AlwaysOnTop
        end
    end

    -- Nettoyage des anciens chams
    for model, highlight in pairs(chamsCache) do
        local hum =
            model
            and model:FindFirstChildOfClass("Humanoid")

        if not activeModels[model]
            or not model.Parent
            or not hum
            or hum.Health <= 0 then

            if highlight then
                highlight:Destroy()
            end

            chamsCache[model] = nil
        end
    end
end

--------------------------------------------------
-- WEAPON CHAMS
--------------------------------------------------

local function updateWeaponChams()
    if not WeaponChamsEnabled then
        for _, hl in pairs(weaponChamsCache) do
            if hl then
                hl:Destroy()
            end
        end

        weaponChamsCache = {}
        return
    end

    local rainbowColor =
        RainbowChams
        and getRainbowColor(RainbowChams_Speed)
        or WeaponChamsColor

    local activeWeapons = {}

    for _, obj in ipairs(camera:GetChildren()) do
        if obj:IsA("Model")
            and (
                obj.Name:find("Knife")
                or obj:FindFirstChild("Weapon")
            ) then

            activeWeapons[obj] = true

            local highlight =
                weaponChamsCache[obj]

            if not highlight
                or not highlight.Parent then

                highlight =
                    Instance.new("Highlight")

                highlight.Adornee = obj
                highlight.Parent = obj

                weaponChamsCache[obj] =
                    highlight
            end

            highlight.FillColor =
                rainbowColor

            highlight.OutlineColor =
                rainbowColor

            highlight.FillTransparency =
                WeaponChamsFillTransparency

            highlight.OutlineTransparency =
                WeaponChamsOutlineTransparency

            highlight.DepthMode =
                Enum.HighlightDepthMode.AlwaysOnTop
        end
    end

    for obj, highlight in pairs(weaponChamsCache) do
        if not activeWeapons[obj]
            or not obj.Parent then

            if highlight then
                highlight:Destroy()
            end

            weaponChamsCache[obj] = nil
        end
    end
end

--------------------------------------------------
-- CHAMS UPDATE LOOP
--------------------------------------------------

task.spawn(function()
    while task.wait(0.05) do

        if ChamsEnabled then
            updatePlayerChams()
        else
            for model, hl in pairs(chamsCache) do
                if hl then
                    hl:Destroy()
                end

                chamsCache[model] = nil
            end
        end

        updateWeaponChams()
    end
end)

--------------------------------------------------
-- COMPLETE ESP CLEANUP
--------------------------------------------------

local function clearAllESP()
    for enemy, esp in pairs(espCache) do
        removeESP(esp)
        espCache[enemy] = nil
    end

    for model, hl in pairs(chamsCache) do
        if hl then
            hl:Destroy()
        end

        chamsCache[model] = nil
    end

    for obj, hl in pairs(weaponChamsCache) do
        if hl then
            hl:Destroy()
        end

        weaponChamsCache[obj] = nil
    end
end

--------------------------------------------------
-- RESPAWN / CHARACTER CHANGES
--------------------------------------------------

player.CharacterAdded:Connect(function()
    -- Nettoyage immédiat quand le joueur local respawn
    clearAllESP()
end)

CharactersFolder.ChildRemoved:Connect(function()
    -- Nettoyage léger quand une équipe disparaît
    task.defer(function()
        for enemy, esp in pairs(espCache) do
            if not enemy.Parent then
                removeESP(esp)
                espCache[enemy] = nil
            end
        end

        for model, hl in pairs(chamsCache) do
            if not model.Parent then
                if hl then
                    hl:Destroy()
                end

                chamsCache[model] = nil
            end
        end
    end)
end)

--// ADVANCED BULLET TRACERS WITH PATTERNS (unchanged)
local BulletTracersEnabled = false
local BulletTracerColor = Color3.fromRGB(0, 255, 255)
local BulletTracerTransparency = 0.3
local BulletTracerDuration = 0.6
local BulletTracerThickness = 0.2
local BulletTracerPattern = "Straight"

local tracerParts = {}

local function createAdvancedTracer(origin, direction)
    local tracer = Instance.new("Part")
    tracer.Anchored = true
    tracer.CanCollide = false
    tracer.Transparency = BulletTracerTransparency
    tracer.Color = BulletTracerColor
    tracer.Material = Enum.Material.Neon
    tracer.Size = Vector3.new(BulletTracerThickness, BulletTracerThickness, 300)
    tracer.CFrame = CFrame.new(origin, origin + direction) * CFrame.new(0, 0, -150)
    tracer.Parent = Workspace

    if BulletTracerPattern == "Wave" then
        task.spawn(function()
            local startTime = tick()
            while tracer.Parent and (tick() - startTime) < BulletTracerDuration do
                local t = (tick() - startTime) * 15
                local offset = Vector3.new(math.sin(t) * 2, 0, 0)
                tracer.CFrame = CFrame.new(origin + offset, origin + direction + offset) * CFrame.new(0, 0, -150)
                RunService.Heartbeat:Wait()
            end
            if tracer.Parent then tracer:Destroy() end
        end)
    elseif BulletTracerPattern == "Spiral" then
        task.spawn(function()
            local startTime = tick()
            while tracer.Parent and (tick() - startTime) < BulletTracerDuration do
                local t = (tick() - startTime) * 20
                local offset = Vector3.new(math.cos(t) * 1.5, math.sin(t) * 1.5, 0)
                tracer.CFrame = CFrame.new(origin + offset, origin + direction + offset) * CFrame.new(0, 0, -150)
                RunService.Heartbeat:Wait()
            end
            if tracer.Parent then tracer:Destroy() end
        end)
    elseif BulletTracerPattern == "Dashed" then
        task.spawn(function()
            local startTime = tick()
            while tracer.Parent and (tick() - startTime) < BulletTracerDuration do
                tracer.Transparency = (math.sin(tick() * 30) > 0) and BulletTracerTransparency or 1
                RunService.Heartbeat:Wait()
            end
            if tracer.Parent then tracer:Destroy() end
        end)
    else
        task.delay(BulletTracerDuration, function()
            if tracer and tracer.Parent then tracer:Destroy() end
        end)
    end

    table.insert(tracerParts, tracer)
end

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and BulletTracersEnabled and isAlive() then
        local origin = camera.CFrame.Position
        local direction = camera.CFrame.LookVector * 300
        createAdvancedTracer(origin, direction)
    end
end)

RunService.Heartbeat:Connect(function()
    for i = #tracerParts, 1, -1 do
        if not tracerParts[i].Parent then
            table.remove(tracerParts, i)
        end
    end
end)

--// PARTICLE EFFECTS (unchanged)
local ParticleEffectsEnabled = false
local ParticleColor = Color3.fromRGB(255, 100, 0)
local ParticleAmount = 25
local ParticleLifetime = 1.2
local ParticleStyle = "Spark"

local function createParticleEffect(position)
    if not ParticleEffectsEnabled then return end

    local attachment = Instance.new("Attachment")
    attachment.Position = position
    attachment.Parent = Workspace.Terrain

    local particle = Instance.new("ParticleEmitter")
    particle.Color = ColorSequence.new(ParticleColor)
    particle.Texture = "rbxassetid://243660364"
    particle.Lifetime = NumberRange.new(ParticleLifetime * 0.6, ParticleLifetime)
    particle.Rate = 0
    particle.EmissionDirection = Enum.NormalId.Front
    particle.SpreadAngle = Vector2.new(35, 35)
    particle.Speed = NumberRange.new(8, 18)
    particle.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0.1)})
    particle.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
    particle.Parent = attachment

    if ParticleStyle == "Smoke" then
        particle.Texture = "rbxassetid://243098098"
        particle.Speed = NumberRange.new(2, 6)
    elseif ParticleStyle == "Fire" then
        particle.Texture = "rbxassetid://241650934"
        particle.Speed = NumberRange.new(5, 12)
    elseif ParticleStyle == "Explosion" then
        particle.Lifetime = NumberRange.new(0.4, 0.8)
        particle.Speed = NumberRange.new(15, 30)
        particle.SpreadAngle = Vector2.new(80, 80)
        particle.Amount = ParticleAmount * 2
    elseif ParticleStyle == "Magic" then
        particle.Texture = "rbxassetid://243098098"
        particle.RotSpeed = NumberRange.new(-200, 200)
    end

    particle:Emit(ParticleAmount)

    task.delay(ParticleLifetime + 0.5, function()
        if attachment then attachment:Destroy() end
    end)
end

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and ParticleEffectsEnabled and isAlive() then
        local ray = camera:ViewportPointToRay(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {camera, player.Character or {}}
        local result = Workspace:Raycast(ray.Origin, ray.Direction * 500, raycastParams)

        if result and result.Position then
            createParticleEffect(result.Position)
        else
            local muzzlePos = camera.CFrame.Position + camera.CFrame.LookVector * 3
            createParticleEffect(muzzlePos)
        end
    end
end)

--// KILL EFFECTS (NEW)
local KillEffectsEnabled = false
local KillEffectColor = Color3.fromRGB(255, 0, 100)
local KillEffectDuration = 0.8
local KillEffectIntensity = 0.6

local killFlashGui = nil
local killText = nil

local function createKillEffects()
    if not KillEffectsEnabled then return end

    -- Screen Flash
    if not killFlashGui then
        killFlashGui = Instance.new("ScreenGui")
        killFlashGui.ResetOnSpawn = false
        killFlashGui.Parent = player:WaitForChild("PlayerGui")

        local flashFrame = Instance.new("Frame")
        flashFrame.Size = UDim2.new(1, 0, 1, 0)
        flashFrame.BackgroundColor3 = KillEffectColor
        flashFrame.BackgroundTransparency = 1
        flashFrame.BorderSizePixel = 0
        flashFrame.Parent = killFlashGui
        killFlashGui.Frame = flashFrame
    end

    local flash = killFlashGui.Frame
    flash.BackgroundTransparency = 0.2
    TweenService:Create(flash, TweenInfo.new(KillEffectDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()

    -- Floating Kill Text
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(0, 300, 0, 100)
    text.Position = UDim2.new(0.5, -150, 0.4, 0)
    text.BackgroundTransparency = 1
    text.Text = "KILL"
    text.TextColor3 = KillEffectColor
    text.TextScaled = true
    text.Font = Enum.Font.GothamBold
    text.TextStrokeTransparency = 0
    text.TextStrokeColor3 = Color3.new(0, 0, 0)
    text.Parent = player.PlayerGui

    TweenService:Create(text, TweenInfo.new(KillEffectDuration * 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -150, 0.25, 0), TextTransparency = 1}):Play()

    task.delay(KillEffectDuration, function()
        if text and text.Parent then text:Destroy() end
    end)
end

-- Detect kills (monitor enemy health dropping to 0)
task.spawn(function()
    local lastHealth = {}
    while task.wait(0.1) do
        if not KillEffectsEnabled then continue end
        local enemyFolder = getEnemyFolder()
        if not enemyFolder then continue end

        for _, enemy in ipairs(enemyFolder:GetChildren()) do
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            if hum then
                local currentHealth = hum.Health
                if lastHealth[enemy] and lastHealth[enemy] > 0 and currentHealth <= 0 then
                    createKillEffects()
                end
                lastHealth[enemy] = currentHealth
            end
        end
    end
end)

--// Visuals Tab UI
Tab_Visuals:CreateSection("ESP Master Switch")
Tab_Visuals:CreateToggle({Name = "Enable Player ESP", CurrentValue = false, Flag = "ESPToggle", Callback = function(Value) EspEnabled = Value end})

Tab_Visuals:CreateSection("ESP Visual Settings")
Tab_Visuals:CreateToggle({Name = "Show Box", CurrentValue = true, Flag = "EspBoxToggle", Callback = function(Value) EspBox = Value end})
Tab_Visuals:CreateToggle({Name = "Show Health Bar", CurrentValue = true, Flag = "EspHealthToggle", Callback = function(Value) EspHealth = Value end})
Tab_Visuals:CreateToggle({Name = "Show Name", CurrentValue = true, Flag = "EspNameToggle", Callback = function(Value) EspName = Value end})
Tab_Visuals:CreateToggle({Name = "Show Distance", CurrentValue = true, Flag = "EspDistanceToggle", Callback = function(Value) EspDistance = Value end})
Tab_Visuals:CreateToggle({Name = "Show Skeleton", CurrentValue = false, Flag = "EspSkeletonToggle", Callback = function(Value) EspSkeleton = Value end})
Tab_Visuals:CreateToggle({Name = "Show Head Dot", CurrentValue = false, Flag = "EspHeadDotToggle", Callback = function(Value) EspHeadDot = Value end})
Tab_Visuals:CreateToggle({Name = "Show Tracers", CurrentValue = false, Flag = "EspTracersToggle", Callback = function(Value) EspTracers = Value end})

Tab_Visuals:CreateSection("Rainbow Settings")
Tab_Visuals:CreateToggle({Name = "🌈 Rainbow ESP", CurrentValue = false, Flag = "RainbowESPToggle", Callback = function(Value) RainbowESP = Value end})
Tab_Visuals:CreateSlider({Name = "Rainbow ESP Speed", Range = {0.1, 10}, Increment = 0.1, Suffix = "", CurrentValue = 2.0, Flag = "RainbowESPSpeed", Callback = function(Value) RainbowESP_Speed = Value end})

Tab_Visuals:CreateToggle({Name = "🌈 Rainbow Chams", CurrentValue = false, Flag = "RainbowChamsToggle", Callback = function(Value) RainbowChams = Value end})
Tab_Visuals:CreateSlider({Name = "Rainbow Chams Speed", Range = {0.1, 10}, Increment = 0.1, Suffix = "", CurrentValue = 2.0, Flag = "RainbowChamsSpeed", Callback = function(Value) RainbowChams_Speed = Value end})

Tab_Visuals:CreateSection("Player Chams (See Through Walls)")
Tab_Visuals:CreateToggle({Name = "Enable Player Chams", CurrentValue = false, Flag = "ChamsToggle", Callback = function(Value) ChamsEnabled = Value; if not Value then for _, hl in pairs(chamsCache) do hl:Destroy() end chamsCache = {} end end})
Tab_Visuals:CreateColorPicker({Name = "Player Chams Color (when Rainbow off)", Color = Color3.fromRGB(255, 0, 255), Flag = "ChamsColorPicker", Callback = function(Value) ChamsColor = Value end})
Tab_Visuals:CreateSlider({Name = "Player Chams Fill Transparency", Range = {0, 1}, Increment = 0.05, Suffix = "", CurrentValue = 0.7, Flag = "ChamsFillTrans", Callback = function(Value) ChamsFillTransparency = Value end})
Tab_Visuals:CreateSlider({Name = "Player Chams Outline Transparency", Range = {0, 1}, Increment = 0.05, Suffix = "", CurrentValue = 0, Flag = "ChamsOutlineTrans", Callback = function(Value) ChamsOutlineTransparency = Value end})

Tab_Visuals:CreateSection("Weapon Chams")
Tab_Visuals:CreateToggle({Name = "Enable Weapon Chams", CurrentValue = false, Flag = "WeaponChamsToggle", Callback = function(Value) WeaponChamsEnabled = Value end})
Tab_Visuals:CreateColorPicker({Name = "Weapon Chams Color", Color = Color3.fromRGB(0, 255, 255), Flag = "WeaponChamsColorPicker", Callback = function(Value) WeaponChamsColor = Value end})
Tab_Visuals:CreateSlider({Name = "Weapon Chams Fill Transparency", Range = {0, 1}, Increment = 0.05, Suffix = "", CurrentValue = 0.5, Flag = "WeaponChamsFillTrans", Callback = function(Value) WeaponChamsFillTransparency = Value end})
Tab_Visuals:CreateSlider({Name = "Weapon Chams Outline Transparency", Range = {0, 1}, Increment = 0.05, Suffix = "", CurrentValue = 0, Flag = "WeaponChamsOutlineTrans", Callback = function(Value) WeaponChamsOutlineTransparency = Value end})

Tab_Visuals:CreateSection("Advanced Bullet Tracers")
Tab_Visuals:CreateToggle({Name = "Enable Bullet Tracers", CurrentValue = false, Flag = "BulletTracersToggle", Callback = function(Value) BulletTracersEnabled = Value end})
Tab_Visuals:CreateDropdown({Name = "Tracer Pattern", Options = {"Straight", "Wave", "Spiral", "Dashed"}, CurrentOption = {"Straight"}, Flag = "TracerPattern", Callback = function(Option) BulletTracerPattern = Option[1] end})
Tab_Visuals:CreateColorPicker({Name = "Tracer Color", Color = Color3.fromRGB(0, 255, 255), Flag = "BulletTracerColorPicker", Callback = function(Value) BulletTracerColor = Value end})
Tab_Visuals:CreateSlider({Name = "Tracer Transparency", Range = {0, 1}, Increment = 0.05, Suffix = "", CurrentValue = 0.3, Flag = "BulletTracerTrans", Callback = function(Value) BulletTracerTransparency = Value end})
Tab_Visuals:CreateSlider({Name = "Tracer Duration", Range = {0.1, 2}, Increment = 0.1, Suffix = " sec", CurrentValue = 0.6, Flag = "BulletTracerDuration", Callback = function(Value) BulletTracerDuration = Value end})
Tab_Visuals:CreateSlider({Name = "Tracer Thickness", Range = {0.1, 1}, Increment = 0.05, Suffix = "", CurrentValue = 0.2, Flag = "BulletTracerThickness", Callback = function(Value) BulletTracerThickness = Value end})

Tab_Visuals:CreateSection("Particle Effects")
Tab_Visuals:CreateToggle({Name = "Enable Particle Effects", CurrentValue = false, Flag = "ParticleEffectsToggle", Callback = function(Value) ParticleEffectsEnabled = Value end})
Tab_Visuals:CreateColorPicker({Name = "Particle Color", Color = Color3.fromRGB(255, 100, 0), Flag = "ParticleColorPicker", Callback = function(Value) ParticleColor = Value end})
Tab_Visuals:CreateSlider({Name = "Particle Amount", Range = {5, 80}, Increment = 5, Suffix = "", CurrentValue = 25, Flag = "ParticleAmount", Callback = function(Value) ParticleAmount = Value end})
Tab_Visuals:CreateSlider({Name = "Particle Lifetime", Range = {0.3, 3}, Increment = 0.1, Suffix = " sec", CurrentValue = 1.2, Flag = "ParticleLifetime", Callback = function(Value) ParticleLifetime = Value end})
Tab_Visuals:CreateDropdown({Name = "Particle Style", Options = {"Spark", "Smoke", "Fire", "Explosion", "Magic"}, CurrentOption = {"Spark"}, Flag = "ParticleStyle", Callback = function(Option) ParticleStyle = Option[1] end})

--// Kill Effects Section
Tab_Visuals:CreateSection("Kill Effects")
Tab_Visuals:CreateToggle({Name = "Enable Kill Effects", CurrentValue = false, Flag = "KillEffectsToggle", Callback = function(Value) KillEffectsEnabled = Value end})
Tab_Visuals:CreateColorPicker({Name = "Kill Effect Color", Color = Color3.fromRGB(255, 0, 100), Flag = "KillEffectColorPicker", Callback = function(Value) KillEffectColor = Value end})
Tab_Visuals:CreateSlider({Name = "Kill Effect Duration", Range = {0.3, 2}, Increment = 0.1, Suffix = " sec", CurrentValue = 0.8, Flag = "KillEffectDuration", Callback = function(Value) KillEffectDuration = Value end})
Tab_Visuals:CreateSlider({Name = "Kill Effect Intensity", Range = {0.2, 1}, Increment = 0.1, Suffix = "", CurrentValue = 0.6, Flag = "KillEffectIntensity", Callback = function(Value) KillEffectIntensity = Value end})

Tab_Visuals:CreateSection("ESP Customization (when Rainbow is off)")
Tab_Visuals:CreateColorPicker({Name = "Box Color", Color = Color3.fromRGB(255, 50, 50), Flag = "BoxColorPicker", Callback = function(Value) BoxColor = Value end})
Tab_Visuals:CreateColorPicker({Name = "Text Color (Name/Distance)", Color = Color3.fromRGB(255, 255, 255), Flag = "TextColorPicker", Callback = function(Value) TextColor = Value end})
Tab_Visuals:CreateColorPicker({Name = "Skeleton Color", Color = Color3.fromRGB(255, 255, 255), Flag = "SkeletonColorPicker", Callback = function(Value) SkeletonColor = Value end})
Tab_Visuals:CreateColorPicker({Name = "Tracer Color", Color = Color3.fromRGB(255, 50, 50), Flag = "TracerColorPicker", Callback = function(Value) TracerColor = Value end})
Tab_Visuals:CreateColorPicker({Name = "Head Dot Color", Color = Color3.fromRGB(255, 255, 255), Flag = "HeadDotColorPicker", Callback = function(Value) HeadDotColor = Value end})

Tab_Visuals:CreateSlider({Name = "Text Size", Range = {10, 20}, Increment = 1, Suffix = "", CurrentValue = 15, Flag = "EspTextSize", Callback = function(Value) EspTextSize = Value end})
Tab_Visuals:CreateSlider({Name = "Box Thickness", Range = {1, 3}, Increment = 0.1, Suffix = "", CurrentValue = 1.5, Flag = "BoxThickness", Callback = function(Value) BoxThickness = Value end})
Tab_Visuals:CreateSlider({Name = "Max ESP Distance", Range = {0, 500}, Increment = 10, Suffix = " studs (0 = unlimited)", CurrentValue = 0, Flag = "EspDistanceLimit", Callback = function(Value) EspMaxDistance = Value end})

--// Configs
Tab_Visuals:CreateSection("Configs")
Tab_Visuals:CreateButton({Name = "Save Current Config", Callback = function() Rayfield:SaveConfiguration() Rayfield:Notify({Title = "Config Saved", Content = "Settings saved successfully!", Duration = 3}) end})
Tab_Visuals:CreateButton({Name = "Load Last Config", Callback = function() Rayfield:LoadConfiguration() Rayfield:Notify({Title = "Config Loaded", Content = "Last config loaded.", Duration = 3}) end})

--// World & Effects (Anti-Flash / Anti-Smoke only)
local AntiFlashEnabled, AntiSmokeEnabled = false, false
Tab_Visuals:CreateSection("World & Effects")
Tab_Visuals:CreateToggle({Name = "Anti-Flashbang", CurrentValue = false, Flag = "AntiFlashToggle", Callback = function(Value) AntiFlashEnabled = Value end})
Tab_Visuals:CreateToggle({Name = "Anti-Smoke", CurrentValue = false, Flag = "AntiSmokeToggle", Callback = function(Value) AntiSmokeEnabled = Value end})

task.spawn(function()
    while task.wait(0.2) do
        if AntiFlashEnabled then
            local gui = player.PlayerGui:FindFirstChild("FlashbangEffect")
            local effect = game:GetService("Lighting"):FindFirstChild("FlashbangColorCorrection")
            if gui then gui:Destroy() end
            if effect then effect:Destroy() end
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if AntiSmokeEnabled then
            local debris = Workspace:FindFirstChild("Debris")
            if debris then
                for _, folder in ipairs(debris:GetChildren()) do
                    if string.match(folder.Name, "Voxel") then folder:ClearAllChildren(); folder:Destroy() end
                end
            end
        end
    end
end)

Rayfield:LoadConfiguration()

-- ============================================================
--  BROOKHAVEN TORNADO V11 — GUI COMPLETA
--  Nuvem visível em todos os EFs · El Reno · Mobile-friendly
-- ============================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Brookhaven Tornado V11",
    LoadingTitle = "Carregando Tornado V11...",
    LoadingSubtitle = "nuvem visível · El Reno",
    Theme = "DarkBlue",
    ToggleUIKeybind = nil,
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false,
})

local Tab = Window:CreateTab("🌪️ Tornado", 4483362458)

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

-- ============================================================
-- 🎵 MÚSICA DO EL RENO
-- ============================================================
local MUSICA_EL_RENO = "rbxassetid://1837224326"

-- ============================================================
-- CONFIG
-- ============================================================
local cfg = {
    tamanho = 150,
    altura = 700,
    velocidade = 4,
    camadas = 30,
    porAnel = 10,
    cor = Color3.fromRGB(90, 85, 80),
    transparencia = 0.3,
    destrocosQtd = 20,
    wanderAtivo = true,
    wanderVel = 60,
    wanderTroca = 6,
    cinematico = true,
    descidaVel = 200,
}

local tornadoFolder, nuvemFolder, ativo, seguir = nil, nil, false, false
local somVento, somMusica, luz = nil, nil, nil

local todasParts, todasCFrames, todasData = {}, {}, {}
local destrocosParts, destrocosData = {}, {}
local nuvemParts, nuvemData = {}, {}

local centroX, centroZ = 0, 0
local wanderTarget = Vector3.new(0, 0, 0)
local wanderTimer = 0

local descidaOffset = 0
local descidaAtiva = false
local descidaVelAtual = 200

-- Ambiente
Lighting.FogEnd = 200000
Lighting.FogStart = 100000
pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)

-- ============================================================
-- LIMPEZA
-- ============================================================
local function destruir()
    if tornadoFolder then tornadoFolder:Destroy() end
    if nuvemFolder then nuvemFolder:Destroy() end
    tornadoFolder, nuvemFolder = nil, nil
    todasParts, todasCFrames, todasData = {}, {}, {}
    destrocosParts, destrocosData = {}, {}
    nuvemParts, nuvemData = {}, {}
    somVento, somMusica, luz = nil, nil, nil
    ativo = false
    descidaAtiva = false
    descidaOffset = 0
end

-- ============================================================
-- ☁️ NUVEM CUMULONIMBUS (corrigida — visível em TODOS os EFs)
-- ============================================================
local function criarNuvem(basePos, cloudY)
    nuvemFolder = Instance.new("Folder")
    nuvemFolder.Name = "Cumulonimbus"
    nuvemFolder.Parent = workspace

    -- CORREÇÃO: tamanho mínimo de 500 studs (senão EFs pequenos ficam invisíveis)
    local tamBase = math.max(cfg.tamanho, 500) * 0.9

    -- CORREÇÃO: nuvem fica mais baixa pra ser visível
    cloudY = basePos.Y + math.max(cfg.altura * 0.6, 300)

    local corBaixo = Color3.fromRGB(45, 45, 55)
    local corMeio  = Color3.fromRGB(70, 70, 80)
    local corTopo  = Color3.fromRGB(120, 120, 135)

    local function addPart(pos, size, color, transp)
        local p = Instance.new("Part")
        p.Shape = Enum.PartType.Ball
        p.Anchored = true
        p.CanCollide = false
        p.CanQuery = false
        p.CanTouch = false
        p.CastShadow = false
        p.Material = Enum.Material.SmoothPlastic
        p.Color = color
        p.Transparency = transp
        p.Size = size
        p.Position = pos
        p.Parent = nuvemFolder
        table.insert(nuvemParts, p)
        table.insert(nuvemData, {origX=pos.X, origY=pos.Y, origZ=pos.Z})
    end

    -- Base (anvil escura)
    for i = 1, 14 do
        local ang = (i/14) * math.pi * 2
        local raio = tamBase * 0.9
        local tam = tamBase * (0.9 + math.random() * 0.3)
        addPart(
            basePos + Vector3.new(math.cos(ang)*raio, cloudY - tamBase*0.4, math.sin(ang)*raio),
            Vector3.new(tam*1.2, tam*0.4, tam),
            corBaixo, 0.4
        )
    end

    -- Meio (corpo)
    for i = 1, 20 do
        local ang = math.random() * math.pi * 2
        local raio = math.random() * tamBase * 0.85
        local alt = cloudY + (math.random() - 0.3) * tamBase * 0.9
        local tam = tamBase * (0.7 + math.random() * 0.6)
        addPart(
            basePos + Vector3.new(math.cos(ang)*raio, alt, math.sin(ang)*raio),
            Vector3.new(tam*1.1, tam*0.85, tam),
            corMeio, 0.45
        )
    end

    -- Topo (billowing)
    for i = 1, 10 do
        local ang = (i/10) * math.pi * 2
        local raio = tamBase * (0.4 + math.random() * 0.3)
        local alt = cloudY + tamBase * (0.6 + math.random() * 0.5)
        local tam = tamBase * (1 + math.random() * 0.5)
        addPart(
            basePos + Vector3.new(math.cos(ang)*raio, alt, math.sin(ang)*raio),
            Vector3.new(tam, tam*0.85, tam),
            corTopo, 0.5
        )
    end

    -- Fade-in
    task.spawn(function()
        for _, p in ipairs(nuvemParts) do
            p:SetAttribute("transpAlvo", p.Transparency)
            p.Transparency = 1
        end
        task.wait(0.2)
        for step = 1, 12 do
            task.wait(0.08)
            local t = step / 12
            for _, p in ipairs(nuvemParts) do
                local alvo = p:GetAttribute("transpAlvo") or 0.5
                p.Transparency = 1 - (1 - alvo) * t
            end
        end
    end)
end

-- ============================================================
-- CRIAR TORNADO
-- ============================================================
local function criarTornado(basePos, tocarMusica)
    basePos = basePos or Vector3.new(0, 3, 0)
    centroX, centroZ = basePos.X, basePos.Z

    if cfg.cinematico then
        local cloudY = basePos.Y + cfg.altura
        criarNuvem(basePos, cloudY)
        descidaOffset = cfg.altura
        descidaVelAtual = cfg.descidaVel
        descidaAtiva = true
        task.wait(1.2)
    else
        descidaOffset = 0
        descidaAtiva = false
    end

    tornadoFolder = Instance.new("Folder")
    tornadoFolder.Name = "TornadoV11"
    tornadoFolder.Parent = workspace

    -- FUNIL
    for i = 1, cfg.camadas do
        local fator = i / cfg.camadas
        local raio = cfg.tamanho * (0.15 + math.pow(fator, 0.75) * 0.85)
        local y = basePos.Y + i * (cfg.altura / cfg.camadas)
        local circ = 2 * math.pi * raio
        local tamP = math.max(circ / cfg.porAnel * 1.3, cfg.tamanho * 0.05)

        local cor = cfg.cor
        if fator > 0.3 and fator < 0.9 then
            cor = cfg.cor:Lerp(Color3.fromRGB(45, 42, 40), 0.5)
        end

        local velAnel = cfg.velocidade * (0.5 + fator * 1.5)

        for j = 1, cfg.porAnel do
            local angBase = (j / cfg.porAnel) * math.pi * 2
            local part = Instance.new("Part")
            part.Anchored = true
            part.CanCollide = false
            part.CanQuery = false
            part.CanTouch = false
            part.CastShadow = false
            part.Material = Enum.Material.SmoothPlastic
            part.Color = cor
            part.Transparency = cfg.transparencia
            part.Size = Vector3.new(tamP*1.4, tamP*0.7, tamP*0.9)
            part.CFrame = CFrame.new(
                centroX + math.cos(angBase)*raio,
                y + descidaOffset,
                centroZ + math.sin(angBase)*raio
            ) * CFrame.Angles(0, angBase + math.pi/2, 0)
            part.Parent = tornadoFolder

            table.insert(todasParts, part)
            table.insert(todasCFrames, part.CFrame)
            table.insert(todasData, {angBase=angBase, raio=raio, y=y, vel=velAnel})
        end
    end

    -- DESTROÇOS
    for i = 1, cfg.destrocosQtd do
        local obj = Instance.new("Part")
        local tipo = math.random(1, 4)
        if tipo == 1 then
            obj.Size = Vector3.new(cfg.tamanho*0.03, cfg.tamanho*0.1, cfg.tamanho*0.03)
            obj.Color = Color3.fromRGB(80, 50, 25)
        elseif tipo == 2 then
            obj.Size = Vector3.new(cfg.tamanho*0.06, cfg.tamanho*0.04, cfg.tamanho*0.1)
            obj.Color = Color3.fromRGB(math.random(80,200), math.random(80,200), math.random(80,200))
        elseif tipo == 3 then
            obj.Size = Vector3.new(cfg.tamanho*0.07, cfg.tamanho*0.06, cfg.tamanho*0.07)
            obj.Color = Color3.fromRGB(180, 130, 90)
        else
            obj.Size = Vector3.new(cfg.tamanho*0.05, cfg.tamanho*0.03, cfg.tamanho*0.05)
            obj.Color = Color3.fromRGB(60, 60, 60)
        end
        obj.Anchored = true
        obj.CanCollide = false
        obj.CanQuery = false
        obj.CanTouch = false
        obj.CastShadow = false
        obj.Material = Enum.Material.SmoothPlastic
        obj.Parent = tornadoFolder

        table.insert(destrocosParts, obj)
        table.insert(destrocosData, {
            a = math.random()*math.pi*2,
            r = cfg.tamanho*(0.25+math.random()*0.6),
            y = cfg.altura*(0.2+math.random()*0.7),
            vel = (8+math.random()*15)*(math.random()>0.5 and 1 or -1),
            spin = math.random(-8,8),
        })
    end

    -- SOM DE VENTO
    if not tocarMusica then
        somVento = Instance.new("Sound")
        somVento.SoundId = "rbxassetid://318451789"
        somVento.Looped = true
        somVento.Volume = 0.7
        somVento.RollOffMaxDistance = 80000
        somVento.RollOffMinDistance = 100
        somVento.Parent = tornadoFolder
        somVento:Play()
    end

    -- MÚSICA DO EL RENO
    if tocarMusica then
        somMusica = Instance.new("Sound")
        somMusica.SoundId = MUSICA_EL_RENO
        somMusica.Looped = true
        somMusica.Volume = 2
        somMusica.RollOffMaxDistance = 200000
        somMusica.RollOffMinDistance = 50
        somMusica.Parent = tornadoFolder
        somMusica:Play()

        Rayfield:Notify({
            Title = "🎵 EL RENO",
            Content = "O maior tornado da história está chegando!",
            Duration = 4,
        })
    end

    -- LUZ
    luz = Instance.new("PointLight")
    luz.Brightness = 2
    luz.Range = cfg.tamanho * 2
    luz.Color = Color3.fromRGB(100, 100, 120)
    luz.Parent = tornadoFolder

    wanderTarget = Vector3.new(centroX, 0, centroZ)
    wanderTimer = 0
    ativo = true
end

-- ============================================================
-- WANDER
-- ============================================================
local function escolherNovoAlvo()
    local ang = math.random() * math.pi * 2
    local dist = 500 + math.random() * 1000
    wanderTarget = Vector3.new(centroX + math.cos(ang)*dist, 0, centroZ + math.sin(ang)*dist)
end

-- ============================================================
-- ANIMAÇÃO
-- ============================================================
RunService.Heartbeat:Connect(function(dt)
    if not ativo or not tornadoFolder then return end
    local t = tick()

    -- DESCIDA
    if descidaAtiva then
        descidaOffset = math.max(0, descidaOffset - descidaVelAtual * dt)
        if descidaOffset <= 0 then
            descidaOffset = 0
            descidaAtiva = false
        end
    end

    -- WANDER
    if cfg.wanderAtivo and not seguir and not descidaAtiva then
        wanderTimer = wanderTimer + dt
        if wanderTimer >= cfg.wanderTroca then
            wanderTimer = 0
            escolherNovoAlvo()
        end
        local dir = Vector3.new(wanderTarget.X - centroX, 0, wanderTarget.Z - centroZ)
        if dir.Magnitude > 5 then
            local passo = dir.Unit * cfg.wanderVel * dt
            centroX = centroX + passo.X
            centroZ = centroZ + passo.Z
        else
            wanderTimer = cfg.wanderTroca
        end
    end

    if seguir then
        local char = Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local p = char.HumanoidRootPart.Position
            centroX = centroX + (p.X - centroX) * 0.02
            centroZ = centroZ + (p.Z - centroZ) * 0.02
        end
    end

    -- FUNIL
    local n = #todasParts
    for i = 1, n do
        local d = todasData[i]
        local ang = d.angBase + t * d.vel
        todasCFrames[i] = CFrame.new(
            centroX + math.cos(ang)*d.raio,
            d.y + descidaOffset,
            centroZ + math.sin(ang)*d.raio
        ) * CFrame.Angles(0, ang + math.pi/2, 0)
    end
    if n > 0 then
        workspace:BulkMoveTo(todasParts, todasCFrames, Enum.BulkMoveMode.FireCFrameChanged)
    end

    -- DESTROÇOS
    for i, obj in ipairs(destrocosParts) do
        local d = destrocosData[i]
        local a = d.a + t * d.vel * 0.05
        local yBase = ((d.y + t*15 - cfg.altura*0.2) % (cfg.altura*0.8)) + cfg.altura*0.2
        obj.CFrame = CFrame.new(
            centroX + math.cos(a)*d.r,
            yBase + descidaOffset,
            centroZ + math.sin(a)*d.r
        ) * CFrame.Angles(t*d.spin, t*d.spin*1.3, t*d.spin*0.7)
    end

    -- NUVEM SEGUE
    if nuvemFolder and not descidaAtiva then
        for i, p in ipairs(nuvemParts) do
            local d = nuvemData[i]
            p.Position = Vector3.new(
                centroX + (d.origX - centroX) * 0.98,
                d.origY,
                centroZ + (d.origZ - centroZ) * 0.98
            )
        end
    end
end)

-- ============================================================
-- PRESETS
-- ============================================================
local PRESETS = {
    EF1 = {tamanho=80, altura=400, velocidade=3, camadas=20, porAnel=8, destrocosQtd=10},
    EF2 = {tamanho=150, altura=600, velocidade=5, camadas=24, porAnel=9, destrocosQtd=15},
    EF3 = {tamanho=280, altura=900, velocidade=7, camadas=28, porAnel=10, destrocosQtd=20},
    EF4 = {tamanho=500, altura=1400, velocidade=9, camadas=32, porAnel=11, destrocosQtd=28},
    EF5 = {tamanho=900, altura=2000, velocidade=12, camadas=36, porAnel=12, destrocosQtd=35},
    ELRENO = {tamanho=1200, altura=750, velocidade=14, camadas=38, porAnel=13, destrocosQtd=50},
}

local function spawnLonge(dist)
    local char = Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        local look = hrp.CFrame.LookVector
        local dirH = Vector3.new(look.X, 0, look.Z)
        if dirH.Magnitude < 0.1 then dirH = Vector3.new(0,0,1) end
        dirH = dirH.Unit
        local alvo = hrp.Position + dirH * dist
        return Vector3.new(alvo.X, 3, alvo.Z)
    end
    return Vector3.new(0, 3, 0)
end

local function aplicarEF(nome, musica)
    local p = PRESETS[nome]
    if not p then return end
    for k, v in pairs(p) do cfg[k] = v end
    local dist = math.clamp(cfg.tamanho * 0.7, 120, 400)
    local base = spawnLonge(dist)

    destruir()
    task.wait(0.1)

    criarTornado(base, musica)

    local total = cfg.camadas * cfg.porAnel + cfg.destrocosQtd
    Rayfield:Notify({
        Title = nome .. " chamando!",
        Content = cfg.tamanho .. " studs · " .. total .. " partes" ..
                 (cfg.cinematico and " · descendo do céu..." or ""),
        Duration = 4,
    })
end

-- ============================================================
-- GUI
-- ============================================================
Tab:CreateSection("🌪️ Spawnar Tornado")

Tab:CreateButton({Name = "EF1 — Fraco (~80 studs)", Callback = function() aplicarEF("EF1", false) end})
Tab:CreateButton({Name = "EF2 — Moderado (~150 studs)", Callback = function() aplicarEF("EF2", false) end})
Tab:CreateButton({Name = "EF3 — Forte (~280 studs)", Callback = function() aplicarEF("EF3", false) end})
Tab:CreateButton({Name = "EF4 — Severo (~500 studs)", Callback = function() aplicarEF("EF4", false) end})
Tab:CreateButton({Name = "EF5 — Catastrófico (~900 studs)", Callback = function() aplicarEF("EF5", false) end})

Tab:CreateButton({
    Name = "🌪️ SPAWNAR EL RENO (1200) + 🎵 MÚSICA",
    Callback = function() aplicarEF("ELRENO", true) end,
})

Tab:CreateSection("☁️ Sistema Cinemático")

Tab:CreateToggle({
    Name = "Nuvem + Descida (Cinema)",
    CurrentValue = true,
    Flag = "Cine",
    Callback = function(v)
        cfg.cinematico = v
        Rayfield:Notify({
            Title = v and "Modo Cinema ATIVO" or "Modo Cinema DESLIGADO",
            Content = v and "Nuvem se forma e tornado desce do céu" or "Tornado aparece direto no chão",
            Duration = 3,
        })
    end,
})

Tab:CreateSlider({
    Name = "Velocidade da Descida",
    Range = {50, 600}, Increment = 25, Suffix = " studs/s",
    CurrentValue = 200, Flag = "DescVel",
    Callback = function(v)
        cfg.descidaVel = v
        if descidaAtiva then descidaVelAtual = v end
    end,
})

Tab:CreateSection("⚙️ Controles")

Tab:CreateButton({
    Name = "🎵 Tocar/Pausar Música",
    Callback = function()
        if somMusica then
            if somMusica.IsPlaying then somMusica:Pause() else somMusica:Play() end
        end
    end,
})

Tab:CreateSlider({
    Name = "Volume da Música",
    Range = {0, 5}, Increment = 0.5,
    CurrentValue = 2,
    Callback = function(v) if somMusica then somMusica.Volume = v end end,
})

Tab:CreateButton({
    Name = "🎯 Ir até o Tornado",
    Callback = function()
        if not tornadoFolder then
            Rayfield:Notify({Title="Nenhum tornado", Content="Spawna um EF primeiro!", Duration=3})
            return
        end
        local char = Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            local ang = math.random() * math.pi * 2
            local dist = cfg.tamanho * 0.5 + 60
            hrp.CFrame = CFrame.new(centroX + math.cos(ang)*dist, hrp.Position.Y, centroZ + math.sin(ang)*dist)
        end
    end,
})

Tab:CreateButton({
    Name = "📱 Mover Tornado pra Mim",
    Callback = function()
        if not tornadoFolder then return end
        local char = Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local p = char.HumanoidRootPart.Position
            centroX, centroZ = p.X, p.Z
        end
    end,
})

Tab:CreateToggle({
    Name = "Seguir Jogador",
    CurrentValue = false,
    Flag = "Seguir",
    Callback = function(v) seguir = v end,
})

Tab:CreateButton({
    Name = "❌ Destruir Tornado + Nuvem",
    Callback = destruir,
})

Tab:CreateSection("🚶 Movimento Aleatório")

Tab:CreateToggle({
    Name = "Andar pelo Mapa",
    CurrentValue = true,
    Flag = "Wander",
    Callback = function(v) cfg.wanderAtivo = v end,
})

Tab:CreateSlider({
    Name = "Velocidade de Deslocamento",
    Range = {10, 300}, Increment = 10, Suffix = " studs/s",
    CurrentValue = 60, Flag = "WVel",
    Callback = function(v) cfg.wanderVel = v end,
})

Tab:CreateSlider({
    Name = "Trocar Direção a Cada",
    Range = {2, 20}, Increment = 1, Suffix = "s",
    CurrentValue = 6, Flag = "WTroca",
    Callback = function(v) cfg.wanderTroca = v end,
})

Tab:CreateSection("🎛️ Ajuste Fino")

Tab:CreateSlider({
    Name = "Largura",
    Range = {40, 1500}, Increment = 20, Suffix = " studs",
    CurrentValue = 150, Flag = "Tam",
    Callback = function(v) cfg.tamanho = v end,
})

Tab:CreateSlider({
    Name = "Altura",
    Range = {200, 3000}, Increment = 50, Suffix = " studs",
    CurrentValue = 700, Flag = "Alt",
    Callback = function(v) cfg.altura = v end,
})

Tab:CreateSlider({
    Name = "Rotação",
    Range = {1, 20}, Increment = 1, Suffix = "x",
    CurrentValue = 4, Flag = "Vel",
    Callback = function(v) cfg.velocidade = v end,
})

Tab:CreateSlider({
    Name = "Opacidade",
    Range = {0, 0.8}, Increment = 0.05,
    CurrentValue = 0.3, Flag = "Opac",
    Callback 

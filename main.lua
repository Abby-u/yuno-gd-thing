local tween = require("libs/tween")
local json = require("libs/dkjson")
local animx = require("libs/animx")
local assets = require("assetsTable")
local camera = require("libs/hump/camera")

local char = require("charHandle")
local strum = require("strumNotesHandle")

local assets = require("assetsTable")

local screenWidth, screenHeight = love.graphics.getDimensions()

local daTitle = ""

local displayOffset = 60
local textAlpha = {0}
local textAlphaTween = tween.new(0.5,textAlpha,{0},'linear')

_G.timer = 0

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function round(n)
    if n >= 0 then
        return math.floor(n + 0.5)
    else
        return math.floor(n - 0.5)
    end
end

local enableSilly = false

local rawJson,size = love.filesystem.read("assets/data/songs/yuno/yuno.json")
local jsonData = json.decode(rawJson)
local notes = {}
local isPlaying = false
local bpm = jsonData.song.bpm
local scrollY = 0
local scrollSpeed = jsonData.song.speed*4.5 or 10
local bfNotes = {}
local dadNotes = {}
local deadBfNotes = {}
local deadDadNotes = {}
local events = {}
local deadEvents = {}
local focusOn = {}
local beatSection = {}
local curBeatSection = 1
local focusBf = false
local left = false
local down = false
local up = false
local right = false
local hitArea = 35*scrollSpeed
local curBeat = 0
local lastBeat = -1
local hold = nil
local bfPos = {770,180}
local dadPos = {80,180}
local gfPos = {405,140}
local other1Pos = {-60,220}
local gd = true

local targetZoom = {2,1}
local zoom = {
    2,
    targetZoom[2]+0.015
}
local posOffset = {0,0,0}
local curPos = {1280,720,0}
local targetPos = {1280,720,0}
local camGDcurPos = {640,160}
local camHUD = camera(640,360,zoom[1])
local camGame = camera(640,360,zoom[2])
local camGD = camera(camGDcurPos[1],camGDcurPos[2],1.5)
local zoomTween = tween.new(1.5,zoom,targetZoom,'outExpo')
local camOffsetDist = 30
local camLerpSpeed = 3
local camCanBop = false
local vertOffset = -100

local dividerVerticles = {
    640+vertOffset,-800,
    630+vertOffset,-100,
    645+vertOffset,0,
    598+vertOffset,124,
    660+vertOffset,200,
    600+vertOffset,344,
    644+vertOffset,540,
    621+vertOffset,569,
    632+vertOffset,600,
    699+vertOffset,634,
    645+vertOffset,701,
    647+vertOffset,750,
    600+vertOffset,900,
    640+vertOffset,1400,
    2200+vertOffset,1400,
    2200+vertOffset,-800
}
local randomVerticles = {
    0,0,
    0,0,
    0,0,
    0,0,
    0,0,
    0,0,
    0,0,
    0,0,
    0,0,
    0,0,
    0,0,
    0,0,
    0,0,
    0,0,
    0,0,
    0,0,
}
local curVerticles = {
    640+vertOffset,-800,
    630+vertOffset,-100,
    645+vertOffset,0,
    598+vertOffset,124,
    660+vertOffset,200,
    600+vertOffset,344,
    644+vertOffset,540,
    621+vertOffset,569,
    632+vertOffset,600,
    699+vertOffset,634,
    645+vertOffset,701,
    647+vertOffset,750,
    600+vertOffset,900,
    640+vertOffset,1400,
    2200+vertOffset,1400,
    2200+vertOffset,-800
}

local bfSinging = false
local bfIdle = true
local singTime = 0

for a,b in pairs(jsonData.song.notes) do
    local bf = b.mustHitSection
    local alt = b.altAnim
    -- print(b.sectionBeats)
    table.insert(beatSection,b.sectionBeats or b.lengthInSteps/4)
    table.insert(focusOn,bf)
    for c,d in pairs(b) do
        if c == "sectionNotes" then
            
            for e,f in pairs(d) do
                if bf then
                    if f[2] >= 0 and f[2] <= 3 then
                        local daTable = {
                            f[1],
                            f[2],
                            f[3],
                            f[4],
                            alt
                        }
                        table.insert(bfNotes,daTable)
                    else
                        local daTable = {
                            f[1],
                            f[2]-4,
                            f[3],
                            f[4],
                            alt
                        }
                        table.insert(dadNotes,daTable)
                    end
                else
                    if f[2] >= 0 and f[2] <= 3 then
                        local daTable = {
                            f[1],
                            f[2],
                            f[3],
                            f[4],
                            alt
                        }
                        table.insert(dadNotes,daTable)
                    else
                        local daTable = {
                            f[1],
                            f[2]-4,
                            f[3],
                            f[4],
                            alt
                        }
                        table.insert(bfNotes,daTable)
                    end
                end
            end
        end
    end
end

if jsonData.song.events then
    for a,b in pairs(jsonData.song.events) do
        local daTable = {
            b[1],
            b[2][1][1],
            b[2][1][2],
            b[2][1][3]
        }
        table.insert(events,daTable)
    end
end

local firstNote = math.min(bfNotes[1][1],dadNotes[1][1])

love.physics.setMeter(64)
local gdWorld = love.physics.newWorld(0,130*64,true)
local objects = {}
local brightness = 0

objects.ground={}
objects.ground.body = love.physics.newBody(gdWorld,640,600,"static")
objects.ground.shape = love.physics.newRectangleShape(200,100)
objects.ground.fixture = love.physics.newFixture(objects.ground.body,objects.ground.shape):setFriction(0.9)

objects.cube={}
objects.cube.body = love.physics.newBody(gdWorld,640,420,"dynamic")
objects.cube.shape = love.physics.newRectangleShape(140,140)
objects.cube.fixture = love.physics.newFixture(objects.cube.body,objects.cube.shape):setFriction(0.9)
objects.cube.onGround = false
objects.cube.jumpPower = 500
objects.cube.movePower = 200
objects.cube.dir = 1
objects.cube.rotSpeed = 0
objects.cube.curRotation = 0
objects.cube.targetRot = 0
objects.cube.body:setFixedRotation(true)
objects.cube.color = {255,255,255,255}
objects.cube.sizeOffset = {
    1,
    1
}
local squishTween = tween.new(1,objects.cube.sizeOffset,{1,1},'outElastic')

local particle = love.graphics.newParticleSystem(love.graphics.newImage("assets/images/yellow.png"),64)
particle:setParticleLifetime(0.1,0.3)
particle:setEmissionRate(100)
particle:setDirection(-math.pi/2)
particle:setLinearAcceleration(0,5000,0,5000)
particle:setSizes(1/5,0.875/5,0.75/5,0.625/5,0.5/5,0.375/5,0.25/5,0.125/5)
particle:setSpread(math.pi/4)
particle:setSpeed(10,1000)
particle:setEmissionArea("borderrectangle",100,1)
particle:stop()
particle:setEmitterLifetime(0.05)

local function physicsCallbacks(a,b,c)
    if a then
        objects.cube.onGround = true
        objects.cube.rotSpeed = 0
        objects.cube.targetRot = round(objects.cube.curRotation/math.pi/2)*math.pi/2
        if isPlaying then
        particle:start()
        end
    end
end

gdWorld:setCallbacks(physicsCallbacks)

local canvas = love.graphics.newCanvas(1280*2,720*2)
local canvas2 = love.graphics.newCanvas(1280*2,720*2)

function love.load()
    if love.system.getOS() == "Android" or love.system.getOS() == "iOS" then
        love.window.setFullscreen(true)
    end
    love.graphics.setBackgroundColor(love.math.colorFromBytes(33, 33, 33))
    assets.music = love.audio.newSource("assets/songs/yuno/Inst.ogg", "stream")
    local voicedir = "assets/songs/yuno/Voices.ogg"
    if love.filesystem.getInfo(voicedir) then
        assets.voice = love.audio.newSource(voicedir, "stream")
    else
        assets.voice = love.audio.newSource("assets/songs/none.ogg", "stream")
    end
    assets.bg2 = love.graphics.newImage("assets/images/stages/yunobg2.png")
    assets.bgGd = love.graphics.newImage("assets/images/stages/bg1.png")
    assets.groundGd = love.graphics.newImage("assets/images/stages/ground1.png")
    assets.ador = love.graphics.newImage("assets/images/ador.png")
    assets.daFont = love.graphics.newFont("assets/fonts/Moderniz.otf",20)
    assets.sliderBar = love.graphics.newImage("assets/images/sliderBar.png")
    assets.sliderBorder = love.graphics.newImage("assets/images/sliderBorder.png")
    assets.bfStrum = strum.loadStrum("yeah")
    assets.dadStrum = strum.loadStrum("yeah")
    assets.bf = char.loadChar("boyf")
    assets.dad = char.loadChar("yuno")
    char.playAnim(assets.bf,"idle")
    char.playAnim(assets.dad,"idle")

    assets.missSounds = {
        love.audio.newSource("assets/sounds/missnote1.ogg","static"),
        love.audio.newSource("assets/sounds/missnote2.ogg","static"),
        love.audio.newSource("assets/sounds/missnote3.ogg","static")
    }
    assets.pause = love.graphics.newImage("assets/images/pause.png")
    assets.video = love.graphics.newVideo("assets/videos/end.ogv")
end

local endd = false

local strumAlt = false

local function changeStrum(num,bool)
    if num == 0 then
        if bool then
            return "left confirm"
        else
            return "left press"
        end
    elseif num == 1 then
        if bool then
            return "down confirm"
        else
            return "down press"
        end
    elseif num == 2 then
        if bool then
            return "up confirm"
        else
            return "up press"
        end
    elseif num == 3 then
        if bool then
            return "right confirm"
        else
            return "right press"
        end
    end
end

local function dadSing(num,bool)
    if num == 0 then
        if bool then
            char.playAnim(assets.dad,"singLEFT-alt")
        else
            char.playAnim(assets.dad,"singLEFT")
        end
        if not focusBf then posOffset = {-camOffsetDist,0,-1} end
    elseif num == 1 then
        if bool then
            char.playAnim(assets.dad,"singDOWN-alt")
        else
            char.playAnim(assets.dad,"singDOWN")
        end
        if not focusBf then posOffset = {0,camOffsetDist,2} end
    elseif num == 2 then
        if bool then
            char.playAnim(assets.dad,"singUP-alt")
        else
            char.playAnim(assets.dad,"singUP")
        end
        if not focusBf then posOffset = {0,-camOffsetDist,-2} end
    elseif num == 3 then
        if bool then
            char.playAnim(assets.dad,"singRIGHT-alt")
        else
            char.playAnim(assets.dad,"singRIGHT")
        end
        if not focusBf then posOffset = {camOffsetDist,0,1} end
    end
    assets.dad.prop.curSingDur = 0
end

local function dadBop()
    char.playAnim(assets.dad,"idle")
end

local function bfBop()
    char.playAnim(assets.bf,"idle")
end

local function beatHit()
    if curBeat % (beatSection[curBeatSection-1] or 4) == 0 then
        curBeatSection = curBeatSection + 1
        if camCanBop then
            brightness = brightness + 40
            zoom = {
                targetZoom[1]+0.03,
                targetZoom[2]+0.015
            }   
            zoomTween = tween.new(1.5,zoom,targetZoom,'outExpo')
        end
        local charCamOffset
        if focusOn[curBeatSection-1] then
            targetPos = {
                bfPos[1] + (assets.bf.data.position[1] + assets.bf.data.camera_position[1]*1 or 0) - 200,
                bfPos[2] + (assets.bf.data.position[2] + assets.bf.data.camera_position[2]*1 or 0),
                1
            }
            focusBf = true
        else
            targetPos = {
                dadPos[1] + (assets.dad.data.position[1] + assets.dad.data.camera_position[1]*1 or 0)*15,
                dadPos[2] + (assets.dad.data.position[2] - assets.dad.data.camera_position[2]*1 or 0)*5,
                -1
            }
            focusBf = false
        end
    end
    if bfIdle and not assets.bf.actor:isActive() and curBeat % 2 == 0 and not hold then
        bfBop()
    end
    if not assets.dad.prop.isSinging and not assets.dad.actor:isActive() and curBeat % 2 == 0 then
        dadBop()
    end
    for i=1,#randomVerticles,2 do
        randomVerticles[i] = math.random(-100,100)
    end
    if curBeat == 4 then
        targetZoom = {
            1,
            targetZoom[2]
        }
        zoomTween = tween.new(1.5,zoom,targetZoom,'outExpo')
        textAlphaTween = tween.new(0.5,textAlpha,{1},'linear')
    end
    if curBeat == 16 then
        textAlphaTween = tween.new(0.5,textAlpha,{0},'linear')
    end
    if strumAlt then
        strumAlt = false
    else
        strumAlt = true
    end
end

local function bfMiss(num)
    local index = math.random(1,3)
    assets.missSounds[index]:setVolume(0.3)
    assets.missSounds[index]:play()
    assets.voice:setVolume(0)
    objects.cube.color = {153,100,227,255}
    bfIdle = false
    singTime = 0
    if (math.abs(objects.cube.curRotation) > math.pi/4) and (math.abs(objects.cube.curRotation) < 3*math.pi/4) then
        objects.cube.sizeOffset = {1.1,0.9}
    else
        objects.cube.sizeOffset = {0.9,1.1}
    end
    squishTween = tween.new(0.5,objects.cube.sizeOffset,{1,1},'outElastic')
end

local function idleNotes(num)
    if num == 1 then
        return strumAlt and "altArrowLEFT" or "arrowLEFT"
    elseif num == 2 then 
        return strumAlt and "altArrowDOWN" or "arrowDOWN"
    elseif num == 3 then
        return strumAlt and "altArrowUP" or "arrowUP"
    elseif num == 4 then
        return strumAlt and "altArrowRIGHT" or "arrowRIGHT"
    end
end

function love.update(dt)
    if endd then
        love.window.setTitle("TikTok: @yourMother")
        if not assets.video:isPlaying() then
            love.event.quit()
        end
        return
    end
    curPos = {
        lerp(curPos[1],targetPos[1]+posOffset[1],dt*camLerpSpeed),
        lerp(curPos[2],targetPos[2]+posOffset[2],dt*camLerpSpeed),
        lerp(curPos[3],targetPos[3]+posOffset[3],dt*camLerpSpeed)
    }
    zoom = {
        lerp(zoom[1],targetZoom[1],dt*5),
        lerp(zoom[2],targetZoom[2],dt*5)
    }
    camGDcurPos = {
        lerp(camGDcurPos[1],objects.cube.body:getX(),dt*(camLerpSpeed+1)),
        camGDcurPos[2]
    }

    -- animx.update(dt)
    char.update(dt)
    zoomTween:update(dt)
    squishTween:update(dt)
    textAlphaTween:update(dt)
    camHUD:zoomTo(zoom[1])
    camGame:zoomTo(zoom[2])
    camGame:lookAt(curPos[1],curPos[2])
    camGame:rotateTo(math.rad(curPos[3]))
    camGD:lookAt(camGDcurPos[1]-300,camGDcurPos[2])
    particle:update(dt)
    particle:moveTo(objects.cube.body:getX(),objects.cube.body:getY()+70)
    gdWorld:update(dt)
    brightness = lerp(brightness,0,dt*4)
    for i=1,#dividerVerticles do
        curVerticles[i] = dividerVerticles[i]
        if i%2 == 1 then
            curVerticles[i] = dividerVerticles[i] + vertOffset + randomVerticles[i]
        end
    end

    if assets.music and not isPlaying then
        
        -- isPlaying = true
        return
    end
    if not isPlaying then
        return
    end

    _G.timer = _G.timer + dt
    scrollY = _G.timer*100*scrollSpeed
    singTime = singTime + dt

    if not assets.bf.actor.current:match("idle") and singTime >= 0.5 and hold == nil and bfSinging then
        objects.cube.color = {255,255,255,255}
        bfSinging = false
        bfIdle = true
        singTime = 3
        bfBop()
        if focusBf then posOffset = {0,0,0} end
    end
    assets.dad.prop.curSingDur = assets.dad.prop.curSingDur + dt
    if assets.other1 then
        assets.other1.prop.curSingDur = assets.other1.prop.curSingDur + dt
        if assets.other1.prop.curAnim ~= "idle" and assets.other1.prop.curSingDur >= assets.other1.prop.singDur/10 and assets.other1.prop.isSinging then
            assets.other1.prop.isSinging = false
            char.playAnim(assets.other1,"idle")
            --if not focusBf then posOffset = {0,0,0} end
        end
    end

    if assets.gf then
        assets.gf.prop.curSingDur = assets.gf.prop.curSingDur + dt
        if assets.gf.prop.curAnim ~= "idle" and assets.gf.prop.curSingDur >= assets.gf.prop.singDur/10 and assets.gf.prop.isSinging then
            assets.gf.prop.isSinging = false
            char.playAnim(assets.gf,"idle")
            --if not focusBf then posOffset = {0,0,0} end
        end
    end
    -- print(assets.dad.prop.curAnim ~= "idle" , assets.dad.prop.curSingDur >= assets.dad.prop.singDur/10 , assets.dad.prop.isSinging)

    if assets.dad.prop.curAnim ~= "idle" and assets.dad.prop.curSingDur >= assets.dad.prop.singDur/10 and assets.dad.prop.isSinging then
        assets.dad.prop.isSinging = false
        dadBop()
        if not focusBf then posOffset = {0,0,0} end
    end

    curBeat = math.floor(_G.timer/(60/bpm))
    if curBeat ~= lastBeat then
        beatHit()
    end

    for i,v in pairs(bfNotes) do
        if (v[1]/10*scrollSpeed) < scrollY - (hitArea/2) then
            bfMiss(v[2])
            table.remove(bfNotes,i)
            table.insert(deadBfNotes,v)
        end
    end

    for i,v in pairs(events) do
        if (v[1]/10*scrollSpeed) < scrollY then
            if v[2] == "Add Camera Zoom" then
                table.remove(events,i)
                table.insert(deadEvents,v)
                zoom = {
                    targetZoom[1]+0.03+(tonumber(v[3])or 0),
                    targetZoom[2]+0.015+(tonumber(v[3])or 0)
                }
                zoomTween = tween.new(1.5,zoom,targetZoom,'outExpo')
                brightness = brightness + 40
            elseif v[2] == "Play Animation" then
                table.remove(events,i)
                table.insert(deadEvents,v)
                if v[4] == "Dad" then
                    char.playAnim(assets.dad,v[3])
                elseif v[4] == "GF" then
                    char.playAnim(assets.gf,v[3])
                end
            elseif v[2] == "Change Character" then
                table.remove(events,i)
                table.insert(deadEvents,v)
                assets.gf.prop.invisible = false
            end
        end
    end

    for i,v in pairs(dadNotes) do
        if (v[1]/10*scrollSpeed) < scrollY then
            if v[4] == "mimi" then
                other1Sing(v[2])
                table.remove(dadNotes,i)
                table.insert(deadDadNotes,v)
                assets.voice:setVolume(1)
            elseif v[4] == "GF Sing" then
                gfSing(v[2])
                table.remove(dadNotes,i)
                table.insert(deadDadNotes,v)
                assets.voice:setVolume(1)
            else
                dadSing(v[2],v[5])
                strum.playStrum(assets.dadStrum,changeStrum(v[2],true),v[2])
                table.remove(dadNotes,i)
                table.insert(deadDadNotes,v)
                assets.dadStrum.prop.press[v[2]+1] = true
                assets.voice:setVolume(1)
            end
        end
    end

    if firstNote and scrollY >= firstNote then
        firstNote = nil
        gd = false
        targetZoom = {1,0.56}
    end

    if not gd then
        if focusBf then
            love.window.setTitle("Geometry Dash: aldora "..assets.bf.prop.curAnim)
        else
            love.window.setTitle("Geometry Dash: yuno "..assets.dad.prop.curAnim)
        end
    end

    for i=1,4 do
        local noteAnim = "a"
        if not assets.bfStrum.prop.press[i] and not assets.bfStrum.actor[i]:isActive() and assets.bfStrum.actor[i]:getCurrentAnimation() ~= idleNotes(i) then
            assets.bfStrum.prop.confirm[i] = false
            assets.bfStrum.prop.press[i] = false
            strum.playStrum(assets.bfStrum, idleNotes(i) ,i-1)
        end
        noteAnim = assets.bfStrum.actor[i].current or "a"
        if noteAnim:match("arrow") or noteAnim:match("altArrow") then
            strum.playStrum(assets.bfStrum, idleNotes(i) ,i-1)
        end
        if  not assets.dadStrum.actor[i]:isActive() and assets.dadStrum.actor[i]:getCurrentAnimation() ~= idleNotes(i) then
            assets.dadStrum.prop.confirm[i] = false
            assets.dadStrum.prop.press[i] = false
            strum.playStrum(assets.dadStrum, idleNotes(i) ,i-1)
        end
        noteAnim = assets.dadStrum.actor[i].current or "a"
        if noteAnim:match("arrow") or noteAnim:match("altArrow") then
            strum.playStrum(assets.dadStrum, idleNotes(i) ,i-1)
        end
    end

    if _G.timer > 1 and not assets.music:isPlaying() and not assets.voice:isPlaying() then
        -- isPlaying = false
        assets.music:stop()
        assets.voice:stop()
        scrollY = 0
        _G.timer = 0
        curBeatSection = 1
        endd = true
        assets.video:play()
        -- sort()
    end

    objects.ground.body:setX(objects.cube.body:getX())

    if objects.cube.curRotation >= math.pi then
        objects.cube.curRotation = objects.cube.curRotation - math.pi*2
        objects.cube.targetRot = objects.cube.targetRot - math.pi*2
    elseif objects.cube.curRotation <= -math.pi then
        objects.cube.curRotation = objects.cube.curRotation + math.pi*2
        objects.cube.targetRot = objects.cube.targetRot + math.pi*2
    end

    if objects.cube.rotSpeed == 0 then
        objects.cube.curRotation = lerp(objects.cube.curRotation, objects.cube.targetRot ,dt*20)
    else
        objects.cube.curRotation = objects.cube.curRotation + dt*objects.cube.rotSpeed
    end

    vertOffset = lerp(vertOffset,100,dt*4)
    

    if enableSilly then
    love.window.setPosition(curPos[1],curPos[2])
    end

    lastBeat = curBeat
end

local function checkKeyDown(num)
    if num == 0 and left then
        return true
    elseif num == 1 and down then
        return true
    elseif num == 2 and up then
        return true
    elseif num == 3 and right then
        return true
    else
        return false
    end
end

local function changeKeyState(num,bool)
    if num == 0 and left then
        if bool then
            char.playAnim(assets.bf,"singLEFT")
            assets.voice:setVolume(1)
            if focusBf then posOffset = {-camOffsetDist,0,-1} end
            bfSinging = true
            objects.cube.dir = -1
            if objects.cube.onGround then
                objects.cube.body:setLinearVelocity(objects.cube.body:getMass()*-objects.cube.movePower,select(2,objects.cube.body:getLinearVelocity()))
                particle:start()
            else
                objects.cube.rotSpeed = 10*objects.cube.dir
                objects.cube.body:setLinearVelocity(objects.cube.body:getMass()*-objects.cube.movePower*0.5,select(2,objects.cube.body:getLinearVelocity()))
            end
        else
            char.playAnim(assets.bf,"singLEFTmiss")
            assets.voice:setVolume(0)
            assets.missSounds[math.random(1,3)]:play()
        end
        left = false
    elseif num == 1 and down then
        if bool then
            char.playAnim(assets.bf,"singDOWN")
            assets.voice:setVolume(1)
            if focusBf then posOffset = {0,camOffsetDist,-2} end
            bfSinging = true
            objects.cube.body:setLinearVelocity(select(1,objects.cube.body:getLinearVelocity()),objects.cube.body:getMass()*objects.cube.jumpPower)
            if objects.cube.onGround then
                if (math.abs(objects.cube.curRotation) > math.pi/4) and (math.abs(objects.cube.curRotation) < 3*math.pi/4) then
                    objects.cube.sizeOffset = {0.9,1.1}
                else
                    objects.cube.sizeOffset = {1.1,0.9}
                end
                squishTween = tween.new(0.7,objects.cube.sizeOffset,{1,1},'outElastic')
            end
        else
            char.playAnim(assets.bf,"singDOWNmiss")
            assets.voice:setVolume(0)
            assets.missSounds[math.random(1,3)]:play()
        end
        down = false
    elseif num == 2 and up then
        if bool then
            char.playAnim(assets.bf,"singUP")
            assets.voice:setVolume(1)
            if focusBf then posOffset = {0,-camOffsetDist,2} end
            bfSinging = true
            if objects.cube.onGround then
                particle:start()
                objects.cube.body:setLinearVelocity(select(1,objects.cube.body:getLinearVelocity()),objects.cube.body:getMass()*-objects.cube.jumpPower)
                objects.cube.onGround = false
                if (math.abs(objects.cube.curRotation) > math.pi/4) and (math.abs(objects.cube.curRotation) < 3*math.pi/4) then
                    objects.cube.sizeOffset = {1.5,0.75}
                else
                    objects.cube.sizeOffset = {0.75,1.5}
                end
                squishTween = tween.new(2,objects.cube.sizeOffset,{1,1},'outElastic')
            end
        else
            char.playAnim(assets.bf,"singUPmiss")
            assets.voice:setVolume(0)
            assets.missSounds[math.random(1,3)]:play()
        end
        up = false
    elseif num == 3 and right then
        if bool then
            char.playAnim(assets.bf,"singRIGHT")
            assets.voice:setVolume(1)
            if focusBf then posOffset = {camOffsetDist,0,1} end
            bfSinging = true
            objects.cube.dir = 1
            if objects.cube.onGround then
                objects.cube.body:setLinearVelocity(objects.cube.body:getMass()*objects.cube.movePower,select(2,objects.cube.body:getLinearVelocity()))
                particle:start()
            else
                objects.cube.rotSpeed = 10*objects.cube.dir
                objects.cube.body:setLinearVelocity(objects.cube.body:getMass()*objects.cube.movePower*0.5,select(2,objects.cube.body:getLinearVelocity()))
            end
        else
            char.playAnim(assets.bf,"singRIGHTmiss")
            assets.voice:setVolume(0)
            assets.missSounds[math.random(1,3)]:play()
        end
        right = false
    end
    bfIdle = false
    singTime = 0
end

local function checkNotePress(num)
    if not isPlaying then
        return
    end
    local found = false
    for i,v in pairs(bfNotes) do
        if checkKeyDown(v[2]) and (v[1]/10*scrollSpeed) > scrollY - (hitArea/2) and (v[1]/10*scrollSpeed) < scrollY + (hitArea/2) then
            table.remove(bfNotes,i)
            table.insert(deadBfNotes,v)
            -- print("valid",v[1])
            changeKeyState(v[2],true)
            found = true
            strum.playStrum(assets.bfStrum,changeStrum(v[2],true),v[2])
            assets.bfStrum.prop.press[v[2]+1] = true
            assets.bfStrum.prop.confirm[v[2]+1] = true
            objects.cube.color = {255,255,255,255}
            break
        end
    end
    if not found then
        hold = false
        bfIdle = true
        strum.playStrum(assets.bfStrum,changeStrum(num,false),num)
        assets.bfStrum.prop.press[num+1] = true
        assets.bfStrum.prop.confirm[num+1] = false
    end
    -- changeKeyState(num,false)
end

function love.keypressed(key,scan,isrepeat)
    if not isPlaying and key then
        isPlaying = true
        assets.music:play()
        assets.voice:play()
        _G.timer = 0
        if key == "y" then
            enableSilly = true
        end
        return
    end
    if key == "q" then
        left = true
        hold = key
        checkNotePress(0)
    elseif key == "w" then
        down = true
        hold = key
        checkNotePress(1)
    elseif key == "o" then
        up = true
        hold = key
        checkNotePress(2)
    elseif key == "p" then
        right = true
        hold = key
        checkNotePress(3)
    elseif key == "something" then
        --restart
        isPlaying = false
        assets.music:stop()
        assets.voice:stop()
        scrollY = 0
        _G.timer = 0
        curBeatSection = 1
        sort()
    end
end

function love.keyreleased(key,scan)
    if not isPlaying then
        return
    end
    if key == "q" then
        left = false
        assets.bfStrum.prop.press[1] = false
    elseif key == "w" then
        down = false
        assets.bfStrum.prop.press[2] = false
    elseif key == "o" then
        up = false
        assets.bfStrum.prop.press[3] = false
    elseif key == "p" then
        right = false
        assets.bfStrum.prop.press[4] = false
    end
    if hold == key then
        hold = nil
    end
end

function love.touchpressed(id,x,y)
    local screnW,screnH = love.graphics.getDimensions()
    if not isPlaying and id then
        isPlaying = true
        assets.music:play()
        assets.voice:play()
        _G.timer = 0
        return
    end
    if x >= 0 and X < screnW/4 then
        left = true
        hold = "q"
        checkNotePress(0)
    elseif x >= screnW/4 and x < screnW/2 then
        down = true
        hold = "w"
        checkNotePress(1)
    elseif x >= screnw/2 and x < screnW*3/4 then
        up = true
        hold = "o"
        checkNotePress(2)
    elseif x >= screnW*3/4 and x <= screnW then
        right = true
        hold = "p"
        checkNotePress(3)
    end
end

function love.touchreleased(id,x,y)
    local screnW,screnH = love.graphics.getDimensions()
    if not isPlaying then
        return
    end
    local daKey = ""
    if x >= 0 and X < screnW/4 then
        left = false
        daKey = "q"
        assets.bfStrum.prop.press[1] = false
    elseif x >= screnW/4 and x < screnW/2 then
        down = false
        daKey = "w"
        assets.bfStrum.prop.press[2] = false
    elseif x >= screnw/2 and x < screnW*3/4 then
        up = false
        daKey = "o"
        assets.bfStrum.prop.press[3] = false
    elseif x >= screnW*3/4 and x <= screnW then
        right = false
        daKey = "p"
        assets.bfStrum.prop.press[4] = false
    end
    if hold == daKey then
        hold = nil
    end
end

local function doNoteColors(num)
    if num == 0 then
        return "arrowLEFT"
    elseif num == 1 then
        return "arrowDOWN"
    elseif num == 2 then
        return "arrowUP"
    elseif num == 3 then
        return "arrowRIGHT"
    end
end

local function drawBfNotes()
    for i=0,3 do
        strum.draw(assets.bfStrum,i,true,(720+i*110)+((i-1)*8),displayOffset,0,0.6,0.6)
    end
    for a,b in pairs(bfNotes) do
        local y = (b[1]/10*scrollSpeed)-scrollY
        if y>-720 and y<720 then
            strum.draw(assets.bfStrum,b[2],false,(720+b[2]*110)+((b[2]-1)*8),y+displayOffset,0,0.6,0.6)
        end
    end
end
local function drawDadNotes()
    for i=0,3 do
        strum.draw(assets.dadStrum,i,true,(50+i*110)+((i-1)*8),displayOffset,0,0.6,0.6)
    end
    for a,b in pairs(dadNotes) do
        local y = (b[1]/10*scrollSpeed)-scrollY
        if y>0 and y<720 then
            strum.draw(assets.dadStrum,b[2],false,(50+b[2]*110)+((b[2]-1)*8),y+displayOffset,0,0.6,0.6)
        end
    end
end

local function daMask()
    local triangles = love.math.triangulate(curVerticles)
    for i,v in ipairs(triangles) do
        love.graphics.polygon("fill",unpack(v))
    end
end

local function drawGD()
    for i=1,3 do
        local parallax = camGDcurPos[1] * 0.8
        love.graphics.setColor(love.math.colorFromBytes(40+brightness,125+brightness,255+brightness,255))
        love.graphics.draw(assets.bgGd, (math.floor(camGDcurPos[1]/(assets.bgGd:getWidth()+parallax))-(i-2))*assets.bgGd:getWidth() + parallax ,-1490)
    end
    love.graphics.setColor(love.math.colorFromBytes(unpack(objects.cube.color)))
    local dX,dY = objects.cube.body:getPosition()
    daX = assets.ador:getWidth()/2*1--*objects.cube.dir
    daY = assets.ador:getWidth()/2*1
    love.graphics.draw(assets.ador,dX,dY,objects.cube.curRotation,1.2*objects.cube.dir*objects.cube.sizeOffset[1],1.2*objects.cube.sizeOffset[2],daX,daY)
    for i=1,5 do
        love.graphics.setColor(love.math.colorFromBytes(0+brightness,102+brightness,255+brightness,255))
        love.graphics.draw(assets.groundGd, (math.floor(camGDcurPos[1]/assets.groundGd:getWidth())-(i-3))*assets.groundGd:getWidth() ,550)
    end
    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle("fill",camGDcurPos[1]-2000,550,4000,10)
    love.graphics.setBlendMode("screen")
    love.graphics.draw(particle,0,0)
    love.graphics.setBlendMode("alpha")
end


function love.draw()
    local songLen = (_G.timer*1000/ (#bfNotes>0 and bfNotes[#bfNotes][1] or 1))
    --game
    camGame:attach()
    love.graphics.draw(assets.bg2,-900,-600,0,1.7)
    char.draw(assets.dad,dadPos[1],dadPos[2])
    love.graphics.stencil(daMask,"replace",1)
    love.graphics.setStencilTest("equal",1)
    camGD:attach()
    drawGD()
    camGD:detach()
    love.graphics.setStencilTest()
    love.graphics.setColor(1,1,1,1)
    love.graphics.setLineWidth(20)
    local daVert = {}
    for i=1, #curVerticles,1 do
        daVert[i] = i%2 == 1 and curVerticles[i]-10 or curVerticles[i]
    end
    love.graphics.polygon("line",daVert)
    camGame:detach()

    --hud/ui
    camHUD:attach()
    love.graphics.setFont(assets.daFont)
    love.graphics.print("Yeahman: Yuno (Modified)",10,710,0,zoom[1],zoom[1],0,20)
    love.graphics.setColor(1,1,1,textAlpha[1])
    --love.graphics.print("Q                W                O                P",760,200)
    love.graphics.setColor(1,1,1,1)

    camHUD:detach()
    camGame:attach()
    love.graphics.stencil(daMask,"replace",1)
    camGame:detach()
    camHUD:attach()
    love.graphics.setStencilTest("equal",0)
    love.graphics.rectangle("fill",0,0,songLen*1280,10)
    love.graphics.setStencilTest()
    
    drawBfNotes()
    love.graphics.setShader()
    drawDadNotes()
    camHUD:detach()
    camGame:attach()
    love.graphics.stencil(daMask,"replace",1)
    camGame:detach()
    love.graphics.setStencilTest("equal",1)
    love.graphics.setScissor(395,0,math.min(songLen*490,490),50)
    for i=1,15 do
        love.graphics.setColor(1,1,0,1)
        love.graphics.draw(assets.sliderBar,(i-1)*assets.sliderBar:getWidth()*0.6,10,0,0.6,0.6)
    end
    love.graphics.setScissor()
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(assets.sliderBorder,640,0,0,0.6,0.6,assets.sliderBorder:getWidth()/2,0)
    love.graphics.setStencilTest()

    love.graphics.setColor(1,1,1,0.27)
    love.graphics.draw(assets.pause,1280-4-96/2,4,0,0.5,0.5)
    love.graphics.setColor(1,1,1,1)

    if endd then
        love.graphics.draw(assets.video,0,0)
    end
end
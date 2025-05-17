local char = {}

local json = require("libs/dkjson")
local animx = require("libs/animx")

function char.loadChar(name)
    local a = {}
    local charDir = love.filesystem.read("assets/data/characters/"..tostring(name)..".json")
    local charJson = json.decode(charDir)
    local imageDir = charJson["assetPath"] or charJson["image"]
    local image = "assets/images/"..imageDir..".png"
    local actor = animx.newActor(image)
    a = {
        ['data']=charJson,
        ['actor']=actor,
        ['animOffset']=nil,
        ['prop'] = {
            isSinging = false,
            singDur = charJson.sing_duration or charJson.singTime or 5,
            curSingDur = 0,
            specialAnim = false,
            curAnim = "idle",
            invisible = false
        }
    }
    return a
end

function char.getAnimOffset(daChar)
    local here = {}
    for i,v in pairs(daChar.data.animations) do
        if v['prefix'] == daChar.actor:getCurrentAnimation() then
            -- self.animOffset = v[i]['offsets']
            daChar.animOffset = v['offsets']
            return
        end
    end
end

function char.playAnim(daChar,name)
    if not daChar.actor then
        daChar:switch(name)
        daChar:getCurrentAnimation():restart()
        daChar:getCurrentAnimation():once()
        return
    end
    local getAnimName = daChar.actor:getCurrentAnimation()
    for i,v in pairs(daChar.data.animations) do
        local old = false
        if v['anim'] == name then
            old = true
            getAnimName = v['name']
            daChar.animOffset = v['offsets']
            goto continue
        end
        if v['name'] == name and not old then
            getAnimName = v['prefix']
            daChar.animOffset = v['offsets']
        end
        ::continue::
    end
    local specialAnim = false
    daChar.actor:switch(getAnimName)
    daChar.actor:getCurrentAnimation():restart()
    daChar.actor:getCurrentAnimation():once()
    daChar.prop.specialAnim = false
    daChar.prop.curAnim = name
    if not name:match("sing") and not name:match("idle") then
        specialAnim = true
        daChar.prop.specialAnim = true
    elseif name:match("sing") then
        daChar.prop.isSinging = true
    else
        --idk
    end
    return specialAnim
end

function char.update(dt)
    animx.update(dt)
end

function char.draw(daChar,x,y,r,sx,sy)
    local animOffset = daChar.animOffset
    if not animOffset then
        animOffset = {0,0}
    end
    local scale = daChar.data.scale
    sx = sx or 1
    sy = sy or 1
    return daChar.actor:render(x + (daChar.data.position[1]) - (animOffset[1]*sx*scale) ,y+(daChar.data.position[2])-(animOffset[2]*sy*scale),r,sx*scale,sy*scale)
end

return char
local strum = {}

local animx = require("libs/animx")

function strum.loadStrum(name)
    local a = {}
    local actors = {}
    local daNoteSkin = ""
    local noteDir = love.filesystem.getDirectoryItems("assets/images/noteSkins/")
    for i,v in pairs(noteDir) do
        if v:find(name) then
            daNoteSkin = "assets/images/noteSkins/"..v
            break
        end
    end
    for i=1,5 do
        local actor = animx.newActor(daNoteSkin)
        table.insert(actors,actor)
    end
    a = {
        ['actor'] = actors,
        ['prop'] = {
            curAnim = {
                "arrowLEFT",
                "arrowDOWN",
                "arrowUP",
                "arrowRIGHT"
            },
            idle = false,
            leftPress = "false",
            leftConfirm = "false",
            downPress = "false",
            downConfirm = "false",
            upPress = "false",
            upConfirm = "false",
            rightPress = "false",
            rightConfirm = "false",
            press = {
                false,
                false,
                false,
                false
            },
            confirm = {
                false,
                false,
                false,
                false
            },
        },
        ['animOffset']=nil,
    }
    return a
end

function strum.playStrum(daStrum,name,num)
    num = num + 1
    for j=1,4 do
        if name and num == j then
            for i,v in pairs(daStrum.actor[num].animations) do
                if i:find(name) then
                    daStrum.actor[j]:switch(i)
                    daStrum.prop.curAnim[j] = i
                    daStrum.actor[j]:startAnimation()
                    goto continue
                end
            end
        else
            --daStrum.actor:switch(daStrum.prop.curAnim[i])
        end
    end
    ::continue::
end

local function basicNotes(num)
    if num == 0 then
        return "purple"
    elseif num == 1 then 
        return "blue"
    elseif num == 2 then
        return "green"
    elseif num == 3 then
        return "red"
    end
end

function strum.update(dt)
    animx.update(dt)
end

function strum.draw(daStrum,num,strum,x,y,r,sx,sy,forcePlay)
    if not strum then
        daStrum.actor[5]:switch(basicNotes(num))
        local ox,oy = daStrum.actor[num+1]:getDimensions()
        daStrum.actor[5]:render(x,y,r,sx,sy)
        --daStrum.actor[num+1]:switch(daStrum.prop.curAnim[num])
    else
        num = num + 1
        daStrum.actor[num]:switch(daStrum.prop.curAnim[num])
        local ox,oy = 0,0
        if daStrum.prop.curAnim[num]:match("confirm") then
            ox,oy = -11,-10
        end
        daStrum.actor[num]:render(x+ox,y+oy,r,sx,sy)
    end
end

return strum
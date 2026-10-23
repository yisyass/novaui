local S={}
S.Text={'none','rainbow','neon','wave','shimmer','gradient','typewriter','glitch','breathing'}
S.Component={'none','gradient','neon_border','border_sweep','hover_lift','hover_glow','ripple','slide_fade','pulse','progress_sweep','loading_shimmer','status_glow','particles'}
local ranges={speed={0,5,1},intensity={0,1,.35},saturation={0,1,.7},brightness={0,1,1},wave={0,12,3},spacing={0,12,0},duration={.1,30,2},direction={-1,1,1}}
function S.Validate(source,parseColor)
    if source==nil then return {} end
    if type(source)~='table' then return nil,'Invalid effects object' end
    local out={}
    for scope,config in pairs(source) do
        if (scope~='text' and scope~='component') or type(config)~='table' then return nil,'Unknown effects scope' end
        local result={kind='none',enabled=false,repeatEffect=true,cursor=false,rainbowGradient=true,colors={'#A78BFAFF','#4ADEA5FF'}}
        for key,value in pairs(config) do
            if ranges[key] then
                local r=ranges[key]
                if type(value)~='number' or value~=value or value<r[1] or value>r[2] then return nil,'Invalid effect '..key end
                result[key]=value
            elseif key=='kind' then
                local found=false;for _,id in ipairs(scope=='text' and S.Text or S.Component) do if id==value then found=true end end
                if not found then return nil,'Unknown effect kind' end;result.kind=value
            elseif key=='enabled' or key=='repeatEffect' or key=='cursor' or key=='rainbowGradient' then
                if type(value)~='boolean' then return nil,'Invalid effect toggle' end;result[key]=value
            elseif key=='colors' then
                if type(value)~='table' or #value<2 or #value>4 then return nil,'Choose two to four effect colours' end
                local n=0;local colors={}
                for index,color in pairs(value) do
                    if type(index)~='number' or index%1~=0 or index<1 or index>#value or not parseColor(color) then return nil,'Invalid effect colours' end
                    colors[index]=color;n=n+1
                end
                if n~=#value then return nil,'Invalid effect colour list' end;result.colors=colors
            else return nil,'Unknown effect property' end
        end
        for key,r in pairs(ranges) do if result[key]==nil then result[key]=r[3] end end
        out[scope]=result
    end
    return out
end
return S

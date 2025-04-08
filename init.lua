local TRAIL_INTERVAL = 0.2
local trail_timers = {}

-- Base trail definitions
local BASE_TRAILS = {
    sparkle = {
        walk = { texture = "default_mese_particle.png", size = 2, color = "#00ffff" },
        sprint = { texture = "default_mese_particle.png", size = 2, color = "#ff0000"}
    },
    flame = {
        walk = { texture = "flame.png", size = 2, color = "#ffa500" },
        sprint = { texture = "flame.png", size = 2.5, color = "#ff4500" }
    },
}

-- Load trail on join
minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    local trail = player:get_attribute("trail_particles:trail")
    if trail and trail_types[trail] then
        trail_particles[name] = trail
    end
end)

-- Save trail on leave
minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    local trail = trail_particles[name]
    if trail then
        player:set_attribute("trail_particles:trail", trail)
    end
end)

-- Check sprinting
local function is_sprinting(player)
    local control = player:get_player_control()
    return control.aux1 and control.up
end

minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        trail_timers[name] = (trail_timers[name] or 0) + dtime
        if trail_timers[name] < TRAIL_INTERVAL then goto continue end
        trail_timers[name] = 0

        local trail_type = player:get_attribute("trail")
        local def = BASE_TRAILS[trail_type or ""]

        if not def then goto continue end

        local pos = vector.add(player:get_pos(), {x = 0, y = 0.5, z = 0})
        local trail_def = is_sprinting(player) and def.sprint or def.walk

        minetest.add_particle({
            pos = pos,
            velocity = {x=0, y=0.3, z=0},
            acceleration = {x=0, y=0.5, z=0},
            expirationtime = 0.6,
            size = trail_def.size,
            texture = trail_def.texture,
            glow = 8,
        })

        ::continue::
    end
end)

-- Command to set trail
minetest.register_chatcommand("trail", {
    params = "<type>",
    description = "Set your trail (sparkle or flame)",
    func = function(name, param)
        if param == "" then
            return false, "Usage: /trail <sparkle|flame|none>"
        end
        if param == "none" then
            local player = minetest.get_player_by_name(name)
            if player then player:set_attribute("trail", "") end
            return true, "Trail removed"
        end
        if not BASE_TRAILS[param] then
            return false, "Trail not found. Available: sparkle, flame, none"
        end
        local player = minetest.get_player_by_name(name)
        if player then
            player:set_attribute("trail", param)
            return true, "Trail set to " .. param
        end
        return false, "Player not found"
    end
})

-- Admin command to set trail for others
minetest.register_chatcommand("settrail", {
    params = "<trail> <playername>",
    description = "Admin command: Set a trail for a player.",
    privs = {server = true},
    func = function(name, param)
        local args = param:split(" ")
        local trail = args[1]
        local target = args[2]

        if not trail or not target then
            return false, "Usage: /settrail <trail> <playername>"
        end

        if trail == "none" then
            trail_particles[target] = nil
            local p = minetest.get_player_by_name(target)
            if p then p:set_attribute("trail_particles:trail", "") end
            return true, "Removed trail from " .. target
        elseif trail_types[trail] then
            trail_particles[target] = trail
            local p = minetest.get_player_by_name(target)
            if p then p:set_attribute("trail_particles:trail", trail) end
            return true, "Trail '" .. trail .. "' set for " .. target
        else
            return false, "Invalid trail type."
        end
    end
})

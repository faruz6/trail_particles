local TRAIL_INTERVAL = 0.2
local trail_timers = {}
local trail_particles = {}

-- trails
local BASE_TRAILS = {
    sparkle = {
        walk = { texture = "default_mese_particle.png", size = 1.5, color = "#00ffff" },
        sprint = { texture = "default_mese_particle.png", size = 2.2, color = "#ff0000" }
    },
    flame = {
        walk = { texture = "flame.png", size = 2, color = "#ffa500" },
        sprint = { texture = "flame.png", size = 2.5, color = "#ff4500" }
    },
}

-- check sprinting
local function is_sprinting(player)
    local velocity = player:get_velocity()
    local horizontal_speed = math.sqrt(velocity.x^2 + velocity.z^2)
    return horizontal_speed > 4.1
end

-- Load
minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    local trail = player:get_attribute("trail_particles:trail")
    if trail then
        trail_particles[name] = trail
    end
end)

-- save on leave
minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    local trail = trail_particles[name]
    if trail then
        player:set_attribute("trail_particles:trail", trail)
    end
end)

-- Show particle trail
minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        trail_timers[name] = (trail_timers[name] or 0) + dtime
        if trail_timers[name] < TRAIL_INTERVAL then goto continue end
        trail_timers[name] = 0

        local trail_type = trail_particles[name]
        local def = BASE_TRAILS[trail_type or ""]
        if not def then goto continue end

        local trail_def = is_sprinting(player) and def.sprint or def.walk
        local pos = vector.add(player:get_pos(), {x = 0, y = 1, z = 0})
       
        local spread = 0.4
        local offset = {
            x = math.random(-spread*100, spread*100) / 100,
            y = math.random(0, 30) / 100,
            z = math.random(-spread*100, spread*100) / 100,
        }
        pos = vector.add(pos, offset)

        minetest.add_particle({
            pos = pos,
            velocity = {x = 0, y = 0.1, z = 0},
            acceleration = {x = 0, y = 0.2, z = 0},
            expirationtime = 0.4,
            size = trail_def.size,
            texture = trail_def.texture,
            color = trail_def.color,
            glow = 8,
            collisiondetection = false,
        })

        ::continue::
    end
end)

-- command for players
minetest.register_chatcommand("trail", {
    params = "<sparkle|flame|none>",
    description = "Choose your particle trail",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found." end

        if param == "none" then
            trail_particles[name] = nil
            player:set_attribute("trail_particles:trail", "")
            return true, "Trail disabled"
        elseif BASE_TRAILS[param] then
            trail_particles[name] = param
            player:set_attribute("trail_particles:trail", param)
            return true, "Trail set to " .. param
        else
            return false, "Available: sparkle, flame, none"
        end
    end
})

-- admin command
minetest.register_chatcommand("settrail", {
    params = "<trail> <playername>",
    description = "Admin-only: Set a trail for a player",
    privs = {server = true},
    func = function(name, param)
        local args = param:split(" ")
        local trail = args[1]
        local target = args[2]
        if not trail or not target then return false, "Usage: /settrail <trail> <player>" end

        if not BASE_TRAILS[trail] and trail ~= "none" then
            return false, "Invalid trail type"
        end

        local player = minetest.get_player_by_name(target)
        if not player then return false, "Player not found" end

        if trail == "none" then
            trail_particles[target] = nil
            player:set_attribute("trail_particles:trail", "")
            return true, "Trail removed from " .. target
        else
            trail_particles[target] = trail
            player:set_attribute("trail_particles:trail", trail)
            return true, "Trail '" .. trail .. "' set for " .. target
        end
    end
})

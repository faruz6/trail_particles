local trail_particles = {}

-- Trail definitions
local trail_types = {
    sparkle = {
        texture = "default_item_smoke.png",
        glow = 10,
        color = "#ffffff",
    },
    flame = {
        texture = "fire_basic_flame.png",
        glow = 15,
        color = "#ff6600",
    },
    bubble = {
        texture = "bubble.png", -- Use a valid texture here
        glow = 5,
        color = "#66ccff",
    }
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

-- Player command to set their own trail
minetest.register_chatcommand("trail", {
    params = "<none|sparkle|flame|bubble>",
    description = "Set your own trail particle effect.",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found." end

        if param == "none" then
            trail_particles[name] = nil
            player:set_attribute("trail_particles:trail", "")
            return true, "Trail disabled."
        elseif trail_types[param] then
            trail_particles[name] = param
            player:set_attribute("trail_particles:trail", param)
            return true, "Trail set to: " .. param
        else
            return false, "Invalid trail. Use: none, sparkle, flame, bubble"
        end
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

-- Trail particles handler
local last_positions = {}

minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        local pos = player:get_pos()
        local last = last_positions[name]

        if last and vector.distance(pos, last) > 0.1 then
            last_positions[name] = vector.new(pos)

            local trail = trail_particles[name]
            if trail and trail_types[trail] then
                local effect = trail_types[trail]
                minetest.add_particle({
                    pos = {
                        x = pos.x + math.random(-2, 2) * 0.05,
                        y = pos.y + 0.5,
                        z = pos.z + math.random(-2, 2) * 0.05
                    },
                    velocity = {x = 0, y = 0.2, z = 0},
                    expirationtime = 0.5,
                    size = 1.5,
                    texture = effect.texture,
                    glow = effect.glow,
                })
            end
        else
            last_positions[name] = vector.new(pos)
        end
    end
end)


pico-8 cartridge // http://www.pico-8.com
version 43
__lua__

-- sprites
trains_up = 1
trains_right = 2
trains_down = 17
trains_left = 18

function rnddir()
    if rnd(1) then
        return 1
    else
        return -1
    end
end

-- track pieces
track_vert = {
    spr = 19,
    name = 'vertical',
    on_active = function(train, mx, my)
        if train.vy >= 0 then
            train:set_direction(0, 1)
        else
            train:set_direction(0, -1)
        end
        return { mx = mx, my = my }
    end
}

track_horiz = {
    spr = 4,
    name = 'horizontal',
    on_active = function(train, mx, my)
        if train.vx >= 0 then
            train:set_direction(1, 0)
        else
            train:set_direction(-1, 0)
        end
        return { mx = mx, my = my }
    end
}

track_tl = {
    spr = 3,
    name = 'turn_top_left',
    on_active = function(train, mx, my)
        if train.vy < 0 then
            train:set_direction(1, 0)
        else
            train:set_direction(0, 1)
        end
        return { mx = mx, my = my }
    end
}

track_tr = {
    spr = 5,
    name = 'turn_top_right',
    on_active = function(train, mx, my)
        if train.vy < 0 then
            train:set_direction(-1, 0)
        else
            train:set_direction(0, 1)
        end
        return { mx = mx, my = my }
    end
}

track_br = {
    spr = 37,
    name = 'turn_bottom_right',
    on_active = function(train, mx, my)
        if train.vy > 0 then
            train:set_direction(-1, 0)
        else
            train:set_direction(0, -1)
        end
        return { mx = mx, my = my }
    end
}


track_bl = {
    spr = 35,
    name = 'turn_bottom_left',
    on_active = function(train, mx, my)
        if train.vy > 0 then
            train:set_direction(1, 0)
        else
            train:set_direction(0, -1)
        end
        return { mx = mx, my = my }
    end
}

track_four = {
    spr = 23,
    name = 'four_intersect',
    is_interactive = true,
    on_active = function(train, mx, my)
        if train.vy != 0 and mx != 0 then
            train:set_direction(mx, 0)
        elseif train.vx != 0 and my != 0 then
            train:set_direction(0, my)
        end
        return { mx = mx, my = my }
    end
}

track_3_top = {
    spr = 7,
    name = 't_intersect_top',
    is_interactive = true,
    on_active = function(train, mx, my)
        if train.vy < 0 then
            if mx == 0 then mx = rnddir() end
            train:set_direction(mx, 0)
        elseif train.vx != 0 and my > 0 then
            train:set_direction(0, 1)
        end
        return { mx = mx, my = my }
    end
}

track_3_bottom = {
    spr = 39,
    name = 't_intersect_bottom',
    is_interactive = true,
    on_active = function(train, mx, my)
        if train.vy > 0 then
            if mx == 0 then mx = rnddir() end
            train:set_direction(mx, 0)
        elseif train.vx != 0 and my < 0 then
            train:set_direction(0, -1)
        end
        return { mx = mx, my = my }
    end
}

track_3_left = {
    spr = 22,
    name = 't_intersect_left',
    is_interactive = true,
    on_active = function(train, mx, my)
        if train.vx < 0 then
            if my == 0 then my = rnddir() end
            train:set_direction(0, my)
        elseif train.vy != 0 and mx > 0 then
            train:set_direction(1, 0)
        end
        return { mx = mx, my = my }
    end
}

track_3_right = {
    spr = 24,
    name = 't_intersect_right',
    is_interactive = true,
    on_active = function(train, mx, my)
        if train.vx > 0 then
            if my == 0 then my = rnddir() end
            train:set_direction(0, my)
        elseif train.vy != 0 and mx < 0 then
            train:set_direction(-1, 0)
        end
        return { mx = mx, my = my }
    end
}

track_by_spr = {
    [track_vert.spr] = track_vert,
    [track_horiz.spr] = track_horiz,
    [track_tl.spr] = track_tl,
    [track_tr.spr] = track_tr,
    [track_br.spr] = track_br,
    [track_bl.spr] = track_bl,
    [track_four.spr] = track_four,
    [track_3_top.spr] = track_3_top,
    [track_3_bottom.spr] = track_3_bottom,
    [track_3_left.spr] = track_3_left,
    [track_3_right.spr] = track_3_right,
}

train_cars = {}
intersections = {}

function init_train_car()
    return {
        x = 0,
        y = 0,
        vx = 0,
        vy = 0,
        spr = trains_up,
        last_track = -1,
        set_direction = function(self, x, y)
            self.vx = x
            self.vy = y
            if x > 0 then
                self.spr = trains_right
            elseif x < 0 then
                self.spr = trains_left
            elseif y > 0 then
                self.spr = trains_down
            elseif y < 0 then
                self.spr = trains_up
            end
        end
    }
end

function set_intersection_dir(x, y, mx, my)
    if x >= 0 and x <= 14 and y >= 0 and y <= 14 then
        local key = x + y * 14
        intersections[key] = { mx = mx, my = my }
    end
end

function get_intersection_dir(x, y)
    if x >= 0 and x <= 14 and y >= 0 and y <= 14 then
        local key = x + y * 14
        return intersections[key]
    end
end

function get_track_type(spr)
    return track_by_spr[spr]
end

function get_track_on_tile(x, y)
    local tile = mget(x, y)
    return get_track_type(tile)
end

function get_track_at(x, y)
    return get_track_on_tile(flr(x / 8), flr(y / 8))
end

function get_random_track()
    local all_tracks = {}
    for i = 0, 14 do
        for j = 0, 14 do
            local t = get_track_on_tile(i, j)
            if t then
                add(all_tracks, { x = i, y = j, data = t })
            end
        end
    end

    return rnd(all_tracks)
end

function get_car_idx_on_tile(x, y)
    for i, car in ipairs(train_cars) do
        if x == flr(car.x / 8) and y == flr(car.y / 8) then
            return i
        end
    end
end

function reset()
    track = get_random_track()
    train_cars = {}

    local front = init_train_car()
    front.x = track.x * 8
    front.y = track.y * 8
    track.data.on_active(front)
    front.last_track = track.data.spr

    -- populate tailing cars
    for i = 0, 4 do
        local car = init_train_car()
        car.x = front.x + ((front.vx * -8) * (i + 1))
        car.y = front.y + ((front.vy * -8) * (i + 1))
        car.spr = front.spr
        car.last_track = front.last_track
        car.vx = front.vx
        car.vy = front.vy
        add(train_cars, car)
    end
end

function _init()
    reset()
end

function _update()
    if btnp(❎) then
        reset()
    end

    local mx = 0
    if btn(➡️) then mx = 1
    elseif btn(⬅️) then mx = -1 end
    
    local my = 0
    if btn(⬆️) then my = -1
    elseif btn(⬇️) then my = 1 end

    local first = true
    local add_move = nil
    for car in all(train_cars) do
        local dx = 0
        local dy = 0

        if car.vx < 0 then dx = 7 end
        if car.vy < 0 then dy = 7 end

        -- what tile is the car entering this frame
        local tilex = flr((car.x + dx) / 8)
        local tiley = flr((car.y + dy) / 8)

        local track = get_track_on_tile(tilex, tiley)

        if track and track.spr != car.last_track then
            -- car hit a new track type
            car.last_track = track.spr

            if first then
                if get_car_idx_on_tile(tilex, tiley) > 1 then
                    -- collided with self
                    reset()
                end

                -- apply track effect to front
                local dir = track.on_active(car, mx, my)

                if track.is_interactive then
                    -- save input setting if track is interactive
                    set_intersection_dir(tilex, tiley, dir.mx, dir.my)
                end
            else
                if track.is_interactive then
                    -- read input setting if track is interactive
                    local saved_dir = get_intersection_dir(tilex, tiley)
                    track.on_active(car, saved_dir.mx, saved_dir.my)
                else
                    -- no input read required
                    track.on_active(car, 0, 0)
                end
            end
        end
        
        car.x += car.vx
        car.y += car.vy

        first = false
    end
end

function _draw()
    cls()
    map(0, 0, 0, 0, 15, 15)
    for c in all(train_cars) do
        spr(c.spr, c.x, c.y)
    end
    print("v( " .. train_cars[1].vx .. ", " .. train_cars[1].vy .. ") p(" .. train_cars[1].x .. ", " .. train_cars[1].y .. ")", 0, 0, 3)
    print(track_by_spr[train_cars[1].last_track].name, 0, 6, 3)
end

__gfx__
00000000007777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077557700777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700075555707755557700666666666666666666660000000000666666660000000000000000000000000000000000000000000000000000000000000000
00077000075555707755555700600000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000075555707755555700600000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700075555707755557700600666666666666660060000000000666006660000000000000000000000000000000000000000000000000000000000000000
00000000077777700777777000600600000000000060060000000000006006000000000000000000000000000000000000000000000000000000000000000000
00000000007777000000000000600600000000000060060000000000006006000000000000000000000000000000000000000000000000000000000000000000
00000000007777000000000000600600000000000000000000600600006006000060060000000000000000000000000000000000000000000000000000000000
00000000077777700777777000600600000000000000000000600600006006000060060000000000000000000000000000000000000000000000000000000000
00000000075555707755557700600600000000000000000000600666666006666660060000000000000000000000000000000000000000000000000000000000
00000000075555707555557700600600000000000000000000600000000000000000060000000000000000000000000000000000000000000000000000000000
00000000075555707555557700600600000000000000000000600000000000000000060000000000000000000000000000000000000000000000000000000000
00000000075555707755557700600600000000000000000000600666666006666660060000000000000000000000000000000000000000000000000000000000
00000000077557700777777000600600000000000000000000600600006006000060060000000000000000000000000000000000000000000000000000000000
00000000007777000000000000600600000000000000000000600600006006000060060000000000000000000000000000000000000000000000000000000000
00000000000000000000000000600600000000000060060000000000006006000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000600600000000000060060000000000006006000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000600666000000006660060000000000666006660000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000600000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000600000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000666666000000006666660000000000666666660000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000030404040404070404040404050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000130000000000130000000000130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000130000000000130000000000130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000130000000000130000000000130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000130000000000130000000000130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000130000000000130000000000130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000160404040404170404040404180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000130000000000130000000000130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000130000000000130000000000130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000130000000000130000000000130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000130000000000130000000000130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000130000000000130000000000130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000230404040404270404040404250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

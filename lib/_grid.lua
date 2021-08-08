_grid = {}
g = grid.connect()

function _grid.dirty_grid(bool)
  if bool == nil then return grid_dirty end
  grid_dirty = bool
  return grid_dirty
end

function _grid.init()
  _grid.grid_views = {'level','center_frequency','recoprocal_quality'}
  _grid.active_view = 1
  _grid.long_press = false
  _grid.counter = {}
  _grid.flickers = {}
  _grid.solids = {}
  _grid.animator = {0,0,0}
  _grid.animation_mode = {0,0,0}
  _grid.frame = 0
  _grid.last_known_width = g.cols
  _grid.last_known_height = g.rows

  for i=1,#_grid.grid_views, 1 do
    _grid.flickers[i] = {}
    _grid.solids[i] = {}
      for x = 1, _grid.last_known_width do
        _grid.counter[x] = {}
        _grid.solids[i][x] = {}
      for y = 1, _grid.last_known_height do
        _grid.counter[x][y] = nil
        -- _grid.solids[x][y] = nil
      end
    end
  end
  
  _grid.dirty_grid(true)
end

function g.key(x, y, z)
  -- graphics:set_message(x, y, z)
  -- fn.break_splash(true)
  -- fn.dirty_screen(true)
  if z == 1 then
    _grid.counter[x][y] = clock.run(_grid.grid_long_press, g, x, y)
    if y<8 or (x<=3 or (x>4 and x<7)) then
      _grid:short_press(x,y) -- and execute a short press instead.
    end
  end
  if z == 0 then -- otherwise, if a grid key is released...
    if _grid.counter[x][y] then -- and the long press is still waiting...
      clock.cancel(_grid.counter[x][y]) -- then cancel the long press clock,
    end
    _grid:set_long_press(false)
  end
end

function _grid:short_press(x, y, from_view)
  from_view = from_view and from_view or self.active_view
  -- samples:select_x(x)
  -- samples:select_y(y)
  -- samples:toggle(x, y)
  -- _grid:register_flicker_at(self:get_x(), self:get_y())
  -- _grid:register_flicker_at(x, y)
  if y < 8 then -- update filter values
    local clear_col
    if self.solids[from_view][x] and self.solids[from_view][x][1] then
      clear_col = y == self.solids[from_view][x][1].active_led
    end
    if from_view == 1 then -- set level
      if clear_col ~= true then
        local level = util.linlin(2,8,0,1.6,9-y)
        params:set("filter_level"..x,level)
      else 
        params:set("filter_level"..x,0)
      end
    elseif from_view == 2 then -- set reciprocal quality
      if clear_col ~= true then
        local rq = util.linlin(1,8,0.1,1,y)
        params:set("reciprocal_quality"..x,rq)
      else 
        params:set("reciprocal_quality"..x,1)
      end
    elseif from_view == 3 then -- set center frequency
      if clear_col ~= true then
        local cf = util.linexp(1,8,cs_cf.minval,cs_cf.maxval,y)
        cf = util.expexp(cs_cf.minval,cs_cf.maxval,cs_cf.maxval,cs_cf.minval,cf)
        params:set("center_frequency"..x,cf)
      else 
        -- local cf = util.linexp(1,8,cs_cf.minval,cs_cf.maxval,(x/16)*8)
        local cf = cs_cf.minval
        params:set("center_frequency"..x,cf)
      end
    end
    self.solids[from_view][x] = {}
    for i=7,y,-1
    do
      if clear_col ~= true then _grid:register_solid_at(x, i, y, from_view) end
    end
    _grid.dirty_grid(true)
    -- fn.dirty_screen(true)
  else
    if x <= 3 then -- change modes
      self.active_view = x
    elseif x == 5 or x == 6 then  -- set animation view
      if (self.animation_mode[_grid.active_view] == 1 and x == 5) or (self.animation_mode[_grid.active_view] == 2 and x == 6) then 
        self.animation_mode[_grid.active_view] = 0 
        _grid.animator[_grid.active_view] = self.animation_mode[_grid.active_view]
      else
        self.animation_mode[_grid.active_view] = x==5 and 1 or 2
        _grid.animator[_grid.active_view] = self.animation_mode[_grid.active_view]
      end
    end
    for i=1,16,1 do
      if i==x then
        i = i<=3 and i or self.active_view
        _grid:register_solid_at(x, y, x, i)
      end
    end

    _grid.dirty_grid(true)
  end
end

function _grid:is_long_press()
  return self.long_press
end

function _grid:grid_long_press(x, y)
  clock.sleep(.5)
  -- print("long press",x,y)
  _grid:set_long_press(true)
  --samples:select_x(x)
  --samples:select_y(y)
  _grid.counter[x][y] = nil
  _grid.dirty_grid(true)  
  -- fn.dirty_screen(true)
end

function _grid.grid_redraw_clock()
  while true do
    clock.sleep(1 / 15)
    _grid.frame = _grid.frame + 1
    if _grid.dirty_grid() == true then
      _grid:grid_redraw()
      _grid.dirty_grid(false)
    end
    if #_grid.flickers[_grid.active_view] > 0 or #_grid.solids[_grid.active_view] > 0 then
      _grid.dirty_grid(true)
    end
  end
end

function _grid:draw_live_samples()
  -- for k, sample in pairs(samples:get_all()) do
  --   if sample:is_live() then
  --     g:led(sample:get_x(), sample:get_y(), 1)
  --   end
  -- end
end

function _grid:draw_playing_samples()
  -- for k, sample in pairs(samples:get_all()) do
  --   if sample:is_playing() then
  --     g:led(sample:get_x(), sample:get_y(), 5)
  --   end
  -- end
end

function _grid:register_solid_at(x, y, active_led, view)
  local solid = {}
  solid.x = x
  solid.y = y
  solid.origin_frame = self.frame
  solid.active_led = active_led and active_led or nil
  if y<8 then 
    solid.level = 5
  elseif x~=4 and x~=7 then
    if x <= 3 or _grid.animator[_grid.active_view] > 0 then
      solid.level = 5
    else
      solid.level = 0
    end
  else
    solid.level = 3
  end 

  table.insert(self.solids[view][x], solid)
end
  
function _grid:draw_led_solids()
  for i=1,16,1 do
    -- if self.solids[i] == nil then break end
    for k, v in pairs(self.solids[self.active_view][i]) do
      -- if v.level == 0 or v.origin_frame + 2 < self.frame then
      if v.level == 0 then
        table.remove(self.solids[self.active_view][i], k)
      else
        g:led(v.x, v.y, v.level)
        -- v.level = v.level - 1
      end
    end
  end
  
end

function _grid:register_flicker_at(x, y)
  local flicker = {}
  flicker.x = x
  flicker.y = y
  flicker.origin_frame = self.frame
  flicker.level = 5
  table.insert(self.flickers[self.active_view], flicker)
end

function _grid:draw_led_flickers()
  for k, v in pairs(self.flickers[self.active_view]) do
    if v.level == 0 or v.origin_frame + 2 < self.frame then
      table.remove(self.flickers[self.active_view], k)
    else
      g:led(v.x, v.y, v.level)
      v.level = v.level - 1
    end
  end
end


--[[function _grid:draw_led_pulses()
  for k, v in pairs(self.flickers[self.active_view]) do
    if v.level == 0 or v.origin_frame + 2 < self.frame then
      table.remove(self.flickers[self.active_view], k)
    else
      g:led(v.x, v.y, v.level)
      v.level = v.level - 1
    end
  end
end
]]


function _grid:animate()
  local i=1
  while i <= 3 do
    -- print("anim",i,_grid.animator[i])
    if _grid.animator[i] ~= 0 then
      for j=1,16,1 do
        if _grid.animator[i] == 1 then
          local col_level = (_grid.solids[i][j] == nil or _grid.solids[i][j][1] == nil) and 
            0 or 
            _grid.solids[i][j][1].active_led
          local new_col_level
          if col_level and col_level ~= 0 then
            if col_level - 1 == 0 then
              new_col_level = 7
            else
              new_col_level = col_level - 1
            end
            _grid:short_press(j, new_col_level,i)
          end
        elseif _grid.animator[i] == 2 then
          k = j<16 and j+1 or 1
          local next_col_level = (_grid.solids[i][k] ~= nil and _grid.solids[i][k][1] ~= nil) and 
            _grid.solids[i][k][1].active_led or (_grid.solids[i][j] and _grid.solids[i][j][1]) and _grid.solids[i][j][1].active_led or nil
          if next_col_level then _grid:short_press(j, next_col_level,i) end
        end
      end
    end
    i = i+1
  end
end

function _grid:draw_spacers()
  g:led(4, 8, 3)
  g:led(7, 8, 3)
end

function _grid:draw_animation_indicators()
  for i=1,3,1 do
    if self.animation_mode[_grid.active_view] == 1 then
      g:led(5, 8, 7)
    elseif self.animation_mode[_grid.active_view] == 2 then
      g:led(6, 8, 7)
    end
  end
end

function _grid:draw_active_view()
  g:led(self.active_view, 8, 7)
end

function _grid:grid_redraw()
  g:all(0)
  self:draw_live_samples()
  self:draw_playing_samples()
  -- self:draw_led_flickers()
  self:draw_spacers()  
  self:draw_animation_indicators()
  self:draw_led_solids()

  -- draw active_view
  -- set leds to show active view and  (if selected) animation mode
  self:draw_active_view()
  g:refresh()
end

function _grid:get_width()
  return _grid.last_known_width
end

function _grid:get_height()
  return _grid.last_known_height
end

function _grid:set_long_press(bool)
  self.long_press = bool
end

return _grid
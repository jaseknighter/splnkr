grid_filter = {}

function grid_filter.dirtygrid(bool)
  if bool == nil then return grid_dirty end
  grid_dirty = bool
  return grid_dirty
end

function grid_filter.init()
  grid_filter.grid_views = {'level','filter_center_frequency','recoprocal_quality'}
  grid_filter.active_view = 1
  grid_filter.long_press = false
  grid_filter.counter = {}
  grid_filter.flickers = {}
  grid_filter.solids = {}
  grid_filter.animator = {0,0,0}
  grid_filter.animation_mode = {0,0,0}
  grid_filter.filter_param_overlay = false
  grid_filter.frame = 0
  grid_filter.last_known_width = g.cols
  grid_filter.last_known_height = g.rows

  for i=1,#grid_filter.grid_views, 1 do
    grid_filter.flickers[i] = {}
    grid_filter.solids[i] = {}
    for x = 1, grid_filter.last_known_width do
      grid_filter.counter[x] = {}
      grid_filter.solids[i][x] = {}
      for y = 1, grid_filter.last_known_height do
        grid_filter.counter[x][y] = nil
        -- grid_filter.solids[x][y] = nil
      end
    end
  end
  
  grid_filter.dirtygrid(true)
end

function grid_filter.key(x, y, z)
  -- graphics:set_message(x, y, z)
  -- fn.break_splash(true)
  -- fn.dirty_screen(true)
  if z == 1 then
    grid_filter.counter[x][y] = clock.run(grid_filter.grid_long_press, g, x, y)
  end
  if z == 0 then -- otherwise, if a grid key is released...
    if grid_filter.counter[x][y] then -- and the long press is still waiting...
      clock.cancel(grid_filter.counter[x][y]) -- then cancel the long press clock,
      if y<8 or (x<=3 or (x>4 and x<7) or x == 8) then
        grid_filter:short_press(x,y) -- and execute a short press instead.
      end
    end
    grid_filter:set_long_press(false)
  end
end

function grid_filter:short_press(x, y, from_view)
  from_view = from_view and from_view or self.active_view
  -- samples:select_x(x)
  -- samples:select_y(y)
  -- samples:toggle(x, y)
  -- grid_filter:register_flicker_at(self:get_x(), self:get_y())
  -- grid_filter:register_flicker_at(x, y)
  if y < 8 then -- update filter values
    local clear_col
    if self.solids[from_view][x] and self.solids[from_view][x][1] then
      clear_col = y == self.solids[from_view][x][1].active_led_height
    end
    if from_view == 1 then -- set level
      if clear_col ~= true then
        local level = util.linlin(2,8,0,cs_level.maxval,params:get("num_sequin")-y)
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
        params:set("filter_center_frequency"..x,cf)
      else 
        -- local cf = util.linexp(1,8,cs_cf.minval,cs_cf.maxval,(x/16)*8)
        local cf = cs_cf.minval
        params:set("filter_center_frequency"..x,cf)
      end
    end
    self.solids[from_view][x] = {}
    for i=7,y,-1
    do
      if clear_col ~= true then grid_filter:register_solid_at(x, i, y, from_view) end
    end
    grid_filter.dirtygrid(true)
    -- fn.dirty_screen(true)
  else
    if x <= 3 then -- change modes
      self.active_view = x
    elseif (x == 5 or x == 6) then  -- set animation view
      if (self.animation_mode[grid_filter.active_view] == 1 and x == 5) or (self.animation_mode[grid_filter.active_view] == 2 and x == 6) then 
        self.animation_mode[grid_filter.active_view] = 0 
        grid_filter.animator[grid_filter.active_view] = 0
      else
        self.animation_mode[grid_filter.active_view] = x==5 and 1 or 2
        grid_filter.animator[grid_filter.active_view] = self.animation_mode[grid_filter.active_view]
      end
    elseif x == 8 then 
      if self.filter_param_overlay == true then 
        self.filter_param_overlay = false
      else
        self.filter_param_overlay = true
      end
    end
    grid_filter.dirtygrid(true)
  end
end

function grid_filter:is_long_press()
  return self.long_press
end

function grid_filter:grid_long_press(x, y)
  clock.sleep(0.5)
  grid_filter:set_long_press(true)
  
  -- clear values on long press 
  local from_view = grid_filter.active_view
  if from_view == 1 then -- set level
    params:set("filter_level"..x,0)
  elseif from_view == 2 then -- set reciprocal quality
    params:set("reciprocal_quality"..x,1)
  elseif from_view == 3 then -- set center frequency
    local cf = cs_cf.minval
    params:set("filter_center_frequency"..x,cf)
  end

  grid_filter.counter[x][y] = nil
  grid_filter.dirtygrid(true)  
end

function grid_filter.grid_redraw_clock()
  while true do
    clock.sleep(1 / 15)
    grid_filter.frame = grid_filter.frame + 1
    if grid_filter.dirtygrid() == true then
      grid_filter:redraw()
      grid_filter.dirtygrid(false)
    end
    if #grid_filter.flickers[grid_filter.active_view] > 0 or #grid_filter.solids[grid_filter.active_view] > 0 then
      grid_filter.dirtygrid(true)
    end
  end
end

function grid_filter:register_solid_at(x, y, active_led_height, view)
  local solid = {}
  solid.x = x
  solid.y = y
  solid.origin_frame = self.frame
  solid.active_led_height = active_led_height and active_led_height or nil
  if y<8 then 
    solid.level = 10
  elseif x~=4 and x~=7 then
    if x <= 3 or grid_filter.animator[grid_filter.active_view] > 0 then
      solid.level = 10
    else
      solid.level = 0
    end
  else
    solid.level = 3
  end 

  table.insert(self.solids[view][x], solid)
end
  
function grid_filter:draw_led_solids()
  for i=1,3,1 do
    for j=1,16,1 do
      -- for k, v in pairs(self.solids[self.active_view][j]) do
      for k, v in pairs(self.solids[i][j]) do
        if v.level == 0 then
          -- table.remove(self.solids[self.active_view][j], k)
          table.remove(self.solids[i][j], k)
        else
          if i == self.active_view then
            g:led(v.x, v.y, v.level)
          end
          if self.filter_param_overlay == true then
            if i== 1 and i ~= self.active_view then
              g:led(v.x, v.y, 2)
            elseif i== 2  and i ~= self.active_view then
              g:led(v.x, v.y, 4)
            elseif i== 3  and i ~= self.active_view then
              g:led(v.x, v.y, 6)
            end
          end
        end
      end
    end
  end
end

function grid_filter:register_flicker_at(x, y)
  local flicker = {}
  flicker.x = x
  flicker.y = y
  flicker.origin_frame = self.frame
  flicker.level = 5
  table.insert(self.flickers[self.active_view], flicker)
end

function grid_filter:draw_led_flickers()
  for k, v in pairs(self.flickers[self.active_view]) do
    if v.level == 0 or v.origin_frame + 2 < self.frame then
      table.remove(self.flickers[self.active_view], k)
    else
      g:led(v.x, v.y, v.level)
      v.level = v.level - 1
    end
  end
end


function grid_filter:draw_led_pulses()
  for k, v in pairs(self.flickers[self.active_view]) do
    if v.level == 0 or v.origin_frame + 2 < self.frame then
      table.remove(self.flickers[self.active_view], k)
    else
      g:led(v.x, v.y, v.level)
      v.level = v.level - 1
    end
  end
end



function grid_filter:animate()
  local i=1
  while i <= 3 do
    if grid_filter.animator and grid_filter.animator[i] ~= 0 then
      for j=1,16,1 do
        if grid_filter.animator[i] == 1 then
          local col_level = (grid_filter.solids[i][j] == nil or grid_filter.solids[i][j][1] == nil) and 
            0 or 
            grid_filter.solids[i][j][1].active_led_height
          local new_col_level
          if col_level and col_level ~= 0 then
            if col_level - 1 == 0 then
              new_col_level = 7
            else
              new_col_level = col_level - 1
            end
            grid_filter:short_press(j, new_col_level,i)
          end
        elseif grid_filter.animator[i] == 2 then
          k = j<16 and j+1 or 1
          local next_col_level = (grid_filter.solids[i][k] ~= nil and grid_filter.solids[i][k][1] ~= nil) and 
            grid_filter.solids[i][k][1].active_led_height or (grid_filter.solids[i][j] and grid_filter.solids[i][j][1]) and grid_filter.solids[i][j][1].active_led_height or nil
          if next_col_level then grid_filter:short_press(j, next_col_level,i) end
        end
      end
    end
    i = i+1
  end
end

function grid_filter:draw_spacers()
  g:led(4, 8, 2)
  g:led(7, 8, 2)
  g:led(9, 8, 2)
  g:led(10, 8, 2)
  -- g:led(11, 8, 2)
  -- g:led(12, 8, 2)
  -- g:led(13, 8, 2)
  g:led(14, 8, 2)
end

function grid_filter:draw_animation_indicators()
  for i=1,3,1 do
    if self.animation_mode[grid_filter.active_view] == 1 then
      g:led(5, 8, 7)
    elseif self.animation_mode[grid_filter.active_view] == 2 then
      g:led(6, 8, 7)
    end
  end
end

function grid_filter:draw_filter_param_overlay()
  if self.filter_param_overlay == true then
    g:led(8, 8, 10)
  else
    g:led(8, 8, 0)
  end
end

function grid_filter:draw_active_view()
  g:led(self.active_view, 8, 7)
end

function grid_filter:redraw()
  if grid_mode == "filter" then
    g:all(0)
    -- self:draw_led_flickers()
    self:draw_spacers()  
    self:draw_animation_indicators()
    self:draw_filter_param_overlay()
    self:draw_led_solids()
    -- draw active_view
    -- set leds to show active view and  (if selected) animation mode
    self:draw_active_view()
    
    --set mode indicator
    g:led(15, 8, 7)
    g:refresh()
  end
end

function grid_filter:get_width()
  return  grid_filter.last_known_width
end

function grid_filter:get_height()
  return  grid_filter.last_known_height
end

function grid_filter:set_long_press(bool)
  self.long_press = bool
end

return  grid_filter
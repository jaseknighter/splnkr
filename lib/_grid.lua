_grid = {}
g = grid.connect()

function _grid.dirty_grid(bool)
  if bool == nil then return grid_dirty end
  grid_dirty = bool
  return grid_dirty
end

function _grid.init()
  _grid.long_press = false
  _grid.counter = {}
  _grid.flickers = {}
  _grid.solids = {}
  _grid.frame = 0
  _grid.last_known_width = g.cols
  _grid.last_known_height = g.rows
  -- print("_grid.last_known_width",g.last_known_width)
    
  for x = 1, _grid.last_known_width do
    _grid.counter[x] = {}
    _grid.solids[x] = {}
    for y = 1, _grid.last_known_height do
      _grid.counter[x][y] = nil
      -- _grid.solids[x][y] = nil
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
    _grid:short_press(x,y) -- and execute a short press instead.
  end
  if z == 0 then -- otherwise, if a grid key is released...
    if _grid.counter[x][y] then -- and the long press is still waiting...
      clock.cancel(_grid.counter[x][y]) -- then cancel the long press clock,
    end
    _grid:set_long_press(false)
  end
end

function _grid:short_press(x, y)
  -- samples:select_x(x)
  -- samples:select_y(y)
  -- samples:toggle(x, y)
  -- _grid:register_flicker_at(self:get_x(), self:get_y())
  -- _grid:register_flicker_at(x, y)
  local clear_col
  if self.solids[x] and self.solids[x][1] then
    clear_col = y == self.solids[x][1].origin_led
  end
  
  if clear_col ~= true then
    -- params:set("reciprocal_quality",0.2)
    local rq = util.linlin(1,8,0.01,1,y)
    print(rq)
    params:set("reciprocal_quality"..x,rq)

  else 
    params:set("reciprocal_quality"..x,1)
  end

  self.solids[x] = {}
  for i=7,y,-1
  do
    -- _grid:register_flicker_at(x, i)
    if clear_col ~= true then _grid:register_solid_at(x, i, y) end
  end
  _grid.dirty_grid(true)
  -- fn.dirty_screen(true)
end

function _grid:is_long_press()
  return self.long_press
end

function _grid:grid_long_press(x, y)
  clock.sleep(.5)
  print("long press",x,y)
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
    if #_grid.flickers > 0 or #_grid.solids > 0 then
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

function _grid:register_solid_at(x, y, origin_led)
  -- print(#self.solids)
  local solid = {}
  solid.x = x
  solid.y = y
  solid.origin_frame = self.frame
  solid.origin_led = origin_led
  solid.level = 5
  table.insert(self.solids[x], solid)
end

function _grid:draw_led_solids()
  for i=1,16,1 do
    -- if self.solids[i] == nil then break end
    for k, v in pairs(self.solids[i]) do
      -- if v.level == 0 or v.origin_frame + 2 < self.frame then
      if v.level == 0 then
        table.remove(self.solids[i], k)
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
  table.insert(self.flickers, flicker)
end

function _grid:draw_led_flickers()
  for k, v in pairs(self.flickers) do
    if v.level == 0 or v.origin_frame + 2 < self.frame then
      table.remove(self.flickers, k)
    else
      g:led(v.x, v.y, v.level)
      v.level = v.level - 1
    end
  end
end


function _grid:grid_redraw()
  -- print("redraw")
  g:all(0)
  self:draw_live_samples()
  self:draw_playing_samples()
  self:draw_led_flickers()
  self:draw_led_solids()
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
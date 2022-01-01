-- softcut study 8: copy
--
-- K1 load backing track
-- K2 random copy/paste
-- K3 save clip
-- E1 level



Cutter = {}
local cutter_labels = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t"}

function Cutter:new(cutter_id, start_x,finish_x)
  local c = setmetatable({}, { __index = Cutter })
  c.cutter_id = cutter_id
  c.start_x = start_x and start_x or 0
  c.finish_x = finish_x and finish_x or c.start_x + 30
  c.start_x_updated = c.start_x 
  c.finish_x_updated = c.finish_x
  c.active_edge = 1
  c.display_mode = 0
  return c
end

function Cutter:set_cutter_id(id)
  self.cutter_id = id
end

function Cutter:set_display_mode(mode)
  -- 0 = nothing highlighted
  -- 1 = highlight active edge
  -- 2 = highlight both edges
  self.display_mode = mode
end

function Cutter:cutters_start_finish_update(start,finish)
  -- self.start_x_updated = (self.start_x * z) + o
  -- self.finish_x_updated = (self.finish_x * z) + o
  self.start_x_updated = start
  self.finish_x_updated = finish
end


function Cutter:get_start_x()
  return self.start_x
end

function Cutter:get_start_x_updated()
  return self.start_x_updated
end

function Cutter:set_start_x(val)
  self.start_x = val 
end

function Cutter:get_finish_x_updated()
  return self.finish_x_updated
end

function Cutter:get_finish_x()
  return self.finish_x
end

function Cutter:set_finish_x(val)
  self.finish_x = val
end

function Cutter:get_active_edge()
  return self.active_edge
end

function Cutter:set_active_edge(active_edge)
  self.active_edge = active_edge
end

function Cutter:rotate_cutter_edge(d)
  self.active_edge = util.clamp(self.active_edge + d,1, 2)
end

function Cutter:update()
  if menu_status == false and waveform_loaded  then
    -- draw cutters
    for i=1,2,1
    do
      local height = 5
      local bottom = screen_size.y - 15

      --draw start lines
      if (self.active_edge == 1 and self.display_mode == 1) or self.display_mode == 2 then
        screen.level(15)
      else
        screen.level(5)
      end
      local start_loc = {math.floor(self.start_x_updated), 25 - height}
      if start_loc[1] >= 10 and start_loc[1] <= 128 then
        screen.move(start_loc[1],start_loc[2])
        screen.line(start_loc[1],bottom)
        screen.stroke()
        screen.move(start_loc[1]-1,bottom)
        screen.line_rel(6, 0)
        screen.stroke()
        --draw cut num 
        -- local text_location_y = (25 - height) + (height * 2) + 6 -- - 2
        local text_location_y = (25 - height)
        screen.move(start_loc[1]+2,text_location_y)
        if self.cutter_id and cutter_labels[self.cutter_id] then screen.text(cutter_labels[self.cutter_id]) end
      end 
      --draw end lines
      if (self.active_edge == 2 and self.display_mode == 1) or self.display_mode == 2 then
        screen.level(15)
      else
        screen.level(5)
      end

      local finish_loc = {math.floor(self.finish_x_updated), 25 - height}
      if finish_loc[1] >= 10 and finish_loc[1] <= 120 then
        screen.move(finish_loc[1],finish_loc[2])
        screen.line(finish_loc[1],bottom)
        -- screen.line_rel(0, 4 * height)
        screen.stroke()
        screen.move(finish_loc[1]-1,bottom)
        screen.line_rel(-5, 0)
        screen.stroke()
        --draw cut num 
        if (finish_loc[1] - start_loc[1] > 11 or start_loc[1] < 12) then
          -- local text_location_y = (25 - height) + (height * 2) + 6 -- - 2
          local text_location_y = (25 - height)
          screen.move(finish_loc[1]-5,text_location_y)
          if self.cutter_id then
            screen.text(cutter_labels[self.cutter_id])
          end
        end 
      end
    end
  end
end

return Cutter
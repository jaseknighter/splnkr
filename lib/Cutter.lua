-- softcut study 8: copy
--
-- K1 load backing track
-- K2 random copy/paste
-- K3 save clip
-- E1 level




Cutter = {}

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

function Cutter:key(n,z)
  if n==1 and z==1 then
    -- do something
  elseif n==2 and z==1 then
    -- if waveform_loaded then
    --   Cutter:copy_cut()
    --   -- if not dismiss_K2_message then dismiss_K2_message = true end
    -- end
  elseif n==3 and z==1 then
    -- if nav_active_control == 1 and waveform_loaded then
    --   playing = playing == 1 and 0 or 1
    --   softcut.play(1, playing)
    -- end
    -- saved = "ss7-"..string.format("%04.0f",10000*math.random())..".wav"
    -- softcut.buffer_write_mono(_path.dust.."/audio/"..saved,1,length,1)
  end
end

--       cutters[cutter_id].start_x = util.clamp(cutters[cutter_id].start_x+(d*1),0,cutters[cutter_id].finish_x)
--       cutters[cutter_id].finish_x = util.clamp(cutters[cutter_id].finish_x+(d*1),cutters[cutter_id].start_x, 128)
    
-- function Cutter:update(zoom,offset)
function Cutter:update()
    if menu_status == false then
    -- screen.clear()
    if not waveform_loaded then
      -- screen.level(15)
      -- screen.move(62,50)
      -- screen.text_center("hold K1 to load sample")
    else
      -- screen.level(15)
      -- screen.move(62,10)
      -- if not dismiss_K2_message then
      --   screen.text_center("K2: random copy/paste")
      -- else
      --   screen.text_center("K3: save new clip")
      -- end

      -- draw cutters
      for i=1,2,1
      do
        local height = math.floor((scale*level) - 20)
        local bottom = math.floor((35 - height) + (height * 2))

        --draw start lines
        if (self.active_edge == 1 and self.display_mode == 1) or self.display_mode == 2 then
          screen.level(15)
        else
          screen.level(5)
        end
        local start_loc = {math.floor(self.start_x_updated), 35 - height}
        
        if start_loc[1] >= 10 and start_loc[1] <= 128 then
          screen.move(start_loc[1],start_loc[2])
          screen.line_rel(0, 2 * height)
          screen.stroke()
          screen.move(start_loc[1]-1,bottom)
          screen.line_rel(6, 0)
          screen.stroke()
          --draw cut num 
          local text_location_y = (35 - height) + (height * 2) + 6 -- - 2
          screen.move(start_loc[1]+2,text_location_y)
          screen.text(self.cutter_id)
        end 
        --draw end lines
        if (self.active_edge == 2 and self.display_mode == 1) or self.display_mode == 2 then
          screen.level(15)
        else
          screen.level(5)
        end

        local finish_loc = {math.floor(self.finish_x_updated), 35 - height}
        if finish_loc[1] >= 10 and finish_loc[1] <= 120 then
          screen.move(finish_loc[1],finish_loc[2])
          screen.line_rel(0, 2 * height)
          screen.stroke()
          screen.move(finish_loc[1]-1,bottom)
          screen.line_rel(-5, 0)
          screen.stroke()
          --draw cut num 
          if (finish_loc[1] - start_loc[1] > 11 or start_loc[1] < 12) then
            local text_location_y = (35 - height) + (height * 2) + 6 -- - 2
            screen.move(finish_loc[1]-5,text_location_y)
            screen.text(self.cutter_id)
          end 
        end

      end
    end
  end
end

-- return Cutter
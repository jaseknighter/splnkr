
sequencer_screen = {}
sequencer_screen.active_ui_group = "sequins group selector (1-5)"
sequencer_screen.active_ui_group_instructions1 = ""
sequencer_screen.active_ui_group_instructions2 = " "
sequencer_screen.active_ui_group_instructions3 = ""
    


Square = {}

-- sequencer_controller.get_active_output_table_slot().output_value

function Square:new(col, row)
  local square = {}
  setmetatable(square, Square)
  square.row = row
  square.col = col
  square.fill = false

  function square:draw()
    -- code to draw squares
    local x_loc = 5 + (self.col-1)*3
    local y_loc = 15 + (self.row-1)* 3
    screen.move(x_loc,y_loc)
    screen.rect(x_loc,y_loc,3,3)
    if (self.fill == true) then 
      -- screen.level(6)
      screen.level(15)
      screen.stroke()
      screen.fill() 
    else
      screen.level(3)
      screen.fill() 
    end
    screen.update()
  end

  return square
end


sequencer_screen.squares = {}

function sequencer_screen.init(num_cols, num_rows)
  active_control = ""
  --[[
  for i=1,num_cols,1 do
    for j=1,num_rows,1 do
      local sq = Square:new(i,j)
      if i==13 then sq.fill = true end
      table.insert(sequencer_screen.squares, sq)
    end
  end
  ]]
end

--[[
  local indices = {
  selected_sequin_group        = sequencer_controller.selected_sequin_group,         -- selected_sequin_group:  value table level 1
  selected_sequin_subgroups     = sequencer_controller.selected_sequin_subgroups,      -- selected_sequin_group:  value table level 2
  selected_sequin               = sequencer_controller.selected_sequin,          -- selected_sequin:  value table level 3
  selected_sequin_output_type   = sequencer_controller.selected_sequin_output_type,    -- output_type_selected:  value table level 4
  selected_sequin_output        = sequencer_controller.selected_sequin_output,         -- output_selected:  value table level 5
  selected_sequin_output_mode   = sequencer_controller.selected_sequin_output_mode,    -- output_mode_selected:  value table level 6
  selected_sequin_output_param  = sequencer_controller.selected_sequin_output_param,   -- output_param_selected:  value table level 7
}
]]
function sequencer_screen.update_screen_instructions(selected_control_indices)
  local active_ui_group_name = sequencer_controller:get_active_ui_group()
  active_ui_group_name = (string.sub(active_ui_group_name,1,13) == "sequin groups") and "sequin groups" or active_ui_group_name
  specs_map = sequencer_controller.get_output_control_specs_map()

  local output_type = selected_control_indices.selected_sequin_output_type
  local output_index = selected_control_indices.selected_sequin_output
  local output_mode = selected_control_indices.selected_sequin_output_mode
  local output_param = selected_control_indices.selected_sequin_output_param
  
  local control_labels = {"","",""}
  local control_bcrumbs = ""
  local sequence_values = {}
  
  -- set control breadcrumbs
  if sequencer_controller.selected_sequin_group then
    control_bcrumbs = control_bcrumbs .. sequencer_controller.selected_sequin_group
    sequence_values = sequencer_screen.get_sequence_values()
  end
  if sequencer_controller.selected_sequin then
    control_bcrumbs = control_bcrumbs .. "-" .. sequencer_controller.selected_sequin .. " "
  end
  if output_type == 1 then -- softcut titles and labels
    control_bcrumbs =  control_bcrumbs .. "sc voice "
    if output_index then
      control_bcrumbs = control_bcrumbs .. output_index .. " "
      local label_pos = 1
      for i=1,#specs_map[1][1],1 do
        control_labels[label_pos] = control_labels[label_pos] .. specs_map[1][1][i][5] .. " "
        label_pos = i%3 == 0 and label_pos + 1 or label_pos
      end  
      if output_param then
        control_bcrumbs = control_bcrumbs .. specs_map[output_type][output_index][output_param][5]
        -- if specs_map[output_type][output_index][output_param][1] == "option" then
        --   local label_pos = 1
        --   control_labels = {"","",""}
        --   for i=1,#specs_map[output_type][output_index][output_param][2],1 do
        --     local param = specs_map[output_type][output_index][output_param][2][i]
        --     control_labels[label_pos] = control_labels[label_pos] .. param .. " "
        --     label_pos = i%3 == 0 and label_pos + 1 or label_pos
        --   end
        -- end
      end
    end
  elseif output_type == 2 then
    control_bcrumbs =  control_bcrumbs .. "dev "
    if output_index then 
      if output_index == 1 then -- midi
        -- control_bcrumbs = control_bcrumbs .. "midi "
        -- local label_pos = 1
        -- for i=1,#specs_map[2][1],1 do
        --   control_labels[label_pos] = control_labels[label_pos] .. specs_map[output_type][output_index][i][5] .. " "
        --   label_pos = i%3 == 0 and label_pos + 1 or label_pos
        -- end
        -- if output_mode then
        --   control_bcrumbs = control_bcrumbs .. specs_map[output_type][output_index][output_mode][5] .. " "
        -- end        
        control_bcrumbs =  control_bcrumbs .. "midi "
        if output_mode == nil then
          control_labels[1] = "v1 v2 v3"
          control_labels[2] = "cc1 cc2 cc3"
          control_labels[3] = "start/stop"
        elseif output_mode < 7 then
          control_bcrumbs = output_mode < 4 and control_bcrumbs .. "v" or  control_bcrumbs .. "cc"
          local output_num = output_mode < 4 and output_mode or output_mode - 3
          if output_param == nil then 
            control_bcrumbs = control_bcrumbs .. output_num
            local label_pos = 1
            for i=1,#specs_map[output_type][output_index][output_mode],1 do
              local val = specs_map[output_type][output_index][output_mode][i][5]
              control_labels[label_pos] = control_labels[label_pos] .. val .. " "
              label_pos = i%3 == 0 and label_pos + 1 or label_pos
            end
          else
            control_bcrumbs = control_bcrumbs  .. output_num .. " " .. specs_map[output_type][output_index][output_mode][output_param][5]
          end
        else
          control_bcrumbs = control_bcrumbs .. "stp/strt" 
        end
      elseif output_index == 2 then -- crow
        control_bcrumbs = "dev crow "
        local label_pos = 1
        if output_mode == nil and output_param == nil then
          for i=1,#specs_map[2][2],1 do
            control_labels[label_pos] = control_labels[label_pos] .. specs_map[output_type][output_index][i][5] .. " "
            label_pos = i%3 == 0 and label_pos + 1 or label_pos
          end
        elseif output_mode then
          control_bcrumbs = control_bcrumbs .. specs_map[output_type][output_index][output_mode][5] .. " "
        end
      elseif output_index == 3 then -- just friends
        local control_bcrumbs_base = control_bcrumbs
        if output_mode == nil and output_param == nil then
          control_bcrumbs =  control_bcrumbs .. "jf "
          control_labels[1] = "play_note"
          control_labels[2] = "vce1 vce2 vce3"
          control_labels[3] = "vce4 vce5 vce6"
        elseif output_mode then
          control_bcrumbs = output_mode == 1 and control_bcrumbs .. "jf note" or control_bcrumbs .. "jf vce" .. (output_mode-1)
          local label_pos = 1
          for i=1,#specs_map[output_type][output_index][output_mode],1 do
            control_labels[label_pos] = control_labels[label_pos] .. specs_map[output_type][output_index][output_mode][i][5] .. " "
            label_pos = i%3 == 0 and label_pos + 1 or label_pos
          end

          if output_param and output_mode == 1 then
            control_bcrumbs = control_bcrumbs .. " " .. specs_map[output_type][output_index][output_mode][output_param][5]
          elseif output_param and output_mode > 1 then 
            control_bcrumbs = control_bcrumbs_base .. "jf vce" .. (output_mode-1)
            control_bcrumbs = control_bcrumbs .. " " .. specs_map[output_type][output_index][output_mode][output_param][5]
          end
        end

      elseif output_index == 4 then -- w/
        local control_bcrumbs_base = control_bcrumbs
        if output_mode == nil and output_param == nil then
          control_bcrumbs =  control_bcrumbs .. "dev w/"
          control_labels[1] = "wsyn1, wsyn2, wsyn3"
          control_labels[2] = "wdel-ks, wdel"
        elseif output_mode then
          if output_mode < 4 then
            control_bcrumbs = control_bcrumbs .. "wsyn" .. output_mode 
          elseif output_mode == 4 then
            control_bcrumbs = control_bcrumbs .. "wdel-ks"
          elseif output_mode == 5 then
            control_bcrumbs = control_bcrumbs .. "wdel"
          end
          local label_pos = 1
          control_labels[1] = ""
          if output_param == nil and output_mode < 6 then
            for i=1,#specs_map[output_type][output_index][output_mode],1 do
              control_labels[label_pos] = control_labels[label_pos] .. specs_map[output_type][output_index][output_mode][i][5] .. " "
              label_pos = i%3 == 0 and label_pos + 1 or label_pos
            end
          elseif output_param and output_mode < 7 then
            control_bcrumbs = control_bcrumbs .. " " .. specs_map[output_type][output_index][output_mode][output_param][5]
            
          elseif output_mode == 4 then 
            control_bcrumbs = control_bcrumbs_base .. "wdel-ks"
          elseif output_mode == 5 then 
            control_bcrumbs = control_bcrumbs_base .. "wdel"
          end
        end
      end
    end
  elseif output_type == 3 then -- effects
    control_bcrumbs =  control_bcrumbs .. "eff "
    if output_index then 
      if output_index == 1 then -- amp
        control_bcrumbs =  control_bcrumbs .. "amp "
      elseif output_index == 2 then -- drywet
        control_bcrumbs =  control_bcrumbs .. "drywet "
      else 
        if output_index == 3 then -- delay
          control_bcrumbs =  control_bcrumbs .. "delay "
        elseif output_index == 4 then -- bitcrush
          control_bcrumbs =  control_bcrumbs .. "bitcrush "
        elseif output_index == 5 then -- enveloper
          control_bcrumbs =  control_bcrumbs .. "env "
        elseif output_index == 6 then -- pitchshift
          control_bcrumbs =  control_bcrumbs .. "p_shift "
        end
        local label_pos = 1
        for i=1,#specs_map[output_type][output_index],1 do
          control_labels[label_pos] = control_labels[label_pos] .. specs_map[output_type][output_index][i][5] .. " "
          label_pos = i%3 == 0 and label_pos + 1 or label_pos
        end
        if output_mode then
          control_bcrumbs = control_bcrumbs .. specs_map[output_type][output_index][output_mode][5] .. " "
        end
      end
    end
  elseif output_type == 4 then -- lattice and patterns  
    local orig_bcrumbs = fn.deep_copy(control_bcrumbs)
    -- control_bcrumbs =  control_bcrumbs .. "lat and pats"
    if output_index then
      if output_index == 1 then
        control_bcrumbs = orig_bcrumbs .. " seq " 
      elseif output_index == 2 then
        control_bcrumbs = orig_bcrumbs .. " subseq " 
      elseif output_index == 3 then
        control_bcrumbs = orig_bcrumbs .. " clp " 
      end
      local label_pos = 1
      if output_type and output_index then
        -- print("output_param",output_param)
        for i=1,#specs_map[output_type][output_index],1 do
          if specs_map[output_type][output_index][i][5] and output_mode ~= 2 then
            control_labels[label_pos] = control_labels[label_pos] .. specs_map[output_type][output_index][i][5] .. " "
            label_pos = i%3 == 0 and label_pos + 1 or label_pos
          elseif output_mode == nil then
            control_labels[label_pos] = control_labels[label_pos] .. "c_morph " 
            label_pos = i%3 == 0 and label_pos + 1 or label_pos
          elseif output_mode == 2 and output_param == nil then
            control_labels[1] = "tempo dur"
            control_labels[2] = "steps shape"
            control_labels[3] = ""
          end
        end
      
        if output_mode then
          if specs_map[output_type][output_index][output_mode][5] then
            control_bcrumbs = control_bcrumbs .. specs_map[output_type][output_index][output_mode][5] .. " "
          elseif output_mode == 2 and output_param ~= nil then
            control_bcrumbs = control_bcrumbs .. specs_map[output_type][output_index][output_mode][output_param][5] .. " "
          end
        end
      end
    end
  end

  -- set more control labels
  -- if active_ui_group_name == "sequin groups" then
  --   control_labels = {"group 1-5"}
  -- elseif active_ui_group_name == "sequin selector" then
  --   control_labels = {"sequin 1-" .. params:get("num_sequin")}
  -- elseif active_ui_group_name == "sequin output types" then
  --   control_labels = {"seq", "subseq", "lat/pat"}
  -- elseif active_ui_group_name == "sequin outputs" then
  -- print("active_ui_group_name",active_ui_group_name)
  if active_ui_group_name == "sequin outputs" then
    if output_type == 1 then
      -- control_bcrumbs =  control_bcrumbs .. "softcut"
      control_labels[1] = "softcut:"
      control_labels[2] = "voices 1-6"
    elseif output_type == 2 then
      control_labels[1] = "devices:"
      control_labels[2] = "midi_note crow jf w/"
      -- control_bcrumbs =  control_bcrumbs .. "dev"
    elseif output_type == 3 then
      control_labels[1] = "effects:"
      control_labels[2] = "amp drywet delay"
      control_labels[3] = "bitcrshr env pshift"
      -- control_bcrumbs =  control_bcrumbs .. "eff"
    elseif output_type == 4 then
      control_labels[1] = "time:"
      control_labels[2] = "sequins sub-sequins"
      control_labels[3] = "clock/lat/pat (clp)"
    end
  elseif active_ui_group_name == "sequin output modes" then
    if output_type == 2 then -- devices
    elseif output_type == 3 then
      -- if output_index ~=5 then

    end
  elseif active_ui_group_name == "sequin output params" then
    if output_type == 1 then --softcut params (cutter mode direction level)
    elseif output_type == 2 then
    end
  elseif active_ui_group_name == "value place integers" then
    control_labels = {}
  elseif active_ui_group_name == "value place decimals" then
    control_labels = {}
  elseif active_ui_group_name == "value selector polarity" then
    control_labels = {}
  elseif active_ui_group_name == "value selector nums" then
    control_labels = {}
  elseif active_ui_group_name == "value selector options" then
    control_labels = {}
  elseif active_ui_group_name == "sequin output values" then
    control_labels = {}
  end
  
  local sequin_values = {}
  sequin_values = sequencer_screen.get_selected_sequin_values() 
  local output_value = nil
  output_value = sequencer_controller.active_output_value_text
  return control_labels, control_bcrumbs, sequence_values, sequin_values, output_value
end

function sequencer_screen.get_sequence_values()
  local vals = sequencer_controller.get_output_values()
  return vals
end

function sequencer_screen.get_selected_sequin_values()
  local vals
  if sequencer_controller.selected_sequin_group and sequencer_controller.selected_sequin then
    sequencer_controller.refresh_selected_sequin_values(sequencer_controller.selected_sequin_group,sequencer_controller.selected_sequin)
    vals = sequencer_controller.selected_sequin_values
  end
  return vals
end
-- local ui_group_acnyms =   { "sgp","sqn","typ","out","mod",
--                             "par","opt","sqm","pol",
--                             "int","dec","num",
--                             -- "num","opt","val"
--                           }

function sequencer_screen.check_for_active_chicklet(acronym)
  local active_ui_group_name = sequencer_controller:get_active_ui_group()
  active_ui_group_name = ((string.sub(active_ui_group_name,1,13) == "sequin groups") and "sequin groups" or active_ui_group_name)

  local active_chicklet = false
  if active_ui_group_name == "sequin groups" and acronym == "sgp" then
    active_chicklet = true
  elseif active_ui_group_name == "sequin selector" and acronym == "sqn" then
    active_chicklet = true
  elseif active_ui_group_name == "sequin output types" and acronym == "typ" then
    active_chicklet = true
  elseif active_ui_group_name == "sequin outputs" and acronym == "out" then
    active_chicklet = true
  elseif active_ui_group_name == "sequin output modes" and acronym == "mod" then
    active_chicklet = true
  elseif active_ui_group_name == "sequin output params" and acronym == "par" then
    active_chicklet = true
  elseif active_ui_group_name == "value place integers" and acronym == "int" then
    active_chicklet = true
  elseif active_ui_group_name == "value place decimals" and acronym == "dec" then
    active_chicklet = true
  elseif active_ui_group_name == "sequence_mode" and acronym == "sqm" then
    active_chicklet = true
  elseif active_ui_group_name == "value selector polarity" and acronym == "pol" then
    active_chicklet = true
  elseif active_ui_group_name == "value selector nums" and acronym == "num" then
    active_chicklet = true
  elseif active_ui_group_name == "value selector options" and acronym == "opt" then
    active_chicklet = true
  -- elseif active_ui_group_name == "sequin output values" and acronym == "val" then
  --   active_chicklet = true
  end
  return active_chicklet 
end



function sequencer_screen.draw_chicklets(selected_control_indices, output_value)
  local selected_value_type = sequencer_controller.get_active_sequin_value_type()
  -- local ui_group_acnyms
  if selected_value_type == "number" then
    ui_group_acnyms =   { "sgp","sqn","typ","out","mod",
                          "par","sqm","pol",
                          "int","dec","num",
    }
  elseif selected_value_type == "notes" then
    ui_group_acnyms =   { "sgp","sqn","typ","out","mod",
                          "par","sqm",
                          "oct","ntn",
    }
  elseif selected_value_type == "option" then
    ui_group_acnyms =   { "sgp","sqn","typ","out","mod",
                          "par","sqm","opt",
    }
  else 
    ui_group_acnyms =   { "sgp","sqn","typ","out","mod",
                          "par","sqm",
    }  
  end 
    
  local chicklet_direction = "lr"
  local c_loc = {5,15}
  local chicklet_dim = {20,10}
  acnym_map = sequencer_controller.get_acnym_map()
  for i=2,#ui_group_acnyms+1,1 do
    -- if chicklet_direction == "lr" then
    -- chicklet_dim[1] = screen.text_extents(ui_group_acnyms[i])
    local screen_level = chicklet_direction == "lr" and 5 or 3
    local active_chicklet = sequencer_screen.check_for_active_chicklet(ui_group_acnyms[i])
    screen_level = active_chicklet == true and 15 or screen_level
    screen.level(screen_level)
    if i <= #ui_group_acnyms then
      screen.move(c_loc[1],c_loc[2])
      screen.rect(c_loc[1],c_loc[2]+3,chicklet_dim[1]+3,chicklet_dim[2]-3)
      screen.fill()
      screen.stroke()
      screen.level(0)
      screen.move(c_loc[1],c_loc[2]+8)
      screen.text(ui_group_acnyms[i])
    elseif c_loc[2]>40 then
      screen_level = 12
      screen.move(c_loc[1]-chicklet_dim[1]-5,c_loc[2])
      
      screen.rect(c_loc[1]-chicklet_dim[1]-5,c_loc[2]+3,(chicklet_dim[1]*2)+8,chicklet_dim[2]-3)
      screen.fill()
      screen.stroke()
      screen.level(15)
      screen.move(c_loc[1]-chicklet_dim[1]-5,c_loc[2]+8)
      if type(output_value) ~= "table" then
        screen.text(output_value and output_value  or "")
      end
    end
    screen.move(c_loc[1]+22,c_loc[2]+8)
    local selected_index = acnym_map[ui_group_acnyms[i]]
    selected_index = selected_index and selected_index or ""
    if ui_group_acnyms[i] ~= "mod" or (ui_group_acnyms[i] == "mod" and sequencer_controller.sequin_output_modes) then
      screen.text_right(selected_index)
    end
    screen.move(c_loc[1],c_loc[2])
    local chick_space = 5
    if chicklet_direction == "lr" and ui_group_acnyms[i+1] then
      if c_loc[1] < 100 then
        c_loc[1] = c_loc[1]+chicklet_dim[1]+chick_space
      else
        c_loc[2] = c_loc[2] + 11
        chicklet_direction = "td"
      end
    elseif chicklet_direction == "td" then
      if c_loc[2] < 45 then
        c_loc[2] = c_loc[2] + 11
      else
        c_loc[1] = c_loc[1]-chicklet_dim[1]-chick_space
        chicklet_direction = "rl"
      end
    elseif chicklet_direction == "rl" then
      c_loc[1] = c_loc[1]-chicklet_dim[1]-chick_space
    end
  end
end

function sequencer_screen.get_control_bcrumbs()
  return sequencer_screen.control_bcrumbs  
end

function sequencer_screen.set_control_bcrumbs(control_bcrumbs)
  sequencer_screen.control_bcrumbs = control_bcrumbs
end

function sequencer_screen.update()
  if grid_mode == "sequencer" then
    local active_control = sequencer_controller:get_active_ui_group()
    active_control = ((string.sub(active_control,1,13) == "sequin groups") and "sequin groups" or active_control)


    selected_control_indices = sequencer_controller.get_selected_indices()
    control_labels, control_bcrumbs, sequence_values, sequin_values, output_value = sequencer_screen.update_screen_instructions(selected_control_indices)


    sequencer_screen.draw_chicklets(selected_control_indices,output_value)
    screen.level(10)
    screen.move(22-17,27)
    screen.line_rel(86+12,0)
    screen.line_rel(0,21)
    screen.line_rel(-86-12,0)
    screen.stroke()

    sequencer_screen.set_control_bcrumbs(control_bcrumbs)
    local show_sequence_values =  active_control ==   "sequin output values"  or 
                                  active_control ==   "value selector nums"   or
                                  active_control ==   "value place integers"  or
                                  active_control ==   "value place digits"
    if show_sequence_values and sequence_values then
      -------------------------
      --  active sequence values for all sequin(s)
      -------------------------
      -- screen.move(5,32)
      -- screen.text(sequence_values)
      local lx,ly = 5,32
      local screen_text = ""
      -- local output_labels = {"(1/3) ","(4/6) ","(7/9) "}
      -- local line_num = 1
      for i=1,#sequence_values do
        screen.move(lx,ly)
        local val = sequence_values[i][1]
        if string.find(val,"%.0") then
          local empty_decimal = string.find(val,"%.0") - 1
          local r = string.find(val,"r")
          val = string.sub(val,1,empty_decimal)
          val = r and val .. "r" or val
        end
        local calculated_absolute_val = sequence_values[i][2]
        if calculated_absolute_val ~= "nil" then 
          -- screen_text = screen_text .. val.."/".. calculated_absolute_val .. "  " 
          if string.find(calculated_absolute_val,"%.0") then
            local empty_decimal = string.find(calculated_absolute_val,"%.0") - 1
            calculated_absolute_val = string.sub(calculated_absolute_val,1,empty_decimal)
            calculated_absolute_val = fn.round_decimals(calculated_absolute_val, 2, "up")  
          end
          -- screen_text = val .."/".. calculated_absolute_val .. "  " 
          screen_text = calculated_absolute_val .. "  " 
        else
          if val == "nil" then 
            -- screen_text = screen_text .. "x" .. "  "
            screen_text = "x" .. "  "
          else -- show option text
            -- screen_text = screen_text .. val .. "  "
            -- check if the value needs to be shown as an option value vs a num
            local options = sequencer_controller.get_options_text()
            val = options == nil and val or options[val]
            val = val and val or "x"
            screen_text = val .. "  "
          end
        end
        local screen_level = i == sequencer_controller.selected_sequin and 15 or 5
        screen.level(screen_level)
        screen.text(screen_text)
        screen.level(10)
        lx = lx + screen.text_extents(screen_text) + 5
        screen_text = ""
        -- screen.text(val)
        if i%3 == 0 then
          lx = 5
          ly = ly+7
        end
      end

      -------------------------
      --  all sequence values for the selected sequin
      -------------------------
      local lx,ly = 50,32
      local screen_text = ""
      local selected_sequin_index = sequencer_controller.selected_sequin_ix
      -- local output_labels = {"(1/3) ","(4/6) ","(7/9) "}
      -- local line_num = 1
      for i=1,5,1 do
        screen.move(lx,ly)
        local val = (sequin_values and #sequin_values > 0) and sequin_values[i] or val
        val = (val ~= "" and val ~= "nil") and val or "-"
        screen_text = screen_text .. val .. "  "
        local screen_level = selected_sequin_index == i and 15 or 5
        screen.level(screen_level)
        screen.text(screen_text)
        -- print("screen_text",screen_text)
        screen.level(screen_level)
        lx = lx + screen.text_extents(screen_text) + 5
        screen_text = ""
        -- screen.text(val)
        if i%2 == 0 then
          lx = 50
          ly = ly+7
        end
      end
    elseif active_control == "value selector options" then
    -- elseif active_control == "value selector options" then
      control_labels = {}
      local options = sequencer_controller.get_options_text()
      if options then
        local label_pos = 1
        for i=1,#options,1 do
          control_labels[i] = control_labels[i] and control_labels[1] or ""
          control_labels[label_pos] = control_labels[label_pos] .. options[i] .. "  "
          label_pos = i%3 == 0 and label_pos + 1 or label_pos
        end   
        local lx,ly = 5,32
        for i=1,#control_labels do
          screen.move(lx,ly)  
          screen.text(control_labels[i])
          ly = ly+7
        end
      end  
    elseif active_control == "value place integers" or active_control == "value place decimals" then
       screen.move(5,32)
       screen.text(active_control)
    elseif active_control == "value selector nums" then
      local active_place = sequencer_controller.active_value_selector_place
      screen.move(5,47)
      screen.text("set value at: " .. active_place)
    else
      local lx,ly = 5,32
      for i=1,#control_labels do
        screen.move(lx,ly)
        screen.text(control_labels[i])
        ly = ly+7
      end
    end
    screen.move(5,10)
    screen.level(3)
    screen.rect(5,10,127,7)
    screen.fill()
    screen.stroke()
    
    screen.level(8)
    screen.move(5,15)
    screen.text(active_control)


      --[[
    screen.level(15)
    screen.move(1,25)
    screen.text(sequencer_screen.active_ui_group)
    screen.move(1,35)
    screen.text(sequencer_screen.active_ui_group_instructions1)
    screen.move(1,45)
    screen.text(sequencer_screen.active_ui_group_instructions2)
    screen.move(1,55)
    screen.text(sequencer_screen.active_ui_group_instructions3)
    ]]

    --[[
    if #sequencer_screen.squares>0 then
      for i=1,#sequencer_screen.squares,1 do
        sequencer_screen.squares[i]:draw()
      end
    end
    ]]
  end
end

return sequencer_screen
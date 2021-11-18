
sequencer_screen = {}

sequencer_screen.active_control = ""

function sequencer_screen.init()

end

function sequencer_screen.update_screen_instructions(selected_control_indices)
  local active_ui_group_name = sequencer_controller:get_active_ui_group_name()
  active_ui_group_name = (string.sub(active_ui_group_name,1,13) == "sequin groups") and "sequin groups" or active_ui_group_name
  specs_map = sequencer_controller.get_output_control_specs_map()
  local selected_sequin = selected_control_indices.selected_sequin
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
  if selected_sequin and output_type == nil then
    control_labels[1] = "softcut devices effects"
    control_labels[2] = "time"
  elseif output_type == 1 then -- softcut titles and labels
    control_bcrumbs =  control_bcrumbs .. "sc voice "
    if output_index then
      control_bcrumbs = control_bcrumbs .. output_index .. " "
      local label_pos = 1
      for i=1,#specs_map[1][1],1 do
        control_labels[label_pos] = control_labels[label_pos] .. specs_map[1][1][i][5] .. " "
        label_pos = i%3 == 0 and label_pos + 1 or label_pos
      end  
      if output_mode then
        control_bcrumbs = control_bcrumbs .. specs_map[output_type][output_index][output_mode][5]
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
    local orig_bcrumbs = fn.deep_copy(control_bcrumbs) .. "time "
    control_bcrumbs =  orig_bcrumbs

    -- control_bcrumbs =  control_bcrumbs .. "lat and pats"
    if output_index then
      if output_index == 1 then
        control_bcrumbs = orig_bcrumbs .. "seq " 
      elseif output_index == 2 then
        control_bcrumbs = orig_bcrumbs .. "subseq " 
      elseif output_index == 3 then
        control_bcrumbs = orig_bcrumbs .. "clp " 
      end
      local label_pos = 1
      if output_type and output_index then
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

function sequencer_screen.get_control_bcrumbs()
  return sequencer_screen.control_bcrumbs  
end

function sequencer_screen.set_control_bcrumbs(control_bcrumbs)
  sequencer_screen.control_bcrumbs = control_bcrumbs
end

function sequencer_screen.update()
  if grid_mode == "sequencer" then
    sequencer_screen.active_control = sequencer_controller:get_active_ui_group_name()
    sequencer_screen.active_control = ((string.sub(sequencer_screen.active_control,1,13) == "sequin groups") and "sequin groups" or sequencer_screen.active_control)


    selected_control_indices = sequencer_controller.get_selected_indices()
    control_labels, control_bcrumbs, sequence_values, sequin_values, output_value = sequencer_screen.update_screen_instructions(selected_control_indices)

    screen.level(8)
    screen.move(5,18)
    screen.line_rel(122,0)
    screen.line_rel(0,32)
    screen.move_rel(-1,-32)
    screen.line_rel(0,32)
    screen.line_rel(-121,0)
    screen.stroke()
    screen.move(5,42)
    screen.rect(5,42,122,8)
    screen.fill()
    screen.stroke()

    sequencer_screen.set_control_bcrumbs(control_bcrumbs)
    local show_sequence_values =  sequencer_screen.active_control ==   "sequin output values"  or 
                                  sequencer_screen.active_control ==   "value selector nums"   or
                                  sequencer_screen.active_control ==   "value place integers"  or
                                  sequencer_screen.active_control ==   "value place digits"
    if show_sequence_values and sequence_values then
      -------------------------
      --  active sequence values for all sequin(s)
      -------------------------
      -- screen.move(5,26)
      -- screen.text(sequence_values)

      local lx,ly = 5,26
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
        screen.level(10)
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
      local lx,ly = 70,26
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
          lx = 70
          ly = ly+7
        end
      end
      screen.level(2)
      screen.move(5,48)
      screen.text("sequins")
      screen.move(70,48)
      screen.text("sub-sequins")

    elseif sequencer_screen.active_control == "value selector options" then
    -- elseif sequencer_screen.active_control == "value selector options" then
      control_labels = {}
      local options = sequencer_controller.get_options_text()
      if options then
        local label_pos = 1
        for i=1,#options,1 do
          control_labels[i] = control_labels[i] and control_labels[1] or ""
          control_labels[label_pos] = control_labels[label_pos] .. options[i] .. "  "
          label_pos = i%3 == 0 and label_pos + 1 or label_pos
        end   
        local lx,ly = 5,26
        for i=1,#control_labels do
          screen.move(lx,ly)  
          screen.text(control_labels[i])
          ly = ly+7
        end
      end  
    else
      local lx,ly = 5,26
      for i=1,#control_labels do
        screen.move(lx,ly)
        screen.text(control_labels[i])
        ly = ly+7
      end
    end

    screen.move(5,10)
    screen.level(3)
    screen.rect(5,10,122,7)
    screen.fill()
    screen.stroke()
    
    screen.level(8)
    screen.move(5,15)

    local select_num =  sequencer_screen.active_control ==   "value selector nums"   or
                        sequencer_screen.active_control ==   "value place integers"  or
                        sequencer_screen.active_control ==   "value place digits"

    local text = select_num == true and "select number" or sequencer_screen.active_control 
    screen.text(text)
    
    
    local output_value_label = "selected value "
    local output_value_label_width = screen.text_extents(output_value_label)
    screen.level(5)
    -- screen.rect(5,53,output_value_label_width,16)
    screen.rect(5,53,122,16)
    screen.fill()
    screen.stroke()
    screen.level(8)
    -- screen.rect(5+output_value_label_width,53,4,8)
    -- screen.fill()
    -- screen.stroke()

    screen.level(12)
    screen.rect(9+output_value_label_width,53,126-10-output_value_label_width,8)
    screen.fill()
    screen.stroke()
    if sequencer_screen.active_control == "sequin output values" and output_value then
      -- print(control_labels, control_bcrumbs, sequence_values, sequin_values, output_value)
      screen.level(0)
      screen.move(5,60)
      screen.text(output_value_label ..output_value)
    end


  end
end

return sequencer_screen
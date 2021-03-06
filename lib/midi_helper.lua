-- midi helper global variables and functions 

function clock.transport.stop()
  if sc.selected_sequin_group and initializing == false then
    grid_sequencer.activate_grid_key_at(sc.selected_sequin_group,1)
  end
end

function clock.transport.start()
  if sc.selected_sequin_group == nil and initializing == false then
    local sequin_group = sc.last_active_sequin_group and sc.last_active_sequin_group or 1
    grid_sequencer.activate_grid_key_at(sequin_group,1)
  end
end


function get_midi_devices()
  local devices = {}
  for i=1,#midi.vports,1
  do
    table.insert(devices, i .. ". " .. midi.vports[i].name)
  end
  midi_devices = devices
  local midi_in = params:lookup_param("midi_in_device")
  midi_in.options = midi_devices
  local midi_out = params:lookup_param("midi_out_device")
  midi_out.options = midi_devices
  
  -- tab.print(midi_devices)
end

midi_out_device = midi.connect(1)


-- set_midi_channels = function()
  --print("set midi channels")
--   if pages.index < 4 then
--     if active_plant == 1 then
--       if device_16n then set_16n_channel_and_cc_values(plant1_cc_channel) end
--     else
--       if device_16n then set_16n_channel_and_cc_values(plant2_cc_channel) end
--     end
--   elseif pages.index == 4 then
--     if active_plant == 1 then
--       if device_16n then set_16n_channel_and_cc_values(env1_cc_channel) end
--     else
--       if device_16n then set_16n_channel_and_cc_values(env2_cc_channel) end
--     end
--   elseif pages.index == 5 then
--     if device_16n then set_16n_channel_and_cc_values(water_cc_channel) end
--   end
-- end

-------------------------------
-- code for the 16n faderbank
--
-- sysex handling code from from: https://llllllll.co/t/how-do-i-send-midi-sysex-messages-on-norns/34359/15
--
-- to get the current 16n configs, call: send_16n_sysex(midi,get_16n_data_table)
--
-- important hex values (with decimal equivalent:
-- `0xF0` - "start byte" (240) - midi_event_index table 1[1]
-- `0x7d` - "manufacturer is 16n" (125) - midi_event_index table 1[2]
-- `0x0F` - "c0nFig" (15) - midi_event_index table 2[2]
-- `0xf7` - "stop byte" (247) -- midi_event_index table 30[1] QUESTION: why is this sent in the middle of the message, before current slider cc values are sent
-- current usb midi channel values: midi_event_index  table 7[2] - 12[2]
-- current trs midi channel values: midi_event_index  table 12[3] - 17[3]
-- current usb cc values: midi_event_index table 20[1] - 27[3]
-- current usb channel/cc/value  midi_event_index table 29[1] - 43[3] QUESTION: why don't all 16 channels show up?

--------------------------------
  
local sysexDataFrame = {}
local message_from_16n = false
local receiving_configs_from_16n = false
local cc_vals_16n = {}
local channel_vals_16n = {}
-- local device_16n

-- note: this function isn't currently required
local process_16n_data = function(data)
  --print("process 16n data")
  local msg_data = midi.to_msg(data)
  
  midi_event_index = midi_event_index + 1
  if midi_event_index == 46 then         -- this is the end of the syssex message from 16n
    cc_vals_16n = {}
    channel_vals_16n = {}
    local store_cc_vals_16n = false
    local store_channel_vals_16n = false
    for i=1,#sysexDataFrame,1
    do
      local val = sysexDataFrame[i]
      if val.type == "other" then 
        for j=1, #val.raw, 1
        do
          -- start collecting cc values
          if i==7 and j==2 then store_cc_vals_16n = true end 
          if store_cc_vals_16n == true then table.insert(cc_vals_16n, val.raw[j]) end
          if i==12 and j==2 then store_cc_vals_16n = false end
          -- start collecting channel values 
          if i==12 and j==3 then store_channel_vals_16n = true end
          if store_channel_vals_16n == true then table.insert(channel_vals_16n, val.raw[j]) end
          if i==17 and j==3 then store_channel_vals_16n = false end
        end
      end
    end -- sysex processing ended, reset midi_event_index
    midi_event_index = 1
    receiving_configs_from_16n = false 
  else   -- assuming this is a data byte
    table.insert(sysexDataFrame, msg_data)
  end
end

set_16n_channel_and_cc_values = function (channel)
  channel_vals_16n = {}
  cc_vals_16n = {}
  for i=1,16,1
  do
    table.insert(channel_vals_16n, channel)
    table.insert(cc_vals_16n, (midi_cc_starting_value-1)+i) 
  end
  update16n()
end

update16n = function()
  local data_table = {0x7d,0x00,0x00,0x0c}
  local m = midi
  for i=1,16,1
  do
    local hex_val = i<15 and "0x"..string.format("%x",channel_vals_16n[i]) or "0x01"
    table.insert(data_table,hex_val)
  end

  for i=1,16,1
  do
    local hex_val = "0x"..string.format("%x",cc_vals_16n[i])
    table.insert(data_table,hex_val)
  end
  send_16n_sysex(midi, data_table)
end

function send_16n_sysex(m,d) 
  m.send(device_16n,{0xf0})
  for i,v in ipairs(d) do
    m.send(device_16n,{d[i]})
  end
  m.send(device_16n,{0xf7})
end


local get_16n_data_table = {0x7d,0x00,0x00,0x1F}
-- set_16n_data_usb_only = {
--   0x7D, 0x00, 0x00, 
--   0x0c, 
--   0x04, 0x02, 0x03, 
--   0x04, 0x05, 0x06, 
--   0x07, 0x08, 0x09, 
--   0x0A, 0x0B, 0x0C, 
--   0x0D, 0x0E, 0x0F, 
--   0x10, 0x20, 
--   0x22, 0x21, 0x23, 
--   0x24, 0x25, 0x26, 
--   0x27, 0x28, 0x29, 
--   0x2A, 0x2B, 0x2C, 
--   0x2D, 0x2E, 0x2F, 
--   0x20, 0x21, 0x22, 
--   0x23, 0x24, 0x25, 
--   0x26, 0x27, 0x28, 
--   0x29, 0x2A, 0x2B, 
--   0x2C, 0x2D, 0x2E, 
--   0x2F}

-------------------------------
-- midi handler functions
-------------------------------


local midi_event_index = 0
midi_event = function(data) 
  -- tab.print(data)
  if message_from_16n and receiving_configs_from_16n then
    -- do something with 16n_data(data)
  else
    if data[1] == 240 and data[2] == 125 then        --- this is the start byte with a a message from the 16n faderbank 
      midi_event_index = 2
      --print("received start byte from the 16n faderbank")
      message_from_16n = true
    elseif message_from_16n == true and data[2] == 15 and data[3] == 2 then        --- this is the start of a message with the 16n configs
      --print("receiving of 16n configs. set receiving_configs_from_16n = true")
      receiving_configs_from_16n = true
    else
      -- handle other message types
      -- local output_bandsaw = params:get("output_bandsaw")
      local output_midi = params:get("output_midi")


      local note_to_play = data[2]
      if note_to_play then
        -- set a random scalar for the note about to play
        -- local num_active_cf_scalars = params:get("num_active_cf_scalars")
        -- local random_cf_scalars_index = params:get(cf_scalars[math.random(num_active_cf_scalars)])
        -- local cf_scalar = cf_scalars_map[random_cf_scalars_index]

        -- set a random note_frequency for the note about to play
        -- local num_note_freq_index = math.random(#tempo_offset_note_frequencies)
        -- local random_note_frequency = tempo_offset_note_frequencies[num_note_freq_index]
        local random_note_frequency = 1
        -- local freq = MusicUtil.note_num_to_freq(note_to_play) * cf_scalar
        local freq = MusicUtil.note_num_to_freq(note_to_play) 
        note_to_play = MusicUtil.freq_to_note_num(freq)
        
        if data[1] == midi_in_command1 then -- plant 1 engine note on
          --print("note to play",note_to_play,midi_in_command1)
          envelopes[1].update_envelope()
          -- if output_bandsaw == 3 or output_bandsaw == 4 or output_midi == 3 or output_midi == 4 then
          --   plants[1].sounds.engine_note_on(note_to_play, freq, random_note_frequency)
          -- end
          -- clock.run(plants[1].sounds.externals1.note_on,1, note_to_play, freq, random_note_frequency, nil,"midi")
          -- clock.run(externals1.note_on,1, note_to_play, freq, random_note_frequency, nil,"midi")
          -- externals1.note_on(1, note_to_play, freq, random_note_frequency, nil,"midi")
          clock.run(externals1.note_on,1, note_to_play, freq, random_note_frequency, nil,"midi")
        end
        if data[1] == midi_in_command2 then -- plant 2 engine note on
          envelopes[2].update_envelope()
          -- if output_bandsaw == 3 or output_bandsaw == 4 or output_midi == 3 or output_midi == 4 then
          --   plants[2].sounds.engine_note_on(note_to_play, freq, random_note_frequency)
          -- end
          clock.run(externals2.note_on,2, note_to_play, freq, random_note_frequency, nil,"midi")
        elseif data[1] == 128 then -- note off
          -- todo: figure out how to implement note off

        end
      end
    end
  end
end


midi.add = function(device)
  params.get_midi_devices()

  --print("midi device add ", device.id, device.name)
  if device.name == "16n" then 
      device_16n = device 
      -- send_16n_sysex(midi,get_16n_data_table)
  end
  device.event = midi_event
end

  -- -- MIDI input
  -- local function midi_event(data)
    
  --   local msg = midi.to_msg(data)
  --   local channel_param = params:get("midi_channel")
    
  --   if channel_param == 1 or (channel_param > 1 and msg.ch == channel_param - 1) then
      
  --     -- Note off
  --     if msg.type == "note_off" then
  --       note_off(msg.note)
      
  --     -- Note on
  --     elseif msg.type == "note_on" then
  --       note_on(msg.note, msg.vel / 127)
        
  --     -- Key pressure
  --     elseif msg.type == "key_pressure" then
  --       set_pressure(msg.note, msg.val / 127)
        
  --     -- Channel pressure
  --     elseif msg.type == "channel_pressure" then
  --       set_pressure_all(msg.val / 127)
        
  --     -- Pitch bend
  --     elseif msg.type == "pitchbend" then
  --       local bend_st = (util.round(msg.val / 2)) / 8192 * 2 -1 -- Convert to -1 to 1
  --       local bend_range = params:get("bend_range")
  --       set_pitch_bend_all(bend_st * bend_range)
        
  --     -- CC
  --     elseif msg.type == "cc" then
  --       -- Mod wheel
  --       if msg.cc == 1 then
  --         set_timbre_all(msg.val / 127)
  --       end
        
  --     end
    
  --   end
    
  -- end


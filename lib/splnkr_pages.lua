-- code to update/draw the pages (screens)

-- WAVEFORMS
local interval = 0
waveform_samples = {}
length = 1
scale = 30
level = 1
position = 0

softcut.level(1,level)

function update_positions(i,pos)
  position = (pos - 1) / length
  if selecting == false then redraw() end
end

function redraw_waveform()
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
    screen.level(4)
    local x_pos = 0
    for i,s in ipairs(waveform_samples) do
      local height = util.round(math.abs(s) * (scale*level))
      screen.move(util.linlin(0,128,10,120,x_pos), 35 - height)
      screen.line_rel(0, 2 * height)
      screen.stroke()
      x_pos = x_pos + 1
    end
    screen.level(15)
    screen.move(util.linlin(0,1,10,120,position),18)
    screen.line_rel(0, 35)
    screen.stroke()
  end
  
  screen.update()
end

function on_render(ch, start, i, s)
  -- print(#s)
  waveform_samples = s
  interval = i
  redraw_waveform()
end

function update_content(buffer,winstart,winend,samples)
  softcut.render_buffer(buffer, winstart, winend - winstart, 128)
end
--/ WAVEFORMS


local draw_top_nav = function()
  screen.level(15)
  screen.stroke()
  screen.rect(0,0,screen_size.x,10)
  screen.fill()
  screen.level(0)
  screen.move(4,7)

  if pages.index == 1 then
      screen.text("page 1: rate/length" )
  elseif pages.index == 2 then
    screen.text("page 2: waveform")
  elseif pages.index == 3 then
    screen.text("page 3: effects")
  -- elseif pages.index == 4 then
  --   screen.text("page 4")
  -- elseif pages.index == 5 then
  --   screen.text("page 5")
  end
  -- navigation marks
  -- screen.level(0)
  screen.rect(0,(pages.index-1)/5*10,2,2)
  screen.fill()
  -- screen.update()
end

local update_pages = function()
  if initializing == false then
    if pages.index == 1 then
      screen.move(10,30)
      screen.level(p1_index == 1 and 15 or 5)
      screen.text("rate: ")
      screen.move(118,30)
      screen.text_right(string.format("%.2f",rate))
      screen.move(10,40)
      screen.level(p1_index == 2 and 15 or 5)
      screen.text("loop start: ")
      screen.move(118,40)
      screen.text_right(string.format("%.3f",loop_start))
      screen.move(10,50)
      screen.level(p1_index == 3 and 15 or 5)
      screen.text("loop end: ")
      screen.move(118,50)
      screen.text_right(string.format("%.3f",loop_end))
      -- screen.text("low (voice 1): ")
      -- screen.move(118,40)
      -- screen.text_right(string.format("%.2f",low))
      -- screen.move(10,50)
      -- screen.text("band (voice 2): ")
      -- screen.move(118,50)
      -- screen.text_right(string.format("%.2f",band))
    
    elseif pages.index == 2 then
      update_content(1,1,length,128)
      redraw_waveform()

    elseif pages.index == 3 then
      screen.move(10,20)
      screen.level(p3_index == 1 and 15 or 5)
      screen.text("vinyl: ")
      screen.move(118,20)
      screen.text_right(string.format("%.3f",vinyl))
      screen.move(10,30)
      screen.level(p3_index == 2 and 15 or 5)
      screen.text("phaser: ")
      screen.move(118,30)
      screen.text_right(string.format("%.3f",phaser))
      screen.move(10,40)
      screen.level(p3_index == 3 and 15 or 5)
      screen.text("delay: ")
      screen.move(118,40)
      screen.text_right(string.format("%.3f",delay))
      screen.move(10,50)
      screen.level(p3_index == 4 and 15 or 5)
      screen.text("strobe: ")
      screen.move(118,50)
      screen.text_right(string.format("%.3f",strobe))
      screen.move(10,60)
      screen.level(p3_index == 5 and 15 or 5)
      screen.text("drywet: ")
      screen.move(118,60)
      screen.text_right(string.format("%.3f",drywet))

    elseif pages.index == 4 then

    elseif pages.index == 5 then

    end
  end

  local menu_status = norns.menu.status()
  if menu_status == false then
    draw_top_nav()
  end


  screen.update()

end




return {
  update_pages = update_pages
}

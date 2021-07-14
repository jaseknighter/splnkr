-- encoders and keys
p1_index = 1
p3_index = 1

local enc = function (n, d)
  -- set variables needed by each page/example
  if n == 1 and alt_pressed == false then
    -- scroll pages
    local page_increment = util.clamp(d, -1, 1)

    local next_page = pages.index + page_increment
    if (next_page <= num_pages and next_page > 0) then
      page_scroll(page_increment)
    end
  end

  if pages.index == 1 then
    if n==1 then
    elseif n==2 then
      p1_index = util.clamp(d+p1_index,1,3)
    elseif n==3 then
      local d_mul = alt_pressed == true and 0.001*d or 0.1*d   
      if p1_index==1 then
        -- print(rate+d/100)
        rate = util.clamp(rate+d/100,-4,4)
        -- print(rate+d/100,rate,d)
        softcut.rate(1,rate)
      elseif p1_index==2 then
        -- low = util.clamp(low+d*200,200,18000)
        loop_start = util.clamp(loop_start+d_mul,1,loop_end)
        softcut.loop_start(1,loop_start)
        softcut.loop_start(2,loop_start)
        -- softcut.position(i,1)
        -- softcut.play(i,1)
    
        -- softcut.post_filter_fc(1,low)
      elseif p1_index==3 then
        loop_end = util.clamp(loop_end+d_mul,loop_start,20)
        softcut.loop_end(1,loop_end)
        softcut.loop_end(2,loop_end)
      
        -- band = util.clamp(band+d*1000,200,18000)
        -- softcut.pre_filter_fc(2,band)
      end
  
    end
    
    loop_length = loop_end - loop_start
    
    
  
  elseif pages.index == 2 then

  elseif pages.index == 3 then
    if n==1 then
    elseif n==2 then
      p3_index = util.clamp(d+p3_index,1,5)
    elseif n==3 then
      local d_mul = alt_pressed == true and 0.001*d or 0.1*d   
      if p3_index==1 then
        vinyl = util.clamp(d_mul + vinyl,0,10)
        engine.vinyl(vinyl)
      elseif p3_index==2 then
        phaser = util.clamp(d_mul + phaser,0,10)
        engine.phaser(phaser)
      elseif p3_index==3 then
        delay = util.clamp(d_mul + delay,0,10)
        engine.delay(delay)
      elseif p3_index==4 then
        strobe = util.clamp(d_mul + strobe,0,5)
        engine.strobe(strobe)
      elseif p3_index==5 then
        drywet = util.clamp(d_mul + drywet,0,1)
        engine.drywet(drywet)

      end
  
    end
  elseif pages.index == 4 then

  elseif pages.index == 5 then

  end
end

local key = function (n,z)
  if (n == 1 and z == 0)  then 

    if (pages.index == 1) then

    elseif(pages.index == 2) then

    elseif(pages.index == 3) then

    elseif(pages.index == 4) then

    elseif(pages.index == 5) then
      
    end
  elseif (n == 2 and z == 0)  then 
    if pages.index == 1 then

    elseif pages.index == 2 then

    elseif pages.index == 3 then

    elseif(pages.index == 4) then

    elseif(pages.index == 5) then
            
    end
  elseif (n == 3 and z == 0)  then 
    if pages.index == 1 then

    elseif pages.index == 2 then

    elseif pages.index == 3 then

    elseif(pages.index == 4) then

    elseif(pages.index == 5) then
            
    end
  end
end

return{
  enc=enc,
  key=key
}

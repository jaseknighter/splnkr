local CutDetector = {}


function CutDetector:new()
  local cd = {}
  setmetatable(cd, CutDetector)


  cd.bright_checked = true
  cd.bright_tab = {}

  cd.bright_diff_tab = {}
  cd.bright_diff_sorted_tab = {}

  function cd.set_bright_start()
    cd.bright_checked = false
    cd.bright_tab = {}
    
  end

  function cd.set_bright(bright)
    if cd.bright_checked == false then
      table.insert(cd.bright_tab, bright)
    end
  end

  function cd.set_bright_completed()
    if cd.bright_checked == false then
      cd.bright_checked = true
      cd.find_cuts()
    end
  end


  function cd.get_sorted_cut_indices()
    local sorted_cut_indices = {}
    for i=#cd.bright_diff_tab,1,-1
    do
      local next_val = cd.bright_diff_sorted_tab[i][2][1]
      local prev_val = cd.bright_diff_sorted_tab[i-1] and cd.bright_diff_sorted_tab[i-1][2][1] or nil
      if prev_val == nil or math.abs(next_val - prev_val) > 15 then
        table.insert(sorted_cut_indices,next_val)
      end
    end
    
    return sorted_cut_indices
  end


  function cd.find_cuts()
    cd.bright_diff_tab = {}
    
    -- first try to find cuts where there are silent areas in the sample
    for i=2,#cd.bright_tab,1 do
      local b_diff = math.abs(cd.bright_tab[i] - cd.bright_tab[i-1])
      if (cd.bright_tab[i] < 10 or  cd.bright_tab[i-1] < 10) and b_diff > 100 then
        table.insert(cd.bright_diff_tab,{i,b_diff})
      end
    end

    -- there aren't any silent areas in the sample just make cuts based on relative differences in volume
    if #cd.bright_diff_tab > 0 then 
      cd.bright_diff_sorted_tab = {}
      for k, v in pairs(cd.bright_diff_tab) do
        table.insert(cd.bright_diff_sorted_tab,{k,v})
      end
    else
      for i=2,#cd.bright_tab,1 do
        local b_diff = math.abs(cd.bright_tab[i] - cd.bright_tab[i-1])
          table.insert(cd.bright_diff_tab,{i,b_diff})
      end
      cd.bright_diff_sorted_tab = {}
      for k, v in pairs(cd.bright_diff_tab) do
        table.insert(cd.bright_diff_sorted_tab,{k,v})
      end
      table.sort(cd.bright_diff_sorted_tab, function(a,b) 
        return a[2][2] < b[2][2]
      end)
      
      for i=1,10,1 do
      -- for i=1,#cd.bright_diff_sorted_tab,1 do
        -- if cd.bright_diff_sorted_tab[i+1] and cd.bright_diff_sorted_tab[i+1]-cd.bright_diff_sorted_tab[i] < 10 then
        -- end
        -- tab.print(cd.bright_diff_sorted_tab[i][2])
        -- print(">>>>>>>>")
      end

    end
  end

  return cd
end

return CutDetector
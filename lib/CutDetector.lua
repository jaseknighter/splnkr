local CutDetector = {}


function CutDetector:new()
  local cd = {}
  setmetatable(cd, CutDetector)


  cd.bright_checked = true
  cd.bright_tab = {}

  local bright_diff_tab = {}
  local bright_diff_sorted_tab = {}

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
    for i=#bright_diff_tab,1,-1
    do
      table.insert(sorted_cut_indices,bright_diff_sorted_tab[i][2][1])
    end
    
    return sorted_cut_indices
  end


  function cd.find_cuts()
    bright_diff_tab = {}
    
    -- first try to find cuts where there are silent areas in the sample
    for i=2,#cd.bright_tab,1 do
      local b_diff = math.abs(cd.bright_tab[i] - cd.bright_tab[i-1])
      if (cd.bright_tab[i] < 10 or  cd.bright_tab[i-1] < 10) and b_diff > 100 then
        table.insert(bright_diff_tab,{i,b_diff})
      end
    end

    -- there aren't any silent areas in the sample just make cuts based on relative differences in volume
    if #bright_diff_tab > 0 then 
      bright_diff_sorted_tab = {}
      for k, v in pairs(bright_diff_tab) do
        table.insert(bright_diff_sorted_tab,{k,v})
      end
    else
      for i=2,#cd.bright_tab,1 do
        local b_diff = math.abs(cd.bright_tab[i] - cd.bright_tab[i-1])
        table.insert(bright_diff_tab,{i,b_diff})
      end
      bright_diff_sorted_tab = {}
      for k, v in pairs(bright_diff_tab) do
        table.insert(bright_diff_sorted_tab,{k,v})
      end
      table.sort(bright_diff_sorted_tab, function(a,b) 
        return a[2][2] < b[2][2]
      end)
    end
  end

  return cd
end

return CutDetector
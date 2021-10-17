local cut_detector = {}

cut_detector.bright_checked = true
cut_detector.bright_tab = {}

local bright_diff_tab = {}
local bright_diff_sorted_tab = {}

-- function cut_detector.get_bright_tab()
--   return bright_diff_tab
-- end

function cut_detector.set_bright_start()
  clock.sleep(0.5)
  cut_detector.bright_checked = false
  cut_detector.bright_tab = {}
end

function cut_detector.set_bright(bright)
  if cut_detector.bright_checked == false then
    table.insert(cut_detector.bright_tab, bright)
  end
end

function cut_detector.set_bright_completed()
  if cut_detector.bright_checked == false then
    cut_detector.bright_checked = true
    cut_detector.find_cuts()
  end
end


function cut_detector.get_sorted_cut_indices()
  local sorted_cut_indices = {}
  for i=#bright_diff_tab,1,-1
  do
    table.insert(sorted_cut_indices,bright_diff_sorted_tab[i][2][1])
  end
  
  return sorted_cut_indices
end


function cut_detector.find_cuts()
  bright_diff_tab = {}
  for i=2,#cut_detector.bright_tab,1
  do
    local b_diff = cut_detector.bright_tab[i] - cut_detector.bright_tab[i-1]
    b_diff = b_diff < 0 and b_diff * -1 or b_diff
    table.insert(bright_diff_tab,{i,b_diff})
  end

  bright_diff_sorted_tab = {}
  for k, v in pairs(bright_diff_tab) do
      table.insert(bright_diff_sorted_tab,{k,v})
  end

  table.sort(bright_diff_sorted_tab, function(a,b) 
      return a[2][2] < b[2][2]
    end
  )
end

return cut_detector
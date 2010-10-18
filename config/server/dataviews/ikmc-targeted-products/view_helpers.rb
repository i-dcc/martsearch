
def idcc_targ_rep_get_progressbar_info( project )
  if project[:mouse_available] == '1'
    return { :vectors => "normal", :cells => "normal", :mice => "normal" }
  end
  
  if project[:escell_available] == '1'
    return { :vectors => "normal", :cells => "normal", :mice => "incomp" }
  end
  
  if project[:vector_available] == '1'
    return { :vectors => "normal", :cells => "incomp", :mice => "incomp" }
  end
  
  if project[:no_products_available] and project[:status]
    return { :vectors => "normal", :cells => "incomp", :mice => "incomp" }
  end
  
  # Some other case
  return { :vectors => "incomp", :cells => "incomp", :mice => "incomp" }
end

FUNCTION ROI_PERCENTILE_THRESHOLD, percentage, name, color, fid=fid, dims=dims, pos=pos, ensure_above_zero=ensure_above_zero, ensure_below_zero=ensure_below_zero, bottom=bottom
  orig_image_data = ENVI_GET_DATA(fid=fid, dims=dims, pos=pos)
  
  if KEYWORD_SET(ensure_below_zero) THEN image_data = orig_image_data[WHERE(orig_image_data LT 0)] ELSE image_data = orig_image_data
  if KEYWORD_SET(ensure_above_zero) THEN image_data = orig_image_data[WHERE(orig_image_data GT 0)] ELSE image_data = orig_image_data
  
  if KEYWORD_SET(bottom) THEN sorted_image_indices = SORT(image_data) ELSE sorted_image_indices = REVERSE(SORT(image_data)) 
  
  len = N_ELEMENTS(image_data)
  
  threshold =  image_data[sorted_image_indices[percentage/100 * len]]
  
  print, threshold
  
  if KEYWORD_SET(bottom) THEN BEGIN
    ENVI_DOIT, 'ROI_THRESH_DOIT', dims=dims, fid=fid, pos=pos, min_thresh=MIN(orig_image_data), $
      max_thresh=threshold, ROI_ID=roi_id, ROI_NAME=name, ROI_COLOR=color, /NO_QUERY
  ENDIF ELSE BEGIN
    ENVI_DOIT, 'ROI_THRESH_DOIT', dims=dims, fid=fid, pos=pos, $
      min_thresh=threshold, max_thresh=MAX(orig_image_data), ROI_ID=roi_id, ROI_NAME=name, ROI_COLOR=color, /NO_QUERY
  ENDELSE
  
  return, roi_id 
END

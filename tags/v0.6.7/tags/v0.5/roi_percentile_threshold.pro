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

PRO GUI_ROI_PERCENTILE_THRESHOLD, event
  ENVI_SELECT, fid=fid, dims=dims, pos=pos, title="Select file for ROI percentile threshold"
  
  ; Create dialog box window
  TLB = WIDGET_AUTO_BASE(title="ROI Percentile Threshold")
  
  ; Add widget to select ROI name
  W_Name = WIDGET_STRING(TLB, /AUTO_MANAGE, prompt="ROI name:", uvalue="name")
  
  ; Add widget to select percentage
  W_Percent = WIDGET_PARAM(TLB, /AUTO_MANAGE, prompt="Percentage Threshold:", uvalue="percent")
  
  W_TopBottom = WIDGET_TOGGLE(TLB, /AUTO_MANAGE, list=["Top", "Bottom"], uvalue="topbottom")
  
  W_Constraint = WIDGET_TOGGLE(TLB, /AUTO_MANAGE, list=["No constraint", "Ensure above zero", "Ensure below zero"], uvalue="constraint")
  
  ; Start the automatic management of the window
  result = AUTO_WID_MNG(TLB) 
  
  ; If the OK button was pressed
  IF result.accept EQ 0 THEN RETURN
  
  CASE result.constraint OF
    0: roi_id = ROI_PERCENTILE_THRESHOLD(result.percent, result.name, 3, fid=fid, dims=dims, pos=pos, bottom=result.topbottom)
    1: roi_id = ROI_PERCENTILE_THRESHOLD(result.percent, result.name, 3, fid=fid, dims=dims, pos=pos, bottom=result.topbottom, /ensure_above_zero)
    2: roi_id = ROI_PERCENTILE_THRESHOLD(result.percent, result.name, 3, fid=fid, dims=dims, pos=pos, bottom=result.topbottom, /ensure_below_zero)
  ENDCASE  
END

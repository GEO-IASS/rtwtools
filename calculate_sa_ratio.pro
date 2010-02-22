FUNCTION SA_RATIO, fid, pos, roi_id, operation=operation
  COMPILE_OPT STRICTARR
  ; Get the number of samples
  ENVI_FILE_QUERY, fid, ns=ns, nl=nl, dims=dims
  
  result = ENVI_GET_PROJECTION(fid=fid, pixel_size=pixel_size) 
  
  ; Get the ROI name
  ENVI_GET_ROI_INFORMATION, roi_id, /short_name, roi_names=roi_name
  
  ; Get the array of 1D points then convert them to actual x and y co-ords
  points = ENVI_GET_ROI(roi_id)
  
  FOR i = 0, N_ELEMENTS(pos) - 1 DO BEGIN
    WholeBand = ENVI_GET_DATA(fid=fid, dims=dims, pos=pos[i])
    
    roi_data = WholeBand[points]

    total_3d_sa = total(roi_data)
    
    total_plan_sa = float(N_ELEMENTS(points)) * (pixel_size[0] * pixel_size[1])

    result = total_3d_sa / total_plan_sa
  ENDFOR
  
  return, result
END

PRO CALCULATE_SA_RATIO, event
  COMPILE_OPT STRICTARR
  
  ; Use the ENVI dialog box to select a file
  ENVI_SELECT, fid=fid, dims=dims,pos=pos, /band, title="Select a surface area image"
  
  if fid EQ -1 THEN RETURN
  
  all_rois = ENVI_GET_ROI_IDS(fid=fid, /LONG_NAME, roi_names=roi_names)
  
  ; Create dialog box window
  TLB = WIDGET_AUTO_BASE(title="SA Ratio")
  
  ; Create a list of ROIs for the user to select multiple ROIs from
  W_ROIList = WIDGET_MULTI(TLB, /AUTO_MANAGE, list=roi_names, uvalue="roi_name", prompt="Select ROI")
  
  ; Start the automatic management of the window
  result = AUTO_WID_MNG(TLB) 
  
  ; If the OK button was pressed
  IF result.accept EQ 0 THEN RETURN
  
  selected_roi_ids = all_rois[WHERE(result.roi_name EQ 1)]

  FOR i = 0, N_ELEMENTS(selected_roi_ids) - 1 DO BEGIN
    result = SA_RATIO(fid, pos, selected_roi_ids[i])
    
    ;ENVI_GET_ROI_INFORMATION, selected_roi_ids[i], /short_name, roi_names=roi_name
    
    ;results_with_names = [roi_name + ":", string(result)]
    
    
    ;print, results_with_names
    
    ;IF N_ELEMENTS(all_results) EQ 0 THEN all_results = results_with_names ELSE all_results = [all_results, "", results_with_names]
    IF N_ELEMENTS(all_results) EQ 0 THEN all_results = result ELSE all_results = [all_results, result]
  ENDFOR


  ; Create dialog box window
  ;result_TLB = WIDGET_AUTO_BASE(title="ROI stats results")
  
  ;W_results = WIDGET_SLABEL(result_TLB, prompt = ["Result of SA Ratio:", all_results])

  ;widget_control, result_TLB, /realize
  
  print, "-----------"
  
  print, all_results
  
  print, "Mean = ", mean(all_results)
  print, "SD = ", stdev(all_results)
END
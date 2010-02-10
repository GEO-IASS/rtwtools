FUNCTION ROI_STATS, fid, pos, roi_id, operation=operation
  COMPILE_OPT STRICTARR
  ; Get the number of samples
  ENVI_FILE_QUERY, fid, ns=ns, nl=nl, dims=dims
  
  ; Get the ROI name
  ENVI_GET_ROI_INFORMATION, roi_id, /short_name, roi_names=roi_name
  
  ; Get the array of 1D points then convert them to actual x and y co-ords
  points = ENVI_GET_ROI(roi_id)
  
  results = dblarr(N_ELEMENTS(pos))
  
  FOR i = 0, N_ELEMENTS(pos) - 1 DO BEGIN
    WholeBand = ENVI_GET_DATA(fid=fid, dims=dims, pos=pos[i])
    
    roi_data = WholeBand[points]
    
    CASE operation OF
      ; Sum
      0: results[i] = total(roi_data)
      ; Mean
      1: results[i] = mean(roi_data)
      ; Median
      2: results[i] = median(roi_data)
      ; StDev
      3: results[i] = stdev(roi_data)
      ; Max
      4: results[i] = max(roi_data)
      ; Min
      5: results[i] = min(roi_data)
    ENDCASE
  ENDFOR
  
  return, results
END

PRO GUI_ROI_STATS, event
  COMPILE_OPT STRICTARR
  ; Ask the user to select a file
  ENVI_SELECT, fid=fid, pos=pos
  
  if fid EQ -1 THEN RETURN
  
  all_rois = ENVI_GET_ROI_IDS(fid=fid, /LONG_NAME, roi_names=roi_names)
  
  operations = ["Sum", "Mean", "Median", "Standard Deviation", "Maximum", "Minimum"]
  
  ; Create dialog box window
  TLB = WIDGET_AUTO_BASE(title="ROI Statistics")
  
  ; Create a list of ROIs for the user to select multiple ROIs from
  W_ROIList = WIDGET_MENU(TLB, /AUTO_MANAGE, list=roi_names, rows=N_ELEMENTS(roi_names), uvalue="roi_name", prompt="Select ROI")
  W_Operation = WIDGET_PMENU(TLB, /AUTO_MANAGE, list=operations, prompt="Select statistic", uvalue="operation")
  
  ; Start the automatic management of the window
  result = AUTO_WID_MNG(TLB) 
  
  ; If the OK button was pressed
  IF result.accept EQ 0 THEN RETURN
  
  selected_roi_ids = all_rois[WHERE(result.roi_name EQ 1)]

  FOR i = 0, N_ELEMENTS(selected_roi_ids) - 1 DO BEGIN
    results = ROI_STATS(fid, pos, selected_roi_ids[i], operation=result.operation)
    
    ; Get the number of bands
    ENVI_FILE_QUERY, fid, bnames=bnames
    print, bnames
    print, results
    
    ENVI_GET_ROI_INFORMATION, selected_roi_ids[i], /short_name, roi_names=roi_name
    
    results_with_names = bnames + ":" + STRCOMPRESS(string(results))
    
    results_with_names = [roi_name + ":", results_with_names]
    
    
    print, results_with_names
    
    IF N_ELEMENTS(all_results) EQ 0 THEN all_results = results_with_names ELSE all_results = [all_results, "", results_with_names]
  ENDFOR


  ; Create dialog box window
  result_TLB = WIDGET_AUTO_BASE(title="ROI stats results")
  
  W_results = WIDGET_SLABEL(result_TLB, prompt = ["Result of ROI Stats:", "Operation: " + operations[result.operation], "", all_results])

  widget_control, result_TLB, /realize
END
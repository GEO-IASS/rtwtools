; Shrink an individual ROI from the file specified with fid
PRO TRANSLATE_ROI, fid, roi_id, x, y
  COMPILE_OPT STRICTARR
  ; Get the number of samples
  ENVI_FILE_QUERY, fid, ns=ns, nl=nl
  
  ; Get the ROI name
  ENVI_GET_ROI_INFORMATION, roi_id, /short_name, roi_names=roi_name
  
  ; Get the array of 1D points then convert them to actual x and y co-ords
  points = ENVI_GET_ROI(roi_id)
  
  ; If there are no points in the ROI then exit
  if points[0] EQ -1 THEN RETURN

  ; Extract the point indices to X and Y co-ordinates
  point_indices = ARRAY_INDICES([ns, nl], points, /DIMENSIONS)
  
  ; Perform the translation
  new_x_indices = reform(point_indices[0, *]) + x
  
  negative_one = -1
  
  ; Deal with the fact that Y is counted from the bottom not the top
  new_y_indices = reform(point_indices[1, *]) + (y * negative_one)
  
  ; Create the new ROI and associated the points with it
  new_roi_id = ENVI_CREATE_ROI(nl=nl, ns=ns, name="Translated " + roi_name)
  ENVI_DEFINE_ROI, new_roi_id, /point, xpts=new_x_indices, ypts=new_y_indices
END

PRO GUI_TRANSLATE_ROIS, event
  COMPILE_OPT STRICTARR
  ; Ask the user to select a file
  ENVI_SELECT, fid=fid
  
  if fid EQ -1 THEN RETURN
  
  all_rois = ENVI_GET_ROI_IDS(fid=fid, /LONG_NAME, roi_names=roi_names)
  
  IF all_rois[0] EQ -1 THEN BEGIN
    result = DIALOG_MESSAGE("No ROIs exist in this image")
    return
  ENDIF
  
  ; Create dialog box window
  TLB = WIDGET_AUTO_BASE(title="Select ROIs to shrink")
  
  ; Create a list of ROIs for the user to select
  W_ROIList = WIDGET_MULTI(TLB, /AUTO_MANAGE, list=roi_names, uvalue="roi_name")
  
  W_X = WIDGET_PARAM(TLB, /AUTO_MANAGE, dt=1, prompt="Distance to translate (X)", default=0, uvalue="x")
  W_Y = WIDGET_PARAM(TLB, /AUTO_MANAGE, dt=1, prompt="Distance to translate (Y)", default=0, uvalue="y")
  
  ; Start the automatic management of the window
  result = AUTO_WID_MNG(TLB) 
  
  ; If the OK button was pressed
  IF result.accept EQ 0 THEN RETURN
  
  selected_roi_ids = all_rois[WHERE(result.roi_name EQ 1)]
  
  ; Initialise the progress bar window
  ENVI_REPORT_INIT, ["Translating ROIs", STRCOMPRESS(STRING(N_ELEMENTS(selected_roi_ids)))], title='Translate ROI status', base=report_base
  ENVI_REPORT_INC, report_base, N_ELEMENTS(selected_roi_ids) - 1
  
  ; Loop through the selected ROIs, shrinking each one
  FOR i = 0, N_ELEMENTS(selected_roi_ids) - 1 DO BEGIN
    print, "DOING ROI ID ", selected_roi_ids[i]
    TRANSLATE_ROI, fid, selected_roi_ids[i], result.x, result.y
    ENVI_REPORT_STAT, report_base, i, N_ELEMENTS(selected_roi_ids) - 1
  ENDFOR
  
  ; Close the progress window
  ENVI_REPORT_INIT,base=report_base, /FINISH
END
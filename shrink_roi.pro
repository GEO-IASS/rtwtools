PRO SHRINK_ROI, fid, roi_id
  ; Get the number of samples
  ENVI_FILE_QUERY, fid, ns=ns, nl=nl
  
  ; Get the array of 1D points then convert them to actual x and y co-ords
  points = ENVI_GET_ROI(roi_id)
  
  x_points = intarr(N_ELEMENTS(points))
  y_points = intarr(N_ELEMENTS(points))
  
  FOR i = 0, N_ELEMENTS(points) - 1 DO BEGIN
    x_points[i] = points[i] MOD ns
    y_points[i] = points[i] / ns
  ENDFOR
  
  ;print, x_points
  ;print, y_points
  
  new_x_points = intarr(100000)
  new_y_points = intarr(100000)
  
  new_x_points[*] = -1
  new_y_points[*] = -1
  
  ; Old image array way of doing it
  ;image_array = intarr(ns, nl)
  ;image_array[x_points, y_points] = 1
  
  start_array_index = 0
  
  FOR i = 0, N_ELEMENTS(y_points) - 1 DO BEGIN
    relevant_x = x_points(WHERE(y_points EQ y_points[i]))
    
    relevant_x_sorted = relevant_x[SORT(relevant_x)]
    
    n_new = N_ELEMENTS(relevant_x_sorted) - 3
    
    if n_new LT 1 THEN CONTINUE
    
    new_x_points[start_array_index:start_array_index+n_new] = relevant_x_sorted[1:N_ELEMENTS(relevant_x_sorted) - 2]
    Print, "NEW X POINTS AFTER ADDING -------------------"
    print, new_x_points[WHERE(new_x_points NE -1)]
    new_y_points[start_array_index:start_array_index + n_new] = y_points[i]
    start_array_index = start_array_index + n_new + 1
    
    ;pRINT, "List from inside FOR loop"
    ;FOR j = 0, N_ELEMENTS(new_x_points) - 1 DO BEGIN
    ;print, new_x_points[j], ", ", new_y_points[j]
    ;ENDFOR
  ENDFOR
  
  new_roi_id = ENVI_CREATE_ROI(nl=nl, ns=ns, name="Shrunk ROI")
  
  new_x_points = new_x_points[WHERE(new_x_points NE -1)]
  new_y_points = new_y_points[WHERE(new_y_points NE -1)]
  
  FOR i = 0, N_ELEMENTS(new_x_points) - 1 DO BEGIN
    print, new_x_points[i], ", ", new_y_points[i]
  ENDFOR
  
  ENVI_DEFINE_ROI, new_roi_id, /point, xpts=new_x_points, ypts=new_y_points
  
  print, "All done"
END

PRO SHRINK_ALL_ROIS
  ENVI_SELECT, fid=fid
  
  print, fid
  
  roi_ids = ENVI_GET_ROI_IDS(fid=fid)
  
  FOR i = 0, N_ELEMENTS(roi_ids) - 1 DO BEGIN
    print, "DOING ROI ID ", roi_ids[i]
    SHRINK_ROI, fid, roi_ids[i]
  ENDFOR
END
;FORWARD_FUNCTION ENVI_GET_DATA, WIDGET_AUTO_BASE, WIDGET_OUTFM, ENVI_GET_MAP_INFO, widget_slabel

FUNCTION ACCA_CALCULATION, fid, dims, pos, report_base
  COMPILE_OPT STRICTARR
  ENVI_REPORT_INC, report_base, 4
  
  ; Load each of the bands of the image that we actually use (not B1 or B7)
  B2 = ENVI_GET_DATA(fid=fid, dims=dims, pos=1)
  B3 = ENVI_GET_DATA(fid=fid, dims=dims, pos=2)
  B4 = ENVI_GET_DATA(fid=fid, dims=dims, pos=3)
  B5 = ENVI_GET_DATA(fid=fid, dims=dims, pos=4)
  B6 = ENVI_GET_DATA(fid=fid, dims=dims, pos=5)
  
  ENVI_REPORT_STAT, report_base, 1, 4
  
  ; Create the arrays to store the output in
  output = bytarr(dims[2] + 1, dims[4] + 1)
  final_output = bytarr(dims[2] + 1, dims[4] + 1)
  
  SnowCount = 0
  DesertCount = 0
  
  ; Calculate the Normalised Difference Snow Index
  NDSI = (B2 - B5) / (B2 + B5)
  
  ; Constant values defining the different classes each pixel can be set to
  NONCLOUD = 1
  AMBIGUOUS = 2
  WARMCLOUD = 3
  COLDCLOUD = 4
  CLOUD = 5
  UPPERTHRESH = 6
  LOWERTHRESH = 7
  
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;; PASS ONE ;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  
  ; Filter 1
  indices = WHERE(B3 LT 0.08, count)
  IF count GT 0 THEN output[indices] = NONCLOUD
  
  indices = 0
  
  ; Filter 2
  indices = WHERE(output EQ 0 AND NDSI GT 0.7, count)
  IF count GT 0 THEN output[indices] = NONCLOUD
  SnowCount = count
  
  indices = 0
  NDSI = 0
  
  ; Filter 3
  indices = WHERE(output EQ 0 AND B6 GT 300, count)
  IF count GT 0 THEN output[indices] = NONCLOUD
  
  indices = 0
  
  ; Filter 4
  indices = WHERE(output EQ 0 AND ((1 - B5) * B6) GT 225, count)
  IF count GT 0 THEN output[indices] = AMBIGUOUS
  
  indices = 0
  
  ; Filter 5
  ind = WHERE(output EQ 0 AND B4 / FLOAT(B3) GT 2.0, count)
  IF count GT 0 THEN output[ind] = AMBIGUOUS
  
  indices = 0
  
  ; Filter 6
  indices = WHERE(output EQ 0 AND B4 / FLOAT(B2) GT 2.0, count)
  IF count GT 0 THEN output[indices] = AMBIGUOUS
  
  indices = 0
  
  ; Filter 7
  indices = WHERE(output EQ 0 AND B4 / FLOAT(B5) LT 1.0, count)
  IF count GT 0 THEN output[indices] = AMBIGUOUS
  DesertCount = count
  
  indices = 0
  
  ; Filter 8a
  indices = WHERE(output EQ 0 AND ((1 - B5) * B6) GT 210, count)
  IF count GT 0 THEN output[indices] = WARMCLOUD
  
  indices = 0
  
  ; Filter 8b (everything that's left - the ELSE clause)
  indices = WHERE(output EQ 0, count)
  IF count GT 0 THEN output[indices] = COLDCLOUD
  
  indices = 0
  
  ENVI_REPORT_STAT, report_base, 2, 4
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;; PASS TWO ;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  IF (SnowCount / N_ELEMENTS(output)) < 0.01 THEN BEGIN
    indices = WHERE(output EQ WARMCLOUD OR output EQ COLDCLOUD, count)
    IF count GT 0 THEN output[indices] = CLOUD
  ENDIF ELSE BEGIN
    indices = WHERE(output EQ COLDCLOUD, count)
    IF count GT 0 THEN output[indices] = CLOUD
    ColdCloudCount = count
    
    indices = WHERE(output EQ WARMCLOUD, count)
    IF count GT 0 THEN output[indices] = AMBIGUOUS
  ENDELSE
  
  min_cloud = MIN(output[WHERE(output EQ CLOUD)])
  max_cloud = MAX(output[WHERE(output EQ CLOUD)])
  std_cloud = STDDEV(output[WHERE(output EQ CLOUD)])
  skew_cloud = SKEWNESS(output[WHERE(output EQ CLOUD)])
  
  DesertIndex = TOTAL( B4 / FLOAT(B5) ) / N_ELEMENTS(output)
  
  IF (DesertIndex GT 0.5) $
    OR ((ColdCloudCount / N_ELEMENTS(output)) GT 0.4) $
    OR (MEAN(B6[WHERE(output EQ CLOUD)]) < 295) THEN BEGIN
      
      CloudData = FLOAT(B6[WHERE(output EQ CLOUD)])
      SortedIndex = SORT(CloudData)
      n = N_ELEMENTS(CloudData)
      UpperThreshold = CloudData[SortedIndex[97.5*n / 100]]
      
      LowerThreshold = CloudData[SortedIndex[83.5*n / 100]]
      
      MaxThreshold = CloudData[SortedIndex[98.75*n / 100]]
      
      ; Skewness is positive
      IF skew_cloud GT 0 THEN BEGIN
        IF skew_cloud GT 1 THEN skew_cloud = 1
     
        SkewFactor = skew_cloud * std_cloud
        
        NewLowerThreshold = LowerThreshold * SkewFactor
        NewUpperThreshold = UpperThreshold * SkewFactor
        
        IF NewUpperThreshold GT MaxThreshold THEN BEGIN
         SkewAllowed  = MaxThreshold / UpperThreshold
          NewLowerThreshold = LowerThreshold * SkewAllows
          NewUpperThreshold = MaxThreshold
        ENDIF
        
        LowerThreshold = NewLowerThreshold
        UpperThreshold = NewUpperThreshold
     ENDIF
        
    output[WHERE(output EQ CLOUD AND B6 LT UpperThreshold AND B6 GT LowerThreshold)] = UPPERTHRESH
    output[WHERE(output EQ CLOUD AND B6 LT LowerThreshold)] = LOWERTHRESH
    
    mean_low = MEAN(output[WHERE(output EQ LOWERTHRESH)])
    max_low = MAX(output[WHERE(output EQ LOWERTHRESH)])
    perc_low = N_ELEMENTS(WHERE(output EQ LOWERTHRESH)) / n
    
    mean_high = MEAN(output[WHERE(output EQ UPPERTHRESH)])
    max_high = MAX(output[WHERE(output EQ UPPERTHRESH)])
    perc_high = N_ELEMENTS(WHERE(output EQ UPPERTHRESH)) / n
  
    IF (mean_high LT 295) OR (perc_high LT 0.4) OR ((SnowCount / N_ELEMENTS(output)) < 0.01) THEN BEGIN
      final_output[WHERE(output EQ CLOUD OR output EQ UPPERTHRESH OR output EQ LOWERTHRESH)] = 1
    ENDIF ELSE BEGIN
      IF (mean_low LT 295) OR (perc_low LT 0.4) THEN BEGIN
        final_output[WHERE(output EQ CLOUD OR output EQ LOWERTHRESH)] = 1
      ENDIF ELSE BEGIN
        final_output[WHERE(output EQ CLOUD)] = 1
      ENDELSE
    ENDELSE
      
  ENDIF ELSE BEGIN 
    ; Return just the CLOUD class
    
    final_output[WHERE(output EQ CLOUD)] = 1
  ENDELSE
  
  ENVI_REPORT_STAT, report_base, 3, 4
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;; POST PROCESSING ;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  ; Fill in gaps
  kernel = [[1, 1, 1], [1, 0, 1], [1, 1, 1]]
  result = CONVOL(final_output, kernel, /CENTER, /EDGE_ZERO)
  
  indices = WHERE(result GE 5, count)
  IF count GT 0 THEN final_output[indices] = 1
  
  ; The final result is now stored in final_output
  
  ; Calculate statistics
  indices = WHERE(final_output EQ 1, count)
  perc_cloud = (count / FLOAT(N_ELEMENTS(final_output))) * 100
  
    ENVI_REPORT_STAT, report_base, 4, 4
  
  return, final_output
END

PRO ACCA_GUI, event
  COMPILE_OPT STRICTARR
  ENVI_SELECT, fid=fid, dims=dims, pos=pos, title="Select a pre-processed Landsat image"

; If the dialog box was cancelled then stop the procedure
  IF fid[0] EQ -1 THEN RETURN
  
  ; Create dialog box window
  TLB = WIDGET_AUTO_BASE(title="ACCA for Landsat 7")
  
  ; Create the widget to let the user select file or memory output
  W_FileOrMem = WIDGET_OUTFM(TLB, /AUTO_MANAGE, uvalue='fm')
  
  ; Start the automatic management of the window
  result = AUTO_WID_MNG(TLB) 
  
  ; If the OK button was pressed
  IF result.accept EQ 0 THEN RETURN
  
  ; Get the details of the input file, ready to write the output to the disk if needed
  ENVI_FILE_QUERY, fid, fname=fname, data_type=data_type, xstart=xstart, $
    ystart=ystart, INTERLEAVE=interleave
    
  ; Get the map info of the file so that we can output it to the new file
  map_info = ENVI_GET_MAP_INFO(FID=fid)
  
  ; Initialise the progress bar window - differently depending if the output is
  ; to memory or to file
  IF result.fm.in_memory EQ 1 THEN BEGIN
    ENVI_REPORT_INIT, ['Input File: ' + fname, 'Output to memory'], title='ACCA status', base=base, /INTERRUPT
  ENDIF ELSE BEGIN
    ENVI_REPORT_INIT, ['Input File: ' + fname, 'Output File: ' + result.fm.name], title='ACCA status', base=base, /INTERRUPT
  ENDELSE
  
  ; Call the function to create the Getis image
  acca_image = ACCA_CALCULATION(fid, dims, pos, base)
  
  indices = WHERE(acca_image EQ 1, count)
  perc_cloud = (count / FLOAT(N_ELEMENTS(acca_image))) * 100
  
  ENVI_REPORT_INIT,base=base, /FINISH

  IF result.fm.in_memory EQ 1 THEN BEGIN
    ; If the user wanted the result to go to memory then just output it there
    ENVI_ENTER_DATA, acca_image
  ENDIF ELSE BEGIN
    ; If the output is to file then open the file, write the binary data
    ; and close the file
    OpenW, unit, result.fm.name, /GET_LUN
    WriteU, unit, acca_image
    FREE_LUN, unit
    
    ; Then calculate the values needed to create the header file, and create it
    NSamples = dims[2] - dims[1] + 1
    NLines = dims[4] - dims[3] + 1
    NBands = 1
    ENVI_SETUP_HEAD, FNAME=result.fm.name, NS=NSamples, NL=NLines, NB=NBands, $
      DATA_TYPE=1, offset=0, INTERLEAVE=interleave, $
      XSTART=xstart+dims[1], YSTART=ystart+dims[3], $
      DESCRIP="ACCA-generated cloud mask. Cloud cover percentage: " + STRTRIM(STRING(perc_cloud),2) + "%", MAP_INFO=map_info, /OPEN, /WRITE
  ENDELSE  
  
  ; Display percentage cloud cover to the user
  base = widget_auto_base(title="ACCA Results")
  text = ["ACCA Results:", "", "Cloud cover percentage: " + STRTRIM(STRING(perc_cloud),2)]
  ws = widget_slabel(base, prompt=text)
  widget_control, base, /realize
END
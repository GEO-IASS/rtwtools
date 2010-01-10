FUNCTION CREATE_CV_IMAGE, file, dims, pos, distance, report_base
  COMPILE_OPT STRICTARR
  NumRows = dims[2] - dims[1]
  NumCols = dims[4] - dims[3]
  
  NumPos = N_ELEMENTS(pos)
  
  ; Let the progress bar know how many bands we're dealing with (denom. of fraction)
  ENVI_REPORT_INC, report_base, NumPos
  
  FOR CurrPos = 0, NumPos - 1 DO BEGIN
    ; Send an update to the progress window telling it to let us know if cancel has been pressed
    ENVI_REPORT_STAT, report_base, CurrPos, NumPos
    
    ; Get the data for the current band
    WholeBand = ENVI_GET_DATA(fid=file, dims=dims, pos=pos[CurrPos])
    
    Dim = (distance * 2) + 1
    
    N = Dim^2
    
    AverageImage = SMOOTH(float(WholeBand), Dim, /EDGE_TRUNCATE)
    
    SquareImage = float(WholeBand)^2
    
    AverageSquareImage = SMOOTH(float(SquareImage), Dim, /EDGE_TRUNCATE)
    
    CVOutput = AverageSquareImage - (AverageImage^2)
    
    VarianceImage = CVOutput * (float(N)/(N-1))
    
    StDevImage = sqrt(VarianceImage)
    
    CVOutput = float(StDevImage) / AverageImage
    
    ; If it's the first time then copy the CV result to OutputArray,
    ; if not then append it to the end of OutputArray
    IF (CurrPos EQ 0) THEN OutputArray = CVOutput ELSE OutputArray = [ [[OutputArray]], [[CVOutput]] ]
  ENDFOR
  
  ; Close the progress window
  ENVI_REPORT_INIT,base=report_base, /FINISH
  
  RETURN, OutputArray
END

PRO GUI_CREATE_CV_IMAGE, event
  COMPILE_OPT STRICTARR
  ; Use the ENVI dialog box to select a file
  ENVI_SELECT, fid=file,dims=dims,pos=pos
  
  ; If the dialog box was cancelled then stop the procedure
  IF file[0] EQ -1 THEN RETURN
  
  ; Create dialog box window
  TLB = WIDGET_AUTO_BASE(title="Create CV Image")
  
  ; Create dropdown list to select distance value
  list = ['d = 1 (3x3 square)', 'd = 2 (5x5 square)', 'd = 3 (7x7 square)', 'd = 4 (9x9 square)']
  
  W_Distance = WIDGET_PMENU(TLB, /AUTO_MANAGE, list=list, uvalue='d')
  
  ; Create the widget to let the user select file or memory output
  W_FileOrMem = WIDGET_OUTFM(TLB, /AUTO_MANAGE, uvalue='fm')
  
  ; Start the automatic management of the window
  result = AUTO_WID_MNG(TLB) 
  
  ; If the OK button was pressed
  IF result.accept EQ 0 THEN RETURN
  
  ; Get the details of the file, ready to write to the disk if needed
  ENVI_FILE_QUERY, file, fname=fname, data_type=data_type, xstart=xstart, $
    ystart=ystart, INTERLEAVE=interleave
    
  ; Get the map info of the file so that we can output it to the new file
  map_info = ENVI_GET_MAP_INFO(FID=file)
  
  ; Initialise the progress bar window - differently depending if the output is
  ; to memory or to file
  IF result.fm.in_memory EQ 1 THEN BEGIN
    ENVI_REPORT_INIT, ['Input File: ' + fname, 'Output to memory'], title='Getis status', base=base, /INTERRUPT
  ENDIF ELSE BEGIN
    ENVI_REPORT_INIT, ['Input File: ' + fname, 'Output File: ' + result.fm.name], title='Getis status', base=base, /INTERRUPT
  ENDELSE
  
  ; Call the function to create the Getis image
  CVImage = CREATE_CV_IMAGE(file, dims, pos, result.d + 1, base)

  IF result.fm.in_memory EQ 1 THEN BEGIN
    ; If the user wanted the result to go to memory then just output it there
    ENVI_ENTER_DATA, CVImage
  ENDIF ELSE BEGIN
    ; If the output is to file then open the file, write the binary data
    ; and close the file
    OpenW, unit, result.fm.name, /GET_LUN
    WriteU, unit, CVImage
    FREE_LUN, unit
    
    ; Then calculate the values needed to create the header file, and create it
    NSamples = dims[2] - dims[1] + 1
    NLines = dims[4] - dims[3] + 1
    NBands = N_ELEMENTS(pos)
    ENVI_SETUP_HEAD, FNAME=result.fm.name, NS=NSamples, NL=NLines, NB=NBands, $
      DATA_TYPE=4, offset=0, INTERLEAVE=interleave, $
      XSTART=xstart+dims[1], YSTART=ystart+dims[3], $
      DESCRIP="CV Image Output", MAP_INFO=map_info, /OPEN, /WRITE
  ENDELSE
END
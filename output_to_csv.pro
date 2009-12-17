PRO OUTPUT_TO_CSV
  ; Use the ENVI dialog box to select a file
  ENVI_SELECT, fid=file,dims=dims,pos=pos
  
  ; If the dialog box was cancelled then stop the procedure
  IF file[0] EQ -1 THEN RETURN
  
  ; TODO: Get this to loop through bands
  ; Get the data for the first band of the file (ignores pos from earlier)
  WholeBand = ENVI_GET_DATA(fid=file, dims=dims, pos=0)
  
  ; Calculate the dimensions of WholeBand
  SizeInfo = SIZE(WholeBand, /DIMENSIONS)
  NumRows = SizeInfo[0]
  NumCols = SizeInfo[1]

  
  FOR Rows = 0, NumRows - 1 DO BEGIN
    FOR Cols = 0, NumCols - 1 DO BEGIN
    print, WholeBand[Rows, Cols], FORMAT=theFormat
    ENDFOR
  ENDFOR
    
  
END
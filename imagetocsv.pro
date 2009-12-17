PRO ImageToCSV, event
  ; Use the ENVI dialog box to select a file
  ENVI_SELECT, fid=file,dims=dims,pos=pos, /BAND_ONLY
  
  ; If the dialog box was cancelled then stop the procedure
  IF file[0] EQ -1 THEN RETURN
  
  WholeBand = ENVI_GET_DATA(fid=file, dims=dims, pos=pos)
  
  Write_CSV_Data, WholeBand + 0
END
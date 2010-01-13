; Routine written by Robin Wilson, University of Southampton
; with much help and advice from Olivia Wilson (especially for bug fixing!)
FUNCTION REPLACE_ZEROES, array, value
  array_indices = WHERE(array EQ 0, count)
  
  if count GT 0 THEN array[array_indices] = value
  
  return, array
END

FUNCTION AREA_OF_TRIANGLE, a, b, c
  s = (a + b + c) / float(2)
  
  result = sqrt(s * abs(s - a) * abs(s - b) * abs(s - c))
  
;  if FINITE(result[3, 1]) EQ 0 THEN BEGIN
;    print, "PROBLEM:"
;    print, a[3, 1]
;    print, b[3, 1]
;    print, c
;    print, "----"
;    print, result[3, 1]
;  ENDIF
  
  return, result
END

FUNCTION DO_CONVOL, x, y, array
  kernel = intarr(3, 3)
  kernel[x,y] = 1
  
  return, CONVOL(float(array), kernel, /CENTER, /EDGE_TRUNCATE)
END

PRO GUI_CALCULATE_SURFACE_AREA, event
    COMPILE_OPT STRICTARR
  ; Use the ENVI dialog box to select a file
  ENVI_SELECT, fid=file,dims=dims,pos=pos, title="Select the image you want to perform the surface area calculation on"
  
  ; If the dialog box was cancelled then stop the procedure
  IF file[0] EQ -1 THEN RETURN
  
  ; Create dialog box window
  TLB = WIDGET_AUTO_BASE(title="Create Surface Area Image")
  
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
    ENVI_REPORT_INIT, ['Input File: ' + fname, 'Output to memory'], title='Surface Area status', base=base, /INTERRUPT
  ENDIF ELSE BEGIN
    ENVI_REPORT_INIT, ['Input File: ' + fname, 'Output File: ' + result.fm.name], title='Surface Area status', base=base, /INTERRUPT
  ENDELSE
  
  ; Call the function to create the Getis image
  SAImage = CALCULATE_SURFACE_AREA(file, pos, dims, base)

  IF result.fm.in_memory EQ 1 THEN BEGIN
    ; If the user wanted the result to go to memory then just output it there
    ENVI_ENTER_DATA, SAImage
  ENDIF ELSE BEGIN
    ; If the output is to file then open the file, write the binary data
    ; and close the file
    OpenW, unit, result.fm.name, /GET_LUN
    WriteU, unit, SAImage
    FREE_LUN, unit
    
    ; Then calculate the values needed to create the header file, and create it
    NSamples = dims[2] - dims[1] + 1
    NLines = dims[4] - dims[3] + 1
    NBands = N_ELEMENTS(pos)
    ENVI_SETUP_HEAD, FNAME=result.fm.name, NS=NSamples, NL=NLines, NB=NBands, $
      DATA_TYPE=5, offset=0, INTERLEAVE=interleave, $
      XSTART=xstart+dims[1], YSTART=ystart+dims[3], $
      DESCRIP="Surface Area Image Output", MAP_INFO=map_info, /OPEN, /WRITE
  ENDELSE
  
END


FUNCTION CALCULATE_SURFACE_AREA, fid, pos, dims, report_base
  COMPILE_OPT STRICTARR
  
  proj = ENVI_GET_PROJECTION(fid=fid, pixel_size=pixel_size)
  
  pixel_size = pixel_size[0]
  
  ;pixel_size = float(10)
  
  ; Get the data for the current band
  WholeBand = ENVI_GET_DATA(fid=fid, dims=dims, pos=pos)

  ; Get the individual cell from top left, top middle etc as below
  ; A  B  C
  ; D  E  F
  ; G  H  I

  A = DO_CONVOL(0, 0, WholeBand)
  B = DO_CONVOL(1, 0, WholeBand)
  C = DO_CONVOL(2, 0, WholeBand)
  D = DO_CONVOL(0, 1, WholeBand)
  E = DO_CONVOL(1, 1, WholeBand)
  F = DO_CONVOL(2, 1, WholeBand)
  G = DO_CONVOL(0, 2, WholeBand)
  H = DO_CONVOL(1, 2, WholeBand)
  I = DO_CONVOL(2, 2, WholeBand)
  
  ENVI_REPORT_STAT, report_base, 0.25, 1.0
  
  ; All of the straight bits
  EB = abs(E - B)
  EF = abs(E - F)
  ED = abs(E - D)
  EH = abs(E - H)
  
  EB = REPLACE_ZEROES(EB, pixel_size)
  EF = REPLACE_ZEROES(EF, pixel_size)
  ED = REPLACE_ZEROES(ED, pixel_size)
  EH = REPLACE_ZEROES(EH, pixel_size)
  
  ENVI_REPORT_STAT, report_base, 0.50, 1.0
  
  ; Top two diagonals
  EA = sqrt(EB^2 + pixel_size^2)
  EC = sqrt(EF^2 + pixel_size^2)
  EI = sqrt(EH^2 + pixel_size^2)
  EG = sqrt(ED^2 + pixel_size^2)

  Area1 = AREA_OF_TRIANGLE(EA/2, EB/2, pixel_size/2)
  Area2 = AREA_OF_TRIANGLE(EC/2, EB/2, pixel_size/2)
  Area3 = AREA_OF_TRIANGLE(EF/2, EC/2, pixel_size/2)
  Area4 = AREA_OF_TRIANGLE(EI/2, EF/2, pixel_size/2)
  Area5 = AREA_OF_TRIANGLE(EH/2, EI/2, pixel_size/2)
  Area6 = AREA_OF_TRIANGLE(EG/2, EH/2, pixel_size/2)
  Area7 = AREA_OF_TRIANGLE(EG/2, ED/2, pixel_size/2)
  Area8 = AREA_OF_TRIANGLE(ED/2, EA/2, pixel_size/2)
  
  ENVI_REPORT_STAT, report_base, 0.75, 1.0
  
  TotalArea = Area1 + Area2 + Area3 + Area4 + Area5 + Area6 + Area7 + Area8
  
  ; Close the progress window
  ENVI_REPORT_INIT,base=report_base, /FINISH
  
  return, TotalArea
END
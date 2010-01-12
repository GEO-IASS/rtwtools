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
  
  if FINITE(result[3, 1]) EQ 0 THEN BEGIN
    print, "PROBLEM:"
    print, a[3, 1]
    print, b[3, 1]
    print, c
    print, "----"
    print, result[3, 1]
  ENDIF
  
  return, result
END

FUNCTION DO_CONVOL, x, y, array
  kernel = intarr(3, 3)
  kernel[x,y] = 1
  
  return, CONVOL(float(array), kernel, /CENTER, /EDGE_TRUNCATE)
END

PRO CALCULATE_SURFACE_AREA, fid, pos, dims
  ENVI_SELECT, fid=fid, pos=pos, dims=dims
  
  ;proj = ENVI_GET_PROJECTION(fid=fid, pixel_size=pixel_size)
  pixel_size = float(10)
  
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
 
  
  ; Excluding E
  ;DiagonalPoints = [[[A]], [[C]], [[G]], [[I]]]
  ;StraightPoints = [[[B]], [[F]], [[D]], [[H]]]
  
  ; All of the straight bits
  EB = abs(E - B)
  EF = abs(E - F)
  ED = abs(E - D)
  EH = abs(E - H)
  
  EB = REPLACE_ZEROES(EB, pixel_size)
  EF = REPLACE_ZEROES(EF, pixel_size)
  ED = REPLACE_ZEROES(ED, pixel_size)
  EH = REPLACE_ZEROES(EH, pixel_size)
  
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
  
  print, Area2
  print, "---------"
  
  TotalArea = Area1 + Area2 + Area3 + Area4 + Area5 + Area6 + Area7 + Area8
  
  print, TotalArea
  help, TotalArea
  
  ;ENVI_ENTER_DATA, FinalArea
END
; Creates a GLT file ready to be geometrically processed by AZGCORR, and then used with CRESCA in ATCOR
; using the 'Create from GLT/MAP' option.
; Call this function with the size of the image you want in x and y, and a base filename for the output
; images in base_filename
PRO CREATE_GLT_IMAGE, x, y, base_filename, reverse_cols=reverse_cols, reverse_rows=reverse_rows
  ; Create one row for the column indices image - make it go from 1 rather than 0 by adding 1 to it
  row = indgen(x) + 1
  
  if keyword_set(reverse_cols) then row = reverse(row)
  
  ; Replicate this down the image
  col_indices_image = cmreplicate(row, y)
  
  ; Create one column for the row indices image - make it go from 1 rather than 0 by adding 1 to it
  column = indgen(y) + 1
  
  if keyword_set(reverse_rows) then column = reverse(column)
  ; Replicate this across the image
  row_indices_image = transpose(cmreplicate(column, x))
  
  ;print, col_indices_image
  
  ;print, "---------"
  
  ;print, row_indices_image
  
  ; Write the ENVI format files
  ENVI_WRITE_ENVI_FILE, col_indices_image, data_type=2, interleave=0, nb=1, nl=y, ns=x, offset=0, out_name=base_filename+"_ColIndices.bsq"
  ENVI_WRITE_ENVI_FILE, row_indices_image, data_type=2, interleave=0, nb=1, nl=y, ns=x, offset=0, out_name=base_filename+"_RowIndices.bsq"
END

PRO GUI_CREATE_GLT_IMAGE, event
  tlb = WIDGET_AUTO_BASE(title="Create GLT Image")
  x = WIDGET_PARAM(tlb, /auto_manage, dt=3, prompt="X length", uvalue="x", xsize=40)
  y = WIDGET_PARAM(tlb, /auto_manage, dt=3, prompt="Y length", uvalue="y", xsize=40)
  filename = WIDGET_OUTF(tlb, /auto_manage, prompt="Enter output base filename", uvalue="outf")
  reversal = WIDGET_TOGGLE(tlb, /auto_manage, list=["Normal", "Reverse rows", "Reverse columns", "Reverse both"], uvalue="reversal")
  
  result = AUTO_WID_MNG(tlb)
  
  IF result.accept EQ 0 THEN RETURN
  
  CASE result.reversal OF
    0: CREATE_GLT_IMAGE, result.x, result.y, result.outf
    1: CREATE_GLT_IMAGE, result.x, result.y, result.outf, /REVERSE_ROWS
    2: CREATE_GLT_IMAGE, result.x, result.y, result.outf, /REVERSE_COLS
    3: CREATE_GLT_IMAGE, result.x, result.y, result.outf, /REVERSE_ROWS, /REVERSE_COLS
  ENDCASE
END
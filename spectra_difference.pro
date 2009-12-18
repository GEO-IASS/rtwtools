PRO SPECTRA_DIFFERENCE, abs=abs
  ENVI_SELECT, fid=A_fid, title="Select SLI A (SPOT)"
  ENVI_SELECT, fid=B_fid, title="Select SLI B (CASI)"
  
  envi_file_query, A_fid, fname=A_fname, spec_names=A_spec_names, ns=A_ns, nl=A_nl, file_type=A_file_type, wl=A_wavelengths
  envi_file_query, B_fid, fname=B_fname, spec_names=B_spec_names, ns=B_ns, nl=B_nl, file_type=B_file_type, wl=B_wavelengths
  
  ; Create dialog box window
  TLB = WIDGET_AUTO_BASE(title="Spectra Difference")
  
  W_A_List = WIDGET_SLIST(TLB, /AUTO_MANAGE, list=A_spec_names, prompt="Choose spectrum from library A:", uvalue="ASpec")
  W_B_List = WIDGET_SLIST(TLB, /AUTO_MANAGE, list=B_spec_names, prompt="Choose spectrum from library A:", uvalue="BSpec")
  
  ; Create the widget to let the user select file or memory output
  W_FileOrMem = WIDGET_OUTFM(TLB, /AUTO_MANAGE, uvalue='fm')
  
  ; Start the automatic management of the window
  result = AUTO_WID_MNG(TLB) 
  
  ; If the cancel button was pressed then exit
  IF result.accept EQ 0 THEN RETURN
  
  
  A_spectra = envi_get_data(fid=A_fid, pos=0, dims=[-1,0,A_ns-1, 0, A_nl-1])
  
  
  B_spectra = envi_get_data(fid=B_fid, pos=0, dims=[-1,0,B_ns-1, 0, B_nl-1])
  
  Diff_spectra = (ABS(A_spectra - B_spectra)/A_spectra) * 100
  
  print, A_fname
  print, B_fname
  print, A_wavelengths
  print, Diff_spectra
  
  IF result.fm.in_memory EQ 1 THEN BEGIN
    ; If the user wanted the result to go to memory then just output it there
    ENVI_ENTER_DATA, Diff_spectra, file_type=ENVI_FILE_TYPE("ENVI Spectral Library"), spec_names="Difference", wavelength_unit=1, wl=A_wavelengths
  ENDIF ELSE BEGIN
    OpenW, unit, result.fm.name, /GET_LUN
    WriteU, unit, Diff_spectra
    FREE_LUN, unit
      
    ; Then calculate the values needed to create the header file, and create it
    
    ENVI_SETUP_HEAD, FNAME=result.fm.name, NS=A_ns, NL=1, NB=1, $
      file_type=ENVI_FILE_TYPE("ENVI Spectral Library"), spec_names="Difference", $
      wavelength_unit=1, wl=A_wavelengths, interleave=0, $
      DATA_TYPE=5, offset=0, DESCRIP="Difference Spec Lib", /OPEN, /WRITE
  END
END
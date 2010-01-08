FUNCTION CALCULATE_PERCENTAGE_DIFFERENCE, SPOT, CASI
  return, (ABS(float(SPOT) - CASI)/CASI) * 100
END

PRO SPECTRA_DIFFERENCE, event, abs=abs
  COMPILE_OPT STRICTARR
  ENVI_SELECT, fid=A_fid, title="Select SLI A (Calibrated File)"
  ENVI_SELECT, fid=B_fid, title="Select SLI B (Ground Data)"
  
  ; Create dialog box window
  ;TLB = WIDGET_AUTO_BASE(title="Spectra Difference")
  
  ; Create the widget to let the user select file or memory output
  ;W_FileOrMem = WIDGET_OUTFM(TLB, /AUTO_MANAGE, uvalue='fm')
  
  ; Start the automatic management of the window
  ;result = AUTO_WID_MNG(TLB) 
  
  ; If the cancel button was pressed then exit
  ;IF result.accept EQ 0 THEN RETURN
  
  envi_file_query, A_fid, fname=A_fname, spec_names=A_spec_names, ns=A_ns, nl=A_nl, file_type=A_file_type, wl=A_wavelengths
  A_spectra = envi_get_data(fid=A_fid, pos=0, dims=[-1,0,A_ns-1, 0, A_nl-1])
  
  envi_file_query, B_fid, fname=B_fname, spec_names=B_spec_names, ns=B_ns, nl=B_nl, file_type=B_file_type, wl=B_wavelengths, data_type=B_dt
  B_spectra = envi_get_data(fid=B_fid, pos=0, dims=[-1,0,B_ns-1, 0, B_nl-1])
  
  ENVI_RESAMPLE_SPECTRA, B_wavelengths, B_spectra, A_wavelengths, B_spectra_resampled, out_dt=B_dt
  
  if A_nl NE B_nl THEN BEGIN
    MESSAGE, "Need same number of spectra in each file"
  ENDIF
  
  Diff_spectra = CALCULATE_PERCENTAGE_DIFFERENCE(A_spectra, B_spectra_resampled)
  
  ; Calculate the band means
  band_means = AVERAGE_OVER_ARRAY(Diff_spectra, 2)
  
  ; Calculate the validation site means
  site_means = AVERAGE_OVER_ARRAY(Diff_spectra, 1)
  
  FOR i = 0, N_ELEMENTS(band_means) - 1 DO BEGIN
    print, "Band " + STRCOMPRESS(STRING(i+1)) + " Average = " + STRCOMPRESS(STRING(band_means[i]))
  ENDFOR
  
  print, "----"
  
  FOR i = 0, N_ELEMENTS(site_means) - 1 DO BEGIN
    print, "Site " + STRCOMPRESS(STRING(i+1)) + " Average = " + STRCOMPRESS(STRING(site_means[i]))
  ENDFOR
  
  print, "Raw data:"
  print, Diff_spectra
  
;  IF result.fm.in_memory EQ 1 THEN BEGIN
;    ; If the user wanted the result to go to memory then just output it there
;    ENVI_ENTER_DATA, Diff_spectra, file_type=ENVI_FILE_TYPE("ENVI Spectral Library"), spec_names="Difference", wavelength_unit=1, wl=A_wavelengths
;  ENDIF ELSE BEGIN
;    OpenW, unit, result.fm.name, /GET_LUN
;    WriteU, unit, Diff_spectra
;    FREE_LUN, unit
;      
;    ; Then calculate the values needed to create the header file, and create it
;    
;    ENVI_SETUP_HEAD, FNAME=result.fm.name, NS=A_ns, NL=1, NB=1, $
;      file_type=ENVI_FILE_TYPE("ENVI Spectral Library"), spec_names="Difference", $
;      wavelength_unit=1, wl=A_wavelengths, interleave=0, $
;      DATA_TYPE=5, offset=0, DESCRIP="Difference Spec Lib", /OPEN, /WRITE
;  END
END
PRO ACCA_CALCULATION
  ENVI_SELECT, fid=fid, dims=dims, pos=pos
  
  
  B1 = ENVI_GET_DATA(fid=fid, dims=dims, pos=0)
  B2 = ENVI_GET_DATA(fid=fid, dims=dims, pos=1)
  B3 = ENVI_GET_DATA(fid=fid, dims=dims, pos=2)
  B4 = ENVI_GET_DATA(fid=fid, dims=dims, pos=3)
  B5 = ENVI_GET_DATA(fid=fid, dims=dims, pos=4)
  B6 = ENVI_GET_DATA(fid=fid, dims=dims, pos=5)
  B7 = ENVI_GET_DATA(fid=fid, dims=dims, pos=6)
  
  output = intarr(dims[2] + 1, dims[4] + 1)
  final_output = intarr(dims[2] + 1, dims[4] + 1)
  SnowCount = 0
  DesertCount = 0
  
  NDSI = (B2 - B5) / (B2 + B5)
  
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
  print, count
  
  ; Filter 2
  indices = WHERE(output EQ 0 AND NDSI GT 0.7, count)
  IF count GT 0 THEN output[indices] = NONCLOUD
  SnowCount = count
  print, count
  
  ; Filter 3
  indices = WHERE(output EQ 0 AND B6 GT 300, count)
  IF count GT 0 THEN output[indices] = NONCLOUD
  print, count
  
  ; Filter 4
  indices = WHERE(output EQ 0 AND ((1 - B5) * B6) GT 225, count)
  IF count GT 0 THEN output[indices] = AMBIGUOUS
  print, count
  
  ; Filter 5
  ind = WHERE(output EQ 0 AND B4 / FLOAT(B3) GT 2.0, count)
  IF count GT 0 THEN output[ind] = AMBIGUOUS
  print, count
  
  ; Filter 6
  indices = WHERE(output EQ 0 AND B4 / FLOAT(B2) GT 2.0, count)
  IF count GT 0 THEN output[indices] = AMBIGUOUS
  print, count
  
  ; Filter 7
  indices = WHERE(output EQ 0 AND B4 / FLOAT(B5) LT 1.0, count)
  IF count GT 0 THEN output[indices] = AMBIGUOUS
  DesertCount = count
  print, count
  
  ; Filter 8a
  indices = WHERE(output EQ 0 AND ((1 - B5) * B6) GT 210, count)
  IF count GT 0 THEN output[indices] = WARMCLOUD
  print, count
  
  ; Filter 8b (everything that's left - the ELSE clause)
  indices = WHERE(output EQ 0, count)
  IF count GT 0 THEN output[indices] = COLDCLOUD
  print, count
  
  e = output
  ENVI_ENTER_DATA, e
  
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
      print, "Doing Pass 2"
      
      CloudData = FLOAT(B6[WHERE(output EQ CLOUD)])
      SortedIndex = SORT(CloudData)
      n = N_ELEMENTS(CloudData)
      UpperThreshold = CloudData[SortedIndex[97.5*n / 100]]
      
      print, UpperThreshold
      
      LowerThreshold = CloudData[SortedIndex[83.5*n / 100]]
      print, LowerThreshold
      
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
  
  ; Search for holes and fill them
  kernel = [[1, 1, 1], [1, 0, 1], [1, 1, 1]]
  result = CONVOL(final_output, kernel, /CENTER, /EDGE_ZERO)
  
  indices = WHERE(result GE 5, count)
  IF count GT 0 THEN final_output[indices] = 1
  
  ENVI_ENTER_DATA, final_output
END
PRO rtwtools_define_buttons, buttonInfo
  ; RTWTools root menu
  ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'RTWTools', $
    /MENU, REF_VALUE = 'Help', /SIBLING, POSITION = 'after'
    
  ; LISA root menu
  ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'LISA', $
    /MENU, REF_VALUE = 'RTWTools', POSITION = 'last'
    
  ; Create Getis image item
  ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Create Getis image', $
      UVALUE = 'Create Getis image', EVENT_PRO = 'CREATE_GETIS_IMAGE', $
      REF_VALUE = 'LISA', POSITION = 'last'
      
  ; Create CV image item
  ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Create CV image', $
      UVALUE = 'Create CV image', EVENT_PRO = 'GUI_CREATE_CV_IMAGE', $
      REF_VALUE = 'LISA', POSITION = 'last'
      
  ; DEMs root menu
  ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'DEMs', $
    /MENU, REF_VALUE = 'RTWTools', POSITION = 'last'
    
  ; Select NeXTMAP tiles root menu
  ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Select NeXTMAP tiles', $
    /MENU, REF_VALUE = 'DEMs', POSITION = 'last'
    
  ; From georef image item
  ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'From georeferenced image', $
      UVALUE = 'From Geo-ref image', EVENT_PRO = 'IMAGE_TO_NM_TILES', $
      REF_VALUE = 'Select NeXTMAP tiles', POSITION = 'last'
      
  ; From corner co-ords item
  ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'From corner co-ordinates', $
      UVALUE = 'From corner co-ordinates', EVENT_PRO = 'GUI_TO_NM_TILES', $
      REF_VALUE = 'Select NeXTMAP tiles', POSITION = 'last'
      
  ; From bottom left corner and length/width item
  ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'From bottom left corner and length/width', $
      UVALUE = 'From bottom left corner and length/width', EVENT_PRO = 'GUI_LEN_WIDTH_TO_NM_TILES', $
      REF_VALUE = 'Select NeXTMAP tiles', POSITION = 'last'
      
  ; Calculate Surface Area item
  ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Calculate Surface Area', $
      UVALUE = 'Calculate Surface Area', EVENT_PRO = 'GUI_CALCULATE_SURFACE_AREA', $
      REF_VALUE = 'DEMs', POSITION = 'last'
  
  ; ROI Tools root menu
  ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'ROI Tools', $
    /MENU, REF_VALUE = 'RTWTools', POSITION = 'last'
    
  ; ROI Percentile Threshold item
  ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'ROI Percentile Threshold', $
      UVALUE = 'ROI Percentile Threshold', EVENT_PRO = 'GUI_ROI_PERCENTILE_THRESHOLD', $
      REF_VALUE = 'ROI Tools', POSITION = 'last'   
      
  ; Shrink ROIs item
  ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Shrink ROIs', $
      UVALUE = 'Shrink ROIs', EVENT_PRO = 'GUI_SHRINK_ROIS', $
      REF_VALUE = 'ROI Tools', POSITION = 'last'  
      
  ; Translate ROIs item
  ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Translate ROIs', $
      UVALUE = 'Translate ROIs', EVENT_PRO = 'GUI_TRANSLATE_ROIS', $
      REF_VALUE = 'ROI Tools', POSITION = 'last'
      
  ; ROI statistics item
  ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'ROI statistics', $
      UVALUE = 'ROI Stats', EVENT_PRO = 'GUI_ROI_STATS', $
      REF_VALUE = 'ROI Tools', POSITION = 'last'
      
  ; Misc root menu
  ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Misc', $
    /MENU, REF_VALUE = 'RTWTools', POSITION = 'last'
    
  ; Create GLT image item
  ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Create GLT image', $
      UVALUE = 'Create GLT Image', EVENT_PRO = 'GUI_CREATE_GLT_IMAGE', $
      REF_VALUE = 'Misc', POSITION = 'last'
  
   ; Output band to CSV item
  ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Output band to CSV', $
      UVALUE = 'Output band to CSV', EVENT_PRO = 'IMAGE_TO_CSV', $
      REF_VALUE = 'Misc', POSITION = 'last'
END
; The procedure below is specifically written to work with .shp files exported
; from eCognition for a project by Robin Wilson, and may not work for other uses
; The idea is that the shape file, and the image file to associate the ROIs with
; are passed to the procedure, and an individual ROI for each shape file polygon
; is created. However, there is attribute checking (see notes in comments), so it
; doesn't do all of the input shapefile.
;
; Adapted from class_image_stats.pro by Andy Pursch, available at http://www.ittvis.com/UserCommunity/CodeLibrary.aspx
;
PRO SHP_TO_ROI, shape_file, image_file
    COMPILE_OPT STRICTARR
  ; Return to the calling program if there is an error
  ON_ERROR, 2

  ; Open (and check) the image file.
  ENVI_OPEN_FILE, image_file, r_fid=fid, /no_interactive_query, /no_realize
  IF fid EQ -1 THEN BEGIN
      void = DIALOG_MESSAGE('Unable to open image file', /error)
      RETURN
  ENDIF

  ; Retrieve information about the file
  ENVI_FILE_QUERY, fid, file_type=file_type, nl=num_lines, $
              ns=num_samps, num_classes=num_classes

  ; Open (and check) the shape file. Use the IDL shapefile object since ENVI's
  ; shapefile API is not exposed to the user.
  shape_file_obj = OBJ_NEW('idlffshape', shape_file)
  IF NOT OBJ_VALID(shape_file_obj) THEN BEGIN
      void = DIALOG_MESSAGE('Unable to access shape file', /error)
      RETURN
  ENDIF
  ; Get the number of entities and the entity type.
  shape_file_obj->GetProperty, N_ENTITIES=num_ent, $
      ENTITY_TYPE=ent_type

 ; Get the info for all attributes.
 shape_file_obj->GetProperty, ATTRIBUTE_INFO=attr_info

  ; Loop through the entities, converting each to an ROI, getting/computing the stats,
  ; writing out the stats.
  icnt=0

  ENVI_BATCH_STATUS_WINDOW,/ON
  repStr='Processing Classification Image'
  ENVI_REPORT_INIT,repStr,BASE=repBase,TITLE='Calculating ROI Statistics'
  ENVI_REPORT_INC,repBase,num_ent
  WIDGET_CONTROL,/HOURGLASS

  ; Start looping over all individual cells from the shapefile
  FOR i=0, num_ent-1 DO BEGIN

    ; Update the processing status bar
        ENVI_REPORT_STAT,repBase,i, num_ent-1

      ; First, get the vertices for the entity.
      this_entity = shape_file_obj -> GetEntity(i) ; Could add the attributes keyword here.
      these_vertices = *(this_entity.vertices)
      attr = shape_file_obj->getAttributes( i)
      
      ; Check the attributes. If the best class field is -1 then a class was not
      ; assigned.
      IF attr.attribute_2 EQ -1 THEN CONTINUE ; ELSE $
      ;IF attr.attribute_2 EQ 1 THEN name = "bright" ELSE $
      ;IF attr.attribute_2 EQ 2 THEN name = "dark"

      print, "these_vertices"
      print, these_vertices

      x_file_coords = reform(these_vertices[0,*])
      y_file_coords = reform(these_vertices[1,*])


      ;x_file_coords = num_samps - x_file_coords
      y_file_coords = num_lines - y_file_coords
      
      ; Do shape file polygon entities get returned as a closed
      ; set of coordinates or if it's just implicit, let's check.  ROIs require
      ; polygons to be explicitly closed.
      last_element_index = N_ELEMENTS(x_file_coords)-1
      IF x_file_coords[0] NE x_file_coords[last_element_index] THEN BEGIN
            x_file_coords = [x_file_coords, x_file_coords[0]]
            y_file_coords = [y_file_coords, y_file_coords[0]]
      ENDIF

      print, "HELLO, ROBIN HERE!"
      print, x_file_coords

      ; Since the overlay grid covers a larger geographic extent than the image some of the
      ; polygons will lie off the image. We can skip them.
      IF TOTAL(x_file_coords LT 0) EQ 0 AND TOTAL(y_file_coords LT 0) EQ 0 AND $
        TOTAL(x_file_coords GT NUM_SAMPS) EQ 0 AND TOTAL(y_file_coords GT NUM_LINES) EQ 0 THEN BEGIN
        ; define counter for the the number of valid ROIs
        icnt++
        
        ; Now that we're in file coordinates, make an roi.
        this_roi_id = ENVI_CREATE_ROI(nl=num_lines, ns=num_samps, name=attr.attribute_1+string(i))
        ENVI_DEFINE_ROI, this_roi_id, /polygon, xpts=x_file_coords, ypts=y_file_coords

        print, "-------"
        print, x_file_coords

      ENDIF
  ENDFOR

  ENVI_REPORT_INIT,BASE=repBase,/FINISH

  ; Destroy shapefile object to free up memory
  OBJ_DESTROY, shape_file_obj
  
  PRINT,'Total number of Valid ROIs found: ', icnt
END

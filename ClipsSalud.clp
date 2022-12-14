; Title: Practica Final - CLIPS RULES  ("ClipsSalud")
; Autor: Juan Torres Contreras
; Version: 5
; Date: 03/06/2022
;
;
; #EXPLICACION-FUNCIONAMIENTO: 
; Partiendo de una estructura tipo arbol (deffacts-Nodos) y, tras seleccionar los sintomas, 
; se guarda en cada 'Nodo' su "pesoCTE" que es la probabilidad de suceder (pesoCTE = 1/numeroHijos)
; Tras esto, se recorren los nodos en orden ascendente (hijos->padres->abuelos...), de modo que se incrementan las probabilidades ("pesoAcumulado")
; de un padre: en funcion del la probabilidad de ocurrir de cada hijo y del 'pesoCTE' del propio padre (pesoAcumulado_padre += pesoCTE_padre*pesoAcumulado_Hijo_i)
; Finalmente, se muestran por pantalla los nodos con mayor probabilidad de cada "nivel" (por defecto: ESPECIALISTA, ENFERMEDAD y MEDICAMENTO)
; [LOS RESULTADOS VARIAN EN FUNCION DE SU PROBABILIDAD DE OCURRIR DE FORMA INDIVIDUAL, AL FINAL SE MUESTRAN LOS MAS PROBABLES]
;
;
; NOTA: He tratado de hacerlo de modo que se requiera el minimo numero de hechos escritos a mano requeridos para el sistema funcione ('toString2' y "deffacts-Nodos"/estructuraArbol)
;         Ej.: El "orden jerarquico" se instancia automaticamente (antes no lo hacía, pero lo he dejado comentado porque facilita la comprension de algunas reglas)
; 
;
; (OBSERVACION_1: No lo he comprobado, pero no creo que funcione si se le agrega un arbol descompensado)
; (OBSERVACION_2: Las relaciones que se muestran en el arbol no son correctas; se usan a modo de ejemplo)    
;
;
;
; MUY_IMPORTANTE: COMO SE CAMBIE DE SITIO/ORDEN ALGUNA REGLA, PUEDE NO FUNCIONAR.
;
;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;               [DATOS NECESARIOS PARA QUE EL SISTEMA FUNCIONE]
;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;-----------------------------------[deffacts-Nodos]----------------------------------
; Para crear la estructura de arbol y sus dependencias.
;
;-----------------------------------[defrule-inicio]----------------------------------
; **(toString_NVL ...) <===== Nombre de los niveles de los nodos cuyas probabilidades queramos conocer  (**DEBUG-ONLY**)
; (toString2 ...) <======== Nombre de los niveles cuyos nodos con mas probabilidades queramos conocer.
; 
;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------


(deftemplate Nodo 
  (slot nivel) 
  (slot nombre)
  (multislot subNodos);Sus elem. se borran con cada incremento del pesoAcumulado
  (slot pesoCTE (type FLOAT) (default 0.0)) ; = 1/numSubNodos(casosPosibles)
  (slot pesoAcumulado (type FLOAT) (default 0.0)) ; Probabilidad acumulada (+= (pesoAcum_hijo * pesoCTE_padre)) <======["calculaIncremento"]
)

;ESTO REPRESENTA EL ARBOL: 
;**(Es aquí donde se define la estructura del arbol, así como sus dependencias o "ramas")**
(deffacts Nodos
  (Nodo (nivel ESPECIALISTA) (nombre OTORRINO)        (subNodos JARABE CONTREX))
  (Nodo (nivel ESPECIALISTA) (nombre ENDOCRINOLOGO)   (subNodos VACUNA))
  (Nodo (nivel ESPECIALISTA) (nombre NUTRICIONISTA)   (subNodos VITAMINA ))
  (Nodo (nivel ESPECIALISTA) (nombre MEDICO_GENERAL)  (subNodos VACUNA PASTILLA))

  (Nodo (nivel MEDICAMENTO) (nombre JARABE)    (subNodos GRIPE))
  (Nodo (nivel MEDICAMENTO) (nombre CONTREX)   (subNodos GRIPE))
  (Nodo (nivel MEDICAMENTO) (nombre VACUNA)    (subNodos GRIPE RUBEOLA HEPATITIS MALARIA))
  (Nodo (nivel MEDICAMENTO) (nombre VITAMINA)  (subNodos ANEMIA))
  (Nodo (nivel MEDICAMENTO) (nombre PASTILLA)  (subNodos RUBEOLA HEPATITIS TUBERCULOSIS))

  (Nodo (nivel ENFERMEDAD) (nombre GRIPE)         (subNodos TOS CANSANCIO FIEBRE DOLOR_DE))
  (Nodo (nivel ENFERMEDAD) (nombre RUBEOLA)       (subNodos FIEBRE ESCALOFRIOS JAQUECA SECRECION))
  (Nodo (nivel ENFERMEDAD) (nombre MALARIA)       (subNodos DIARREA FIEBRE ICTERICIA ESCALOFRIOS))
  (Nodo (nivel ENFERMEDAD) (nombre HEPATITIS)     (subNodos DIARREA NAUSEAS ICTERICIA))
  (Nodo (nivel ENFERMEDAD) (nombre TUBERCULOSIS)  (subNodos TOS CANSANCIO ESCALOFRIOS))
  (Nodo (nivel ENFERMEDAD) (nombre ANEMIA)        (subNodos CANSANCIO NAUSEAS APATIA))

  (Nodo (nivel SINTOMA) (nombre DIARREA))
  (Nodo (nivel SINTOMA) (nombre TOS))
  (Nodo (nivel SINTOMA) (nombre CANSANCIO))
  (Nodo (nivel SINTOMA) (nombre FIEBRE))
  (Nodo (nivel SINTOMA) (nombre DOLOR_DE))
  (Nodo (nivel SINTOMA) (nombre NAUSEAS))
  (Nodo (nivel SINTOMA) (nombre ICTERICIA))
  (Nodo (nivel SINTOMA) (nombre APATIA))
  (Nodo (nivel SINTOMA) (nombre ESCALOFRIOS))
  (Nodo (nivel SINTOMA) (nombre JAQUECA))
  (Nodo (nivel SINTOMA) (nombre SECRECION))
)


(deftemplate Orden
  (slot superNodo)  
  (slot subNodo)
  (slot state  (allowed-values ON OFF) (default OFF)) ;Controla el orden: "hijo-->padre"
)
;ORDEN JERARQUICO [SE CREA AUTOMATICAMENTE]
;**(Las ependencias jerarquicas; determina el orden "padre"-->"hijo")**
; (deffacts SystemFlow
;   (Orden (superNodo ESPECIALISTA) (subNodo MEDICAMENTO)) 
;   (Orden (superNodo MEDICAMENTO)  (subNodo ENFERMEDAD)) 
;   (Orden (superNodo ENFERMEDAD)   (subNodo SINTOMA)) 
;   (Orden (superNodo SINTOMA)      (subNodo SINTOMA))  ;El ultimo nivel ("Hojas") tiene el mismo simbolo para superNodo y subNodo: 
                                                        ;para diferenciarlo del resto facilmente.
; )



;##################################################
;############### INIT-CONTROL-FLOW ################
;##################################################
 (defrule findHojas
  (not(Orden))
  (Nodo (nivel ?hojaLvl) (nombre ?name) (subNodos))
  =>
  (assert (Orden (superNodo ?hojaLvl) (subNodo ?hojaLvl)) )
)
(defrule findNextPadre
  ;Un padre cuyo nivel NO se ha guardado
  (Nodo (nivel ?padreLvl) (subNodos $? ?hijoName $?))
  (not(Orden (superNodo ?padreLvl)))

  ;Un hijo cuyo nivel SI se ha guardado
  (Nodo (nivel ?hijoLvl) (nombre ?hijoName) )
  (Orden (superNodo ?hijoLvl)) 
  =>
  (assert (Orden (superNodo ?padreLvl) (subNodo ?hijoLvl)))
)



;################################################## 
;############## TO_STRING_ELEMENTS ################
;##################################################
;ESTABLECE QUE Y COMO SE MUESTRAN LOS RESULTADOS
;**(Aquí se decide que resultado mostrar)** 
 (defrule inicio
    =>  
  ;;DEBUG ONLY;; (assert (toString_NVL ESPECIALISTA MEDICAMENTO ENFERMEDAD))  ;;DEBUG ONLY;;
   (assert (toString2 ESPECIALISTA MEDICAMENTO ENFERMEDAD))   
 )



;################################################## 
;##################### INIT #######################
;##################################################
;(Inicializa lo renecesario para poder leer del teclado y guardarlo)
(defrule arranqueSistema
  (or(toString2 $? ?)(toString_NVL $? ?))
  (not(Hojas $?))
  =>
   ;Input
   (assert (userInput))
   (assert (READ_MODE INIT)) ;(ControlFlow)
  
   ;(Sintomas seleccionados)
   (assert (Hojas))
)



;##################################################
;##################### HUD ########################
;##################################################
(defrule showHUD ;Muestra el encabezado del Hud.
  (userInput $?data)
  ?mode<-(READ_MODE INIT)
  =>
  (clear-window)

  (printout t "De los siguientes sintomas, ¿cuáles tiene?:" crlf);  
  (printout t "=======================" crlf);  

  (retract ?mode)
  (assert(READ_MODE showHojas))
)

;---------------- ENLISTA SINTOMAS ----------------
(defrule showEveryHoja ;Muestra (sin marcar) los sintmas no se seleccionados
  (READ_MODE showHojas)
  (Nodo (nivel ?) (nombre ?hojaX) (subNodos)) ;SER-HOJA
  (not(userInput $?  ?hojaX $?))
  => 
  (printout t ?hojaX crlf);  
)
(defrule showEveryHoja-selectedOnes ;Muestra y marca los sintomas seleccionados
  (READ_MODE showHojas)

  (Nodo (nivel ?) (nombre ?hojaX) (subNodos)) ;SER-HOJA
  (userInput $?  ?hojaX $?)
  => 
  (printout t "[#]"?hojaX"" crlf); ;(Marca hoja/sintoma seleccionado)
)

;----------------------- END ----------------------
(defrule showHUD-end ;Da info extra sobre el hud. 
  (userInput $?data)
  ?mode<-(READ_MODE showHojas)
  (not(errNoInput))
  =>
  (retract ?mode)
  (assert (READ_MODE ON))
  (printout t "=======================" crlf);  
  (printout t "(Para terminar, escriba en una nueva linea: end) " crlf);  
  (printout t "(Vuelva a escribir un sintoma para borralo)" crlf);  
  (printout t "=======================" crlf);  
  
  (if (> (length$ $?data) 0)
    then 
    (printout t "**SUS SINTOMAS SON: "  $?data crlf);  
    (printout t "=======================" crlf);  
  )

)
(defrule showHUD-end-errNoInput ;Salta un "error" si tratas de salir sin tener, al menos, un sintoma seleccionado.
  (userInput $?data)
  ?mode<-(READ_MODE showHojas)
  ?err<-(errNoInput)
  =>
  (retract ?mode ?err)
  (assert (READ_MODE ON))
  
  (printout t "=======================" crlf);  
  (printout t "(Para terminar, escriba en una nueva linea: end) " crlf);  
  (printout t "(Vuelva a escribir un sintoma para borralo)" crlf);  
  (printout t "=======================" crlf);  
 
  (if (> (length$ $?data) 0)
    then 
    (printout t "**SUS SINTOMAS SON: "  $?data crlf);  
    (printout t "=======================" crlf);  
  )

  (printout t "**[Error!: Introduzca, al menos, un sintoma]**" crlf);  ;err
)



;################################################## 
;#################### READ-INPUT ##################
;##################################################
(defrule readInput ;Lee lo escrito por teclado y verifica si se ha puesto 'end' para hacer el calculo.
   ?mode<-(READ_MODE ON)
   ?usr<-(userInput $?data)
   =>
   (retract ?mode)
   (printout t "Sintomas: ");
   (bind ?lineInput (upcase (readline)))

   (if (symbolp (str-index "END" ?lineInput)) ;(si se escribe 'end' en alguna parte de una misma linea, el resto se descarta)
      then
         (assert (READ_MODE ON-CHECK))
         (assert (newLine (explode$ ?lineInput))) ;Permite agregar multiples sintomas en una sola linea 
      else
        (clear-window)
        (if (> (length$ $?data) 0)
          then
          (assert (READ_MODE END))
          (printout t "Sintomas: " crlf)
          else 
          (assert (READ_MODE INIT)) 
          (assert (errNoInput))
        ) 
   )
)

;------------------ CHECK-INPUT -------------------
(defrule checkInput-removeRepe ;Si se vuelve seleccionar un sintoma ya seleccionado: lo borra.
  (READ_MODE ON-CHECK)
  ?line<-(newLine $?i1 ?input $?i2)
  ?usr<-(userInput $?ui1 ?input $?ui2)
  =>
  (retract ?line ?usr)
  (assert (userInput $?ui1 $?ui2))
  (assert (newLine $?i1 $?i2))     
  ;;DEBUG ONLY;; (printout t "REPE_Input: "?input crlf) ;;DEBUG ONLY;;
)
(defrule checkInput-addNew ;Si existe, agrega un nuevo sintoma a lista.
  (READ_MODE ON-CHECK)
  ?line<-(newLine $?i1 ?input $?i2)
  (not(userInput $?ui1 ?input $?ui2))

  (Nodo (nivel ?) (nombre ?input) (subNodos)) ;SER-HOJA
  ?usr<-(userInput $?data)
  =>
  (retract ?line ?usr)
  (assert (userInput $?data ?input))
  (assert (newLine $?i1 $?i2))      
  ;;DEBUG ONLY;; (printout t "NEW_Input: "?input crlf) ;;DEBUG ONLY;;
)
(defrule checkInput-discardNotPosibleOpcion ;Borra los imputs que no son sintomas/opciones a elegir
  (READ_MODE ON-CHECK)
  ?line<-(newLine $?i1 ?input $?i2)
  (not(userInput $?ui1 ?input $?ui2))

  (not(Nodo (nivel ?) (nombre ?input) (subNodos)) ) ;NOT_SER-HOJA
  =>
  (retract ?line)
  (assert (newLine $?i1 $?i2))        
  ;;DEBUG ONLY;; (printout t "NEW_Input: "?input crlf) ;;DEBUG ONLY;;
)

;-------------------- END-INPUT -------------------
(defrule checkInput-end
  ?mode<-(READ_MODE ON-CHECK)
  ?line<-(newLine) ;esta vacia
  => 
  (retract ?mode ?line)
  (assert (READ_MODE INIT))
)

;-------------------- SAVE INPUT  -----------------
(defrule printInput-start ;Mientras se muestran por pantalla, mete uno a uno los sintomas seleccionados en 'Hojas' para su posterior computo
   (READ_MODE END)
   ?i<-(userInput ?x $?xlist)
   ?h<-(Hojas $?hl)
   =>
   (retract ?i ?h)
   (assert (userInput $?xlist) (Hojas $?hl ?x))
   (printout t "=> " ?x crlf)
  )
(defrule printInput-end
  ?mode<-(READ_MODE END)
  (not(userInput ?))
  =>
  (retract ?mode)
)



;################################################## 
;############### CALCULO DE PESOS #################
;##################################################
;-------------------- NO HOJAS --------------------
;Para nodos que no son "hoja"
(defrule calculaPesoCTE-NO-Hojas
  (Hojas $?)
  (not(READ_MODE ?))

  ?n<-(Nodo (nivel ?superN) (nombre ?nodeName) (subNodos $?subNodosList ?lastHijo) (pesoCTE 0.0)) ;no__SER-HOJA (tener hijos)
  =>
  (bind ?pCTE  (/ 1 (+ (length$ $?subNodosList) 1) )) ;(+1 por el ?lastHijo, usado para verificar que no se trata de una hoja)
  (modify ?n (pesoCTE ?pCTE))  ; Calculo del 'PesoPropio' (o peso de cada SubNodo activo)
  ;;DEBUG ONLY;;  (printout t "["?superN"-pesoCTE] " ?nodeName ":  "  ?pCTE crlf) ;;DEBUG ONLY;;
)

;----------------- HOJAS (ON/OFF) -----------------
;Init-Peso-Hojas = [+1.0] (activas) / [-0.0000001] (noActivas) = pesoCTE (tb. instancia 'pesoCTE' para que 'calculaPesoCTE-end' se pueda ejecutar)
(defrule initPesos__Hojas_ON
 (Hojas $?)
 (not(READ_MODE ?))
 (Hojas $? ? $?)

 ?hoja<-(Nodo (nivel ?superN) (nombre ?nameHoja) (subNodos) (pesoAcumulado 0.0)) ;SER-HOJA
 (Hojas $? ?nameHoja $?) ;(esta seleccionada)
  =>
  (modify ?hoja (pesoCTE 1.0) (pesoAcumulado 1.0))
  ;;DEBUG ONLY;;  (printout t "(hoja)["?nameHoja"_ON]" crlf) ;;DEBUG ONLY;;
)
(defrule initPesos__Hojas_OFF
  (Hojas $?)
  (not(READ_MODE ?))
  (Hojas $? ? $?)
  
  ?hoja<-(Nodo (nivel ?superN) (nombre ?nameHoja) (subNodos) (pesoAcumulado 0.0)) ;SER-HOJA
  (not(Hojas $? ?nameHoja $?)) ;(no estar seleccionada)
  =>
  (modify ?hoja (pesoCTE -0.0000001) (pesoAcumulado -0.0000001))
  ;;DEBUG ONLY;;  (printout t "(hoja)["?nameHoja"_OFF]" crlf) ;;DEBUG ONLY;;
)

;------------------ END CALCULO -------------------
(defrule calculaPesoCTE-end
  (Hojas $?)
  (not(READ_MODE ?))
  (not (Orden (state ON))) ; PX SI NO, EJECUTA DOS VECES ESTA REGLA POR ALGUNA RAZON QUE DESCONOZCO
  (not (Nodo (pesoCTE 0.0)))

  ?hoja<-(Orden (superNodo ?superN_2) (subNodo ?superN_2))                  
  ?o_1<-(Orden (superNodo ?superN_1&~?superN_2) (subNodo ?superN_2))
  =>
  (modify ?o_1 (state ON)) ;Activa el recuentoIncremental por los "padres" de las "hojas" del arbol.
 ;;DEBUG ONLY;; (printout t "[UpperHojas_Lvl]: " ?superN_1 crlf) ;;DEBUG ONLY;;
 ;;DEBUG ONLY;; (printout t "[Hojas_Lvl]: " ?superN_2 crlf) ;;DEBUG ONLY;;
)



;##################################################
;################ PROB. ACUMULADA #################
;##################################################
;(OJO: Empieza por los nodos "padre" de las "hojas" (no empieza por las hojas; su probAcum depende de si existen o no))
(defrule calculaIncrementos
  (not(READ_MODE ?))
  (Orden (superNodo ?superN_1)  (subNodo ?subN_2&~?superN_1) (state ON))
  ?n_1<-(Nodo (nivel ?superN_1) (nombre ?nodeName_1)  (pesoCTE ?pesoCTE_1) (pesoAcumulado ?pAcum_1) (subNodos ?subN_1 $?restoNodos)) ; "Padre"
  ?n_2<-(Nodo (nivel ?subN_2)   (nombre ?subN_1)                           (pesoAcumulado ?pAcum_2) )                                ; "Hijo"
  =>
  (modify ?n_1 (subNodos $?restoNodos))
  (if (> ?pAcum_2 0) 
    then 
      (modify ?n_1 (pesoAcumulado (+ ?pAcum_1 (* ?pesoCTE_1 ?pAcum_2))) )
  )
)



;##################################################
;################ CAMBIO DE NIVEL #################
;##################################################
(defrule cambio-Nivel ;(Hijo--->Padre)
  (not(READ_MODE ?))
  ?o_2<-(Orden (superNodo ?superN_2) (subNodo ?subN_3&~?superN_2) (state ON))   ; "Hijo"
  (not(Nodo (nivel ?superN_2)  (subNodos ?subN_2 $?restoNodos)))                ; ===>  si todos los nodos de un nivel tienen su lista de subnodos Vacia, se cambia de nivel. 
  ?o_1<-(Orden (superNodo ?superN_1) (subNodo ?superN_2))                       ; "Padre"
  =>
  (modify ?o_2 (state OFF))
  (modify ?o_1 (state ON))
)
(defrule cambio-Nivel-END
  (not(READ_MODE ?))
  (not(ProgramOver TRUE))

  ?o_2<-(Orden (superNodo ?superN_2) (subNodo ?subN_3&~?superN_2) (state ON))       
  (not(Nodo (nivel ?superN_2)  (subNodos ?subN_2 $?restoNodos)))  
  (not(Orden (superNodo ?superN_1) (subNodo ?superN_2)))  ;Si ha alcanzando el nivel maximo y todos sus nodos 
                                                          ;tienen su lista de subnodos Vacia (por el incremento de su prob.)=>PROGRAM-OVER   
  =>                                                      
  (assert (ProgramOver TRUE))  
  (assert (ProgramOver TO-STRING))    
  (printout t  crlf crlf);  
) 



;################################################## 
;############## RESULTADOS toString ###############
;##################################################
;------------------ DEBUGG-ONLY -------------------
;Muestra las probabilidades para cada nodo (DEBUGG-ONLY)
(defrule toString
  (not(READ_MODE ?))
  (ProgramOver TO-STRING)
  (Nodo (nivel ?nvlX)(nombre ?nodeNameX) (pesoAcumulado ?pAcumX))
  (toString_NVL $? ?nvlX $?)                                      ;<=== Permite conocer la probAcumulada de los nodos en funcion de su nivel/Orden
  =>
  (printout t "Prob. "?nodeNameX "["?nvlX"]:  " ?pAcumX crlf crlf);  
)

;-------------- SOLO MAS PROBABLES ----------------
;Por cada nivel (en 'toString2'), muestra el nodo con mayor probabilidad (en caso de haber 2 o mas nodos del mismo nivel y equiprobables,
;por defecto, solo muestra el primero, pero se puede modificar anulando ciertas lineas para que lo haga)
(defrule showResult-start 
  (not(READ_MODE ?))
  (ProgramOver TRUE)
  =>
  (assert (toString2-done ))
  (printout t crlf crlf "====================================" crlf); 
)
(defrule getNivelMasProbable
  (toString2 $? ?nivelX $?)
  (not(toString2-done $? ?nivelX $?))

  (Nodo (nivel ?nivelX) (nombre ?nodoX) (pesoAcumulado ?p1))
  (not (Nodo (nivel ?nivelX) (pesoAcumulado ?p2&:(> ?p2 ?p1))))
  
  ?strdone<-(toString2-done $?doneList)          ;;Si se habilita, solo muesta la primera opcion mas probable;;
  =>
  (retract ?strdone)                             ;;Si se habilita, solo muesta la primera opcion mas probable;;
  (assert (toString2-done $?doneList ?nivelX))   ;;Si se habilita, solo muesta la primera opcion mas probable;;

  (assert (topNivel ?nivelX ?nodoX ?p1))
)
(defrule showResult-end
  ?m<-(topNivel ?nivelX ?nodoX ?prob)
  (not(topNivel ?nivelX))
  =>
  (retract ?m)                                   ;;Si se habilita, solo muesta la primera opcion mas probable;;
  (printout t ?nivelX ": " ?nodoX     "  ("?prob")" crlf);  
  (printout t "====================================" crlf); 
)

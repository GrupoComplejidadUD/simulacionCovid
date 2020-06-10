__includes["utils.nls" "BaseDatosOperaciones.nls" "metodosCreacion.nls" "moverPoblacion.nls" "funcionesDistribucion.nls" "hospitales.nls"]

extensions [
  py ; extension ejecutar python desde netlogo
]


breed [personas persona]
breed [buses bus]
breed [casas casa]
breed [lugares lugar]
breed [vehiculos vehiculo]
breed [hospitales hospital]
breed [cementerios cementerio]

personas-own
  [ infectada?                ;; si es true, la persona esta infectada
    asintomatica?             ;; si es true, la persona esta infectada pero es asintomatica
    infeccioso?               ;; si es true, puede infectar a otras personas
    restante-serInmune        ;; Cuantos dias de inmunidad ha dejado la persona
    tiempo-infectado          ;; cuanto tiempo, en dias, la persona ha estado infectada
    coordenadaCasa            ;; coordenadas de la casa
    coordenadaVehiculo        ;; coordenadas del vehiculo
    estacionCercana           ;;
    lugarPosicion             ;; Lugar en el que esta en x momento
    lugarInfeccion            ;;
    tiempoPromedioViajeAlTrabajo       ;;
    tiempoPromedioViajeACasa      ;;
    tiempoPromedioViajeAlTrabajoValor       ;;
    tiempoPromedioViajeACasaValor
    irAEstacion?              ;; Para indicar cuando debe volver a casa
    alTrabajo?                ;;
    volverACasa?              ;;
    enCasa?
    confinado?                ;;
    tiempoInternoLatencia     ;; tiempo que tiene el infectado para volverse contagioso
    vehiculoPropio?           ;; si tiene vehiculo propio
    irAlVehiculo?
    aleatorioProbabilidaInfectar
    aleatorioProbabilidadMorir
    aleatorioProbabilidaContacto
    estratoSocial
    nivelEnfermedad           ;; leve, grave o critico
    contacto_otros
    muerto
    ocupacion                 ;; estudiante, trabajador o jubilado
    sexo                      ;; sexo de la persona
    edad ]                    ;; Edad de la persona

globals
  [ %infectados              ;; que % de la poblacion esta infectada
    %inmune                  ;; que % de la poblacion es inmune
    esperanzaVida            ;; Esperanza de vida de la persona
    oportunidad-reproduccion ;; la probabilidad de una persona de generar descendencia cada tick
    capacidad-mundo          ;; Numero de personas en el mundo
    muertos                  ;; Numero de muertos
    numeroCamasUCI
    contagiados              ;; Numero de contagiados
    horaActual               ;; hora en formato 24h
    areaTipo                 ;; Area tipo 1, 2, 3 o 4
    maxX                     ;; maximo valor de X
    maxY                     ;; maximo valor de Y
    listaLugaresParaIr       ;; Lista de los lugares a los que puede ir una persona
    listaAtributosPersona    ;; Lista atributos para obtener variables del agente persona
    insertarDatos?           ;;
    variableEdad             ;; 365 dias por 24 horas por 60 minutos
    duracion-inmunidad ]     ;; Cuantas semanas dura la inmunidad

to setup
  clear-all
  set insertarDatos? true
  py:setup py:python ; ejemplificar python en py
  (py:run "from moduloPython import *")
  set listaAtributosPersona [ "infectada?" "asintomatica?" "restante-serInmune" "tiempo-infectado" "coordenadaCasa" "edad" "sexo" "ocupacion" "confinado?" "tiempoPromedioViajeAlTrabajoValor" "tiempoPromedioViajeACasaValor" "vehiculoPropio?" "estratoSocial" "nivelEnfermedad" "lugarInfeccion" "muerto"]
  (py:run "resetDataBase('dias')")
  setup-constantes
  setup-personas
  actualizar-variables-globales
  update-display
  reset-ticks
end

;; Creamos un numero de infectados el cual es de 10 y son distribuidas aleatoriamente
to setup-personas
  set maxX max-pxcor
  set maxy max-pxcor
  set areaTipo 1

  crearPersonas
  crearEstaciones
  crearLugares
  crearHospital
  crearCementerio

  ask n-of numeroInfectados personas [
    set tiempoInternoLatencia 0 ;; las personas infectadas desde el dia 0 son infecciosas
    get-infeccion-setup
  ]

  crearPersonasConVehiculoPropio
  crearVehiculos
  distribuirEnCasasYVehiculos
  crearCasasConfinamiento

end

to-report getTiempoPromedioViaje
  report (random (90 - 30) + 30)
end

to get-infeccion
  set infectada? true
  set lugarInfeccion lugarPosicion
  let probabilidadSerAsintomatico random-float 100
  if probabilidadSerAsintomatico < %infectadosAsintomaticos
  [
    set asintomatica? true
  ]
  set restante-serInmune 0
  set contagiados contagiados + 1
end

to get-infeccion-setup
  set infectada? true
  let probabilidadSerAsintomatico random-float 100
  if probabilidadSerAsintomatico < %infectadosAsintomaticos
  [
    set asintomatica? true
  ]
  set lugarInfeccion "sin definir"
  set restante-serInmune 0
  set contagiados contagiados + 1
end

to get-saludable
  set infectada? false
  set asintomatica? false
  set restante-serInmune 0
  set tiempo-infectado 0
end

to curarse
  set infectada? false
  set asintomatica? false
  set tiempo-infectado 0
  set restante-serInmune duracion-inmunidad
end

;; Configuracion constantes del modelo
to setup-constantes
  set esperanzaVida 75 * 365 * 24 * 60     ;;
  set capacidad-mundo 1000
  set oportunidad-reproduccion 1
  set duracion-inmunidad 52 * 24 * 60
  set muertos 0
  set numeroCamasUCI camasUCI
  set contagiados 0
  set variableEdad 365 * 24 * 60 ; 365 dias por 24 horas por 60 minutos para llevar a unidades de tick
end

to go
  set horaActual getHora
  let hora item 0 horaActual
  let minuto item 1 horaActual
  ask personas [
    if hora = 0 and minuto = 0 [nuevoDiaReset]
    if not confinado? and nivelEnfermedad = "ninguno" and not muerto
    [moverse]
    get-edad
    if infectada? [
      if tiempoInternoLatencia = 0 [set infeccioso? true]
      set tiempoInternoLatencia tiempoInternoLatencia - 1
      if hora = 0 and minuto = 1 [recuperarse-o-morir] ;; una vez al dia se evalua la posibilidad de morir
    ]
    ifelse infectada? and infeccioso? [infectar ] [ ];;reproducir ]
  ]
  if hora = 0 and minuto = 0 [guardarDiaBaseDatos]
  if hora = 23 and minuto = 58 [guardarDatosDia "fin"]
  actualizar-variables-globales
  update-display
  tick
end

to actualizar-variables-globales
  if count personas > 0
    [ set %infectados (count personas with [ infectada? ] / count personas) * 100
      set %inmune (count personas with [ immune? ] / count personas) * 100 ]
end

to update-display
  ask personas
    [ set color ifelse-value infectada?
      [ ifelse-value asintomatica?
        [white]
        [red]
      ]
      [ ifelse-value immune?
        [ grey ]
        [ green ]
      ]
     ]
end

to get-edad
  ;; Las personas mueren de viejas si sobrepasan la esperanza de vida
  set edad edad + 0.000011415525 / 60 ; (1 /365) / 24 / 60
  if edad > esperanzaVida [ ircementerio ]
  if immune? [ set restante-serInmune restante-serInmune - 1 ]
  if infectada? [ set tiempo-infectado tiempo-infectado + 1 ]
end

to nuevoDiaReset
  set insertarDatos? true
  set volverACasa? false
  set alTrabajo? true
  ifelse vehiculoPropio? [
    set irAEstacion? false
    set irAlVehiculo? true
  ]
  [
    set irAEstacion? true
  ]
  set enCasa? false
  set tiempoPromedioViajeACasa getTiempoPromedioViaje
  set tiempoPromedioViajeAlTrabajo getTiempoPromedioViaje
  set tiempoPromedioViajeACasaValor getTiempoPromedioViaje
  set tiempoPromedioViajeAlTrabajoValor getTiempoPromedioViaje
  set aleatorioProbabilidaInfectar random-float 100
  set aleatorioProbabilidadMorir random-float 100
  set aleatorioProbabilidaContacto random-float 100

end

;; si una persona esta infectada, infectara a otras personas en el mismo patch. Las personas inmunes no se infectan
to infectar
    ask other personas-here with [ not infectada? and not immune? ]
    [
    let probabilidadInteraccionLugar getProbabilidadContacto
    if aleatorioProbabilidaContacto < probabilidadInteraccionLugar
    [
      if aleatorioProbabilidaInfectar < infeccioso
      [ get-infeccion ] ]
    ]
end

to-report getProbabilidadContacto
  if lugarPosicion = "transporte" [report %probabilidadContactoTransporte ]
  if lugarPosicion = "trabajo" [ report %probabilidadContactoTrabajo ]
  report 3 ;; probabilidad de interactuar en otro lugar diferente al trabajo o transporte ??? DEFINIR
end

;;Una vez que la persona ha estado enferma, o se recupera(volviendose inmune) o muere
to recuperarse-o-morir
  if lugarPosicion = "hospital" [set aleatorioProbabilidadMorir (aleatorioProbabilidadMorir / 10)]
  if aleatorioProbabilidadMorir < getProbabilidadMorir edad
  [ ;show ((edad / 60) / 24)/ 365
    ;show aleatorioProbabilidadMorir
    ;show getProbabilidadMorir edad
    if lugarPosicion = "hospital" [
      set numeroCamasUCI numeroCamasUCI + 1
    ]
    ircementerio
  ]

  if tiempo-infectado > duracionVirus * 24 * 60     ;; si la persona ha sobrevivido la duracion del virus, entonces se cura y se mueve a la casa
  [
    if lugarPosicion = "hospital" [
      set numeroCamasUCI numeroCamasUCI + 1
      setxy item 0 coordenadaCasa item 1 coordenadaCasa
      set lugarPosicion "casa"
    ]
    curarse
    set nivelEnfermedad "ninguno"
    let casaHospital casas-on patch-ahead 0
    ask casaHospital [
        set color white
    ]
  ]

end

to ircementerio
  set muerto true
  let lugarCementerio min-n-of 1 cementerios [distance myself]
  move-to one-of lugarCementerio
  set muertos muertos + 1
  ask cementerios [set label muertos]
end
;; Si hay menos personas que la capacidad permitida del mundo, las persona se reproducen
to reproducir
  if count personas < capacidad-mundo and random-float 100 < oportunidad-reproduccion
    [ hatch 1
      [ set edad 1
        lt 45 fd 1
        get-saludable ] ]
end

to-report immune?
  report restante-serInmune > 0
end

to-report getHora
  let minutos ticks
  let horas int (ticks / 60)
  if minutos >= 60
  [ set minutos minutos mod 60]
  let dia horas / 24
  if horas >= 24
  [set horas horas mod 24]

  report (list horas minutos int dia)
end
; Copyright 2020 Carlos Daza
; based on the virus simulation created by Uri Wilensky
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
365
10
1283
929
-1
-1
14.0
1
10
1
1
1
0
0
0
1
-32
32
-32
32
1
1
1
ticks
30.0

SLIDER
35
150
227
183
duracionVirus
duracionVirus
0.0
99.0
14.0
1.0
1
dias
HORIZONTAL

SLIDER
35
100
229
133
infeccioso
infeccioso
0.0
99.0
11.0
1.0
1
%
HORIZONTAL

BUTTON
35
675
105
710
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
111
675
182
711
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
1340
180
1592
344
Poblacion
Horas
Personas
0.0
52.0
0.0
200.0
true
true
"" ""
PENS
"Infectada" 1.0 0 -2674135 true "" "plot count personas with [ infectada? ]"
"Inmune" 1.0 0 -7500403 true "" "plot count personas with [ immune? ]"
"Saludable" 1.0 0 -10899396 true "" "plot count personas with [ not infectada? and not immune? ]"
"total" 1.0 0 -13345367 true "" "plot count personas"

SLIDER
35
10
229
43
numero-personas
numero-personas
10
capacidad-mundo
447.0
1
1
NIL
HORIZONTAL

MONITOR
1340
15
1433
60
NIL
%infectados
1
1
11

MONITOR
1440
15
1514
60
NIL
%inmune
1
1
11

MONITOR
1520
15
1594
60
dias
ticks / 60 / 24
1
1
11

MONITOR
1410
70
1497
115
No Muertes
muertos
17
1
11

MONITOR
1340
70
1397
115
Hora
horaActual
17
1
11

SLIDER
35
195
237
228
tiempoLatencia
tiempoLatencia
0
10
0.0
1
1
dias
HORIZONTAL

SLIDER
35
240
222
273
%confinamiento
%confinamiento
0
100
1.0
1
1
%
HORIZONTAL

SLIDER
35
415
227
448
%vehiculoPropio
%vehiculoPropio
0
100
1.0
1
1
%
HORIZONTAL

SLIDER
35
455
297
488
%infectadosAsintomaticos
%infectadosAsintomaticos
0
100
80.0
1
1
%
HORIZONTAL

MONITOR
1465
125
1592
170
No Asintomaticos
count personas with [asintomatica? = true]
17
1
11

MONITOR
1340
125
1442
170
No Infectados
count personas with [infectada? = true]
17
1
11

SLIDER
35
495
337
528
%probabilidadContactoTransporte
%probabilidadContactoTransporte
0
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
35
540
312
573
%probabilidadContactoTrabajo
%probabilidadContactoTrabajo
0
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
35
55
222
88
numeroInfectados
numeroInfectados
0
100
11.0
1
1
NIL
HORIZONTAL

SLIDER
35
580
207
613
camasUCI
camasUCI
0
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
35
625
292
658
%probabilidadIrHospital
%probabilidadIrHospital
0.0
100.0
10.6
0.2
1
%
HORIZONTAL

MONITOR
1510
70
1592
115
Camas Uci
camasUCI
17
1
11

SLIDER
35
285
317
318
%confinamientoTrabajadores
%confinamientoTrabajadores
0
100
45.0
1
1
%
HORIZONTAL

SLIDER
35
325
307
358
%confinamientoEstudiantes
%confinamientoEstudiantes
0
100
50.0
1
1
%
HORIZONTAL

SLIDER
35
370
287
403
%confinamientoJubilados
%confinamientoJubilados
0
100
50.0
1
1
%
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model simulates the transmission and perpetuation of a virus in a human population.

Ecological biologists have suggested a number of factors which may influence the survival of a directly transmitted virus within a population. (Yorke, et al. "Seasonality and the requirements for perpetuation and eradication of viruses in populations." Journal of Epidemiology, volume 109, pages 103-123)

## HOW IT WORKS

The model is initialized with 150 people, of which 10 are infected.  People move randomly about the world in one of three states: healthy but susceptible to infection (green), sick and infectious (red), and healthy and immune (gray). People may die of infection or old age.  When the population dips below the environment's "carrying capacity" (set at 300 in this model) healthy people may produce healthy (but susceptible) offspring.

Some of these factors are summarized below with an explanation of how each one is treated in this model.

### The density of the population

Population density affects how often infected, immune and susceptible individuals come into contact with each other. You can change the size of the initial population through the NUMBER-PEOPLE slider.

### Population turnover

As individuals die, some who die will be infected, some will be susceptible and some will be immune.  All the new individuals who are born, replacing those who die, will be susceptible.  People may die from the virus, the chances of which are determined by the slider CHANCE-RECOVER, or they may die of old age.

In this model, people die of old age at the age of 50 years.  Reproduction rate is constant in this model.  Each turn, if the carrying capacity hasn't been reached, every healthy individual has a 1% chance to reproduce.

### Degree of immunity

If a person has been infected and recovered, how immune are they to the virus?  We often assume that immunity lasts a lifetime and is assured, but in some cases immunity wears off in time and immunity might not be absolutely secure.  In this model, immunity is secure, but it only lasts for a year.

### Infectiousness (or transmissibility)

How easily does the virus spread?  Some viruses with which we are familiar spread very easily.  Some viruses spread from the smallest contact every time.  Others (the HIV virus, which is responsible for AIDS, for example) require significant contact, perhaps many times, before the virus is transmitted.  In this model, infectiousness is determined by the INFECTIOUSNESS slider.

### Duration of infectiousness

How long is a person infected before they either recover or die?  This length of time is essentially the virus's window of opportunity for transmission to new hosts. In this model, duration of infectiousness is determined by the DURATION slider.

### Hard-coded parameters

Four important parameters of this model are set as constants in the code (See `setup-constants` procedure). They can be exposed as sliders if desired. The turtles’ lifespan is set to 50 years, the carrying capacity of the world is set to 300, the duration of immunity is set to 52 weeks, and the birth-rate is set to a 1 in 100 chance of reproducing per tick when the number of people is less than the carrying capacity.

## HOW TO USE IT

Each "tick" represents a week in the time scale of this model.

The INFECTIOUSNESS slider determines how great the chance is that virus transmission will occur when an infected person and susceptible person occupy the same patch.  For instance, when the slider is set to 50, the virus will spread roughly once every two chance encounters.

The DURATION slider determines the number of weeks before an infected person either dies or recovers.

The CHANCE-RECOVER slider controls the likelihood that an infection will end in recovery/immunity.  When this slider is set at zero, for instance, the infection is always deadly.

The SETUP button resets the graphics and plots and randomly distributes NUMBER-PEOPLE in the view. All but 10 of the people are set to be green susceptible people and 10 red infected people (of randomly distributed ages).  The GO button starts the simulation and the plotting function.

The TURTLE-SHAPE chooser controls whether the people are visualized as person shapes or as circles.

Three output monitors show the percent of the population that is infected, the percent that is immune, and the number of years that have passed.  The plot shows (in their respective colors) the number of susceptible, infected, and immune people.  It also shows the number of individuals in the total population in blue.

## THINGS TO NOTICE

The factors controlled by the three sliders interact to influence how likely the virus is to thrive in this population.  Notice that in all cases, these factors must create a balance in which an adequate number of potential hosts remain available to the virus and in which the virus can adequately access those hosts.

Often there will initially be an explosion of infection since no one in the population is immune.  This approximates the initial "outbreak" of a viral infection in a population, one that often has devastating consequences for the humans concerned. Soon, however, the virus becomes less common as the population dynamics change.  What ultimately happens to the virus is determined by the factors controlled by the sliders.

Notice that viruses that are too successful at first (infecting almost everyone) may not survive in the long term.  Since everyone infected generally dies or becomes immune as a result, the potential number of hosts is often limited.  The exception to the above is when the DURATION slider is set so high that population turnover (reproduction) can keep up and provide new hosts.

## THINGS TO TRY

Think about how different slider values might approximate the dynamics of real-life viruses.  The famous Ebola virus in central Africa has a very short duration, a very high infectiousness value, and an extremely low recovery rate. For all the fear this virus has raised, how successful is it?  Set the sliders appropriately and watch what happens.

The HIV virus, which causes AIDS, has an extremely long duration, an extremely low recovery rate, but an extremely low infectiousness value.  How does a virus with these slider values fare in this model?

## EXTENDING THE MODEL

Add additional sliders controlling the carrying capacity of the world (how many people can be in the world at one time), the average lifespan of the people and their birth-rate.

Build a similar model simulating viral infection of a non-human host with very different reproductive rates, lifespans, and population densities.

Add a slider controlling how long immunity lasts. You could also make immunity imperfect, so that immune turtles still have a small chance of getting infected. This chance could get higher over time.

## VISUALIZATION

The circle visualization of the model comes from guidelines presented in
Kornhauser, D., Wilensky, U., & Rand, W. (2009). http://ccl.northwestern.edu/papers/2009/Kornhauser,Wilensky&Rand_DesignGuidelinesABMViz.pdf.

At the lowest level, perceptual impediments arise when we exceed the limitations of our low-level visual system. Visual features that are difficult to distinguish can disable our pre-attentive processing capabilities. Pre-attentive processing can be hindered by other cognitive phenomena such as interference between visual features (Healey 2006).

The circle visualization in this model is supposed to make it easier to see when agents interact because overlap is easier to see between circles than between the "people" shapes. In the circle visualization, the circles merge to create new compound shapes. Thus, it is easier to perceive new compound shapes in the circle visualization.
Does the circle visualization make it easier for you to see what is happening?

## RELATED MODELS

* HIV
* Virus on a Network

## CREDITS AND REFERENCES

This model can show an alternate visualization of the Virus model using circles to represent the people. It uses visualization techniques as recommended in the paper:

Kornhauser, D., Wilensky, U., & Rand, W. (2009). Design guidelines for agent based model visualization. Journal of Artificial Societies and Social Simulation, JASSS, 12(2), 1.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (1998).  NetLogo Virus model.  http://ccl.northwestern.edu/netlogo/models/Virus.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 1998 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

This model was converted to NetLogo as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227. Converted from StarLogoT to NetLogo, 2001.

<!-- 1998 2001 -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

building store
false
0
Rectangle -7500403 true true 30 45 45 240
Rectangle -16777216 false false 30 45 45 165
Rectangle -7500403 true true 15 165 285 255
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 30 180 105 240
Rectangle -16777216 true false 195 180 270 240
Line -16777216 false 0 165 300 165
Polygon -7500403 true true 0 165 45 135 60 90 240 90 255 135 300 165
Rectangle -7500403 true true 0 0 75 45
Rectangle -16777216 false false 0 0 75 45

bus
false
0
Polygon -7500403 true true 15 206 15 150 15 120 30 105 270 105 285 120 285 135 285 206 270 210 30 210
Rectangle -16777216 true false 36 126 231 159
Line -7500403 false 60 135 60 165
Line -7500403 false 60 120 60 165
Line -7500403 false 90 120 90 165
Line -7500403 false 120 120 120 165
Line -7500403 false 150 120 150 165
Line -7500403 false 180 120 180 165
Line -7500403 false 210 120 210 165
Line -7500403 false 240 135 240 165
Rectangle -16777216 true false 15 174 285 182
Circle -16777216 true false 48 187 42
Rectangle -16777216 true false 240 127 276 205
Circle -16777216 true false 195 187 42
Line -7500403 false 257 120 257 207

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

cemetery
false
0
Rectangle -7500403 true true 45 195 75 270
Rectangle -7500403 true true 225 195 255 270
Rectangle -7500403 true true 90 105 210 270
Circle -7500403 true true 90 45 120
Rectangle -1 true false 135 105 165 210
Rectangle -1 true false 105 135 195 165

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

factory
false
0
Rectangle -7500403 true true 76 194 285 270
Rectangle -7500403 true true 36 95 59 231
Rectangle -16777216 true false 90 210 270 240
Line -7500403 true 90 195 90 255
Line -7500403 true 120 195 120 255
Line -7500403 true 150 195 150 240
Line -7500403 true 180 195 180 255
Line -7500403 true 210 210 210 240
Line -7500403 true 240 210 240 240
Line -7500403 true 90 225 270 225
Circle -1 true false 37 73 32
Circle -1 true false 55 38 54
Circle -1 true false 96 21 42
Circle -1 true false 105 40 32
Circle -1 true false 129 19 42
Rectangle -7500403 true true 14 228 78 270

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

hospital
false
0
Rectangle -1 true false 270 120 285 255
Rectangle -1 true false 15 180 270 255
Polygon -1 true false 0 180 300 180 240 135 60 135 0 180
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 45 195 105 240
Rectangle -16777216 true false 195 195 255 240
Line -7500403 true 75 195 75 240
Line -7500403 true 225 195 225 240
Line -16777216 false 270 180 270 255
Line -16777216 false 0 180 300 180
Circle -2674135 true false 97 37 134
Rectangle -1 true false 150 45 165 150
Rectangle -1 true false 105 90 210 105

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

house efficiency
false
0
Rectangle -7500403 true true 180 90 195 195
Rectangle -7500403 true true 90 165 210 255
Rectangle -16777216 true false 165 195 195 255
Rectangle -16777216 true false 105 202 135 240
Polygon -7500403 true true 225 165 75 165 150 90
Line -16777216 false 75 165 225 165

house ranch
false
0
Rectangle -7500403 true true 270 120 285 255
Rectangle -7500403 true true 15 180 270 255
Polygon -7500403 true true 0 180 300 180 240 135 60 135 0 180
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 45 195 105 240
Rectangle -16777216 true false 195 195 255 240
Line -7500403 true 75 195 75 240
Line -7500403 true 225 195 225 240
Line -16777216 false 270 180 270 255
Line -16777216 false 0 180 300 180

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@

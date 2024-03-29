globals [
  ; CONSTANTS

  btn-width
  btn-height
  world-size-w
  world-size-h

  ; VARIABLES

  setup?
  page
  pageLoad
  buttons
  m-down?
  click?

  animation
  brush-turtle
  draw-color
  erase?
  frame-turtle
]

patches-own [ previous-frame? ]

to toggle-previous
  if setup? = true [
  ask patches [
    if previous-frame? = true
    [
      ifelse pcolor = 2.9
      [set pcolor 0]
        [
      if pcolor = 0
        [set pcolor 2.9]
        ]
    ]
  ]
  ]
end

to-report isWithin [ xp yp x y width height ]
  ifelse (xp >= x and xp <= (x + width)) and (yp >= y and yp <= (y + height))
  [ report true ]
  [ report false ]
end

to draw-rect [ x y w h c ]
  ask patches with [ pxcor >= x and pxcor <= x + w and pycor >= y and pycor <= y + h] [ set pcolor c ]
end

to clear-page
 ask patches [ set pcolor black ]
 set buttons []
 clear-turtles
end

to listen-btns
  foreach buttons [ btn ->
    let callback item 0 btn
    let x item 1 btn
    let y item 2 btn
    let name item 3 btn

    if click? = true and isWithin mouse-xcor mouse-ycor x y btn-width btn-height = true
    [
      print "Clicked Button!"
      run callback
    ]
  ]
end

to draw-text [ x y text ]
  crt 1 [
    set heading 0
    set label text
    set size 0
    setxy x y
  ]
end


to setup
  ca
  reset-ticks

  ; SET CONSTANTS

  set btn-width 40
  set btn-height 20
  set world-size-w 200
  set world-size-h 120

  ; SET MISC

  resize-world world-size-w * -1 world-size-w world-size-h * -1 world-size-h
  set-patch-size 2
  set page "MENU"
  set pageLoad "NONE"
  set buttons []
  set animation []
  set draw-color 9.9
  set erase? false
  set setup? true

  print "Finished Setup!"
end

to register-button [ onclick x y name ]
  print "Registering Button "
  print name
  ; onclick is a callback function

  let buttonObject (list onclick x y name)
  set buttons lput buttonObject buttons

  ; draw button
  draw-rect x y btn-width + length name btn-height red
  draw-text x + btn-width y + (btn-height / 2) name

end

to render-menu
  if page != pageLoad
  [
    print "Setting Up Menu"
    clear-page

    set pageLoad page
    ; register buttons
    register-button [[] -> ( set page "ANIMATOR" )] -20 0 "Animate!"
    register-button [[] -> ( set page "RENDER")] -20 -30 "Render!"
    register-button [[] -> (set page "GENERATOR")] -20 -60 "Generate!"

    draw-text 60 50 "SUPER NETLOGO ANIMATOR™"
    draw-text 30 40 "by randy3"
  ]

  listen-btns
end

to render-play
  if page != pageLoad
  [
    print "Setting up Play Page"
    clear-page

    set pageLoad page

    ; register buttons
    register-button [[] -> ( set page "MENU" )] world-size-w * -1 world-size-h - btn-height "BACK"
    register-button [[] -> ( play-animation )] world-size-w * -1 + btn-width * 1.2 world-size-h - btn-height "PLAY"
  ]

  listen-btns
end

to create-frame [ duplicate? ]
  print "Generating Frame"
  let x world-size-w * -1

  let frame (list world-size-w (world-size-h - btn-height)) ; width, height

  let prePixel 0 ; color of the previous pixel
  let running 0 ; how many colors of the pixel in a row

  ; OLD DATA FORMAT - save each pixel color
  ; new compressed pixel format - find patterns in repeating pixel colors and compress them as ( pixel-color, repeating-pixel-count )

  while [x <= world-size-w] [
    let y world-size-h * -1
    while [ y < world-size-h - btn-height ] [

      if [pcolor] of patch x y = 2.9 [ ask patch x y [ set pcolor black set previous-frame? false ] ]

      let pixelColor [pcolor] of patch x y

      ifelse pixelColor = prePixel
      [ set running running + 1 ]
      [
        ; add info of previous to frame
        set frame lput (list prePixel running) frame
        set prePixel pixelColor
        set running 1 ; THIS WAS MY DEMISE LOL. I SPENT 2 HOURS FIXING THIS BUG. this was initially "set running 0" and the whole drawing was messed up. I spent 2 hours looking for what went wrong until i realized i had to change 0 to 1.
      ]

      if [pcolor] of patch x y != 0
      [ ask patch x y [ if duplicate? = false [ set pcolor 2.9 ] set previous-frame? true ] ]

      set y y + 1
    ]

    set x x + 1
  ]

  ; put in remaining pixel data
  set frame lput (list prePixel running) frame
  set animation lput frame animation
  ask turtle frame-turtle [set label ( word "frame " length animation )]
end

to listen-animate
  ask turtle brush-turtle [
    set color draw-color
    setxy mouse-xcor mouse-ycor
  ]
  ifelse mouse-ycor < world-size-h - btn-height
  [
    if mouse-down? = true ; keeping it within drawing space
    [
      ; draw based on color n stuff
      ask patch mouse-xcor mouse-ycor [
        ifelse erase? = true
        [
          if pcolor != 2.9 [
            ifelse previous-frame? = true [ set pcolor 2.9 ] [ set pcolor 0 ]
          ]
        ]
        [ set pcolor draw-color ]

        ask neighbors [
          if pycor < world-size-h - btn-height
          [
            ifelse erase? = true
            [
              if pcolor != 2.9 [
                ifelse previous-frame? = true [ set pcolor 2.9 ] [ set pcolor 0 ]
              ]
            ]
            [ set pcolor draw-color ]
          ]
        ]
      ]
    ]
  ]
  [
    if mouse-xcor >= 60 and mouse-down? = true
    [
      set draw-color [ pcolor ] of patch mouse-xcor mouse-ycor
      set erase? false
    ]
  ]
end

to output-animation
  output-print animation
end

to play-animation
  print "playing animation"
  foreach animation [frame ->
    ask patches with [ pcolor != 0 and pycor < world-size-h - btn-height] [ set pcolor black ]

    let width item 0 frame
    let height item 1 frame


    let y 0
    let c 2

    while [ c < length frame ] [
      let batch item c frame ; [pixel-color, number-repeated]
      let pixColor item 0 batch
      let repeated item 1 batch

      ifelse pixColor != 0 [
        ; i completely forgot how this works pls don't try to understand it
        ;foreach batch [pix ->
         ; ask patch ((floor ((y - 2) / (world-size-h * 2) )) - 200) (((y - 2) mod (world-size-h * 2 - btn-height)) - world-size-h + btn-height) [ set pcolor pixColor ]
          ;set y y + 1
        ; ]
         ; ERROR batch is only 2 elements you have to make a while loop
        ; ERROR WHEN y is 0 then pycor is 97 for some reason

        let batchCounter 0
        while [ batchCounter < repeated ] [
          ; x -------------------------------------------------------  y -------------------------------------------------------------------
          ask patch ((floor (y / (world-size-h * 2 - btn-height) )) - world-size-w) ((y mod (world-size-h * 2 - btn-height)) - world-size-h)
          [ set pcolor pixColor ]

          set batchCounter batchCounter + 1
          set y y + 1
        ]


      ] [ set y y + repeated ]

      set c c + 1
    ]

    wait 1 / fps
  ]
end

to erase-toggle
  if setup? = true [
  set erase? not erase?
  ]
end

to clear-canvas
  ask patches with [pycor < world-size-h - btn-height ]
  [
    ifelse previous-frame? = true
    [ set pcolor 2.9 ]
    [ set pcolor black ]
  ]
end

to render-animator
  if page != pageLoad
  [
    print "Setting Up Animator"
    clear-page

    set pageLoad page

    register-button [[] -> ( set page "MENU" )] world-size-w * -1 world-size-h - btn-height "BACK"
    register-button [[] -> ( create-frame false )] world-size-w * -1 + btn-width * 1.2 world-size-h - btn-height "KEYFRAME"
    register-button [[] -> ( erase-toggle )] world-size-w * -1 + btn-width * 2.5 world-size-h - btn-height "ERASE"
    register-button [[] -> ( clear-canvas )] world-size-w * -1 + btn-width * 3.7 world-size-h - btn-height "CLEAR"
    register-button [[] -> ( create-frame true )] world-size-w * -1 + btn-width * 4.9 world-size-h - btn-height "DUPLICATE"

    ; render cursor
    crt 1 [
      set shape "hollow-circle"
      set size 5
      set color draw-color
      set brush-turtle who
    ]

    crt 1 [
      set size 0
      setxy world-size-w - 1 -1 * world-size-h + 1
      set label ( word "frame " length animation )
      set frame-turtle who
    ]

    ; render color-picker
    ask patches with [pxcor >= 60 and pycor >= world-size-h - btn-height] [set pcolor pxcor]
    ask patches with [previous-frame? = true] [ set pcolor 2.9 ]
  ]

  listen-btns

  ; animation drawing logic
  listen-animate
end

to render-generator
  if page != pageLoad
  [
    print "setting up generator page"
    clear-page

    set pageLoad page

    register-button [[] -> ( set page "MENU" )] world-size-w * -1 world-size-h - btn-height "BACK"
    register-button [[] -> ( output-animation )] -20 0 "Print"
  ]

  listen-btns
end

to go
  if setup? != true [
    draw-text 50 50 "LOADING..."
    setup
  ]

  if m-down? != mouse-down?
  [
    set m-down? mouse-down? ; prevent multiple clicks from registering for one click
    set click? m-down? ; click gets set to false later
  ]

  if page = "MENU"
  [
    render-menu
  ]

  if page = "ANIMATOR"
  [
    render-animator
  ]

  if page = "RENDER"
  [
    render-play
  ]

  if page = "GENERATOR"
  [
    render-generator
  ]

  set click? false
end
@#$#@#$#@
GRAPHICS-WINDOW
1047
10
1857
501
-1
-1
2.0
1
12
1
1
1
0
1
1
1
-200
200
-120
120
0
0
1
ticks
30.0

BUTTON
744
183
868
218
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
1

BUTTON
744
138
869
171
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

OUTPUT
689
245
929
299
11

SLIDER
764
338
936
371
fps
fps
1
30
10.0
1
1
NIL
HORIZONTAL

BUTTON
692
447
800
480
toggle erase
erase-toggle
NIL
1
T
OBSERVER
NIL
E
NIL
NIL
1

BUTTON
833
451
1038
484
Hide Previous Frame (space)
toggle-previous
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

A netlogo software to make animations using patches

## HOW IT WORKS

First you draw a frame, then it stores all the patches, then it compresses it, and adds it to a list. Then you draw another frame. After you draw all the frames, you can play it back.

## HOW TO USE IT

First click on setup. Then click on go. Then click on the animiate button in the model and start drawing. Once you are done drawing, click on keyframe to add the frame to your animiaton. You can click on dupliciate if you want to keyframe and have the same frame redrawn. If you want to change color click on the color palette. If you want to go back to home, click on back. If you want to start erasing, press on erase, and press clear to clear the entire frame. Once you are done keyframing, you can go to home and click on render. In the render page, you can press play and it will play the animation! now you can press back and you can click on generate and press print to output the animation data in the output box. 

## EXTENDING THE MODEL

- reading and writing text files to save the animation
- editing previous frames
- Better Compression ( possibly turning the list into a super compressed string to save even more ram allowing for more frames
- UI redesign
- undo and redo

## NETLOGO FEATURES

Netlogo can accept functions as parameters but it is quite weird.
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

hollow-circle
false
0
Circle -7500403 false true 33 33 234

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.1
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
0
@#$#@#$#@

;           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
;                   Version 2, December 2004
;
; Copyright (C) 2023 Matthias Gatto <uso.cosmo.ray@gmail.com>
;
; Everyone is permitted to copy and distribute verbatim or modified
; copies of this license document, and changing it is allowed as long
; as the name is changed.
;
;            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
;   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
;
;  0. You just DO WHAT THE FUCK YOU WANT TO.

(begin;; entry point
  (define mod_init
    (lambda (mod)
      (begin
	      (display "timest_dungeon INIT \n\n")
        (ywSizeCreate 800 600 mod "window size")
        (ygInitWidgetModule mod "timest_dungeon" (yeCreateFunction "tmst_init"))
        mod
      )
    )
  )

  (define get_sprite_pos
    (lambda (wid room pos)
      (yeGetInt(yeGet(yeGet(yeGet(yeGet wid "json") room) "sprite-pos") pos))
    )
  )

  (define get_stat
    (lambda (wid room stat)
      (yeGetInt(yeGet(yeGet(yeGet(yeGet wid "json") room) "stats") stat))
    )
  )

  (define hero_hp_bar
    (lambda (wid)
      (ywCanvasNewRectangle wid 0 300 100 100 "rgba: 0 0 0 255")
    )
  )

  (define tmst_action
    (lambda (wid events)
      (let ((str "Hello Action\n" ))
        (begin
          (display str)
          ;;
          ;;(ywCanvasMoveObjXY (yeGet wid "car") 1 0)
        )
      )
    )
  )

  (define tmst_init
    (lambda (wid unues_type)
      (let
        ((unused (yePushBack wid (ygFileToEnt YJSON "rooms.json") "json"))
        (x (get_sprite_pos wid "first" "x"))
        (y (get_sprite_pos wid "first" "y"))
        (w (get_sprite_pos wid "first" "w"))
        (h (get_sprite_pos wid "first" "h"))
        (enemy_max_hp (get_stat wid "first" "hp"))
        (enemy_atk (get_stat wid "first" "atk"))
        (enemy_def (get_stat wid "first" "def"))
        (enemy_crit (get_stat wid "first" "%crit"))
        (hp 10)
        (atk 4)
        (def 2)
        (crit 10))
        (begin
        (display "Hello world\n")
        (ywSetTurnLengthOverwrite 100000)
        (yeCreateFunction "tmst_action" wid "action")
        ;;(ywCanvasNewTextByStr wid 10 25 "test")
        (yePushBack wid (ywCanvasNewImg wid 0 0 "cave.jpg" (ywRectCreate 0 0 1000 1000)) "cave")
        (yePushBack wid (ywCanvasNewImg wid 200 230 "spritesheets/HeroesHero.png" (ywRectCreate 9 88 36 70)) "hero")
        (yePushBack wid (ywCanvasNewImg wid 550 (- 300 h)
                      (yeGetString(yeGet(yeGet(yeGet wid "json") "first") "enemy-img"))
                      (ywRectCreate x y w h)) "monster")
        (yePushBack wid (ywCanvasNewImg wid 350 400
                      "spritesheets/Clock.png"
                      (ywRectCreate 0 0 100 100)) "clock")
        (ywCanvasNewHSegment wid 0 300 1000 "rgba: 0 0 0 255")
        ;;(yePushBack wid (ywCanvasNewImg wid 100 100 "car.png" (ywRectCreate 100 100 100 100)) "car")
        ;; canvas widget, and set a white background
        ;; yaeString is like yeCreateString, but yeCreateString return the string,
        ;; and yae, it's parent
        (ywidNewWidget (yaeString "rgba: 255 255 255 255" wid "background") "canvas")
        )
      )
    )
  )
)
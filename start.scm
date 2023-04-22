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

  (define set_stat
    (lambda (wid room stat value)
      (yeReCreateInt value (yeGet(yeGet(yeGet wid "json") room) "stats") stat)
    )
  )

  (define add_stat
    (lambda (wid room stat value)
      (yeAddAt (yeGet(yeGet(yeGet wid "json") room) "stats") stat value)
      )
    )

  (define hero_hp_bar
    (lambda (wid)
      (let (
          (maxhp (get_stat wid "hero" "maxhp")) 
          (hp (get_stat wid "hero" "hp")) 
        )
        (begin
          (ywCanvasRemoveObj wid (yeGet wid "hero_bar_back"))
          (ywCanvasRemoveObj wid (yeGet wid "hero_bar_front"))
          (yePushBack wid (ywCanvasNewRectangle wid 176 198 108 16 "rgba: 0 0 0 255") "hero_bar_back")
          (yePushBack wid (ywCanvasNewRectangle wid 180 202 (round (/ 100 (/ maxhp hp))) 8 "rgba: 0 255 0 255") "hero_bar_front")
	  (display (/ 100 (/ maxhp hp)))
	  (display " <- bar l\n")
        )
      )
    )
  )  
  
  (define monster_hp_bar
    (lambda (wid)
      (letrec (
          (maxhp (get_stat wid "first" "maxhp")) 
          (hp (get_stat wid "first" "hp")) 
        )
        (begin

          (ywCanvasRemoveObj wid (yeGet wid "monster_bar_back"))
          (ywCanvasRemoveObj wid (yeGet wid "monster_bar_front"))
          (yePushBack wid (ywCanvasNewRectangle wid 548 98 108 16 "rgba: 0 0 0 255") "monster_bar_back")
          (yePushBack wid (ywCanvasNewRectangle wid 552 102 (/ 100 (/ maxhp hp)) 8 "rgba: 0 255 0 255") "monster_bar_front")      
        )
      )
    )
  )

  (define tmst_action
    (lambda (wid events)
      (let (
        (str "Hello Action\n" )
        (maxhp (get_stat wid "hero" "maxhp"))
        (hp (get_stat wid "hero" "hp"))        
        )
        (begin
	  (if (and
	       (yevAnyMouseDown events)
	       (ywRectContain (yeGet wid "clock-rect") (yeveMouseX) (yeveMouseY))
	       )
	      (display "on clock")
	      )

	  (yePrint (yeGet wid "state"))
	  (yePrint (yeGet wid "state-a"))
	  (if (= (yeGetIntAt wid "state-a") 5)
	      (begin
		(if (= (yeGetIntAt wid "state") 0)
		    (add_stat wid "hero" "hp"  (- (get_stat wid "first" "atk")))
		    )
		(if (= (yeGetIntAt wid "state") 0)
		    (add_stat wid "first" "hp"  (- (get_stat wid "hero" "atk")))
		    )

		)
	      )
	  (yeIncrAt wid "state-a")
	  (yePrint (yeGet(yeGet(yeGet wid "json") "hero") "stats"))
	  (if (> (yeGetIntAt wid "state-a") 10)
	      (begin
		(yeReCreateInt 0 wid "state-a")
		(yeIncrAt wid "state")
		(if (> (yeGetIntAt wid "state") 3)
		    (yeReCreateInt 0 wid "state")
		)
		)
	      )
	  (if (= (yeGetIntAt wid "state") 0)
		 (ywCanvasStringSet (yeGet wid "action-txt") (yeCreateString "the guy attack !!")))
	      (if (= (yeGetIntAt wid "state") 1)
		 (ywCanvasStringSet (yeGet wid "action-txt") (yeCreateString "the guy deal ?? dmgs !!")))
	  (if (= (yeGetIntAt wid "state") 2)
		  (ywCanvasStringSet (yeGet wid "action-txt") (yeCreateString "bad guy attack !!!"))
	  (if (= (yeGetIntAt wid "state") 3)
		 (ywCanvasStringSet (yeGet wid "action-txt") (yeCreateString "bad guy deal ?? dmgs :(")))
	      )
          (display str)
          (hero_hp_bar wid)
          (monster_hp_bar wid)
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
        )
        (begin
        (display "Hello world\n")
        (ywSetTurnLengthOverwrite 100000)
        (yeCreateFunction "tmst_action" wid "action")
        ;;(ywCanvasNewTextByStr wid 10 25 "test")
        
        (set_stat wid "hero" "hp" (get_stat wid "hero" "maxhp"))
        (set_stat wid "first" "hp" (get_stat wid "first" "maxhp"))
        (display (get_stat wid "first" "maxhp"))
        (yePushBack wid (ywCanvasNewImg wid 0 0 "cave.jpg" (ywRectCreate 0 0 1000 1000)) "cave")
	      (yePushBack wid (ywCanvasNewImg wid 550 (- 300 h)
					(yeGetString(yeGet(yeGet(yeGet wid "json") "first") "enemy-img"))
					(ywRectCreate x y w h)) "monster")

        (yePushBack wid (ywCanvasNewTextByStr wid 20 20 "") "action-txt")
        (ywCanvasSetStrColor (yeGet wid "action-txt") "rgba: 255 255 255 255")
        (yeCreateInt 0 wid "state")
        (yeCreateInt 0 wid "state-a")
        (ywRectCreate 350 400 100 100 wid "clock-rect")
        (yePushBack wid (ywCanvasNewImg wid 350 400
					"spritesheets/Clock.png"
					(ywRectCreate 0 0 100 100)) "clock")
        (yePushBack wid (ywCanvasNewImg wid 200 230 "spritesheets/HeroesHero.png" (ywRectCreate 9 88 36 70)) "hero")
        (ywCanvasNewHSegment wid 0 300 1000 "rgba: 0 0 0 255")
        (ywidNewWidget (yaeString "rgba: 255 255 255 255" wid "background") "canvas")
        )
      )
    )
  )
)

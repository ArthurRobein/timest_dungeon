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

  (define STATE_PJ_ATK 0)
  (define STATE_PJ_END_ATK 1)
  (define STATE_ENEMY_ATK 2)
  (define STATE_ENEMY_END_ATK 3)
  (define STATE_PJ_DEAD 4)
  (define STATE_ENEMY_DEAD 5)
  (define STATE_RESET 6)

  (define NB_TURN_COOLDOWN 30)
  (define STATE_TURN_L 10)

  (define STATE_DMG_TIME 8)

  (define reprint_stats
    (lambda (wid)
      (ywCanvasStringSet (yeGet wid "hp-stat-txt") (yeStringAddInt (yeCreateString "Health: ") (get_stat wid "hero" "hp")))
      (ywCanvasStringSet (yeGet wid "atk-stat-txt") (yeStringAddInt (yeCreateString "Attack: ") (get_stat wid "hero" "atk")))
      (ywCanvasStringSet (yeGet wid "def-stat-txt") (yeStringAddInt (yeCreateString "Defense: ") (get_stat wid "hero" "def")))
      (ywCanvasStringSet (yeGet wid "crit-stat-txt") (yeStringAddInt (yeCreateString "Crit rate: ") (get_stat wid "hero" "%crit")))
      )
    )

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

  (define rm_obj
    (lambda (wid key)
      (ywCanvasRemoveObj wid (yeGet wid key))
      )
    )

  (define repush_obj
    (lambda (wid key obj)
      (ywCanvasRemoveObj wid (yeGet wid key))
      (yeReplaceBack wid obj key)
      )
    )

  (define get_cur_room
    (lambda (wid)
      (yeGet (yeGet wid "json") (yeGetStringAt wid "cur_room"))
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
      (begin
        (yeAddAt (yeGet(yeGet(yeGet wid "json") room) "stats") stat value))
      )
    )


  (define cooldown_reset_bar
    (lambda (wid)
      (ywCanvasRemoveObj wid (yeGet wid "cool_bar_front"))
      (ywCanvasRemoveObj wid (yeGet wid "cool_bar_back"))
      (yeReplaceBack wid (ywCanvasNewRectangle wid 600 20 108 16 "rgba: 0 0 0 255") "cool_bar_back")
      (yeReplaceBack wid (ywCanvasNewRectangle wid 604 24
                                               (round (/ (* (yeGetIntAt wid "cur_cooldown") 100) NB_TURN_COOLDOWN)
                                                      ) 8 "rgba: 0 55 233 255")
                     "cool_bar_front")
      (display (/ 100
                  (/ (yeGetIntAt wid "cur_cooldown") NB_TURN_COOLDOWN)))
      )
    )

  (define hero_hp_bar
    (lambda (wid)
      (let (
            (maxhp (get_stat wid "hero" "maxhp"))
            (hp (get_stat wid "hero" "hp"))
            )
        (begin
          (ywCanvasRemoveObj wid (yeGet wid "hero_bar_front"))
          (ywCanvasRemoveObj wid (yeGet wid "hero_bar_back"))
          (yeReplaceBack wid (ywCanvasNewRectangle wid 176 198 108 16 "rgba: 0 0 0 255") "hero_bar_back")
          (if (> hp 0)
              (yeReplaceBack wid (ywCanvasNewRectangle wid 180 202 (round (/ 100 (/ maxhp hp))) 8 "rgba: 0 255 0 255") "hero_bar_front")
              )
          (display " <- bar l\n")
          )
        )
      )
    )

  (define monster_hp_bar
    (lambda (wid)
      (let (
            (maxhp (get_stat wid (yeGetStringAt wid "cur_room") "maxhp"))
            (hp (get_stat wid (yeGetStringAt wid "cur_room") "hp"))
            )
        (begin

          (ywCanvasRemoveObj wid (yeGet wid "monster_bar_back"))
          (ywCanvasRemoveObj wid (yeGet wid "monster_bar_front"))
          (yeReplaceBack wid (ywCanvasNewRectangle wid 548 98 108 16 "rgba: 0 0 0 255") "monster_bar_back")
          (if (> hp 0)
              (yeReplaceBack wid (ywCanvasNewRectangle wid 552 102 (round (/ 100 (/ maxhp hp))) 8 "rgba: 0 255 0 255") "monster_bar_front"))
          )
        )
      )
    )

  (define add_reminiscence
    (lambda (wid)
      (let (
            (x (modulo (yuiRand) 200))
            (y (modulo (yuiRand) 100))
            )
        (begin
          (yeReplaceBack wid (ywCanvasNewImg wid (+ 100 x) (+ 100 y) "spritesheets/Remi_idle.png"
            (ywRectCreate 26 22 43 63))
            (yeGetString (yeStringAddInt (yeCreateString "remi") (yeGetIntAt wid "reminiscence_number"))))
          (yeIncrAt wid "reminiscence_number")
          )
        )
      )
    )

  (define reminiscence_attack
    (lambda (wid num state)
      (if (< num (yeGetIntAt wid "reminiscence_number"))
        (let (
          (remi_x (ywCanvasObjPosX (yeGet wid (yeGetString (yeStringAddInt (yeCreateString "remi") num)))))
          (remi_y (ywCanvasObjPosY (yeGet wid (yeGetString (yeStringAddInt (yeCreateString "remi") num)))))
        )
          (begin
            (if (= state STATE_PJ_ATK)
              (begin
              (display "PJ ATK\n")
              (ywCanvasRemoveObj wid (yeGet wid (yeGetString (yeStringAddInt (yeCreateString "remi") num))))
              (yeReplaceBack wid (ywCanvasNewImg wid remi_x remi_y "spritesheets/Remi_attack.png" (ywRectCreate 225 18 88 68))
                (yeGetString (yeStringAddInt (yeCreateString "remi") num)))
            ))
            (if (= state STATE_PJ_END_ATK)
              (begin
              (ywCanvasRemoveObj wid (yeGet wid (yeGetString (yeStringAddInt (yeCreateString "remi") num))))
              (yeReplaceBack wid (ywCanvasNewImg wid remi_x remi_y "spritesheets/Remi_idle.png" (ywRectCreate 26 22 43 63))
                (yeGetString (yeStringAddInt (yeCreateString "remi") num)))
            ))
            (reminiscence_attack wid (+ 1 num) state)
          )
        )
      )
    )
  )

  (define combat_action
    (lambda (wid events)
      (let (
            (maxhp (get_stat wid "hero" "maxhp"))
            (hp (get_stat wid "hero" "hp"))
            (total_dmg (+ (get_stat wid "hero" "atk") (* (yeGetIntAt wid "reminiscence_number") (get_stat wid "hero" "atk"))))
            )
        (begin
          (yePrint (yeGet wid "state"))
          (yePrint (yeGet wid "state-a"))
          (if (= (yeGetIntAt wid "state-a") STATE_DMG_TIME)
            (begin
              (if (= (yeGetIntAt wid "state") STATE_PJ_ATK)
                (begin
                  (add_stat wid (yeGetStringAt wid "cur_room") "hp" (- total_dmg))
                  (yeReCreateInt total_dmg wid "dmg-deal"))
                )
              (if (= (yeGetIntAt wid "state") STATE_ENEMY_ATK)
                (let (
                  (rand (modulo (yuiRand) (yeGetIntAt wid "reminiscence_number")))
                  )
                  (if (= (yeGetIntAt wid "reminiscence_number") 0)
                    (begin
                      (add_stat wid "hero" "hp"  (- (get_stat wid (yeGetStringAt wid "cur_room") "atk")))
                      (yeReCreateInt (get_stat wid (yeGetStringAt wid "cur_room") "atk") wid "dmg-deal"))
                    (begin
                      (if (> rand 0)
                        (begin
                          (yeAddAt wid "reminiscence_number" -1)
                          (ywCanvasRemoveObj wid
                            (yeGet wid (yeGetString (yeStringAddInt (yeCreateString "remi") (yeGetIntAt wid "reminiscence_number"))))))
                        (begin
                          (add_stat wid "hero" "hp"  (- (get_stat wid (yeGetStringAt wid "cur_room") "atk")))
                          (yeReCreateInt (get_stat wid (yeGetStringAt wid "cur_room") "atk") wid "dmg-deal")))
                    )
                  )
                )
              )
            )
          )
          (yeIncrAt wid "state-a")
          (yeIncrAt wid "cur_cooldown")
          (yeIntForceBound (yeGet wid "cur_cooldown") 0 NB_TURN_COOLDOWN)
          (if (> (yeGetIntAt wid "state-a") STATE_TURN_L)
              (begin
                (yeReCreateInt 0 wid "state-a")
                (yeIncrAt wid "state")
                (if (> (yeGetIntAt wid "state") STATE_ENEMY_END_ATK)
                    (yeReCreateInt 0 wid "state")
                    )
                (if (< (get_stat wid "hero" "hp") 1) (yeReCreateInt STATE_PJ_DEAD wid "state"))
                (if (< (get_stat wid (yeGetStringAt wid "cur_room") "hp") 1)
		    (begin
		      (yeReCreateInt 0 wid "new-win")
		      (yeReCreateInt STATE_ENEMY_DEAD wid "state")
		      )
		    )
                ))
          (if (= (yeGetIntAt wid "state") STATE_PJ_ATK)
              (begin
                (ywCanvasStringSet (yeGet wid "action-txt") (yeCreateString "the guy attack !!"))
                (ywCanvasRemoveObj wid (yeGet wid "hero"))
                (yeReplaceBack wid (ywCanvasNewImg wid 200 230 "spritesheets/Hero_attack.png" (ywRectCreate 225 18 88 68)) "hero")
                (reminiscence_attack wid 0 STATE_PJ_ATK)
                ))
          (if (= (yeGetIntAt wid "state") STATE_PJ_END_ATK)
              (begin
                (ywCanvasStringSet (yeGet wid "action-txt") (yeStringAddInt (yeCreateString "the guy deal ")
                                                                            (yeGetIntAt wid "dmg-deal")))
                (ywCanvasRemoveObj wid (yeGet wid "hero"))
                (yeReplaceBack wid (ywCanvasNewImg wid 200 230 "spritesheets/Hero_idle.png" (ywRectCreate 26 22 43 63)) "hero")
                (reminiscence_attack wid 0 STATE_PJ_END_ATK)
                ))
          (if (= (yeGetIntAt wid "state") STATE_ENEMY_ATK)
              (begin
                (ywCanvasStringSet (yeGet wid "action-txt") (yeCreateString "bad guy attack !!!"))
                (ywCanvasRemoveObj wid (yeGet wid "hero"))
                (ywCanvasMoveObjXY (yeGet wid "monster") -5 0)
                (yeReplaceBack wid (ywCanvasNewImg wid 200 230 "spritesheets/Hero_hurt.png" (ywRectCreate 7 27 46 59)) "hero")))
          (if (= (yeGetIntAt wid "state") STATE_ENEMY_END_ATK)
              (begin
                (ywCanvasStringSet (yeGet wid "action-txt") (yeStringAddInt (yeCreateString "bad guy deal ")
                                                                            (yeGetIntAt wid "dmg-deal")))
                (ywCanvasRemoveObj wid (yeGet wid "hero"))
                (ywCanvasMoveObjXY (yeGet wid "monster") 5 0)
                (yeReplaceBack wid (ywCanvasNewImg wid 200 230 "spritesheets/Hero_idle.png" (ywRectCreate 26 22 43 63)) "hero")))

          (hero_hp_bar wid)
          (monster_hp_bar wid)
          (cooldown_reset_bar wid)
          )
        )
      )
    )

  (define dead_action
    (lambda (wid events)
      (begin
        (ywCanvasStringSet (yeGet wid "dead-txt") (yeCreateString "DEAD !!!! !!"))
        (ywCanvasStringSet (yeGet wid "action-txt") (yeCreateString ""))
        (ywCanvasRemoveObj wid (yeGet wid "hero"))
        (yeReplaceBack wid (ywCanvasNewImg wid 200 248 "spritesheets/Hero_dead.png" (ywRectCreate 98 41 47 45)) "hero")
        )
      )
    )

  (define goto_room
    (lambda (wid room_info)
      (yePrint room_info)
      (yeReCreateString (yeGetStringAt room_info 0) wid "cur_room")
      (yeReCreateInt STATE_PJ_ATK wid "state")

      (yePrint (get_cur_room wid))
      (rm_obj wid "choose-yellow")
      (rm_obj wid "choose-blue")
      (rm_obj wid "choose-green")
      (rm_obj wid "choose-rect-0")
      (rm_obj wid "choose-rect-1")
      (rm_obj wid "choose-rect-2")
      (ywCanvasStringSet (yeGet wid "choose-txt-0") (yeCreateString ""))
      (ywCanvasStringSet (yeGet wid "choose-txt-1") (yeCreateString ""))
      (ywCanvasStringSet (yeGet wid "choose-txt-2") (yeCreateString ""))
      )
    )

  (define choose_3_rooms
    (lambda (wid events)
      (display "choose between 3 rooms\n")

      (repush_obj wid "choose-rect-0"
		  (ywCanvasNewRectangle wid 5 5 260 290 "rgba: 230 230 230 200"))
      (ywCanvasStringSet (yeGet wid "choose-txt-0") (yeCreateString "room 0"))
      (ywCanvasSetWeight wid (yeGet wid "choose-txt-0") 10)

      (repush_obj wid "choose-rect-1"
		  (ywCanvasNewRectangle wid 270 5 260 290 "rgba: 230 230 230 200"))
      (ywCanvasStringSet (yeGet wid "choose-txt-1") (yeCreateString "room 1"))
      (ywCanvasSetWeight wid (yeGet wid "choose-txt-1") 10)

      (repush_obj wid "choose-rect-2"
		  (ywCanvasNewRectangle wid 535 5 260 290 "rgba: 230 230 230 200"))
      (ywCanvasStringSet (yeGet wid "choose-txt-2") (yeCreateString "room 2"))
      (ywCanvasSetWeight wid (yeGet wid "choose-txt-2") 10)

      (let ((rect (ywRectCreate 5 5 260 290)))
	(if (ywRectContain rect (yeveMouseX) (yeveMouseY))
	    (begin
	      (repush_obj wid "choose-yellow" (ywCanvasNewRectangleByRect wid rect "rgba: 190 190 60 100"))
	      (if (yevAnyMouseDown events) (goto_room wid (yeGet (yeGet (get_cur_room wid) "nexts") 0)))
	      )
	    )
	)

      (let ((rect (ywRectCreate 270 5 260 290)))
	(if (ywRectContain rect (yeveMouseX) (yeveMouseY))
	    (begin
	      (repush_obj wid "choose-blue" (ywCanvasNewRectangleByRect wid rect "rgba: 60 60 190 100"))
	      (if (yevAnyMouseDown events) (goto_room wid (yeGet (yeGet (get_cur_room wid) "nexts") 1))))
	    )
	)

      (let ((rect (ywRectCreate 535 5 260 290)))
        (if (ywRectContain rect (yeveMouseX) (yeveMouseY))
          (begin
            (repush_obj wid "choose-green" (ywCanvasNewRectangleByRect wid rect "rgba: 60 190 60 100"))
            (if (yevAnyMouseDown events) (goto_room wid (yeGet (yeGet (get_cur_room wid) "nexts") 2))))
        )
	    )
    )
  )

  (define dead_enemy_action
    (lambda (wid events)
      (let (
            (next_l (yeLen (yeGet (get_cur_room wid) "nexts")))
            (new_win (yeGetIntAt wid "new-win"))
            )
        (begin
	  (if (= new_win 0)
	      (let (
		    (rand (modulo (yuiRand) 4))
		    )
		(if (= rand 0)
		    (begin (add_stat wid "hero" "maxhp" 1)
			   (add_stat wid "hero" "hp" 1)
			   (yeReCreateString "maxhp" wid "which-win")))
		(if (= rand 1)
		    (begin (add_stat wid "hero" "atk" 1)
			   (yeReCreateString "atk" wid "which-win")))
		(if (= rand 2)
		    (begin (add_stat wid "hero" "def" 1)
			   (yeReCreateString "def" wid "which-win")))
		(if (= rand 3)
		    (begin (add_stat wid "hero" "%crit" 1)
			   (yeReCreateString "%crit" wid "which-win")))
		)
	      )
	  (if (< new_win 30)
	      (begin
		(yeIncrAt wid "new-win")
		(display "new win handler\n")
		(repush_obj wid "win-rect"
			    (ywCanvasNewRectangle wid 0 0 800 300 "rgba: 230 230 230 200"))
		(repush_obj wid "win-text"
			    (ywCanvasNewText wid 350 30
					     (yeStringAdd (yeCreateString "Ta ta ta ta, tatatata ta ta\nYOU WIN\n") (yeGetStringAt wid "which-win"))
					     )
			    )
		)
	      (begin
		(rm_obj wid "win-rect")
		(rm_obj wid "win-text")
		(if (= 3 next_l) (choose_3_rooms wid events)
		    (display "odd number of ROOM !!!!"))
		)
	      )
          )
        )
      )
    )

  (define init_room
    (lambda (wid)
      (yeForeach (yeGet wid "json")
        (lambda (room _unused)
          (yeReCreateInt
          (yeGetIntAt (yeGet  room "stats") "maxhp")
          (yeGet room "stats")
          "hp")
        )
	)
      (yeReCreateString "first" wid "cur_room")
      (yeReCreateInt 0 wid "state")
      (yeReCreateInt 0 wid "state-a")
      (yeReCreateInt 1 wid "cur_cooldown")
    )
  )

  (define reset_action
    (lambda (wid events)
      (display "reset_action\n")
      (add_reminiscence wid)
      (init_room wid)
      )
    )

  (define tmst_action
    (lambda (wid events)
      (reprint_stats wid)
      (if
        (and
          (and
            (and (> (yeGetIntAt wid "cur_cooldown") (- NB_TURN_COOLDOWN 1))
                (yevAnyMouseDown events))
            (ywRectContain (yeGet wid "clock-rect") (yeveMouseX) (yeveMouseY)))
            (> STATE_PJ_DEAD (yeGetIntAt wid "state")))
          (begin
            (display "on clock")
            (yeReCreateInt STATE_RESET wid "state")
            )
          )

      (if (= (yeGetIntAt wid "state") STATE_PJ_DEAD)
          (dead_action wid events)
          (if (= (yeGetIntAt wid "state") STATE_ENEMY_DEAD)
              (dead_enemy_action wid events)
              (if (= (yeGetIntAt wid "state") STATE_RESET)
                  (reset_action wid events)
                  (combat_action wid events)
                  )
              )
          )
      )
    )

  (define tmst_init
    (lambda (wid unues_type)
      (let
        ((unused (yePushBack wid (ygFileToEnt YJSON "rooms.json") "json"))
          (first_room (yeReCreateString "first" wid "cur_room"))
          (x (get_sprite_pos wid (yeGetStringAt wid "cur_room") "x"))
          (y (get_sprite_pos wid (yeGetStringAt wid "cur_room") "y"))
          (w (get_sprite_pos wid (yeGetStringAt wid "cur_room") "w"))
          (h (get_sprite_pos wid (yeGetStringAt wid "cur_room") "h"))
          )
        (begin
          (display "Hello world\n")
          (ywSetTurnLengthOverwrite 100000)
          (yeCreateFunction "tmst_action" wid "action")
          ;;(ywCanvasNewTextByStr wid 10 25 "test")

          ;; yeForeach take at first elem, array entity, 2nd a scheme function
          ;; and a thrid optional argument (not use, nor send here)
          ;; third argument is return by yeForeach (so nil here)
          (init_room wid)
          (yeCreateInt 0 wid "reminiscence_number")
          (yePushBack wid (ywCanvasNewImg wid 0 0 "cave.jpg" (ywRectCreate 0 0 1000 1000)) "cave")
          (yePushBack wid (ywCanvasNewImg wid 550 (- 300 h)
                                          (yeGetString(yeGet(yeGet(yeGet wid "json") (yeGetStringAt wid "cur_room")) "enemy-img"))
                                          (ywRectCreate x y w h)) "monster")

          (yePushBack wid (ywCanvasNewTextByStr wid 30 30 "") "dead-txt")
          (ywCanvasSetStrColor (yeGet wid "dead-txt") "rgba: 255 255 255 255")
          (yePushBack wid (ywCanvasNewRectangle wid 20 390 200 170 "rgba: 0 0 0 100") "stat-background")

          (yePushBack wid (ywCanvasNewTextByStr wid 30 20 "") "action-txt")
          (yePushBack wid (ywCanvasNewTextByStr wid 30 400 "") "hp-stat-txt")
          (yePushBack wid (ywCanvasNewTextByStr wid 30 430 "") "atk-stat-txt")
          (yePushBack wid (ywCanvasNewTextByStr wid 30 460 "") "def-stat-txt")
          (yePushBack wid (ywCanvasNewTextByStr wid 30 490 "") "crit-stat-txt")

          (ywCanvasSetStrColor (yeGet wid "action-txt") "rgba: 255 255 255 255")
          (ywCanvasSetStrColor (yeGet wid "hp-stat-txt") "rgba: 255 255 255 255")
          (ywCanvasSetStrColor (yeGet wid "atk-stat-txt") "rgba: 255 255 255 255")
          (ywCanvasSetStrColor (yeGet wid "def-stat-txt") "rgba: 255 255 255 255")
          (ywCanvasSetStrColor (yeGet wid "crit-stat-txt") "rgba: 255 255 255 255")


          (yePushBack wid (ywCanvasNewTextByStr wid 20 20 "") "choose-txt-0")
          (yePushBack wid (ywCanvasNewTextByStr wid 290 20 "") "choose-txt-1")
          (yePushBack wid (ywCanvasNewTextByStr wid 560 20 "") "choose-txt-2")

          (ywRectCreate 350 400 100 100 wid "clock-rect")
          (yePushBack wid (ywCanvasNewImg wid 350 400
                                          "spritesheets/Clock.png"
                                          (ywRectCreate 0 0 100 100)) "clock")
          (yePushBack wid (ywCanvasNewImg wid 200 230 "spritesheets/Hero_idle.png" (ywRectCreate 26 22 43 63)) "hero")
          (ywCanvasNewHSegment wid 0 300 1000 "rgba: 0 0 0 255")
          (yeCreateInt 1 wid "have_weight")
          (ywidNewWidget (yaeString "rgba: 255 255 255 255" wid "background") "canvas")
          )
        )
      )
    )
  )

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
        (display "remove ")
        (display value)
        (display "to ")
        (display (yeGetIntAt (yeGet(yeGet(yeGet wid "json") room) "stats") stat))
        (display "\n")
        (yeAddAt (yeGet(yeGet(yeGet wid "json") room) "stats") stat value))
      )
    )


  (define cooldown_reset_bar
    (lambda (wid)
      (ywCanvasRemoveObj wid (yeGet wid "cool_bar_back"))
      (ywCanvasRemoveObj wid (yeGet wid "cool_bar_front"))
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
          (ywCanvasRemoveObj wid (yeGet wid "hero_bar_back"))
          (ywCanvasRemoveObj wid (yeGet wid "hero_bar_front"))
          (yeReplaceBack wid (ywCanvasNewRectangle wid 176 198 108 16 "rgba: 0 0 0 255") "hero_bar_back")
          (if (> hp 0)
              (yeReplaceBack wid (ywCanvasNewRectangle wid 180 202 (round (/ 100 (/ maxhp hp))) 8 "rgba: 0 255 0 255") "hero_bar_front")
              )
                                        ;(display (/ 100 (/ maxhp hp)))
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
          (yePushBack wid (ywCanvasNewImg wid (+ 100 x) (+ 100 y) "spritesheets/Hero_idle.png" (ywRectCreate 26 22 43 63)) "remi")
          )
        )
      )
    )

  (define combat_action
    (lambda (wid events)
      (let (
            (maxhp (get_stat wid "hero" "maxhp"))
            (hp (get_stat wid "hero" "hp"))
            )
        (begin

          (yePrint (yeGet wid "state"))
          (yePrint (yeGet wid "state-a"))
          (ywCanvasStringSet (yeGet wid "hp-stat-txt") (yeStringAddInt (yeCreateString "Health: ") (get_stat wid "hero" "hp")))
          (ywCanvasStringSet (yeGet wid "atk-stat-txt") (yeStringAddInt (yeCreateString "Attack: ") (get_stat wid "hero" "atk")))
          (ywCanvasStringSet (yeGet wid "def-stat-txt") (yeStringAddInt (yeCreateString "Defense: ") (get_stat wid "hero" "def")))
          (ywCanvasStringSet (yeGet wid "crit-stat-txt") (yeStringAddInt (yeCreateString "Crit rate: ") (get_stat wid "hero" "crit")))

          (if (= (yeGetIntAt wid "state-a") STATE_DMG_TIME)
              (begin
                (if (= (yeGetIntAt wid "state") STATE_PJ_ATK)
                    (begin
                      (add_stat wid (yeGetStringAt wid "cur_room") "hp"  (- (get_stat wid "hero" "atk")))
                      (yeReCreateInt (get_stat wid "hero" "atk") wid "dmg-deal"))
                    )
                (if (= (yeGetIntAt wid "state") STATE_ENEMY_ATK)
                    (begin
                      (add_stat wid "hero" "hp"  (- (get_stat wid (yeGetStringAt wid "cur_room") "atk")))
                      (yeReCreateInt (get_stat wid (yeGetStringAt wid "cur_room") "atk") wid "dmg-deal")
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
                (yeReplaceBack wid (ywCanvasNewImg wid 200 230 "spritesheets/Hero_attack.png" (ywRectCreate 225 18 88 68)) "hero")))
          (if (= (yeGetIntAt wid "state") STATE_PJ_END_ATK)
              (begin
                (ywCanvasStringSet (yeGet wid "action-txt") (yeStringAddInt (yeCreateString "the guy deal")
                                                                            (yeGetIntAt wid "dmg-deal")))
                (ywCanvasRemoveObj wid (yeGet wid "hero"))
                (yeReplaceBack wid (ywCanvasNewImg wid 200 230 "spritesheets/Hero_idle.png" (ywRectCreate 26 22 43 63)) "hero")))
          (if (= (yeGetIntAt wid "state") STATE_ENEMY_ATK)
              (begin
                (ywCanvasStringSet (yeGet wid "action-txt") (yeCreateString "bad guy attack !!!"))
                (ywCanvasRemoveObj wid (yeGet wid "hero"))
                (ywCanvasMoveObjXY (yeGet wid "monster") -5 0)
                (yeReplaceBack wid (ywCanvasNewImg wid 200 230 "spritesheets/Hero_hurt.png" (ywRectCreate 7 27 46 59)) "hero")))
          (if (= (yeGetIntAt wid "state") STATE_ENEMY_END_ATK)
              (begin
                (ywCanvasStringSet (yeGet wid "action-txt") (yeStringAddInt (yeCreateString "bad guy deal")
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
        )
      )
    )

  (define reset_action
    (lambda (wid events)
      (display "reset_action\n")
      )
    )

  (define choose_3_rooms
    (lambda (wid events)
      (begin
	(rm_obj wid "win-rect")
	(rm_obj wid "win-text")
        (display "choose between 3 rooms\n")
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
          (yePrint (yeGet (get_cur_room wid) "nexts"))
          (display next_l)
	  (display "dead_enemy_action\n")
	  (if (< new_win 30)
	      (begin
		(yeIncrAt wid "new-win")
		(display "new win handler\n")
		(repush_obj wid "win-rect"
			    (ywCanvasNewRectangle wid 0 0 800 300 "rgba: 230 230 230 200"))
		(repush_obj wid "win-text"
			    (ywCanvasNewTextByStr wid 350 30 "Ta ta ta ta, tatatata ta ta\nYOU WIN"))
		)
	      (if (= 3 next_l) (choose_3_rooms wid events)))
          )
        )
      )
    )

  (define tmst_action
    (lambda (wid events)
      (if (and
           (and (> (yeGetIntAt wid "cur_cooldown") (- NB_TURN_COOLDOWN 1))
                (yevAnyMouseDown events))
           (ywRectContain (yeGet wid "clock-rect") (yeveMouseX) (yeveMouseY))
           )
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

          (yeReCreateInt 1 wid "cur_cooldown")
          ;; yeForeach take at first elem, array entity, 2nd a scheme function
          ;; and a thrid optional argument (not use, nor send here)
          ;; third argument is return by yeForeach (so nil here)
          (yeForeach (yeGet wid "json")
                     (lambda (room _unuesed)
                       (yeReCreateInt
                        (yeGetIntAt (yeGet  room "stats") "maxhp")
                        (yeGet room "stats")
                        "hp")
                       )
                     )

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

          (add_reminiscence wid)

          (yeCreateInt 0 wid "state")
          (yeCreateInt 0 wid "state-a")
          (ywRectCreate 350 400 100 100 wid "clock-rect")
          (yePushBack wid (ywCanvasNewImg wid 350 400
                                          "spritesheets/Clock.png"
                                          (ywRectCreate 0 0 100 100)) "clock")
          (yePushBack wid (ywCanvasNewImg wid 200 230 "spritesheets/Hero_idle.png" (ywRectCreate 26 22 43 63)) "hero")
          (ywCanvasNewHSegment wid 0 300 1000 "rgba: 0 0 0 255")
          (ywidNewWidget (yaeString "rgba: 255 255 255 255" wid "background") "canvas")
          )
        )
      )
    )
  )

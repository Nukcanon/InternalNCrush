extends Control
class_name StatGraph
var rows:Array=[]
var weapon:Dictionary={}
func configure(kind:int,w:Dictionary,role:int,variant:int):
	rows.clear();weapon={};visible=true
	if kind==1 and w.kind=="gun":
		weapon=w
		rows=[["피해 / 1발",float(w.damage)*int(w.pellets),150.,"%d%s"%[w.damage," × %d"%w.pellets if w.pellets>1 else ""]],
		["DPS / 지속",CombatBalance.firing_dps(w),360.,"%.0f / %.0f"%[CombatBalance.firing_dps(w),CombatBalance.sustained_dps(w)]],
		["연사 속도",CombatBalance.sustained_rpm(w),1000.,"%d RPM"%CombatBalance.sustained_rpm(w)],
		["유효 거리",w.reach,150.,"%d m"%w.reach],["안정성",w.stability,100.,"%d / 100"%w.stability],
		["조준 속도",800.-w.ads_ms,800.,"%d ms"%w.ads_ms],["휴대성",w.portability,100.,"%d · %.1f kg"%[w.portability,w.weight_kg]],
		["탄창 / 장전",w.mag,100.,"%d / %.2f초"%[w.mag,w.reload]]]
	elif kind==1 and w.kind=="remote":
		rows=[["포탑 탄환 DPS",38.,60.,"23 → 38"],["탄환 감쇠 시작",12.,60.,"12 m"],["48m 탄환 피해",10.,100.,"10%"],["최대 단계 미사일",30.,100.,"30 / 2초"]]
	elif kind==1:
		rows=[["회복 / 초" if w.kind=="heal" else "수리 / 초",24. if w.kind=="heal" else 80.,100.,"최대 24 HP" if w.kind=="heal" else "최대 80 HP"],["작동 거리",w.reach,20.,"%d m"%w.reach],["에너지",w.mag,180.,str(w.mag)]]
	elif kind==2 and variant==9:
		rows=[["해체 시간",10.,30.,"10초 / 기본 30초"],["구매 비용",400.,1000.,"400 크레딧"]]
	elif kind==2:
		match role:
			0:rows=[["폭발 피해",120.,150.,"최대 120"],["반경",5.5,10.,"5.5 m"],["안전핀 후 지연",3.,5.,"3.0초"],["소지량",1.,3.,"1개"]] if variant==1 else [["방어구 회복",25.,50.,"25 / 최대 50"],["소지량",1.,3.,"1개"]]
			1:rows=[["표식 거리",160.,200.,"160 m"],["지속 시간",6.,15.,"6초"]]
			2:rows=[["지속 시간",15.,20.,"15초"],["정지 퍼짐 감소",65.,100.,"65%"]]
			3:rows=[["내구도",float(AbilityBalance.COVER_HP[variant]),420.,str(AbilityBalance.COVER_HP[variant])],["최대 설치",2.,3.,"2개"]]
			4:rows=[["연막 지속",10.,15.,"10초"],["연막 반경",5.,10.,"5 m"],["섬광 반경",13.,20.,"13 m"],["섬광 지속",2.2,5.,"최대 2.2초"]]
			5:rows=[["즉시 회복",25.,100.,"25 HP"],["작동 거리",4.,20.,"4 m"]]
	elif kind==3:rows=[["최대 체력",100.,150.,"100 HP"],["추가 방어구",variant*25.,50.,str(variant*25)]]
	elif kind==4:
		var cooldown=AbilityBalance.COOLDOWNS[role]
		rows=[["재사용 대기",cooldown,40.,"%d초"%cooldown],["효과 시간",AbilityBalance.DURATIONS[role],180. if role==3 else 10.,"설치형" if role==3 else "%.2f초"%AbilityBalance.DURATIONS[role]]]
		if role==3:rows.append_array([["포탑 내구도",180.,300.,"180 → 300"],["초당 탄환 피해",38.,60.,"23 → 38"],["탐지 거리",55.,106.,"맵별 55 → 106 m"]])
	else:visible=false
	custom_minimum_size=Vector2(430,rows.size()*19+(67 if not weapon.is_empty() else 6));queue_redraw()
func _draw():
	var font=get_theme_default_font();var ink=Color("d2e2ec");var accent=Color("66d5c2");var width=maxf(430,size.x)
	for i in range(rows.size()):
		var r=rows[i];var y=i*19.;var x=118.;var length=width-255.
		draw_string(font,Vector2(0,y+15),r[0],HORIZONTAL_ALIGNMENT_LEFT,-1,14,ink)
		draw_style_box(_bar(Color("2b4555")),Rect2(x,y+5,length,8))
		if float(r[1])>0.:draw_style_box(_bar(accent),Rect2(x,y+5,length*clampf(float(r[1])/float(r[2]),0.,1.),8))
		draw_string(font,Vector2(width-127,y+15),r[3],HORIZONTAL_ALIGNMENT_LEFT,-1,13,ink)
	if weapon.is_empty():return
	var y=rows.size()*19.+5.;var max_distance=minf(180.,float(weapon.falloff_end)*1.2);var origin=Vector2(118,y+36)
	draw_string(font,Vector2(0,y+15),"거리별 피해",HORIZONTAL_ALIGNMENT_LEFT,-1,14,ink)
	draw_string(font,Vector2(0,y+33),"몸통 · 1발",HORIZONTAL_ALIGNMENT_LEFT,-1,12,ink.darkened(.18))
	var points=PackedVector2Array()
	for i in range(51):points.append(origin+Vector2((width-255)*i/50.,-CombatBalance.range_factor(weapon,max_distance*i/50.)*30))
	draw_line(origin,origin+Vector2(width-255,0),Color("607887"),1.);draw_polyline(points,accent,2.,true)
	draw_string(font,Vector2(width-127,y+15),"0 → %d m"%max_distance,HORIZONTAL_ALIGNMENT_LEFT,-1,12,ink)
	draw_string(font,Vector2(width-127,y+33),"최저 %d%%"%roundi(float(weapon.min_damage_scale)*100),HORIZONTAL_ALIGNMENT_LEFT,-1,12,ink)
	draw_string(font,Vector2(0,y+53),"DPS: 근거리 몸통 전탄 명중 · 지속: 재장전 포함",HORIZONTAL_ALIGNMENT_LEFT,width,12,ink.darkened(.14))
func _bar(color:Color) -> StyleBoxFlat:
	var box=StyleBoxFlat.new();box.bg_color=color;box.set_corner_radius_all(3);return box

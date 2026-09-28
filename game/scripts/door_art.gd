class_name DoorArt
extends RefCounted
const SETS={
	"town":["wood_panel","cottage","glass_store","frosted_office","hotel_panel","restroom"],
	"port":["ship_bulkhead","submarine","container","loading_bay","steel_security"],
	"industry":["warehouse_shutter","loading_bay","container","maintenance_louver","garage_fold","fire_exit"],
	"lab":["lab_observation","hospital_swing","server_access","cold_store","fire_exit"],
	"historic":["wood_plank","arched_plank","barn_cross","garden_gate","ornate_gate"],
	"station":["station_ticket","frosted_office","fire_exit","steel_security"],
	"library":["wood_panel","school_classroom","sliding_shoji","hotel_panel"],
	"secure":["vault","steel_security","cell_gate","chain_gate","server_access"]}
static func style(index:int,id:int) -> String:
	var family="town"
	if index in [0,1,5,21,23,28]:family="port"
	elif index in [2,8,11,13,15,25]:family="industry"
	elif index in [3,14,20,29]:family="lab"
	elif index in [4,10,12,18,19,24,26,30]:family="historic"
	elif index==6:family="station"
	elif index==22:family="library"
	elif index==27:family="secure"
	var roster=SETS[family];return "door_"+roster[(id-1+(0 if index in [22,27] else index))%roster.size()]

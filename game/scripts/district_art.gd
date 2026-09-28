class_name DistrictArt
extends RefCounted
## Curated local objects: deliberately different rosters, not a global random pool.
const PROPS=[
	["cargo_pallet","mooring_bollards","container","rope_crate","dock_rescue"],
	["workshop_lathe","air_compressor","hose_reel","work_cart","drill_press"],
	["transformer","workshop_lathe","ventilation_fan","cargo_pallet","staff_lockers"],
	["laboratory_sink","sample_rack","instrument_cabinet","staff_lockers","solar_array"],
	["solar_array","air_compressor","notice_board","cargo_pallet"],
	["water_pump","mooring_bollards","dock_rescue","rope_crate","park_bench"],
	["park_bench","notice_board","staff_lockers","cargo_pallet","garden_planter"],
	["cafe_parasol","garden_planter","park_bench","notice_board","stone_fountain"],
	["drill_press","workshop_lathe","work_cart","air_compressor","staff_lockers"],
	["bakery_display","cafe_parasol","notice_board","park_bench","garden_planter"],
	["fruit_cart","potting_bench","timber_stack","hose_reel","tree"],
	["transformer","instrument_cabinet","ventilation_fan","work_cart"],
	["stone_fountain","stone_bench","memorial_stone","garden_planter","notice_board"],
	["cargo_pallet","container","work_cart","staff_lockers","notice_board"],
	["sample_rack","laboratory_sink","instrument_cabinet","ventilation_fan"],
	["workshop_lathe","drill_press","air_compressor","timber_stack","cargo_pallet"],
	["solar_array","ventilation_fan","garden_planter","park_bench","notice_board"],
	["produce_stall","bakery_display","fruit_cart","fish_table","cafe_parasol","cargo_pallet"],
	["air_compressor","drill_press","work_cart","timber_stack","cargo_pallet"],
	["stone_bench","produce_stall","memorial_stone","fruit_cart","notice_board"],
	["transformer","water_pump","instrument_cabinet","ventilation_fan","staff_lockers"],
	["water_pump","hose_reel","dock_rescue","mooring_bollards","rope_crate"],
	["library_bookcase","reading_desk","notice_board","garden_planter","stone_bench"],
	["rope_crate","mooring_bollards","cargo_pallet","dock_rescue","hose_reel"],
	["stone_bench","memorial_stone","stone_fountain","garden_planter","tree"],
	["workshop_lathe","transformer","air_compressor","ventilation_fan","cargo_pallet"],
	["potting_bench","water_pump","hose_reel","sample_rack","garden_planter"],
	["staff_lockers","notice_board","park_bench","instrument_cabinet","ventilation_fan"],
	["dock_rescue","solar_array","mooring_bollards","rope_crate","instrument_cabinet"],
	["instrument_cabinet","ventilation_fan","transformer","staff_lockers","work_cart"],
	["memorial_stone","stone_bench","timber_stack","garden_planter","notice_board"],
	["notice_board","cargo_pallet","work_cart","park_bench"]]
static func prop(index:int,ordinal:int) -> String:
	var roster=PROPS[clampi(index,0,PROPS.size()-1)]
	return roster[ordinal%roster.size()]
static func original(kind:String) -> bool:
	return kind not in ["car","tree","boat","container","tank"]
static func loose(index:int,ordinal:int) -> String:
	var roster=["barrel","crate","cone","canister","tire"]
	if index in [3,14,20,29]:roster=["crate","canister"]
	elif index in [7,9,10,12,17,19,22,24,26,30]:roster=["crate"]
	elif index in [0,5,21,23,28]:roster=["crate","canister","tire"]
	return roster[ordinal%roster.size()]

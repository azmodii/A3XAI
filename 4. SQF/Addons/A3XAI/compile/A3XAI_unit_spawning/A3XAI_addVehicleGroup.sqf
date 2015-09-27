#include "\A3XAI\globaldefines.hpp"

private ["_unitGroup", "_vehicle", "_unitsAlive", "_unitLevel", "_trigger", "_rearm" ,"_pos", "_posReflected"];
	
_unitGroup = _this select 0;
_vehicle = _this select 1;

_pos = getPosATL _vehicle;
_pos set [2,0];
_unitsAlive = {alive _x} count (units _unitGroup);

if (_unitsAlive isEqualTo 0) exitWith {diag_log format ["A3XAI Error: %1 cannot create trigger area for empty group %2.",__FILE__,_unitGroup];};

{
	if (alive _x) then {
		if ((_x getHit "legs") > 0) then {_x setHit ["legs",0]};
		unassignVehicle _x;
	};
} count (units _unitGroup);

for "_i" from ((count (waypoints _unitGroup)) - 1) to 0 step -1 do {
	deleteWaypoint [_unitGroup,_i];
};

if (_pos call A3XAI_checkInNoAggroArea) then {
	_pos = _pos call A3XAI_getSafePosReflected;
	[_unitGroup,"IgnoreEnemies"] call A3XAI_forceBehavior;
	if !(_pos isEqualTo []) then {
		_tempWP = [_unitGroup,_pos,"if !(local this) exitWith {}; [(group this),PATROL_DIST_VEHICLEGROUP] call A3XAI_moveToPosAndPatrol;"] call A3XAI_addTemporaryWaypoint;
	};
} else {
	_unitGroup setCombatMode "YELLOW";
	_unitGroup setBehaviour "AWARE";
	[_unitGroup,_pos] call A3XAI_setFirstWPPos;
	0 = [_unitGroup,_pos,PATROL_DIST_VEHICLEGROUP] spawn A3XAI_BIN_taskPatrol;
};

if !(_pos isEqualTo []) then {
	_unitLevel = _unitGroup getVariable ["unitLevel",1];
	_trigger = createTrigger [TRIGGER_OBJECT,_pos,false];
	_trigger setTriggerArea [TRIGGER_SIZE_SMALL,TRIGGER_SIZE_SMALL,0,false];
	_trigger setTriggerActivation ["ANY", "PRESENT", true];
	_trigger setTriggerTimeout [TRIGGER_TIMEOUT_VEHICLEGROUP, true];
	_trigger setTriggerText (format ["AI Vehicle Group %1",mapGridPosition _vehicle]);
	_trigger setTriggerStatements ["{if (isPlayer _x) exitWith {1}} count thisList != 0;","","0 = [thisTrigger] spawn A3XAI_despawn_static;"];
	0 = [4,_trigger,[_unitGroup],PATROL_DIST_VEHICLEGROUP,_unitLevel,[_unitsAlive,0]] call A3XAI_initializeTrigger;

	_unitGroup setVariable ["GroupSize",_unitsAlive];
	_unitGroup setVariable ["unitType","vehiclecrew"];
	_unitGroup setVariable ["trigger",_trigger];

	[_trigger,"A3XAI_staticTriggerArray"] call A3XAI_updateSpawnCount;
	0 = [_trigger] spawn A3XAI_despawn_static;

	if !(local _unitGroup) then {
		A3XAI_sendGroupTriggerVars_PVC = [_unitGroup,[_unitGroup],PATROL_DIST_VEHICLEGROUP,1,1,[_unitsAlive,0],0,"vehiclecrew",false,true];
		A3XAI_HCObjectOwnerID publicVariableClient "A3XAI_sendGroupTriggerVars_PVC";
	};

	true
} else {
	_unitGroup setVariable ["GroupSize",-1];
	if !(local _unitGroup) then {
		A3XAI_updateGroupSize_PVC = [_unitGroup,-1];
		A3XAI_HCObjectOwnerID publicVariableClient "A3XAI_updateGroupSize_PVC";
	};
	deleteVehicle _vehicle;
	if (A3XAI_debugLevel > 0) then {
		diag_log format ["A3XAI Debug: Vehicle group %1 inside no-aggro area. Deleting group.",_unitGroup];
	};
	
	false
};
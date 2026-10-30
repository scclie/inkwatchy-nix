{ configPath ? null }:
let
  config =
    if configPath == null then
      {}
    else
      import (builtins.toPath configPath);
  inkwatchy = config.inkwatchy or {};
  target = inkwatchy.target or "Watchy_2";
  defines = inkwatchy.defines or {};
  rawDefines = inkwatchy.rawDefines or {};
  validDefine = value:
    let type = builtins.typeOf value;
    in type == "bool" || type == "int" || type == "string";
  validRawDefine = value: builtins.typeOf value == "string";
in
assert builtins.isAttrs config;
assert builtins.isAttrs inkwatchy;
assert target == "Watchy_2";
assert builtins.isAttrs defines;
assert builtins.isAttrs rawDefines;
assert builtins.all (name: validDefine defines.${name}) (builtins.attrNames defines);
assert builtins.all (name: validRawDefine rawDefines.${name}) (builtins.attrNames rawDefines);
{
  inherit defines rawDefines target;
}

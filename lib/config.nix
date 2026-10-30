{ templatePath, configPath ? null }:
let
  config = import ./eval-config.nix { inherit configPath; };
  template = builtins.readFile (builtins.toPath templatePath);
  lines = builtins.filter builtins.isString (builtins.split "\n" template);
  parseDefine = line:
    let
      match = builtins.match
        "^[ \t]*(//[ \t]*)?#define[ \t]+([A-Za-z_][A-Za-z0-9_]*)([ \t]+.*)?$"
        line;
    in
      if match == null then null else { name = builtins.elemAt match 1; };
  definitions = builtins.filter (definition: definition != null) (map parseDefine lines);
  names = map (definition: definition.name) definitions;
  known = builtins.listToAttrs (map (name: { inherit name; value = true; }) names);
  typedNames = builtins.attrNames config.defines;
  rawNames = builtins.attrNames config.rawDefines;
  duplicateNames = builtins.filter (name: builtins.hasAttr name config.rawDefines) typedNames;
  configuredNames = typedNames ++ rawNames;
  unknownNames = builtins.filter (name: !(builtins.hasAttr name known)) configuredNames;
  renderTyped = value:
    if builtins.isBool value then
      if value then "1" else "0"
    else if builtins.isInt value then
      toString value
    else
      builtins.toJSON value;
  typedValues = builtins.mapAttrs (_: renderTyped) config.defines;
  values = typedValues // config.rawDefines;
  renderLine = line:
    let definition = parseDefine line;
    in
      if definition != null && builtins.hasAttr definition.name values then
        "#define ${definition.name} ${values.${definition.name}}"
      else
        line;
in
if builtins.length names != builtins.length (builtins.attrNames known) then
  throw "duplicate template define"
else if duplicateNames != [] then
  throw "duplicate define: ${builtins.head duplicateNames}"
else if unknownNames != [] then
  throw "unknown define: ${builtins.head unknownNames}"
else
  builtins.concatStringsSep "\n" (map renderLine lines)

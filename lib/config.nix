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
  parsed = builtins.foldl' (state: line:
    let
      startsBlock = builtins.match ".*/\\*.*" line != null;
      endsBlock = builtins.match ".*\\*/.*" line != null;
      inBlock = state.inBlock || startsBlock;
      definition = if inBlock then null else parseDefine line;
    in {
      inBlock = if state.inBlock then !endsBlock else startsBlock && !endsBlock;
      entries = state.entries ++ [{ inherit definition line; }];
    }
  ) {
    inBlock = false;
    entries = [];
  } lines;
  definitions = builtins.filter (definition: definition != null)
    (map (entry: entry.definition) parsed.entries);
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
  renderLine = entry:
    if entry.definition != null && builtins.hasAttr entry.definition.name values then
      "#define ${entry.definition.name} ${values.${entry.definition.name}}"
    else
      entry.line;
in
if builtins.length names != builtins.length (builtins.attrNames known) then
  throw "duplicate template define"
else if duplicateNames != [] then
  throw "duplicate define: ${builtins.head duplicateNames}"
else if unknownNames != [] then
  throw "unknown define: ${builtins.head unknownNames}"
else
  builtins.concatStringsSep "\n" (map renderLine parsed.entries)

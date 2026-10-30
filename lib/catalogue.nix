{ templatePath }:
let
  template = builtins.readFile (builtins.toPath templatePath);
  lines = builtins.filter builtins.isString (builtins.split "\n" template);
  parseDefine = line:
    let
      match = builtins.match
        "^[ \t]*(//[ \t]*)?#define[ \t]+([A-Za-z_][A-Za-z0-9_]*)([ \t]+(.*))?$"
        line;
      value = if match == null then null else builtins.elemAt match 3;
    in
      if match == null then null else {
        name = builtins.elemAt match 1;
        value = if value == null || value == "" then "1" else value;
      };
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
  firstToken = value:
    let match = builtins.match "^[ \t]*([^ \t]+).*" value;
    in if match == null then value else builtins.elemAt match 0;
  typedValue = value:
    builtins.match "^-?[0-9]+$" value != null
    || value == "true"
    || value == "false"
    || builtins.match "^\"[^\"]*\"$" value != null;
  defineLine = definition:
    let value = firstToken definition.value;
    in if typedValue value then
      "      # ${definition.name} = ${value};"
    else
      "      # ${definition.name} = ${builtins.toJSON value};";
  commentLine = line:
    let match = builtins.match "^[ \t]*//[ \t]?(.*)$" line;
    in if match == null then null else "      # ${builtins.elemAt match 0}";
  definesLines = builtins.filter (line: line != null) (map (entry:
    if entry.definition != null && typedValue (firstToken entry.definition.value) then
      defineLine entry.definition
    else if entry.definition == null then
      commentLine entry.line
    else
      null
  ) parsed.entries);
  rawLines = builtins.filter (line: line != null) (map (entry:
    if entry.definition != null && !(typedValue (firstToken entry.definition.value)) then
      defineLine entry.definition
    else
      null
  ) parsed.entries);
in
if builtins.length names != builtins.length (builtins.attrNames known) then
  throw "duplicate template define"
else
  builtins.concatStringsSep "\n" ([
    "{"
    "  inkwatchy = {"
    "    target = \"Watchy_2\";"
    ""
    "    defines = {"
  ] ++ definesLines ++ [
    "    };"
    ""
    "    rawDefines = {"
  ] ++ rawLines ++ [
    "    };"
    "  };"
    "}"
    ""
  ])

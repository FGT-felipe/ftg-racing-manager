import re

original_file = r"d:\PROYECTOS\Fire Tower Games\Projects\ftg-racing-manager\refactor_original.dart"
target_file = r"d:\PROYECTOS\Fire Tower Games\Projects\ftg-racing-manager\lib\screens\race\race_strategy_screen.dart"

with open(original_file, "r", encoding="utf-8") as f:
    orig = f.read()

# settings_str
# search for `Text(\n                          "CAR CONFIGURATION",`
settings_start = orig.find('Text(\n                          "CAR CONFIGURATION",')
settings_end = orig.find('const SizedBox(width: 24);\n                  // COLUMN B: STRATEGY')
if settings_end == -1: settings_end = orig.find('const SizedBox(width: 24),\n                  // COLUMN B: STRATEGY')

settings_str = orig[settings_start:settings_end].strip()
# remove trailing `],` that closes the column
settings_str = settings_str.rsplit("],", 1)[0].strip()

# strategy_str
strategy_start = orig.find('Text(\n                          "STRATEGY & PIT STOPS",')
strategy_end = orig.find('// Closes Right Column children')
if strategy_end == -1:
    strategy_end = orig.find('const SizedBox(height: 32),\n            SizedBox(')

strategy_str = orig[strategy_start:strategy_end].strip()

# Now we have the correct strings.
# But wait, original file had `Row( children: [ Expanded( Column( CAR ) ), Expanded( Column( STRATEGY ) ) ])`
# The closing brackets are complex.

# Let's write a targeted regex to just grab the children of the internal columns.

settings_match = re.search(r'Text\(\s*"CAR CONFIGURATION",.*?(?=const SizedBox\(width: 24)', orig, re.DOTALL)
if settings_match:
    settings_str = settings_match.group(0).strip()
    # strip trailing `],` and `),` and `),` manually
    settings_str = re.sub(r'\],\s*\),\s*\),\s*$', '', settings_str).strip()

strategy_match = re.search(r'Text\(\s*"STRATEGY & PIT STOPS",.*?(?=const SizedBox\(height: 32\))', orig, re.DOTALL)
if strategy_match:
    strategy_str = strategy_match.group(0).strip()
    # strip trailing brackets (the end of the Row and inner Columns)
    # The inner row ends at: 
    #                         ),
    #                       ],
    #                     ),
    #                   ),
    #                 ],
    #               ),
    #             ],
    # So we can just split at `if (!_isSubmitted && currentSetup.pitStops.length < 5)` and include that block, ignoring the rest.
    p = strategy_str.find("OutlinedButton.styleFrom(")
    if p != -1:
        # find the end of the OutlinedButton
        p2 = strategy_str.find("),", p)
        p3 = strategy_str.find("),", p2 + 1)
        p4 = strategy_str.find("),", p3 + 1)
        strategy_str = strategy_str[:p4 + 2]
    else:
        # fallback
        pass

with open(target_file, "r", encoding="utf-8") as f:
    target_content = f.read()

# target_content has `Widget _buildCarConfiguration(DriverSetupInfo currentSetup, ThemeData theme) {\n    return Column(\n      crossAxisAlignment: CrossAxisAlignment.start,\n      children: [\n        \n      ],\n    );\n  }`
new_car_cfg = f'''Widget _buildCarConfiguration(DriverSetupInfo currentSetup, ThemeData theme) {{
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        {settings_str}
      ],
    );
  }}'''

new_strategy = f'''Widget _buildStrategyAndPitStops(DriverSetupInfo currentSetup, ThemeData theme) {{
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        {strategy_str}
      ],
    );
  }}'''

# replace
target_content = re.sub(r'Widget _buildCarConfiguration.*?\}\n  \}', new_car_cfg, target_content, flags=re.DOTALL)
target_content = re.sub(r'Widget _buildStrategyAndPitStops.*?\}\n  \}', new_strategy, target_content, flags=re.DOTALL)

with open(target_file, "w", encoding="utf-8") as f:
    f.write(target_content)

print(f"settings len: {{len(settings_str)}}, strategy len: {{len(strategy_str)}}")

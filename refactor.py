import re

filepath = r"d:\PROYECTOS\Fire Tower Games\Projects\ftg-racing-manager\lib\screens\race\race_strategy_screen.dart"
with open(filepath, "r", encoding="utf-8") as f:
    lines = f.readlines()

content = "".join(lines)

# We will extract the blocks from the old build method manually by finding boundaries.
header_start = content.find("Card(\n              color: theme.colorScheme.surface")
header_end = content.find("const SizedBox(height: 24);\n\n            if (_circuit != null)")
if header_end == -1: header_end = content.find("const SizedBox(height: 24),\n\n            if (_circuit != null)")
header_str = content[header_start:header_end].strip()

_circuit_start = content.find("              Text(\n                \"Circuit Characteristics\",")
c_end = content.find("const SizedBox(height: 24),\n            ],")
circuit_str = content[_circuit_start:c_end].strip()

driver_tabs_start = content.find("if (_drivers.isNotEmpty)\n                        Container(\n                          height: 50,")
driver_tabs_end = content.find("if (currentSetup != null) ...[")
driver_tabs_str = content[driver_tabs_start:driver_tabs_end].strip()
# Remove the 'if (_drivers.isNotEmpty)' from the string because we move it to the build method
if driver_tabs_str.startswith("if (_drivers.isNotEmpty)"):
    driver_tabs_str = driver_tabs_str.replace("if (_drivers.isNotEmpty)\n                        ", "")

settings_start = content.find("Text(\n                                        \"CAR CONFIGURATION\",")
settings_end = content.find("const SizedBox(width: 24),\n                            // COLUMN B: STRATEGY")
settings_str = content[settings_start:settings_end].strip()
settings_str = settings_str.rsplit("],", 1)[0].strip()

strategy_start = content.find("Text(\n                                        \"STRATEGY & PIT STOPS\",")
strategy_end = content.find("], // Closes Right Column children")
strategy_str = content[strategy_start:strategy_end].strip()
strategy_str = strategy_str.rsplit("],", 1)[0].strip()

submit_start = content.find("SizedBox(\n              width: double.infinity,\n              child: ElevatedButton.icon(")
submit_end = content.find("],\n        ),\n      ),\n    );\n\n    if (widget.isEmbed) return content;")
submit_str = content[submit_start:submit_end].strip()

build_method_start = content.find("  Widget build(BuildContext context) {")
top_part = content[:build_method_start]
bottom_part = content[content.find("if (widget.isEmbed) return content;"):]

new_build_method = '''  Widget build(BuildContext context) {
    if (_isLoading && _circuit == null) {
      final loadingIndicator = const Center(child: CircularProgressIndicator());
      if (widget.isEmbed) return loadingIndicator;
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: loadingIndicator,
      );
    }

    final currentSetup = _selectedDriverId != null
        ? _driverSetups[_selectedDriverId]
        : null;
    final theme = Theme.of(context);

    final content = SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT COLUMN
            Expanded(
              flex: 5,
              child: _buildQualifyingGrid(),
            ),
            const SizedBox(width: 32),
            // RIGHT COLUMN
            Expanded(
              flex: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(theme),
                  const SizedBox(height: 24),
                  
                  if (_circuit != null) ...[
                    _buildCircuitCharacteristics(theme),
                    const SizedBox(height: 24),
                  ],

                  const Text(
                    "CONFIGURE DRIVER:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  if (_drivers.isNotEmpty) _buildDriverSelectorTabs(theme),
                  
                  if (currentSetup != null) ...[
                    _buildCarConfiguration(currentSetup, theme),
                    const SizedBox(height: 32),
                    _buildStrategyAndPitStops(currentSetup, theme),
                  ],

                  const SizedBox(height: 32),
                  _buildSubmitButton(theme),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    '''

helpers = f'''

  Widget _buildHeaderCard(ThemeData theme) {{
    return {header_str},
    );
  }}

  Widget _buildCircuitCharacteristics(ThemeData theme) {{
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        {circuit_str}
      ],
    );
  }}

  Widget _buildDriverSelectorTabs(ThemeData theme) {{
    return {driver_tabs_str};
  }}

  Widget _buildCarConfiguration(DriverSetupInfo currentSetup, ThemeData theme) {{
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        {settings_str}
      ],
    );
  }}

  Widget _buildStrategyAndPitStops(DriverSetupInfo currentSetup, ThemeData theme) {{
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        {strategy_str}
      ],
    );
  }}

  Widget _buildSubmitButton(ThemeData theme) {{
    return {submit_str};
  }}
'''

final_content = top_part + helpers + new_build_method + bottom_part

with open(filepath, "w", encoding="utf-8") as f:
    f.write(final_content)
print("File rewritten successfully")

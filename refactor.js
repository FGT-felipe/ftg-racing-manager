const fs = require('fs');

const code = fs.readFileSync('functions/index.js', 'utf8');

const scheduledRaceRegex = /exports\.scheduledRace\s*=\s*onSchedule\(\{\s*schedule:\s*"0 14 \* \* 0",\s*timeZone:\s*"America\/Bogota",\s*memory:\s*"1GiB",\s*timeoutSeconds:\s*540,\s*\}, async \(\) => \{\s*logger\.info\("=== RACE START ==="\);\s*try \{(.*?)\}\s*catch\s*\((.*?)\)\s*\{\s*logger\.error\("Error in scheduledRace",\s*\2\);\s*\}\s*\}\);/s;

const match = code.match(scheduledRaceRegex);
if (match) {
    const tryBlockLogic = match[1];

    const replacement = `
async function runRaceLogic() {
  try {
${tryBlockLogic}
  } catch(err) {
    logger.error("Error in runRaceLogic", err);
  }
}

exports.scheduledRace = onSchedule({
  schedule: "0 14 * * 0",
  timeZone: "America/Bogota",
  memory: "1GiB",
  timeoutSeconds: 540,
}, async () => {
  logger.info("=== RACE START ===");
  await runRaceLogic();
});
`;

    const newCode = code.replace(scheduledRaceRegex, replacement);
    fs.writeFileSync('functions/index.js', newCode);
    console.log("Refactoring complete");
} else {
    console.log("Could not match scheduledRace block. Please check the regex.");
}

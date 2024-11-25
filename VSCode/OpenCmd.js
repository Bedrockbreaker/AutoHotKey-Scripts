const { exec } = require("child_process");

const workspaceFolder = process.argv[2];

function getCommand(folder, platform) {
	return {
		win32: `wt -d "${folder}"`,
		darwin: `open -a Terminal "${folder}"`,
		linux: `systemd-run --user --quiet konsole --workdir "${folder}"`,
	}[platform];
}

exec(getCommand(workspaceFolder, process.platform));
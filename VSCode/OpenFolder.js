const { exec } = require("child_process");

const workspaceFolder = process.argv[2];

function getCommand(folder, platform) {
	return {
		win32: `explorer "${folder}"`,
		darwin: `open "${folder}"`,
		linux: `systemd-run --user --quiet dolphin --new-window "${folder}"`,
	}[platform];
}

exec(getCommand(workspaceFolder, process.platform));
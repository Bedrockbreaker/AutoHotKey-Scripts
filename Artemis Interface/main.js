function post() {
	fetch("http://localhost:9696/plugins/ab41d601-35e0-4a73-bf0b-94509b006ab0/StringEndPoint", { method: "POST", body: process.argv[2] })
		.then(res => { if (res.status !== 200) setTimeout(() => post(), 5000); })
		.catch(err => setTimeout(() => post(), 5000));
}

post();
logs-screen
    svg.feather.aLoader(if="{loading}")
        use(xlink:href="data/icons.svg#loader")
    pre(if="{logs}" ref="codeBlock")
        code {logs}
    script.
        const exec = require('util').promisify(require('child_process').exec);
        this.loading = true;

        const refreshLogs = async () => {
            const {stdout} = await exec(`${opts.provider} logs ${opts.container.ID}`);
            this.logs = stdout;
            this.loading = false;
            this.update();

            this.refs.codeBlock.scrollTo(0, this.refs.codeBlock.scrollHeight);
        };
        refreshLogs();
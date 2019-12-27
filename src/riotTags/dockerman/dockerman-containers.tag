dockerman-containers
    .toright
        .ghostlyButton(title="Refresh (it is done automatically every 10 seconds)" onclick="{refresh}")
            svg.feather.rotatehoverccw(if="{!loading}")
                use(xlink:href="data/icons.svg#refresh-ccw")
            svg.feather.aLoader(if="{loading}").rotate
                use(xlink:href="data/icons.svg#loader")
    <yield/>
    .clear
    p.anErrorBlock(if="{error}") {error.toString()}
    button(if="{showLaunchDocker}" onclick="{launchDocker}")
        svg.feather
            use(xlink:href="data/icons.svg#play")
            span Launch Docker
    .aContainer(if="{containers}" each="{containers}")
        .aContainer-anIcon
            svg.feather
                use(xlink:href="data/icons.svg#hexagon")
        .aContainer-aName
            h3.clipboard(onclick="{copyText}") {Names}
            code.clipboard(onclick="{copyText}") {ID}
        .aContainer-anImage {Image}
        .aContainer-aStatus {Status}
        .aContainer-Ports
            a.ghostlyButton(each="{parsePorts(Ports)}" href="{href}")
                code(if="{publicIp}") {publicIp !== '0.0.0.0'? publicIp : 'local'}:{publicPort}
                span(if="{publicIp}")
                    |
                    | →
                    |
                code {internalPort}@{protocol}
        .aContainer-Actions
            .ghostlyButton(title="Show logs" onclick="{toggleLogs}" class="{active: showLogs}")
                svg.feather
                    use(xlink:href="data/icons.svg#align-left")
            .ghostlyButton(title="Run command" onclick="{toggleTerminal}" class="{active: showTerminal}")
                svg.feather
                    use(xlink:href="data/icons.svg#terminal")
            .ghostlyButton(title="Stop the container" onclick="{stopContainer}")
                svg.feather(if="{!stopping}")
                    use(xlink:href="data/icons.svg#x-octagon")
                svg.feather(if="{stopping}").rotate
                    use(xlink:href="data/icons.svg#loader")
            .ghostlyButton(title="Kill the container" onclick="{killContainer}")
                svg.iconify
                    use(xlink:href="data/icons.svg#kill")
        .aContainer-Logs(if="{showLogs}")
            logs-screen(container="{this}" provider="{opts.provider}")
        .aContainer-aTerminal(if="{showTerminal}")
            terminal-screen(container="{this}" provider="{opts.provider}")
    p.anInfoBlock(if="{containers && !containers.length}") No containers here!
    script.
        this.opts.provider = this.opts.provider || 'docker';
        const exec = require('util').promisify(require('child_process').exec);

        const template = `'{
            "Status": "{{.Status}}",
            "Names": "{{.Names}}",
            "ID": "{{.ID}}",
            "Image": "{{.Image}}",
            "Ports": "{{.Ports}}"
        }'`.split(/\n +/).join('');

        this.loading = true;
        const getContainers = async () => {
            const provider = this.opts.provider;
            try {
                const command = `${provider} container list --format=${provider === 'podman'? 'json' : '\'{{json .}}\''}`;
                let {stdout} = await exec(command);
                console.debug(stdout);
                if (provider === 'docker') {
                    stdout = `[${stdout.split('\n').join(',')}]`;
                }
                const newContainers = JSON.parse(stdout);
                if (!this.containers) {
                    this.containers = newContainers;
                } else {
                    // Update the old array from the new one, so we don't trigger excess layout updates and don't loose state of UI components
                    for (const cont of newContainers) {
                        const oldcont = this.containers.find(oldcont => oldcont.id === cont.id);
                        if (!oldcont) {
                            // this is a new container, add it to the list of containers
                            this.containers.push(cont);
                        } else {
                            // this is an existing container, update it
                            for (const i in cont) {
                                oldcont[i] = cont[i];
                            }
                        }
                    }
                    // Reverse lookup to remove excess containers
                    for (const oldcont of this.containers) {
                        const ind = newContainers.findIndex(newcont => newcont.id === oldcont.id)
                        if (ind === -1) {
                            this.containers.splice(ind, 1);
                        }
                    }
                }
                this.loading = false;
                delete this.error;
                this.update();
            } catch (e) {
                this.error = e;
                if (this.error.toString().includes('Is the docker daemon running?') &&
                    provider === 'docker' &&
                    process.platform === 'linux'
                ) {
                    this.showLaunchDocker = true;
                }
                this.update();
                throw e;
            }
        };
        getContainers();
        setInterval(getContainers, 1000 * 10);

        this.launchDocker = async e => {
            this.showLaunchDocker = false;
            this.loading = true;
            this.update();
            try {
                await exec('systemctl start docker');
                getContainers();
            } catch (e) {
                this.error = e;
                this.loading = false;
                this.update();
                throw e;
            }
        };

        this.toggleLogs = e => {
            e.item.showLogs = !e.item.showLogs;
        };
        this.toggleTerminal = e => {
            e.item.showTerminal = !e.item.showTerminal;
        };
        this.killContainer = async e => {
            try {
                let {stdout} = await exec(`${this.opts.provider} kill ${e.item.ID}`);
                console.debug(stdout);
                getContainers();
            } catch(e) {
                this.error = e;
                this.update();
            }
        };
        this.stopContainer = async e => {
            if (e.item.stopping) {
                return;
            }
            try {
                e.item.stopping = true;
                this.update();
                let {stdout} = await exec(`${this.opts.provider} stop ${e.item.ID}`);
                console.debug(stdout);
                getContainers();
            } catch(e) {
                this.error = e;
                e.item.stopping = false;
                this.update();
            }
        };

        this.refresh = e => {
            if (this.loading) {
                return;
            }
            getContainers();
        };

        const portPattern = /((?<publicIp>\d+\.\d+\.\d+\.\d+):(?<publicPort>\d+)->)?(?<internalPort>\d+)\/(?<protocol>\w+)/i;
        this.parsePorts = str => {
            const rawPorts = str.split(/,\s*/);
            const ports = rawPorts.map(port => {
                const result = portPattern.exec(port)
                const obj = {
                    internalPort: Number(result.groups.internalPort),
                    protocol: result.groups.protocol
                };
                if (result.groups.publicPort) {
                    obj.publicPort = Number(result.groups.publicPort);
                    obj.publicIp = result.groups.publicIp;
                    if (obj.internalPort !== 22 && obj.protocol === 'tcp') {
                        const webProtocol = (obj.publicPort === 433 || obj.internalPort === 443)? 'https' : 'http';
                        if (obj.publicIp === '0.0.0.0') {
                            obj.href = `${webProtocol}://localhost:${obj.publicPort}`;
                        } else {
                            obj.href = `${webProtocol}://${obj.publicIp}:${obj.publicPort}`;
                        }
                    }
                }
                return obj;
            });
            return ports;
        };

        this.copyText = e => {
            const {clipboard} = require('electron');
            clipboard.writeText(e.target.innerText);
            e.target.classList.add('copied');
            setTimeout(() => {
                e.target.classList.remove('copied');
            }, 1000);
        };
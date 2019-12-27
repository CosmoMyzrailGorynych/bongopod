terminal-screen
    pre(if="{result}")
        code
            | {result}
        svg.feather(if="{executing}")
            use(xlink:href="data/icons.svg#loader")
    form(onsubmit="{processForm}")
        input(type="text" refs="commandInput")
        button(type="submit") Submit
    script.
        const exec = require('util').promisify(require('child_process').exec);
        this.processForm = e => {
            e.preventDefault();

        }
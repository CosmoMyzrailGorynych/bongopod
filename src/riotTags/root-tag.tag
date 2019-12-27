root-tag
    header
        h1
            img(src="data/img/logo.svg")
            | BongoPod

    main
        section
            dockerman-containers(provider="docker")
                h2
                    svg.icon
                        use(xlink:href="data/icons.svg#docker")
                    span Docker
        section
            dockerman-containers(provider="podman")
                h2
                    svg.icon
                        use(xlink:href="data/icons.svg#podman")
                    span Podman
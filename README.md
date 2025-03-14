# nautobot-lab-pod-porter
* A pod-porter to deploy a nautobot lab environment to Podman or Docker.

* I **100%** recommend using Podman over Docker, but the choice is yours.

### Pod-Porter Reference

* [Pod-Porter](https://pod-porter.readthedocs.io/en/latest/)
* [Pod-Porter Examples](https://github.com/btr1975/automation-framework/tree/main/porter)

### Included
* Nautobot
* Nautobot-Celery-Worker
* Nautobot-Celery-Beat
* REDIS
* Postgres
* Vault

### Some Directions

* Clone the repo
* Build the container using the Makefile, or make.bat file in the containers directory
* Use pod-porter to generate the entire compose file
* Use podman-compose or docker-compose to deploy the environment

### Informational URLs

* [Pod-Porter](https://pod-porter.readthedocs.io/en/latest)
* [Podman](https://podman.io/)
* [Podman Compose](https://github.com/containers/podman-compose)
* [Docker](https://www.docker.com/)
* [Docker Compose](https://docs.docker.com/compose/)
* [Docker Swarm](https://docs.docker.com/engine/swarm/)
* [Compose Specification](https://compose-spec.io/)
* [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)
* [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)

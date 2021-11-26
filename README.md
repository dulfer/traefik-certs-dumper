# Traefik Certificates Dumper
This tool exports Let's Encrypt certificates from [Traefik](https://github.com/traefik/traefik), stored in `acme.json`, to  `.pem` and `.key` files on disk.  
The exported certificates can be linked or imported into other containers/applications and enable HTTPS support.

## Disclaimer
This image is based on [Alpine Linux](https://github.com/alpinelinux) (size ~46MB) and is built on top of the hard work of   
 * mailu: [mailu/traefik-certdumper](https://hub.docker.com/r/mailu/traefik-certdumper)
 * ldez: [ldez/traefik-certs-dumper](https://github.com/ldez/traefik-certs-dumper)
 * kereis: [kereis/traefik-certs-dumper](https://github.com/kereis/traefik-certs-dumper/)

The image is nice and small, but comes with a tradeoff. As there is no docker support in the image itself, automatic restarts are not supported. The output will hold __'Docker command is not available. Restart container functionality will not work!'__, including the suggestion to use an alternative image (humenius/traefik-certs-dumper:latest).

For reference documentation I suggest visiting their repositories and show them your appreciation for developing this tool while you are there.

*Note that this tool does __not__ take care of configuring the certificate retrieval process in Traefik itself, nor is it capable of handling the Let's Encrypt certificate process for you. To use it, you are expected to already have Traefik setup (and working!) with ACME certificate configuration. Instructions available in the [Traefik.io: Let's Encrypt](https://doc.traefik.io/traefik/https/acme/) docs.*
 
# Building the image
  > Given I put hardly any effort in creating this tool, I don't push a built image to the public registries. To use it, you'll have to build it yourself and use its image id to run it, or publish it to a (private)registry yourself. If you don't want to build it yourself, I suggest using the docker-based image published by kereis (```humenius/traefik-certs-dumper:latest```). The only difference with his and mine is the size of the image.

## Prerequisites
* Make sure you have Git installed for your platform: [git-guides: Install Git](https://github.com/git-guides/install-git)  
* Install the docker engine: [docs.docker.com: Get Docker](https://docs.docker.com/get-docker/).  
* (optional) Install Docker Compose to run the built image: [docs.docker.com: Compose / Install](https://docs.docker.com/compose/install/)   
More information about Docker Compose can be found on the tool's website: [docs.docker.com: Compose / Getting Started](https://docs.docker.com/compose/gettingstarted/)

## The build process
1. Clone this repository to local disk  
```bash
 git clone https://github.com/dulfer/traefik-certs-dumper.git
```
2. cd into the directory and run the following command
```bash
 cd traefik-certs-dumper  
 docker build .
```

3. Once the build has finished take note of the newly-built _image id_, displayed at the end of the build output.  
In the output example below this id is ```c41cd379be2e```
```docker
[...]
Step 11/12 : VOLUME ["/output"]
 ---> Running in 8f1d57c7d6ca
Removing intermediate container 8f1d57c7d6ca
 ---> d8041088596e
Step 12/12 : ENTRYPOINT ["/usr/bin/dump"]
 ---> Running in 07aaba04ebdb
Removing intermediate container 07aaba04ebdb
 ---> c41cd379be2e
Successfully built c41cd379be2e
```

## Docker Compose file
Create a new ```docker-compose.yaml``` in a new directory and paste in the configuration example below.  
> You can also add the following config to your existing docker-compose file that holds the _traefik_ compose config and have it depend on the traefik container using ```depends_on:```

The example below will exporting __all certificates__ to the output directory.  
Make sure you subsitute the following volumes and placeholders
| Item | Description |
|---|---|
| ```c41cd379be2e``` | Replace with the image id of your docker build |
| /opt/traefik/data | Path to your Traefik ```acme.json``` file | 
| /opt/ssl | Path where the certificates will be dumped to |

 ```yaml
version: "3.7"

services:
  certdumper:
    image: c41cd379be2e
    container_name: traefik_certdumper
    network_mode: none
    volumes:
      - /opt/traefik/data:/traefik:ro
      - /opt/ssl:/output:rw
      - /var/run/docker.sock:/var/run/docker.sock:ro
    healthcheck:
      test: ["CMD", "/usr/bin/healthcheck"]
      interval: 30s
      timeout: 10s
      retries: 5
 ```

## Run it!
Run
```bash
$ docker-compose up certdumper
```
If all goes well, the output should be something like this and certificates will be written to the output directory you configured in the docker-compose file.
```
$ docker-compose up certdumper
traefik is up-to-date
Recreating traefik_certdumper ... done
Attaching to traefik_certdumper
traefik_certdumper  | [2021-11-26T13:49:10+0000]: Docker command is not available. Restart container functionality will not work!
traefik_certdumper  | [2021-11-26T13:49:10+0000]: In case you need it, consider using the Docker version of this image.
traefik_certdumper  | [2021-11-26T13:49:10+0000]: (e.g.: humenius/traefik-certs-dumper:latest)
traefik_certdumper  | [2021-11-26T13:49:10+0000]: Got value of DOMAIN: mydomain.com. Splitting values.
traefik_certdumper  | [2021-11-26T13:49:10+0000]: Values split! Got 'mydomain.com'
traefik_certdumper  | [2021-11-26T13:49:10+0000]: ACME file path: /traefik/acme.json
traefik_certdumper  | [2021-11-26T13:49:10+0000]: Clearing dumping directory
traefik_certdumper  | [2021-11-26T13:49:10+0000]: Dumping certificates
traefik_certdumper  | [2021-11-26T13:49:10+0000]: Certificate and key for 'mydomain.com' still up to date, doing nothing
```
# Excalidraw docker-compose stack

## What is this?

If you want to self-host excalidraw without the need of an Internet connection, this is for you! It creates a complete Docker stack consisting of

- excalidraw (client)
- excalidraw-room (collaboration server)
- excalidraw-json (sharing server) *)
- Minio S3 (data store server)
- Nginx (frontend reverse proxy)

*) this is not the official excalidraw-json implementation, but the fantastic, S3-store based reimplementation of Minh Nguyen, see https://github.com/NMinhNguyen/excalidraw-json

The benefit of this setup is, that you only need to open the outside SSL port to Nginx from the host. All other network connections are being made over the internal Docker network.

The S3 datastore is being initialized on first start, so user, password and bucket will be set up for you, so you don't have to do anything here. Also, securing the access to the Minio server or the other components is not that important, because it will be reachable over the Docker overlay network only. The single containers' exposed ports are not reachable from the rest of the network.

Note:
As I wanted this to be independent of any Internet based network service as close as possible, I deactivated the configuration for the excalidraw Firebase database per default. If you want to use this database, you have to change the `REACT_APP_FIREBASE_CONFIG` accordingly.

## How to set this up and start?

Just copy the existing configuration example file `env-example` to `.env` and customize it to your needs. In most cases, you only have to setup a few variables to get it up and running. The main variable you have to configure is:

- PUB_SRV_NAME

Then two simple steps have to follow:

1. run `./build.sh` and wait for it to complete
2. run `docker-compose up -d`

Now, open your browser and navigate to the start page at `https://<PUB_SRV_NAME>`, add `:<HTTPS_PORT>` if necessary, like `https://my.test.server` or `https://my.test.server:8443`.

Note:
If you want to change the `HTTPS_PORT`, you do have to add the port to the values of the `REACT_APP_*` variables and run `./build.sh` again, too!

Here is an example:
You want to change Nginx's https listening port to 8443. Set `HTTPS_PORT=8443` in `.env` and change the other variables like so:

`REACT_APP_BACKEND_V1_GET_URL=https://$PUB_SRV_NAME:$HTTPS_PORT/api/v1/`
		or
`REACT_APP_BACKEND_V1_GET_URL=https://$PUB_SRV_NAME:8443/api/v1/`

(For more options, see table below.)

## What about own SSL certificates?

After the first start via `docker-compose` you will find self-signed certs under `./data/nginx/keys`. Simply

- stop everything via `docker-compose down`, 
- exchange `cert.crt` with your server certificate and `cert.key` with associated private no-password-key
- and start everything again with `docker-compose up -d`

Now Nginx should serve excalidraw with your own certificates.

## What are the provided scripts for?

- `build.sh` - this will get all necessary Github repositories, create the folder structure and build the local Docker images for the containers
- `cleanup.sh` - this will do the opposite: stop stack, remove Docker images and all folders (this will also destroy the shared storage!), but it keeps your `.env` file

## How to backup?

As you don't have the Firebase database in the background, you won't have saved rooms at all, but you have the S3 datastore for all shared drawings. Everything you need to backup is the `./data`folder which will be created on the first run of `build.sh`.

## What can be set up?

| Variable name                   | Default value                      | Comment                                                      |
| ------------------------------- | ---------------------------------- | ------------------------------------------------------------ |
| BUILDREPO                       | localbuild                         | Name of local Docker image repository                        |
| TZ                              | Europe/Berlin                      | Timezone                                                     |
| PUB_SRV_NAME                    | example.fritz.box                  | DNS name of the host by which it is accessable over you network |
| ENABLE_LETSENCRYPT              | 0                                  | Generate Let's Encrypt certs for Nginx via acme.sh or use your own (UNTESTED, only added for convenience and later use perhaps) |
| LETSENCRYPT_DOMAIN              | see `PUB_SRV_NAME`                 |                                                              |
| LETSENCRYPT_EMAIL               | admin@`PUB_SRV_NAME`               |                                                              |
| LETSENCRYPT_USE_STAGING         | 0                                  | Use Let's Encrypt staging server for testing                 |
| HTTP_PORT                       | 80                                 | http outside port for Nginx, only for permanent redirect to https |
| HTTPS_PORT                      | 443                                | https outside port for Nginx<br />Beware: see the REACT_APP_... entries also! |
| PROXY                           | (commented out)                    | Set as you would http(s)_proxy for Linux to build the stack over network proxy.<br />Beware: you might have to define a systemd override for docker.service, too! |
| REACT_APP_BACKEND_V1_GET_URL    | https://`PUB_SRV_NAME`/api/v1/     | (if you changed the https port to something else than 443, you have to add the port here, too!) |
| REACT_APP_BACKEND_V2_GET_URL    | https://`PUB_SRV_NAME`/api/v2/     | (if you changed the https port to something else than 443, you have to add the port here, too!) |
| REACT_APP_BACKEND_V2_POST_URL   | https://`PUB_SRV_NAME`/api/v2/post | (if you changed the https port to something else than 443, you have to add the port here, too!) |
| REACT_APP_SOCKET_SERVER_URL     | https://`PUB_SRV_NAME`/            | (if you changed the https port to something else than 443, you have to add the port here, too!) |
| REACT_APP_FIREBASE_CONFIG       | (empty)                            | Cleared out to stop excalidraw from connecting to Firebase database. |
| EXCALIDRAW_S3_ENDPOINT          | http://minio:3000                  | Dockerized S3 instance                                       |
| EXCALIDRAW_S3_BUCKET_NAME       | excalidraw                         | S3 bucket                                                    |
| EXCALIDRAW_S3_ACCESS_KEY_ID     | minios                             | S3 "user", set as you like, but don't change betweek restarts |
| EXCALIDRAW_S3_SECRET_ACCESS_KEY | miniosKey1234                      | S3 "pass", set as you like, but don't change between restarts |
| EXCALIDRAW_S3_FORCE_PATH_STYLE  | true                               |                                                              |
| EXCALIDRAW_ALLOWED_ORIGIN       | ''                                 | Localhost is already included, but everything else is handled via Nginx |



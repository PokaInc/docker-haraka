# docker-haraka
[![docker-haraka build status](https://img.shields.io/docker/build/pokainc/docker-haraka.svg)](https://hub.docker.com/r/pokainc/docker-haraka/)

Custom minimal Haraka image featuring a simple SMTP relay, automated DKIM record creation/deletion and a clone of the 
SES bounce notification system.

### Run
#### Required environment variables
* DOMAIN `# Domain name for creating the SPF record`
* HOSTED_ZONE_ID `# Hosted Zone Id from Route53 for creating the SPF record`
* BOUNCES_SNS_TOPIC_ARN `# The SNS topic where SES-like bounces notifications will be sent`

#### Optional environment variables
* LOG_LEVEL `(default: NOTICE)`

#### Exemple
```
docker run -e DOMAIN=exemple.com HOSTED_ZONE_ID=abc123 BOUNCES_SNS_TOPIC_ARN=arn:aws:sns:ca-central-1:111122223333:MyTopic -p 2525:25 pokainc/docker-haraka:v1.0.0
```

### Send a test mail
#### Exemple
```
docker run --rm flowman/swaks -f from@exemple.com -t to@exemple.com -s localhost -p 2525
```

### Development

#### Using Docker

```
make build
```

Just make sure you specify valid AWS credentials and resources as environment.

#### Locally
1. Make sure you have a valid `node` installation. 

2. Install Haraka using `npm install Haraka@2.8.16`. 

3. `cd` in the `app` dir run `npm install` to install the plugins dependencies.

4. Then `cd` back to this dir and start Hakara using `sudo karaka -c app/`. You can avoid `sudo` by changing the port
to something else.

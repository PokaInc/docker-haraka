# docker-haraka

Custom minimal Haraka image featuring a simple SMTP relay, automated DKIM record creation/deletion and a clone of the 
SES bounce notification system.

### Build
```
make build
```

### Push
```
make push
```

### Generate changelog
```
make generate-changelog FUTURE_RELEASE=vx.x.x
```

### Run
#### Required environment variables
* DOMAIN
* HOSTED_ZONE_ID
* AWS_REGION
* BOUNCES_SNS_TOPIC_ARN

#### Optional environment variables
* LOG_LEVEL `(default: NOTICE)`

### Development
#### Using Docker
Just make sure you specify valid AWS credentials and resources as environment.

#### Locally
1. Make sure you have a valid `node` installation. 

2. Install Haraka using `npm install Haraka@2.8.16`. 

3. `cd` in the `app` dir run `npm install` to install the plugins dependencies.

4. Then `cd` back to this dir and start Hakara using `sudo karaka -c app/`. You can avoid `sudo` by changing the port
to something else.
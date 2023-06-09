# codenow-aws-ecr-adapter

### Description

Component react on NATS scm.*.component.registered event. For the newly registered component it check if ECR is enabled for given account. If so, aws-ecr-adapter write new container registry repository into default.tfvars in customer space git repository and
 execute Terraform apply to provide the ECR into AWS. After that event about ok/nok ECR creation is emitted. 

![](./doc/diagram.png "")


### Project structure

`./cmd/` - main go function     
`./configs/` - Benthos configuration and pipeline definition  
`./dev/` - resources for local (docker-compose) development and mocking   
`./processor/` - custom Benthos processor implementation   
`./terraform/` - Terraform resources files definition  
`./docker-compose.yaml` - docker compose for local development, mocking and testing  
`./Dockerfile` - Dockerfile for binary go build a runtime image creation

### Build

- local
In root folder of this project run:

`docker build -t aws-ecr-adapter -f Dockerfile .`

- cloud  
trigger CODENOW SSP pipeline

### Local DEV

- fill AWS_S3_ACCESS_KEY_ID and AWS_S3_SECRET_ACCESS_KEY env variables in docker-compose.yaml to connecet tarreform to S3 state storage.  


- build image lovally as shown above  


- in root project directory:
```
docker compose up 
```

- to run nats sandbox run:
```
docker run --rm -it -v dev/nats/nats_nkey:/tmp/nats/nats_nkey natsio/nats-box:latest
```
- and inside the sandbox container publish message to nats subject:
```
nats pub -s nats://host.docker.internal:4222 scm.test.component.created '{"tenantName":"test","applicationName":"test-application","componentName":"test-component","owner":"romisek","personalSpace":true,"type":"xxx","sshUrl": "ss","httpUrl":"string"}' -H Access-Token:xxx --nkey /tmp/nats/nats_nkey
```

- also you can listen for result event:  
```
nats sub -s nats://host.docker.internal:4222 ecr.created  --nkey /tmp/nats/nats_nkey
```

### Deploy & release

This adapter must be deployed along with inventory-provisioner  

For release or preview deploy on dev environment run appropriate job in [SSP](https://stxcn.codenow.com/applications/code-now-container-registry/components/aws-ecr-adapter)  
Released helm package version is then referenced and deployed through ssp repo. See [/factory/codenow-aws-ecr-adapter/](https://github.com/StratoxEnterprises/codenow-customer-space-ssp-preview/blob/master/factory/codenow-aws-ecr-adapter/Chart.yaml) and
 [/factory/applications/](https://github.com/StratoxEnterprises/codenow-customer-space-ssp-preview/blob/master/factory/applications/templates/codenow-aws-ecr-adapter.yaml) example.

Ensure correct values (services hosts) and secrets (s3 access keys and nats key) are provided correctly.
#!/bin/bash


echo $imageName #getting Image name from env variable
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 991256897826.dkr.ecr.us-east-1.amazonaws.com

docker run --rm -v /root/.docker/config.json:/root/.docker/config.json  \
    -v $WORKSPACE:/root/.cache/  \
    aquasec/trivy:0.17.2 -q image --exit-code 0 --severity LOW,MEDIUM,HIGH --light $imageName

docker run --rm -v /root/.docker/config.json:/root/.docker/config.json  \
    -v $WORKSPACE:/root/.cache/  \
    aquasec/trivy:0.17.2 -q image --exit-code 1 --severity CRITICAL --light $imageName

# docker run --rm -v $WORKSPACE:/root/.cache/ aquasec/trivy:0.17.2 -q image --exit-code 0 --severity LOW,MEDIUM,HIGH --light $imageName
# docker run --rm -v $WORKSPACE:/root/.cache/ aquasec/trivy:0.17.2 -q image --exit-code 1 --severity CRITICAL --light $imageName

    # Trivy scan result processing
    exit_code=$?
    echo "Exit Code : $exit_code"

    # Check scan results
    if [[ ${exit_code} == 1 ]]; then
        echo "Image scanning failed. Vulnerabilities found"
        exit 1;
    else
        echo "Image scanning passed. No vulnerabilities found"
    fi;
# Demo: Analyze images with anchorectl in a jenkins pipeline without the Anchore plugin

[![Anchore Enterprise with anchorectl](https://github.com/pvnovarese/anchorectl-pipeline/actions/workflows/anchorectl-enterprise.yaml/badge.svg)](https://github.com/pvnovarese/anchorectl-pipeline/actions/workflows/anchorectl-enterprise.yaml)

This is a very rough demo of integrating Anchore with Jenkins using anchorectl.  

## Part 1: Jenkins Setup

We're going to run jenkins in a container to make this fairly self-contained and easily disposable.  This command will run jenkins and bind to the host's docker sock (if you don't know what that means, don't worry about it, it's not important).

`$ docker run -u root -d --name jenkins --rm -p 8080:8080 -p 50000:50000 -v /var/run/docker.sock:/var/run/docker.sock -v /tmp/jenkins-data:/var/jenkins_home jenkinsci/blueocean
`

and we'll need to install jq, python, and anchore-cli in the jenkins container:

```
 $ docker exec --user=0 jenkins /bin/bash
 # apk add jq python3 
 # python3 -m ensurepip
 # pip3 install --upgrade pip setuptools anchorecli
 # curl -o /tmp/anchorectl.tar.gz https://anchorectl-releases.s3-us-west-2.amazonaws.com/v0.1.3/anchorectl_0.1.3_linux_amd64.tar.gz
 # tar xzvf /tmp/anchorectl.tar.gz --directory /usr/local/bin
 # exit 
``` 

Once Jenkins is up and running, we have just a few things to configure:
- Get the initial password (`$ docker logs jenkins`)
- log in on port 8080
- Unlock Jenkins using the password from the logs
- Select “Install Selected Plugins” and create an admin user
- Create a credential so we can push images into Docker Hub:
	- go to manage jenkins -> manage credentials
	- click “global” and “add credentials”
	- Use your Docker Hub username and password (get an access token from Docker Hub if you are using multifactor authentication), and set the ID of the credential to “docker-hub”.
- Create a credential so we can send image analysis to Anchore	
	- go to manage jenkins -> manage credentials
	- click “global” and “add credentials”
	- Use an Anchore username and password, and set the ID of the credential to “AnchoreJenkinsUser”.


## Part 2: A Simple Image Scan

Now we’ll set up a simple package stoplist with syft:

- Fork this repo
- edit the Jenkinsfile and set ANCHORE_URL to your appropriate API endpoint
- From the jenkins main page, select “New Item” 
- Name it “Anchore Demo with CLI”
- Choose “pipeline” and click “OK”
- On the configuration page, scroll down to “Pipeline”
- For “Definition,” select “Pipeline script from SCM”
- For “SCM,” select “git”
- For “Repository URL,” paste in the URL of your forked github repo
	e.g. https://github.com/pvnovarese/anchore-pipeline-no-plugin (with your github user ID)
- Click “Save”
- You’ll now be at the top-level project page.  Click “Build Now”

Jenkins will check out the repo and build an image using the provided Dockerfile.  This image will be a simple copy of the alpine base image with curl added.  Once the image is built, Jenkins will call Syft, analyze the image, send the results to the Anchore instance, re-tag the image as "prod," push the prod tag to Docker Hub, and then delete the images locally.

## Part 3: Cleanup
- Kill the jenkins container (it will automatically be removed since we specified --rm when we created it):
	`pvn@gyarados /home/pvn> docker kill jenkins`
- Remove the jenkins-data directory from /tmp
	`pvn@gyarados /home/pvn> sudo rm -rf /tmp/jenkins-data/`
- Remove all demo images from your local machine:
	`pvn@gyarados /home/pvn> docker image ls | grep -E "anchore-pipeline-scanning" | awk '{print $3}' | xargs docker image rm -f`


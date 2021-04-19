// requires syft https://github.com/anchore/syft
// version 0.12.6 or higher
// requires anchore engine or anchore enterprise 
//
pipeline {
  environment {
    // set some variables
    //
    // we don't need registry if using docker hub
    // but if you're using a different registry, set this 
    // REGISTRY = 'registry.hub.docker.com'
    //
    // set path for syft executable.  I put this in jenkins_home as noted
    // in README but you may install it somewhere else like /usr/local/bin
    SYFT_LOCATION = "/var/jenkins_home/syft"
    //
    // you will need a credential with your docker hub user/pass
    // (or whatever registry you're using) and a credential with
    // user/pass for your anchore instance:
    // ...
    // first let's set the docker hub credential and extract user/pass
    // we'll use the USR part for figuring out where are repository is
    HUB_CREDENTIAL = "docker-hub"
    // use credentials to set DOCKER_HUB_USR and DOCKER_HUB_PSW
    DOCKER_HUB = credentials("${HUB_CREDENTIAL}")
    // we'll need the anchore credential to pass the user
    // and password to syft so it can upload the results
    ANCHORE_CREDENTIAL = "AnchoreJenkinsUser"
    // use credentials to set ANCHORE_USR and ANCHORE_PSW
    ANCHORE = credentials("${ANCHORE_CREDENTIAL}")
    //
    // api endpoint of your anchore instance
    ANCHORE_URL = "http://anchore3-priv.novarese.net:8228/v1"
    //
    // assuming you want to use docker hub, this shouldn't need
    // any changes, but if you're using another registry, you
    // may need to tweek REPOSITORY 
    REPOSITORY = "${DOCKER_HUB_USR}/anchore-pipeline-scanning"
    TAG = ":devbuild-${BUILD_NUMBER}"    
    //
    // don't need an IMAGELINE if we're not using the anchore plugin
    // IMAGELINE = "${REPOSITORY}${TAG} Dockerfile"
  } // end environment
  agent any
  stages {
    stage('Checkout SCM') {
      steps {
        checkout scm
      } // end steps
    } // end stage "checkout scm"
    stage('Build image and tag as dev') {
      steps {
        script {
          // build image and record repo/tag in DOCKER_IMAGE
          // for now we're just going to build and pass it 
          // to syft to scan, then later we'll push to the 
          // registry which is why we need to save this in
          // DOCKER_IMAGE variable.
          // 
          DOCKER_IMAGE = docker.build REPOSITORY + TAG
        } // end script
      } // end steps
    } // end stage "build image and tag as dev"
    stage('Analyze with syft and send report to Anchore') {
      steps {
        // execute SYFT_LOCATION with the image we just built.  options:
        // -H, --host string      the hostname or URL of the Anchore Enterprise instance to upload to
        // -u, --username string  the username to authenticate against Anchore Enterprise
        // -p, --password string. the password to authenticate against Anchore Enterprise
        sh '${SYFT_LOCATION} ${REPOSITORY}${TAG} -H ${ANCHORE_URL} -u ${ANCHORE_USR} -p ${ANCHORE_PSW}'
          //
          // if we want to also do a simple package block, we can add something like this:
          // syft -o json /                             # json output is more reliable to parse
          // -H ${ANCHORE_URL} -u ${ANCHORE_USR} -p ${ANCHORE_PSW} ${REPOSITORY}${TAG} | /
          // jq .artifacts[].name | tr "\n" " " | /.    # extract package names and remove linebreaks
          // grep -qv curl                              # fail if "curl" (or whatever) is in the list of packages
          //
          // IMPORTANT!
          // ----------
          // syft ONLY uploads the software bill of materials and does NOT 
          // get an evaluation back.  if you want to evaluate the image
          // and make a decision about breaking the pipeline, you'll need
          // to do something like this:
        sh '/usr/bin/anchore-cli --url ${ANCHORE_URL} --u {ANCHORE_USR} --p ${ANCHORE_PSW} evaluate check ${REPOSITORY}${TAG}'
          // 
      } // end steps
    } // end stage "analyze with syft"
    // THIS STAGE IS OPTIONAL
    // the purpose of this stage is to simply show that if an image passes the scan we could
    // continue the pipeline with something like "promoting" the image to production etc
    //stage('Re-tag as prod and push to registry') {
    //  steps {
    //    script {
    //      docker.withRegistry( '', HUB_CREDENTIAL) {
    //        DOCKER_IMAGE.push('prod') 
    //        // DOCKER_IMAGE.push takes the argument as a new tag for the image before pushing          
    //      }
    //    } // end script
    //  } // end steps
    //} // end stage "re-tag as prod"
    stage('Clean up') {
      // delete the images locally
      steps {
        sh 'docker rmi ${REPOSITORY}${TAG} #${REPOSITORY}:prod || failure=1' 
        //
        // the "|| failure=1" at the end of this line just catches problems with the :prod
        // tag not existing if we didn't uncomment the optional "re-tag as prod" stage
        //
      } // end steps
    } // end stage "clean up"
  } // end stages
} // end pipeline

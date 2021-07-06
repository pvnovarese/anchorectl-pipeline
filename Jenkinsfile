// requires anchore-cli https://github.com/anchore/anchore-cli
// requires anchorectl
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
    // and password to anchorectl so it can upload the results
    ANCHORE_CREDENTIAL = "AnchoreJenkinsUser"
    // use credentials to set ANCHORE_USR and ANCHORE_PSW
    ANCHORE = credentials("${ANCHORE_CREDENTIAL}")
    //
    // api endpoint of your anchore instance (minus the /v1)
    ANCHORE_URL = "http://anchore3-priv.novarese.net:8228"
    //
    // assuming you want to use docker hub, this shouldn't need
    // any changes, but if you're using another registry, you
    // may need to tweek REPOSITORY 
    REPOSITORY = "${DOCKER_HUB_USR}/anchorectl-test"
    //
  } // end environment
  agent any
  stages {
    stage('Checkout SCM') {
      steps {
        checkout scm
      } // end steps
    } // end stage "checkout scm"
    
    stage('Build image and tag with build number') {
      steps {
        script {
          dockerImage = docker.build REPOSITORY + ":${BUILD_NUMBER}"
        } // end script
      } // end steps
    } // end stage "build image and tag w build number"
    
    stage('Analyze image with anchorectl and get evaluation') {
      steps {
        script {
          // first, analyze with anchorectl and upload sbom to anchore enterprise
          sh '/var/jenkins_home/anchorectl --url ${ANCHORE_URL} --user ${ANCHORE_USR} --password ${ANCHORE_PSW} sbom upload ${REPOSITORY}:${BUILD_NUMBER}'
          // 
          // (note - at this point the image has not been pushed anywhere)
          //
          // next, wait for analysis to complete (even though we generated the sbom locally, the backend analyzer
          // still has some work to do - it validates the uploaded sbom and inserts it into the catalog, plus it
          // will do an initial policy evaluation etc.
          sh '/usr/bin/anchore-cli --url ${ANCHORE_URL} --u ${ANCHORE_USR} --p ${ANCHORE_PSW} image wait --timeout 120 --interval 2 ${REPOSITORY}:${BUILD_NUMBER}'
          // now, grab the evaluation
          try {
            sh '/usr/bin/anchore-cli --url ${ANCHORE_URL} --u ${ANCHORE_USR} --p ${ANCHORE_PSW} evaluate check ${REPOSITORY}:${BUILD_NUMBER}'
            // if you want the FULL details of the policy evaluation (which can be quite long), use "evaluate check --detail" instead
            //
          } catch (err) {
            // if evaluation fails, clean up (delete the image) and fail the build
            sh 'docker rmi ${REPOSITORY}:${BUILD_NUMBER}'
            sh 'exit 1'
          } // end try
        } // end script 
      } // end steps
    } // end stage "analyze with syft"
    
    // THIS STAGE IS OPTIONAL
    // the purpose of this stage is to simply show that if an image passes the scan we could
    // continue the pipeline with something like "promoting" the image to production etc
    stage('Re-tag as prod and push to registry') {
      steps {
        script {
          docker.withRegistry( '', HUB_CREDENTIAL) {
            DOCKER_IMAGE.push('prod') 
            // DOCKER_IMAGE.push takes the argument as a new tag for the image before pushing      
          sh '/var/jenkins_home/anchorectl --url ${ANCHORE_URL} --user ${ANCHORE_USR} --password ${ANCHORE_PSW} image add ${REPOSITORY}:prod'
            // this "image add" is just so the backend knows about the new tag for this image, we don't have to wait for an evaluation
          }
        } // end script
      } // end steps
    } // end stage "re-tag as prod"
    
    stage('Clean up') {
      // delete the images locally
      steps {
        sh 'docker rmi ${REPOSITORY}:${BUILD_NUMBER} ${REPOSITORY}:prod || failure=1' 
        //
        // the "|| failure=1" at the end of this line just catches problems with the :prod
        // tag not existing if we didn't uncomment the optional "re-tag as prod" stage
        //
      } // end steps
    } // end stage "clean up"
    
  } // end stages
} // end pipeline

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
    
    stage('Verify Tools') {
      steps {
        sh """
          which docker
          which anchore-cli
          which /var/jenkins_home/anchorectl
          """
      } // end steps
    } // end stage "Verify Tools"
    
    
    stage('Build Image') {
      steps {
        script {
          dockerImage = docker.build REPOSITORY + ":${BUILD_NUMBER}"
        } // end script
      } // end steps
    } // end stage "Build Image"
    
    stage('Analyze Image w/ anchorectl') {
      steps {
        script {
          // first, analyze with anchorectl and upload sbom to anchore enterprise
          sh '/var/jenkins_home/anchorectl --url ${ANCHORE_URL} --user ${ANCHORE_USR} --password ${ANCHORE_PSW} sbom upload --wait ${REPOSITORY}:${BUILD_NUMBER}'
          // sh '/usr/bin/anchore-cli --url ${ANCHORE_URL} --u ${ANCHORE_USR} --p ${ANCHORE_PSW} image wait --timeout 120 --interval 2 ${REPOSITORY}:${BUILD_NUMBER}'
          // 
          // (note - at this point the image has not been pushed anywhere)
          //
          // we do the "image wait" to wait for analysis to complete (even though we generated the sbom locally, 
          // the backend analyzer still has some work to do - it validates the uploaded sbom and inserts it into 
          // the catalog, plus it will do an initial policy evaluation etc.
          // 
          // now let's get the evaluation
          //
          try {
            sh '/usr/bin/anchore-cli --url ${ANCHORE_URL} --u ${ANCHORE_USR} --p ${ANCHORE_PSW} evaluate check ${REPOSITORY}:${BUILD_NUMBER}'
            // if you want the FULL details of the policy evaluation (which can be quite long), use "evaluate check --detail" instead
            //
          } catch (err) {
            // if evaluation fails, clean up (delete the image) and fail the build
            sh """
              docker rmi ${REPOSITORY}:${BUILD_NUMBER}
              echo ${REPOSITORY}:${BUILD_NUMBER} > anchore_images
              anchore name: 'anchore_images'
              exit 1
            """
          } // end try
        } // end script 
      } // end steps
    } // end stage "analyze with anchorectl"
    
    // THIS STAGE IS OPTIONAL
    // the purpose of this stage is to simply show that if an image passes the scan we could
    // continue the pipeline with something like "promoting" the image to production etc
    stage('Promote to Prod and Push to Registry') {
      steps {
        script {
          // login to docker hub, re-tag image as "prod" and then push to docker hub
          // then we use anchorectl to add the "prod" tag to the catalog - no need to wait for evaluation
          sh """
            docker login -u ${DOCKER_HUB_USR} -p ${DOCKER_HUB_PSW}
            docker tag ${REPOSITORY}:${BUILD_NUMBER} ${REPOSITORY}:prod
            docker push ${REPOSITORY}:prod
            echo ${REPOSITORY}:prod > anchore_images
            """
          anchore name: 'anchore_images'
        } // end script
      } // end steps
    } // end stage "Promote to Prod"
    
    stage('Clean Up') {
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

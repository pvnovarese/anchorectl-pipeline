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
    // now set the actual envvars that anchorectl uses:
    ANCHORECTL_ANCHORE_USER = "${ANCHORE_USR}"
    ANCHORECTL_ANCHORE_PASSWORD = "${ANCHORE_PSW}"
    //
    // and the same for anchore-cli
    ANCHORE_CLI_USER = "${ANCHORE_USR}"
    ANCHORE_CLI_PASS = "${ANCHORE_PSW}"
    //
    // api endpoint of your anchore instance (anchore-cli needs the trailing /v1,
    // anchorectl doesn't want the /v1)
    // we could hardcode these eg:
    // ANCHORECTL_ANCHORE_URL = "http://anchore33-priv.novarese.net:8228"
    // ANCHORE_CLI_URL = "http://anchore33-priv.novarese.net:8228/v1/"
    // but I have a secret text credential called AnchoreUrl and AnchorectlURL:
    ANCHORECTL_ANCHORE_URL = credentials("AnchorectlUrl")
    ANCHORE_CLI_URL = credentials("AnchoreUrl")
    //
    // assuming you want to use docker hub, this shouldn't need
    // any changes, but if you're using another registry, you
    // may need to tweek REPOSITORY 
    REPOSITORY = "${DOCKER_HUB_USR}/anchorectl-test"
    TAG = "build-${BUILD_NUMBER}"
    PASSTAG = "main"
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
          which anchorectl
          """
      } // end steps
    } // end stage "Verify Tools"
    
    
    stage('Build Image') {
      steps {
        script {
          // build image and record repo/tag in DOCKER_IMAGE
          // then push it to docker hub (or whatever registry)
          //
          sh """
            docker login -u ${DOCKER_HUB_USR} -p ${DOCKER_HUB_PSW}
            docker build -t ${REPOSITORY}:${TAG} --pull -f ./Dockerfile .
            # we don't need to push since we're using anchorectl, but if you wanted to you could do this:
            # docker push ${REPOSITORY}:${TAG}
          """
          // I don't like using the docker plugin but if you want to use it, here ya go
          // DOCKER_IMAGE = docker.build REPOSITORY + ":" + TAG
          // docker.withRegistry( '', HUB_CREDENTIAL ) { 
          //  DOCKER_IMAGE.push() 
          // }
        } // end script
      } // end steps
    } // end stage "Build Image"
    
    stage('Analyze Image w/ anchorectl') {
      steps {
        script {
          // first, create the local json SBOM to be archived, then
          // analyze with anchorectl and upload sbom to anchore enterprise
          sh '''
            anchorectl -o json sbom create ${REPOSITORY}:${TAG} > ${JOB_BASE_NAME}.json
            anchorectl sbom upload --wait ${REPOSITORY}:${TAG}
          '''
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
            sh 'anchore-cli evaluate check ${REPOSITORY}:${TAG}'
            // if you want the FULL details of the policy evaluation (which can be quite long), use "evaluate check --detail" instead
            //
          } catch (err) {
            // if evaluation fails, clean up (delete the image) and fail the build
            sh """
              docker rmi ${REPOSITORY}:${TAG}
              # optional: grab the evaluation with the anchore plugin so we can archive it
              # echo ${REPOSITORY}:${TAG} > anchore_images
              # this doesn't actually work because we didn't push the image and the 
              # plug-in automatically does an "image add" which fails.
              exit 1
            """
            // anchore name: 'anchore_images'
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
          // login to docker hub, re-tag image as ${PASSTAG} and then push to docker hub
          // then we EITHER:
          // 1. use anchorectl to add the PASSTAG tag to the catalog - no need to wait for evaluation
          // 2. use anchore plugin to add the PASSTAG tag and grab the evaluation report
          sh """
            docker login -u ${DOCKER_HUB_USR} -p ${DOCKER_HUB_PSW}
            docker tag ${REPOSITORY}:${TAG} ${REPOSITORY}:${PASSTAG}
            docker push ${REPOSITORY}:${PASSTAG}
            echo ${REPOSITORY}:${PASSTAG} > anchore_images
            """
          anchore name: 'anchore_images'
        } // end script
      } // end steps
    } // end stage "Promote to Prod"
    
    stage('Clean Up') {
      // archive the sbom and delete the images locally
      steps {
        archiveArtifacts artifacts: '*.json'
        sh 'docker rmi ${REPOSITORY}:${TAG} ${REPOSITORY}:${PASSTAG} || failure=1' 
        //
        // the "|| failure=1" at the end of this line just catches problems with the :prod
        // tag not existing if we didn't uncomment the optional "re-tag as prod" stage
        //
      } // end steps
    } // end stage "clean up"
    
  } // end stages
} // end pipeline


/*
 Pipeline to deploy opentaxii to Kubernetes cluster using Helm packages (CI/CDish)
 1. definition of pod template ( docker, helm)
 2. clone the source code 
 3. build packages
 4. build dockerimage 
 5. build helm chart
 6. push image and chart to artifactory
 7. deploy on k8s cluster

 TODO:
 added tests here 
*/

//this has to change <--
def tag_image (branch){
  if (branch.contains("master")){
    tag = "latest"
    version = "0.0.0-latest"
  } else {
    tag = branch.minus("release-")
    version = tag 
  }
  return [tag, version]  
}  


def label = "pod_Build_${BUILD_NUMBER}"
podTemplate(label: label, containers: [

  containerTemplate(name: 'docker', image: 'docker:latest', command: 'cat', ttyEnabled: true),
  containerTemplate(name: 'helm', image: 'lachlanevenson/k8s-helm:v2.13.0', command: 'cat', ttyEnabled: true)
],
volumes: [
  hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock')
 
]) {
  node(label) {

    def PACKAGE = "opentaxii"
    def ARTIFACTORY_URL = "artifactory.app.eiq.sh"

    stage('Create packages') {
      container('docker') {
        sh "apk add --update make"
        
        def repo = git url: "https://github.com/eclecticiq/opentaxii-k8s.git", branch: 'master', credentialsId: 'f886c899-82f1-4f2f-9837-d50d4fa423c7'
        def branch = repo.GIT_BRANCH 
        def version, tag = tag_image (branch)
        stash name: "git-source"
        

        //sh "make build-packages IMAGE_TAG=${version} version=${version} ITERATION=1"
        //archiveArtifacts(artifacts: 'dist/*', fingerprint: true)
      }
    }
    stage('Docker image') {
      withCredentials([usernamePassword(credentialsId: '63b8cd21-edfc-4ba0-ba4d-f733b625bb68', 
        passwordVariable: 'password', 
        usernameVariable: 'username')]) {
        container('docker') {
          sh """
            docker login -u ${username} -p ${password} ${ARTIFACTORY_URL}
            docker build -t artifactory.app.eiq.sh/docker/eiq-opentaxii:${tag} .
            docker push ${ARTIFACTORY_URL}/docker/eiq-opentaxii:${tag}
          """
        }
      }
    }
    stage ('Helm chart')  {

      withCredentials([usernamePassword(credentialsId: '63b8cd21-edfc-4ba0-ba4d-f733b625bb68', 
        passwordVariable: 'password', 
        usernameVariable: 'username')]) {
        container('helm') {
          
          unstash "git-source"
          sh "apk add --update curl"
         
          sh """
            helm init
            helm repo update
            helm repo add helm https://${ARTIFACTORY_URL}/artifactory/helm --username ${username} --password ${password}
            cd helm/opentaxii ; helm template --set image.tag=${tag} -f Chart.yaml -f values.yaml .
            pwd ; helm package --version ${version} .
            curl -u${username}:${password} -T ${PACKAGE}-${version}.tgz https://${ARTIFACTORY_URL}/artifactory/helm/${PACKAGE}-${version}.tgz
          """
        }
      }
    }
    stage ('Deploy chart on k8s'){
      container ('helm'){
        sh " cd helm/opentaxii ; helm upgrade --set image.tag=${tag} --install ${PACKAGE}-release ./${PACKAGE}-${version}.tgz" 
      }
    }

  }//node
}



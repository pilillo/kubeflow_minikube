if [ -z "$1" ] || [ "$1" != "install" ] && [ "$1" != "start" ];then
        echo "usage: $0 {install | start}";
        exit 1
fi

# start k8s
if [ "$1" = "install" ];then
        minikube stop
        minikube delete
fi

# start local k8s instance
minikube start --cpus 8 --memory 8096 --disk-size=20g --vm-driver kvm2

# setup kubeflow on minikube
# https://www.kubeflow.org/docs/started/getting-started-minikube/
if [ "$1" = "install" ];then
        # https://stackoverflow.com/questions/2013547/assigning-default-values-to-shell-variables-with-a-single-command-in-bash
        KUBEFLOW_SRC=${1:-$HOME"/kubeflow_src"}
        mkdir ${KUBEFLOW_SRC}
        cd ${KUBEFLOW_SRC}
        export KUBEFLOW_TAG=v0.3.4

        # download installation files
        curl https://raw.githubusercontent.com/kubeflow/kubeflow/${KUBEFLOW_TAG}/scripts/download.sh | bash

        KFAPP=${KUBEFLOW_SRC}/configs/
        ${KUBEFLOW_SRC}/scripts/kfctl.sh init ${KFAPP} --platform minikube

        cd ${KFAPP}
        ${KUBEFLOW_SRC}/scripts/kfctl.sh generate all
        ${KUBEFLOW_SRC}/scripts/kfctl.sh apply all
fi

# port forward ambassador (reverse proxy)
kubectl port-forward --namespace=kubeflow svc/ambassador 9992:80 &

# now services are accessible at:
# Access Kubeflow dashboard at http://localhost:9992/
# Access JupyterHub at http://localhost:9992/hub/

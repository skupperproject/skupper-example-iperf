# Testing network throughput across clusters

This tutorial demonstrates how to perform real-time network throughput measurements on an application router network using the iperf3 tool.

In this tutorial, you will deploy iperf3 servers in separate clusters. You will also create an application router network, which will enable the iperf3 instances to run in client mode and access peer iperf3 servers running on the different clusters (e.g. private and public).

To complete this tutorial, do the following:

* [Prerequisites](#prerequisites)
* [Step 1: Set up the demo](#step-1-set-up-the-demo)
* [Step 2: Deploy the Skupper Network](#step-2-deploy-the-skupper-network)
* [Step 3: Deploy the iperf3 servers](#step-3-deploy-the-iperf3-servers)
* [Step 4: Annotate services to join the Skupper Network](#step-3-annotate-services-to-join-the-skupper-network)
* [Step 5: Run benchmark tests across the clusters](#step-4-run-benchmark-tests-across-the-clusters)
* [Next steps](#next-steps)

## Prerequisites

The basis for this demonstration is to test communication performance across distributed clusters. You should have access to three independent clusters to observe performance over a Skupper Network. As an example, the three clusters might be comprised of:

* A "private cloud" cluster running on your local machine
* Two public cloud clusters running in public cloud providers

For the purpose of running the benchmark test against the public clusters, you should install the iperf3 program to your local machine.

## Step 1: Set up the demo

1. On your local machine, make a directory for this tutorial and clone the following repos into it:

   ```bash
   mkdir iperf-demo
   cd iperf-demo
   git clone https://github.com/skupperproject/skupper-example-iperf.git
   curl -fL https://github.com/skupperproject/skupper-cli/releases/download/0.0.1-alpha/linux.tgz -o skupper.tgz
   mkdir $HOME/bin
   tar -xf skupper.tgz --directory $HOME/bin
   export PATH=$PATH:$HOME/bin
   ```

   To test your installation, run the 'skupper' command with no arguments. It will print a usage summary.

   ```bash
   $ skupper
   usage: skupper <command> <args>
   [...]
   ```

## Step 2: Deploy the Skupper Network

On each cluster, define the application router role and connectivity to peer clusters.

1. In the terminal for the first public cluster, deploy the *public1* application router, and create its secrets:

   ```bash
   skupper init --id public1
   skupper connection-token private1-to-public1-token.yaml
   skupper connection-token public2-to-public1-token.yaml
   ```

2. In the terminal for the second public cluster, deploy the *public2* application router, create its secrets and define its connections to the peer *public1* cluster:

   ```bash
   skupper init --id public2
   skupper connection-token private1-to-public2-token.yaml
   skupper connect public2-to-public1-token.yaml
   ```

3. In the terminal for the private cluster, deploy the *private1* application router and define its connections to the public clusters

   ```bash
   skupper init --id private1
   skupper connect private1-to-public1-token.yaml
   skupper connect private1-to-public2-token.yaml
   ```

## Step 3: Deploy the iperf3 servers

After creating the application router network, you deploy the three iperf3 servers to each of the clusters.

1. In the terminal for the *private1* cluster, deploy the first iperf3 server:

   ```bash
   kubectl apply -f ~/iperf-demo/skupper-example-iperf/deployment-iperf3-a.yaml
   ```

2. In the terminal for the *public1* cluster, deploy the second iperf3 server:

   ```bash
   kubectl apply -f ~/iperf-demo/skupper-example-iperf/deployment-iperf3-b.yaml
   ```

3. In the terminal for the *public2* cluster, deploy the third iperf3 server:

   ```bash
   kubectl apply -f ~/iperf-demo/skupper-example-iperf/deployment-iperf3-c.yaml
   ```

## Step 4: Annotate services to join to the Skupper Network


1. In the terminal for the *private1* cluster, annotate the iperf3-svc-a service:

   ```bash
   kubectl annotate service iperf3-svc-a skupper.io/proxy=tcp
   ```

2. In the terminal for the *public1* cluster, annotate the iperf3-svc-b service:

   ```bash
   kubectl annotate service iperf3-svc-b skupper.io/proxy=tcp
   ```

3. In the terminal for the *public2* cluster, annotate the iperf3-svc-c service:

   ```bash
   kubectl annotate service iperf3-svc-c skupper.io/proxy=tcp
   ```

## Step 5: Run benchmark tests across the clusters

After deploying the iperf3 servers into the private and public cloud clusters, the application router network connects the servers and enables communications even though they are running in separate clusters.

1. In the terminal for the *private1* cluster, run the iperf3 client benchmark against each server:

   ```bash
   iperf3 -c  $(kubectl get service iperf3-svc-a -o=jsonpath='{.spec.clusterIP}')
   iperf3 -c  $(kubectl get service iperf3-svc-b -o=jsonpath='{.spec.clusterIP}')
   iperf3 -c  $(kubectl get service iperf3-svc-c -o=jsonpath='{.spec.clusterIP}')
   ```

2. In the terminal for the *public1* cluster, attach to the iperf3 server container running in the cluster and run the iperf3 client benchmark against each server:

   ```bash
   kubectl exec -it $(kubectl get pod -l application=iperf3-server-b -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c  $(kubectl get service iperf3-svc-a -o=jsonpath='{.spec.clusterIP}')
   kubectl exec -it $(kubectl get pod -l application=iperf3-server-b -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c  $(kubectl get service iperf3-svc-b -o=jsonpath='{.spec.clusterIP}')
   kubectl exec -it $(kubectl get pod -l application=iperf3-server-b -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c  $(kubectl get service iperf3-svc-c -o=jsonpath='{.spec.clusterIP}')
   ```

3. In the terminal for the *public2* cluster, attach to the iperf3 server container running in the cluster and run the iperf3 client benchmark against each server:

   ```bash
   kubectl exec -it $(kubectl get pod -l application=iperf3-server-c -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c  $(kubectl get service iperf3-svc-a -o=jsonpath='{.spec.clusterIP}')
   kubectl exec -it $(kubectl get pod -l application=iperf3-server-c -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c  $(kubectl get service iperf3-svc-b -o=jsonpath='{.spec.clusterIP}')
   kubectl exec -it $(kubectl get pod -l application=iperf3-server-c -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c  $(kubectl get service iperf3-svc-c -o=jsonpath='{.spec.clusterIP}')
   ```

## Next steps

Restore your cluster environment by returning the resource created in the demonstration. On each cluster, delete the demo resources and the skupper network:

1. In the terminal for the *private1* cluster, delete the resources:


   ```bash
   kubectl delete -f ~/iperf-demo/skupper-example-iperf/deployment-iperf3-a.yaml
   skupper delete
   ```

2. In the terminal for the *public1* cluster, delete the resources:


   ```bash
   kubectl delete -f ~/iperf-demo/skupper-example-iperf/deployment-iperf3-b.yaml
   skupper delete
   ```

3. In the terminal for the *public2* cluster, delete the resources:


   ```bash
   kubectl delete -f ~/iperf-demo/skupper-example-iperf/deployment-iperf3-c.yaml
   skupper delete
   ```


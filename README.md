# Testing network throughput across clusters

[![main](https://github.com/skupperproject/skupper-example-iperf/actions/workflows/main.yaml/badge.svg)](https://github.com/skupperproject/skupper-example-iperf/actions/workflows/main.yaml)

This example is part of a [suite of examples][examples] showing the
different ways you can use [Skupper][website] to connect services
across cloud providers, data centers, and edge sites.

[website]: https://skupper.io/
[examples]: https://skupper.io/examples/index.html

#### Contents

* [Overview](#overview)
* [Prerequisites](#prerequisites)
* [Step 1: Set up the demo](#step-1-set-up-the-demo)
* [Step 2: Install the Skupper command-line tool](#step-2-install-the-skupper-command-line-tool)
* [Step 3: Configure separate console sessions](#step-3-configure-separate-console-sessions)
* [Step 4: Access your clusters](#step-4-access-your-clusters)
* [Step 5: Set up your namespaces](#step-5-set-up-your-namespaces)
* [Step 6: Install Skupper in your namespaces](#step-6-install-skupper-in-your-namespaces)
* [Step 7: Check the status of your namespaces](#step-7-check-the-status-of-your-namespaces)
* [Step 8: Deploy the Virtual Application Network](#step-8-deploy-the-virtual-application-network)
* [Step 9: Deploy the iperf3 servers](#step-9-deploy-the-iperf3-servers)
* [Step 10: Create Skupper services for the Virtual Application Network](#step-10-create-skupper-services-for-the-virtual-application-network)
* [Step 11: Bind the Skupper services to the deployment targets on the Virtual Application Network](#step-11-bind-the-skupper-services-to-the-deployment-targets-on-the-virtual-application-network)
* [Step 12: Run benchmark tests across the clusters](#step-12-run-benchmark-tests-across-the-clusters)
* [Accessing the web console](#accessing-the-web-console)
* [Cleaning up](#cleaning-up)
* [Next steps](#next-steps)
* [About this example](#about-this-example)

## Overview

This tutorial demonstrates how to perform real-time network throughput measurements on a Virtual Application Network 
using the iperf3 tool.
In this tutorial you will:
* deploy iperf3 servers in three separate clusters
* use the iperf3 server pods to run iperf3 client test instances

* create a Virtual Application Network which will enable the iperf3 client test instances to access iperf3 
servers in any cluster

## Prerequisites

* The `kubectl` command-line tool, version 1.15 or later
([installation guide][install-kubectl])

* The `skupper` command-line tool, the latest version ([installation
guide][install-skupper])
[install-kubectl]: https://kubernetes.io/docs/tasks/tools/install-kubectl/
[install-skupper]: https://skupper.io/install/index.html
The basis for this demonstration is to test communication performance across distributed clusters. 
You should have access to three independent clusters to observe performance over a Skupper Network. 
As an example, the three clusters might be composed of:

* A private cloud cluster running on your local machine (**private1**)
* Two public cloud clusters running in public cloud providers (**public1** and **public2**)

## Step 1: Set up the demo

On your local machine, make a directory for this tutorial and clone the example repo into it:

```bash
mkdir ~/iperf-demo
cd ~/iperf-demo
git clone https://github.com/skupperproject/skupper-skewer-iperf.git
```

## Step 2: Install the Skupper command-line tool

The `skupper` command-line tool is the entrypoint for installing
and configuring Skupper.  You need to install the `skupper`
command only once for each development environment.
On Linux or Mac, you can use the install script (inspect it
[here][install-script]) to download and extract the command:
~~~ shell
curl https://skupper.io/install.sh | sh
~~~
The script installs the command under your home directory.  It
prompts you to add the command to your path if necessary.
For Windows and other installation options, see [Installing
Skupper][install-docs].
[install-script]: https://github.com/skupperproject/skupper-website/blob/main/docs/install.sh
[install-docs]: https://skupper.io/install/index.html

## Step 3: Configure separate console sessions

Skupper is designed for use with multiple namespaces, usually on
different clusters.  The `skupper` command uses your
[kubeconfig][kubeconfig] and current context to select the
namespace where it operates.
[kubeconfig]: https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/
Your kubeconfig is stored in a file in your home directory.  The
`skupper` and `kubectl` commands use the `KUBECONFIG` environment
variable to locate it.
A single kubeconfig supports only one active context per user.
Since you will be using multiple contexts at once in this
exercise, you need to create distinct kubeconfigs.
Start a console session for each of your namespaces.  Set the
`KUBECONFIG` environment variable to a different path in each
session.

_**Console for public1:**_

~~~ shell
export KUBECONFIG=~/.kube/config-public1
~~~

_**Console for public2:**_

~~~ shell
export KUBECONFIG=~/.kube/config-public2
~~~

_**Console for private1:**_

~~~ shell
export KUBECONFIG=~/.kube/config-private1
~~~

## Step 4: Access your clusters

The procedure for accessing a Kubernetes cluster varies by
provider. [Find the instructions for your chosen
provider][kube-providers] and use them to authenticate and
configure access for each console session.
[kube-providers]: https://skupper.io/start/kubernetes.html

## Step 5: Set up your namespaces

Use `kubectl create namespace` to create the namespaces you wish
to use (or use existing namespaces).  Use `kubectl config
set-context` to set the current namespace for each session.

_**Console for public1:**_

~~~ shell
kubectl create namespace public1
kubectl config set-context --current --namespace public1
~~~

_**Console for public2:**_

~~~ shell
kubectl create namespace public2
kubectl config set-context --current --namespace public2
~~~

_**Console for private1:**_

~~~ shell
kubectl create namespace private1
kubectl config set-context --current --namespace private1
~~~

## Step 6: Install Skupper in your namespaces

The `skupper init` command installs the Skupper router and service
controller in the current namespace.  Run the `skupper init` command
in each namespace.
**Note:** If you are using Minikube, [you need to start `minikube
tunnel`][minikube-tunnel] before you install Skupper.
[minikube-tunnel]: https://skupper.io/start/minikube.html#running-minikube-tunnel

_**Console for public1:**_

~~~ shell
skupper init --site-name public1
~~~

_**Console for public2:**_

~~~ shell
skupper init --site-name public2
~~~

_**Console for private1:**_

~~~ shell
skupper init --site-name private1
~~~

_Sample output:_
~~~ console
$ skupper init --site-name <namespace>
Waiting for LoadBalancer IP or hostname...
Skupper is now installed in namespace '<namespace>'.  Use 'skupper status' to get more information.
~~~

## Step 7: Check the status of your namespaces

Use `skupper status` in each console to check that Skupper is
installed.

_**Console for public1:**_

~~~ shell
skupper status
~~~

_**Console for public2:**_

~~~ shell
skupper status
~~~

_**Console for private1:**_

~~~ shell
skupper status
~~~

_Sample output:_
~~~ console
Skupper is enabled for namespace "<namespace>" in interior mode. It is connected to 1 other site. It has 1 exposed service.
The site console url is: <console-url>
The credentials for internal console-auth mode are held in secret: 'skupper-console-users'
~~~
As you move through the steps below, you can use `skupper status` at
any time to check your progress.

## Step 8: Deploy the Virtual Application Network

Creating a link requires use of two `skupper` commands in
conjunction, `skupper token create` and `skupper link create`.
The `skupper token create` command generates a secret token that
signifies permission to create a link.  The token also carries the
link details.  Then, in a remote namespace, The `skupper link
create` command uses the token to create a link to the namespace
that generated it.
**Note:** The link token is truly a *secret*.  Anyone who has the
token can link to your namespace.  Make sure that only those you
trust have access to it.
First, use `skupper token create` in one namespace to generate the
token.  Then, use `skupper link create` in the other to create a
link.
On each cluster, using the `skupper` tool, define the Virtual Application Network and the connectivity for the peer clusters.
1. In the terminal for the first public cluster, deploy the **public1** application router. 
Create a connection token for connections from the **public2** cluster and the **private1** cluster.
2. In the terminal for the second public cluster, deploy the **public2** application router. 
Create a connection token for connections from the **private1** cluser and connect to the **public1** cluster.
3. In the terminal for the private cluster, deploy the **private1** application router. 
Connect to the **public1** and **public2** clusters.

_**Console for public1:**_

~~~ shell
skupper token create ./tmp/private1-to-public1-token.yaml
skupper token create ./tmp/public2-to-public1-token.yaml
~~~

_**Console for public2:**_

~~~ shell
skupper token create ./tmp/private1-to-public2-token.yaml
skupper link create ./tmp/public2-to-public1-token.yaml
~~~

_**Console for private1:**_

~~~ shell
skupper link create ./tmp/private1-to-public1-token.yaml
skupper link create ./tmp/private1-to-public2-token.yaml
~~~

## Step 9: Deploy the iperf3 servers

After creating the application router network, deploy one iperf3 server to each of the clusters.

1. In the terminal for the **private1** cluster, deploy the first iperf3 server.
2. In the terminal for the **public1** cluster, deploy the second iperf3 server.
3. In the terminal for the **public2** cluster, deploy the third iperf3 server.

_**Console for private1:**_

~~~ shell
kubectl apply -f deployment-iperf3-a.yaml
~~~

_**Console for public1:**_

~~~ shell
kubectl apply -f deployment-iperf3-b.yaml
~~~

_**Console for public2:**_

~~~ shell
kubectl apply -f deployment-iperf3-c.yaml
~~~

## Step 10: Create Skupper services for the Virtual Application Network

1. In the terminal for the **private1** cluster, create the iperf3-server-a service.
2. In the terminal for the **public1** cluster, create the iperf3-server-b service.
3. In the terminal for the **public2** cluster, create the iperf3-server-c service.

_**Console for private1:**_

~~~ shell
skupper service create iperf3-server-a 5201
~~~

_**Console for public1:**_

~~~ shell
skupper service create iperf3-server-b 5201
~~~

_**Console for public2:**_

~~~ shell
skupper service create iperf3-server-c 5201
~~~

4. In each of the cluster terminals, verify that the services are present:
```bash
skupper service status
```
Note that each cluster depicts the target it provides.

## Step 11: Bind the Skupper services to the deployment targets on the Virtual Application Network

1. In the terminal for the **private1** cluster, expose the iperf3-server-a deployment.
2. In the terminal for the **public1** cluster, annotate the iperf3-server-b deployment.
3. In the terminal for the **public2** cluster, annotate the iperf3-server-c deployment.

_**Console for private1:**_

~~~ shell
skupper service bind iperf3-server-a deployment iperf3-server-a
~~~

_**Console for public1:**_

~~~ shell
skupper service bind iperf3-server-b deployment iperf3-server-b
~~~

_**Console for public2:**_

~~~ shell
skupper service bind iperf3-server-c deployment iperf3-server-c
~~~

4. In each of the cluster terminals, verify the services bind to the targets
```bash
skupper service status
```
Note that each cluster depicts the target it provides.

## Step 12: Run benchmark tests across the clusters

After deploying the iperf3 servers into the private and public cloud clusters, the application router network
connects the servers and enables communications even though they are running in separate clusters.
1. In the terminal for the **private1** cluster, attach to the iperf3-server-a container running in the
**private1** cluster and run the iperf3 client benchmark against each server.
2. In the terminal for the **public1** cluster, attach to the iperf3-server-b container running in the
**public1** cluster and run the iperf3 client benchmark against each server.
3. In the terminal for the **public2** cluster, attach to the iperf3-server-c container running in the
**public2** cluster and run the iperf3 client benchmark against each server.

_**Console for private1:**_

~~~ shell
kubectl exec $(kubectl get pod -l application=iperf3-server-a -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c iperf3-server-a
kubectl exec $(kubectl get pod -l application=iperf3-server-a -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c iperf3-server-b
kubectl exec $(kubectl get pod -l application=iperf3-server-a -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c iperf3-server-c
~~~

_**Console for public1:**_

~~~ shell
kubectl exec $(kubectl get pod -l application=iperf3-server-b -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c iperf3-server-a
kubectl exec $(kubectl get pod -l application=iperf3-server-b -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c iperf3-server-b
kubectl exec $(kubectl get pod -l application=iperf3-server-b -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c iperf3-server-c
~~~

_**Console for public2:**_

~~~ shell
kubectl exec $(kubectl get pod -l application=iperf3-server-c -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c iperf3-server-a
kubectl exec $(kubectl get pod -l application=iperf3-server-c -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c iperf3-server-b
kubectl exec $(kubectl get pod -l application=iperf3-server-c -o=jsonpath='{.items[0].metadata.name}') -- iperf3 -c iperf3-server-c
~~~

## Accessing the web console

Skupper includes a web console you can use to view the application
network.  To access it, use `skupper status` to look up the URL of
the web console.  Then use `kubectl get
secret/skupper-console-users` to look up the console admin
password.
**Note:** The `<console-url>` and `<password>` fields in the
following output are placeholders.  The actual values are specific
to your environment.

_**Console for public1:**_

~~~ shell
skupper status
kubectl get secret/skupper-console-users -o jsonpath={.data.admin} | base64 -d
~~~

_Sample output:_

~~~ console
$ skupper status
Skupper is enabled for namespace "public1" in interior mode. It is connected to 1 other site. It has 1 exposed service.
The site console url is: <console-url>
The credentials for internal console-auth mode are held in secret: 'skupper-console-users'

$ kubectl get secret/skupper-console-users -o jsonpath={.data.admin} | base64 -d
<password>
~~~

Navigate to `<console-url>` in your browser.  When prompted, log
in as user `admin` and enter the password.

## Cleaning up

Restore your cluster environment by returning the resources created in the demonstration and delete the skupper network

_**Console for private1:**_

~~~ shell
kubectl delete deployment iperf3-server-a
skupper delete
~~~

_**Console for public1:**_

~~~ shell
kubectl delete deployment iperf3-server-b
skupper delete
~~~

_**Console for public2:**_

~~~ shell
kubectl delete deployment iperf3-server-c
skupper delete
~~~

## Next steps

- [Find more examples](https://skupper.io/examples/)

## About this example

This example was produced using [Skewer][skewer], a library for
documenting and testing Skupper examples.

[skewer]: https://github.com/skupperproject/skewer

Skewer provides utility functions for generating the README and
running the example steps.  Use the `./plano` command in the project
root to see what is available.

To quickly stand up the example using Minikube, try the `./plano demo`
command.

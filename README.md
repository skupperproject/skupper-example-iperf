# iPerf

[![main](https://github.com/skupperproject/skupper-example-iperf/actions/workflows/main.yaml/badge.svg)](https://github.com/skupperproject/skupper-example-iperf/actions/workflows/main.yaml)

#### Perform real-time network throughput measurements while using iPerf3

This example is part of a [suite of examples][examples] showing the
different ways you can use [Skupper][website] to connect services
across cloud providers, data centers, and edge sites.

[website]: https://skupper.io/
[examples]: https://skupper.io/examples/index.html

#### Contents

* [Overview](#overview)
* [Prerequisites](#prerequisites)
* [Step 1: Install the Skupper command-line tool](#step-1-install-the-skupper-command-line-tool)
* [Step 2: Configure separate console sessions](#step-2-configure-separate-console-sessions)
* [Step 3: Access your clusters](#step-3-access-your-clusters)
* [Step 4: Set up your namespaces](#step-4-set-up-your-namespaces)
* [Step 5: Install Skupper in your namespaces](#step-5-install-skupper-in-your-namespaces)
* [Step 6: Check the status of your namespaces](#step-6-check-the-status-of-your-namespaces)
* [Step 7: Link your namespaces](#step-7-link-your-namespaces)
* [Step 8: Deploy the iperf3 servers](#step-8-deploy-the-iperf3-servers)
* [Step 9: Expose iperf3 from each namespace](#step-9-expose-iperf3-from-each-namespace)
* [Step 10: Run benchmark tests across the clusters](#step-10-run-benchmark-tests-across-the-clusters)
* [Accessing the web console](#accessing-the-web-console)
* [Cleaning up](#cleaning-up)
* [Next steps](#next-steps)
* [About this example](#about-this-example)

## Overview

This tutorial demonstrates how to perform real-time network throughput measurements across Kubernetes 
using the iperf3 tool.
In this tutorial you:
* deploy iperf3 in three separate clusters
* run iperf3 client test instances

## Prerequisites

* The `kubectl` command-line tool, version 1.15 or later
([installation guide][install-kubectl])

* Access to three clusters to observe performance. 
As an example, the three clusters might consist of:

* A private cloud cluster running on your local machine (**private1**)
* Two public cloud clusters running in public cloud providers (**public1** and **public2**)

## Step 1: Install the Skupper command-line tool

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

## Step 2: Configure separate console sessions

Skupper is designed for use with multiple namespaces, usually on
different clusters.  The `skupper` and `kubectl` commands use your
[kubeconfig][kubeconfig] and current context to select the
namespace where they operate.

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

## Step 3: Access your clusters

The procedure for accessing a Kubernetes cluster varies by
provider. [Find the instructions for your chosen
provider][kube-providers] and use them to authenticate and
configure access for each console session.

[kube-providers]: https://skupper.io/start/kubernetes.html

## Step 4: Set up your namespaces

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

## Step 5: Install Skupper in your namespaces

The `skupper init` command installs the Skupper router and
controller in the current namespace.  Run the `skupper init` command
in each namespace.

**Note:** If you are using Minikube, [you need to start `minikube
tunnel`][minikube-tunnel] before you install Skupper.

[minikube-tunnel]: https://skupper.io/start/minikube.html#running-minikube-tunnel

_**Console for public1:**_

~~~ shell
skupper init --enable-console --enable-flow-collector
~~~

_**Console for public2:**_

~~~ shell
skupper init
~~~

_**Console for private1:**_

~~~ shell
skupper init
~~~

_Sample output:_

~~~ console
$ skupper init
Waiting for LoadBalancer IP or hostname...
Waiting for status...
Skupper is now installed in namespace '<namespace>'.  Use 'skupper status' to get more information.
~~~

## Step 6: Check the status of your namespaces

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

## Step 7: Link your namespaces

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

_**Console for public1:**_

~~~ shell
skupper token create ~/private1-to-public1-token.yaml
skupper token create ~/public2-to-public1-token.yaml
~~~

_**Console for public2:**_

~~~ shell
skupper token create ~/private1-to-public2-token.yaml
skupper link create ~/public2-to-public1-token.yaml
skupper link status --wait 60
~~~

_**Console for private1:**_

~~~ shell
skupper link create ~/private1-to-public1-token.yaml
skupper link create ~/private1-to-public2-token.yaml
skupper link status --wait 60
~~~

If your console sessions are on different machines, you may need
to use `scp` or a similar tool to transfer the token securely.  By
default, tokens expire after a single use or 15 minutes after
creation.

## Step 8: Deploy the iperf3 servers

After creating the application router network, deploy `iperf3` in each namespace.

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

## Step 9: Expose iperf3 from each namespace

We have established connectivity between the namespaces and deployed `iperf3`.
Before we can test performance, we need access to the `iperf3` from each namespace.

_**Console for private1:**_

~~~ shell
skupper expose deployment/iperf3-server-a --port 5201
~~~

_**Console for public1:**_

~~~ shell
skupper expose deployment/iperf3-server-b --port 5201
~~~

_**Console for public2:**_

~~~ shell
skupper expose deployment/iperf3-server-c --port 5201
~~~

## Step 10: Run benchmark tests across the clusters

After deploying the iperf3 servers into the private and public cloud clusters,
the virtual application network enables communications even though they are 
running in separate clusters.

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
Skupper is enabled for namespace "public1". It is connected to 1 other site. It has 1 exposed service.
The site console url is: <console-url>
The credentials for internal console-auth mode are held in secret: 'skupper-console-users'

$ kubectl get secret/skupper-console-users -o jsonpath={.data.admin} | base64 -d
<password>
~~~

Navigate to `<console-url>` in your browser.  When prompted, log
in as user `admin` and enter the password.

## Cleaning up

To remove Skupper and the other resources from this exercise, use
the following commands.

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

# Set up private package feeds with Azure ML

## Introduction

When working with Azure Machine Learning, your security team may require the use of private package channels as part of the software build process. In this tutorial, we'll explain how you can configure your Azure Machine Learning environment to install packages from a private source. We will set up a network-isolated Azure Machine Learning workspace, pointing to package feed host in the same Azure virtual network.

## Step 1: Azure resource set up

1. Set up a network-isolated Azure Machine Learning environment [using this template](https://github.com/Azure/azure-quickstart-templates/tree/master/quickstarts/microsoft.machinelearningservices/machine-learning-end-to-end-secure). This creates:
   
   * An Azure virtual network
   * Azure Machine Learning workspace
   * Dependent Azure resource
   * A "jumpbox" virtual machine (to access the private environment): 
		
1. Set up your private package repository. Pick your preferred host:

   * [Azure Artifacts](https://learn.microsoft.com/en-us/azure/devops/artifacts/start-using-azure-artifacts?view=azure-devops)
   * [Sonatype Nexus OSS](https://azuremarketplace.microsoft.com/en-in/marketplace/apps/askforcloudllc1651766049149.nexus_repository_oss_on_ubuntu_20_04_lts?tab=Overview&exp=ubp8) - Instructions:
        * Deploy an Azure VM with Nexus in the same VNET and subnet as the private link endpoint of the Azure Machine Learning workspace: `snet-training`.

1. Connect to the machine in your private network [using Bastion](https://learn.microsoft.com/en-us/azure/bastion/bastion-connect-vm-rdp-windows#rdp)

1. Access your [Azure Machine Learning workspace](http://ml.azure.com/)

## Step 2: configure Azure Machine Learning compute instance

Compute instance provides a managed workstation for data science, and comes with pre-installed with Conda and Python versions that point to public feeds for package management.

Check first if your compute instance can access your private repository:

* Check if from CI can connect: 
  ```bash
  telnet <ip address> <port>
  ```

Run the following commands to configure `conda` to point to your private feeds:

* Add your private channel:
  ```bash
  conda config --add channels http://localhost:8081/repository/conda-proxy/
  conda config --add repodata_fns <repodata_file_on_your_server>.json
  ```
* Optionally, remove public channels:
  ```bash
  conda config --remove channels defaults \
  ```

* Azure Machine Learning compute instance comes packaged with pre-installed Conda environments. The default user has no privileges to modify these environments. You can create new conda environments, and modify packages using `sudo` permissions e.g.
  ```bash
  sudo /anaconda/condabin/conda install dask-ml
  ```

Run the following commands to configure `pip` to point to your private feed:

* Create a pip configuration file
  ```bash
  mkdir $HOME/.config
  mkdir $HOME/.config/pip
  touch $HOME/.config/pip/pip.conf
  ```

* Edit `pip.conf` using your favorite editor:
  ```bash
  [global]
  index = http://localhost:8081/repository/pypi-all/pypi
  index-url = http://localhost:8081/repository/pypi-all/simple
  trusted-host = http://localhost:8081/repository/pypi-all/simple
  ```

* Optionally, create a [compute instance customization script](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-customize-compute-instance) to automate the setup of new instances.

## Step 3: create Azure Machine Learning base images

1. Use the Azure Machine Learning Studio UI or CLI/SDK to create a custom Azure ML environment
   ![](images/create_azureml_environment.png)

1. Add the following lines to your dockerfile to configure Conda and Pip:
   ```dockerfile
   # Configure conda private channels
   RUN conda config --set offline false \
   && conda config --remove channels defaults || true \
   && conda config --add channels http://192.168.0.13:8081/repository/conda-proxy/main

   # Configure pip private indices
   RUN pip config set global.index http://192.168.0.13:8081/repository/pypi-all/pypi \
   &&  pip config set global.index-url http://192.168.0.13:8081/repository/pypi-all/simple
   ```

1. Create your Azure ML environment, and use the create environments when running your training or inference jobs.

1. Optionally, publish your Azure ML environment to an Azure Machine Learning registry to reuse the created environment across workspaces.

## References
* Set up Sonatype Nexus Conda repository - https://help.sonatype.com/repomanager3/nexus-repository-administration/formats/conda-repositories
* Set up Sonatype Nexus Python repository - https://help.sonatype.com/repomanager3/nexus-repository-administration/formats/pypi-repositories 
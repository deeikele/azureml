FROM mcr.microsoft.com/azureml/aifx/stable-ubuntu2004-cu115-py38-torch1110:biweekly.202211.2

# Configure conda private channels
RUN conda config --set offline false \
&& conda config --remove channels defaults || true \
&& conda config --add channels http://192.168.0.13:8081/repository/conda-proxy/main

# Configure pip private indices
RUN pip config set global.index http://192.168.0.13:8081/repository/pypi-all/pypi/ \
&&  pip config set global.index-url http://192.168.0.13:8081/repository/pypi-all/simple/ \
&&  pip config set global.trusted-host = 192.168.0.13

# Install pip dependencies
RUN pip install 'ipykernel~=6.0' \
                'azureml-core==1.48.0' \
                'azureml-dataset-runtime==1.48.0' \
                'azureml-defaults==1.48.0' \
                'azure-ml==0.0.1' \
                'azure-ml-component==0.9.15.post2' \
                'azureml-mlflow==1.48.0' \
                'azureml-contrib-services==1.48.0' \
                'azureml-contrib-services==1.48.0' \
                'torch-tb-profiler~=0.4.0' \
                'py-spy==0.3.12' \
                'debugpy~=1.6.3'

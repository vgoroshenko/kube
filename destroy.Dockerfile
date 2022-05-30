# Install dependencies
FROM debian:latest
RUN apt-get update
RUN apt-get install -y curl awscli jq unzip gnupg software-properties-common git

# Install aws-iam-authenticator
RUN curl -o /usr/local/bin/aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/aws-iam-authenticator
RUN chmod +x /usr/local/bin/aws-iam-authenticator
RUN aws-iam-authenticator help

#"Install kubectl"
RUN apt-get install -y apt-transport-https ca-certificates curl
RUN curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
RUN apt-get update
RUN apt-get install -y kubectl

# Install Terraform
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
RUN apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
RUN apt-get update && apt-get install terraform -y
RUN terraform --version

# Copy build files to the container
COPY . /usr/local/bin/app

# Set the working directory to the app files within the container
WORKDIR /usr/local/bin/app/docker_build_env
RUN ls

RUN chmod +x ../scripts/*.sh
# initialize aws credentials for terraform state backend if Builder dont have iam role
RUN mkdir ~/.aws
RUN ../scripts/vault_retrieve_awsconf.sh

# apply terraform config for cubernetes cluster and deployments
RUN mkdir ~/.kube
RUN mkdir .kube/
RUN terraform init
RUN terraform destroy --auto-approve

# upload kubernetes config in Vault
#RUN ../scripts/vault_write_kubeconf.sh

# upload url, token and certificat for push deployment in Vault
RUN ../scripts/vault_write_url.sh


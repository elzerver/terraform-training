terraform state 
terraform destroy -target aws_instance.web-server-instance
terraform apply -target aws_instance.web-server-instance

terraform.tfvars

terraform apply -var-file example.tfvars

subnet_prefix = ["10.0.0.0/24","10.1.0.0/24"]
var.subnet_prefix[0]

Manage objects

subnet_prefix = [{cidr_block = "10.0.0.0/24", name = "prod_subnet"}, {cidr_block = "10.1.0.0/24", name = "dev_subnet"}]

var.subnet_prefix[0].cidr_block

git init

git remote add origin https://github.com/user/repo.git
# Set a new remote

$ git remote -v
# Verify new remote
> origin  https://github.com/user/repo.git (fetch)
> origin  https://github.com/user/repo.git (push)

git fetch 

git pull origin dev
o
git branch --set-upstream-to=origin/<branch> dev


variable "region" {
  description = "AWS region where VPC and subnets will be created"
  type        = string
  # default     = "us-east-1"
}

variable "ALL-VPC-INFO" {
  description = "VPC and subnet info"
  type = object({
    vpc-cidr          = string,
    availability_zones = list(string),
    subnet_names       = list(string),
    public_subnets     = list(string),
    private_subnets    = list(string),
    web-ec2-subnet     = string,
    app-ec2-subnet     = string
  })

  default = {
    vpc-cidr          = "192.168.0.0/16"
    availability_zones = ["a", "b", "c", "d", "e", "f"]
    subnet_names       = ["subnet-a", "subnet-b", "subnet-c", "subnet-d", "subnet-e", "subnet-f"]
    public_subnets     = ["subnet-a", "subnet-b", "subnet-c"]
    private_subnets    = ["subnet-d", "subnet-e", "subnet-f"]
    web-ec2-subnet     = "subnet-a"
    app-ec2-subnet     = "subnet-b"
  }
}





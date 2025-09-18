locals {
  vpc-id        = aws_vpc.ALL.id
  #az_list       = [for az in var.ALL-VPC-INFO.availability_zones : "${var.region}${az}"]
  az_list       = data.aws_availability_zones.available.names
  half          = floor(length(local.az_list) / 2) # split into public/private
  anywhere      = "0.0.0.0/0"
  all-traffic   = "0.0.0.0/0"
  postgres-port = "5432"
  tcp           = "tcp"
  ssh-port      = 22
  http-port     = 80
  primary_instance_ips = { for i, instance in aws_instance.primary : i => instance.public_ip } # Here I chnaged
  
  ami_owners = {
    redhat      = "309956199498"
    rocky       = "792107900819"
    amazonlinux = "137112412989"
    ubuntu      = "099720109477"
    debian      = "136693071363"
    suse        = "013907871322"
    almalinux   = "679593333241"
  }

  ami_filters = {
    redhat      = ["RHEL-8*"]
    rocky       = ["Rocky-8*"]
    amazonlinux = ["amzn2-ami-hvm-*-x86_64-gp2"]
    ubuntu      = ["ubuntu/images/hvm-ssd/ubuntu-24.04-amd64-server-*"]
    debian      = ["debian-11-amd64-*"]
    suse        = ["suse-sles-15-sp4-v*"]
    almalinux   = ["almalinux-8*"]
  }


}


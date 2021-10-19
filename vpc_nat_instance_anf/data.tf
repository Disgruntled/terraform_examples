data "aws_vpc_endpoint" "firewall" {
  vpc_id = aws_vpc.main.id

  tags = {
    "AWSNetworkFirewallManaged" = "true"
    "Firewall"                  = aws_networkfirewall_firewall.tf_anf.arn
  }

  depends_on = [aws_networkfirewall_firewall.tf_anf]
}


#latest AL2 AMI
data "aws_ami" "al2_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}


#Get the AZs for our account
data "aws_availability_zones" "available" {
  state = "available"
}
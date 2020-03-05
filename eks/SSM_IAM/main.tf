
provider "aws" {
  profile = var.profile
  region  = var.region
}

resource "aws_iam_role" "ec2_instance_role" {
  name = "ec2_instance_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_policy_attachment" "Roles_for_default_ec2_instance_policy" {
  name  = "Roles_for_default_ec2_instance_policy"
  roles = [aws_iam_role.ec2_instance_role.name]
  ####Use of the AmazonEC2RoleforSSM policy is not a good practice. 
  ####It includes the entitlement "S3:GetObject" without a resource clause, 
  ####so potentially anyone or attacker with access to this ec2 instance 
  ####may be able to read all your buckets unless you take further steps!!!!!
  ####Real scenarios with an obligation to protect data should make a better policy.
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"

}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "ssm_instance_profile_eks"
  role = aws_iam_role.ec2_instance_role.name
}

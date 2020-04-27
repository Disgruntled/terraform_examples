resource "aws_iam_policy" "permissions_boundary_policy" {
  name        = "IAMLimitedEditBoundary"
  path        = "/"
  description = "A policy created to allow some user self service of IAM entities"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "NoBoundaryDelete",
            "Effect": "Deny",
            "Action": [
                "iam:DeleteUserPermissionsBoundary",
                "iam:DeleteRolePermissionBoundary"
            ],
            "Resource": "*"
        },
            {
            "Sid": "NoBoundaryModify",
            "Effect": "Deny",
            "Action": [
                "iam:DeletePolicyVersion",
                "iam:SetDefaultPolicyVersion",
                "iam:CreatePolicyVersion",
                "iam:DeletePolicy"
            ],
            "Resource": "arn:aws:iam::*:policy/IAMLimitedEditBoundary"
        },
            {
            "Sid": "AllowModifyCustomerPolicies",
            "Effect": "Allow",
            "Action": [
                "iam:DeletePolicyVersion",
                "iam:SetDefaultPolicyVersion",
                "iam:CreatePolicyVersion",
                "iam:CreatePolicy",
                "iam:DeletePolicy"
            ],
            "Resource": "arn:aws:iam::*:policy/customer-policies/*"
        },
        {
            "Sid": "CreateOrChangeOnlyWithBoundaryInPath",
            "Effect": "Allow",
            "Action": [
                "iam:PutUserPermissionsBoundary",
                "iam:CreateRole",
                "iam:PutRolePermissionsBoundary"
            ],
            "Resource": [
                "arn:aws:iam::*:user/customer-users/*",
                "arn:aws:iam::*:role/customer-roles/*"
            ],
            "Condition": {
                "StringLike": {
                    "iam:PermissionsBoundary": "arn:aws:iam::*:policy/IAMLimitedEditBoundary"
                }
            }
        },
        {
            "Sid": "AttachOnlyCustomerPolicies",
            "Effect": "Allow",
            "Action": [
                "iam:AttachUserPolicy",
                "iam:DetachUserPolicy",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy"
            ],
            "Resource": [
                "arn:aws:iam::*:user/customer-users/*",
                "arn:aws:iam::*:role/customer-roles/*"
            ],
            "Condition": {
                "ArnLike": {
                  "iam:PolicyARN" : "arn:aws:iam::*:policy/customer-policies/*"
                }
            }
        },
        {
            "Sid": "IAMRead",
            "Effect": "Allow",
            "Action": [
                "iam:List*",
                "iam:Get*",
                "iam:Describe*"
            ],
            "Resource": "*"
        },
                {
            "Sid": "S3Limited",
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:PutObject*",
                "s3:List*",
                "s3:Describe*",
                "s3:Abort*"
            ],
            "Resource": "*"
        },
       {
            "Sid": "AllowActions",
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "kms:*"

            ],
            "Resource": "*"
        },
       {
            "Sid": "Ec2Deny",
            "Effect": "Deny",
            "Action": [
                "ec2:CreateVpcEndpoint",
                "ec2:ModifyVpcEndpoint",
                "ec2:CreateVpc"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
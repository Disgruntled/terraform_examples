policy "block-all-sgs-with-all-ips" {
   source = "https://raw.githubusercontent.com/Disgruntled/terraform_examples/master/sentinel_policies/blocksgswithall"
   enforcement_level = "advisory"
}

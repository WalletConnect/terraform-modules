# `dns` module

Create a public Route53 zone for a fqdn and generate a wildcard certificate for it.

**Note:** A wildcard certificate is only generated if the fqdn is not a top level domain e.g.
  - login.walletconnect.com will generate a wildcard
  - walletconnect.com will not generate a wildcard

`hosted_zone_name` has to be created externally and can be a public or private hosted zone.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.33 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.33 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.domain_certificate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_route53_record.cert_verification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.hosted_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_fqdn"></a> [fqdn](#input\_fqdn) | n/a | `string` | n/a | yes |
| <a name="input_hosted_zone_name"></a> [hosted\_zone\_name](#input\_hosted\_zone\_name) | The domain for the zone, e.g. `login.walletconnect.com`, this will result in the certificate of `*.login.walletconnect.com` | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_certificate_arn"></a> [certificate\_arn](#output\_certificate\_arn) | The ARN for the generated certificate so that is can be passed to other services e.g. ELBs. |
| <a name="output_zone_arn"></a> [zone\_arn](#output\_zone\_arn) | The ARN for the created zone so that you can add other records to the zone. |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | The ID for the created zone so that you can add other records to the zone. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

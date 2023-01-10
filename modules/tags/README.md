# `tags` module

Create a list of standard tags.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.33 |

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_tags"></a> [additional\_tags](#input\_additional\_tags) | Map of optional tags to consolidate with the required tags. | `map(string)` | `{}` | no |
| <a name="input_application"></a> [application](#input\_application) | Application tag - A tag that uniquely identifies and application. | `string` | n/a | yes |
| <a name="input_env"></a> [env](#input\_env) | Environment tag - Allowed values are dev, qc, stable, rc | `string` | `"dev"` | no |
| <a name="input_env_group"></a> [env\_group](#input\_env\_group) | AWS Environment Group(this is the account name on aws) | `string` | `"walletconnect"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_tags"></a> [tags](#output\_tags) | Combined map of required and optional tags. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

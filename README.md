# tf-multi-env-cookiecutter

[Cookiecutter](https://www.cookiecutter.io/) template to generate a basic multi-environment Terraform project.

## Pre-requisites

Install [cookiecutter](https://cookiecutter.readthedocs.io/en/stable).

I recommend using [uv](https://docs.astral.sh/uv/) to manage the Python environment. Below is one way to get started for [Homebrew](https://brew.sh) users. Follow the [cookiecutter installation instructions](https://cookiecutter.readthedocs.io/en/stable/installation.html) for other methods.

```sh
brew install uv
```

```sh
uv tool install cookiecutter
```

## Run

```sh
cookiecutter gh:andreswebs/tf-multi-env-cookiecutter
```

## Configurations

See the configuration options in [cookiecutter.json](cookiecutter.json).

### Terraform bootstrap

Use the CloudFormation templates in the [cf/]({{cookiecutter.project_name}}/cf) directory to bootstrap the Terraform configuration:

- [tf-remote-state.yaml]({{cookiecutter.project_name}}/cf/tf-remote-state.yaml): deploy the resources for Terraform remote state in the shared services account
- [iam-role-infra-workload.yaml]({{cookiecutter.project_name}}/cf/iam-role-infra-workload.yaml): deploy as a stack set on the management AWS account to create workload roles in each account, which can be assumed from the shared services initial IAM role

### CI/CD bootstrap

Check this file and follow the instructions in the comments: [envs/shared/cicd-iam-bootstrap.tf]({{cookiecutter.project_name}}/envs/shared/cicd-iam-bootstrap.tf)

## Authors

**Andre Silva** - [@andreswebs](https://github.com/andreswebs)

## License

This project is licensed under the [Unlicense](UNLICENSE).

set dotenv-load

# Show all the tasks
list:
  @just -lu

# Initialize the project
init:
  terraform init
  tflint --init

# Ensure the formatting is correct
format *FLAGS:
  terraform fmt -recursive {{FLAGS}}

# Run linters
lint:
  tflint --module --recursive

# Ensure the project is valid
validate:
  terraform validate

# Plan the changes
plan:
  terraform plan

# Checks to run in CI
ci: (format "--check") lint validate


alias f := format
alias fmt := format
alias l := lint
alias v := validate

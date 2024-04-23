set dotenv-load := true

# Show all the tasks
list:
  @just -lu


# Run a terraform command
terraform command *ARGS:
  @just terraform/{{command}} {{ARGS}}

alias tf := terraform

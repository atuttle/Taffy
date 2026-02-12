# Taffy

REST API framework for CFML

## Running Tests

You can check if box ("commandbox") cli is install by running `box version`.
You can install box by running `brew install commandbox`.

Then install project dependencies: `box install`

### Start servers

box run-script start:all
box run-script start:lucee5
box run-script start:lucee6
box run-script start:lucee7

### Run tests

box run-script test:all
box run-script test:lucee5
box run-script test:lucee6
box run-script test:lucee7

### Stop servers

box run-script stop:all
box run-script stop:lucee5
box run-script stop:lucee6
box run-script stop:lucee7

## Documentation References

- Taffy documentation: `./docs/`
- CFML Syntax docs
  - cfdocs has cross-platform reference data in `.ignore/cfdocs/`
  - Lucee docs are in `.ignore/lucee-docs/`
- Testbox docs: `.ignore/testbox-docs/`
- Commandbox docs: `.ignore/commandbox-docs/`

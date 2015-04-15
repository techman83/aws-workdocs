Testing AWS::WorkDocs
===================

Testing will automatically occur if the right files + dependencies 
are present.

You can run them with `dzil test` or `prove -lr t/` from the root
of the repository.

Live Testing
============

A file named `~/.workdocstest` will need to be present with the
following contents:

```ini
[auth]
username=workdocs.user@example.com
password=a_good_password
alias=workdocs_organisation
region=us-west-1
[test]
username=test.user@example.com
password=suitably_complex-Pass
firstname=Test
surname=User
```

You'll need to set the relevant username/password/alias/region
for your WorkDocs Account.

Offline Testing
===============

This will mostly be aimed at Travis, but if the dependencies
`Dancer2` and `Proc::Daemon` are satisfied these will be run.

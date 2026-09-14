# Releasing a New Version of cmnlib

Use the `gh` command line tool to create a new release from the current state
of the `main` branch.

> [!IMPORTANT]
> - Use the value of [`_CMN_VERSION_`] for `<tag>` in the following command.
> - Keep title format.
> - Keep notes format, make sure to remove any empty section.

```shell
gh release create <tag> \
   --title "Version <tag>" \
   --notes-file - << EOF
### Fixes:

- `cmn::namespace::func1` : ...
- `cmn::namespace::func2` : ...

### Features:

- Introduce `cmn::namespace::new_func` ...
- Introduce `cmn::new_namespace` ...

### Misc.:

- `cmn::nmspc::old_func` : Removed
- ...
EOF
```

[`_CMN_VERSION_`]: cmnlib.sh#L18

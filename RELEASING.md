# Releasing a New Version of cmnlib

1. Make sure you are on an up-to-date `main` branch:
   ```shell
   git checkout main && git pull origin main
   ```

2. Create a new tag:
   ```shell
   git tag <YYYYMMDD>
   ```

3. Push the tag:
   ```
   git push origin main --tags
   ```

4. From GitHub web UI:
   1. Click [Releases]
   2. Click the [Draft a new release][draft] button
   3. Fill the form:
      1. Select the tag you've just created
      2. Add a release title. Format MUST be "Version <tag>"
      3. Copy and paste the following template for the changelog.
      4. Click the "Publish release" button.

```md
### Fixes:

- `cmn::namespace::func1` : ...
- `cmn::namespace::func2` : ...

### Features:

- Introduce `cmn::namespace::new_func` ...
- Introduce `cmn::new_namespace` ...

### Misc.:

- `cmn::nmspc::old_func` : Removed
- ...

```


[Releases]: https://github.com/Scalingo/buildpack-cmnlib/releases
[draft]: https://github.com/Scalingo/buildpack-cmnlib/releases/new

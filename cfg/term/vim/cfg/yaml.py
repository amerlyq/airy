# SEE ref for yaml:
#   http://www.yaml.org/refcard.html
#   http://learnxinyminutes.com/docs/yaml/

try:
    # Use json to correct '\' escaping for dict)
    import vim
    import json
    import yaml
except ImportError:
    print("Err: yaml not found, INSTALL: python3-yaml, OR: pip3 install yaml")
    vim.command("return -1")

fmt = 'NeoBundle "{0:s}", {1:s}'
cfgs, defs = map(vim.eval, ("a:paths", "a:default"))


def load_yml(doc):
    for src, opts in doc.items():
        # Remove to fasten loading
        [opts.pop(k, None) for k in ["description", "contract"]]
        try:
            vim.command(fmt.format(src, json.dumps(dict(defs, **opts))))
        except vim.error as err:
            print(err)


for c in (cfgs if isinstance(cfgs, list) else (cfgs,)):
    with open(c) as f:
        for doc in [doc for doc in yaml.safe_load_all(f) if doc is not None]:
            load_yml(doc)

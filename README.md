# Container Storage

Here I want to explore how we can generate a static registry for some kind
of container (a binary or set of layers) using Github Pages and some storage.
For this task, we will do the following:

 1. Manifests will be stored in Github Pages.
 2. Containers / blobs / artifacts will be in Google Storage

For this to work, we map the following OCI conventions to Github Pages:

## Registry

Since the content will be served on Github pages (via the master branch)
we can assert that the registry base address is the Github pages 
address. This means for the repository "singularityhub/container-storage"
we use the address "https://singularityhub.github.io/container-storage/.

## Namespace

It follows then, that a container namespace are some number of subfolders at
the base of the repository. For example, if we want to follow Docker Hub
convention with a namespace corresponding to `<username>/<reponame>`
we can create subfolders like "vanessa/greeting"

```bash
$ mkdir -p vanessa/greeting
```
```
$ tree
├── README.md
└── vanessa           # ( --- vanessa namespace
    └── greeting      # ( --- vanessa/greeting "collection"
```

This is a nice organization because if I'm browsing the repository, I can
find all containers owned by user vanessa in the "vanessa" folder, for example.
This means that the complete url for the base of a repository (where we will
append other commands to look up types, etc.) corresponds to:

```bash
docker://singularityhub.github.io/container-storage/vanessa/greeting
```

But we need to expose different endpoints to make that work.

## Manifest

The root for [image manifests](https://github.com/opencontainers/image-spec/blob/master/manifest.md) 
might be found at:

```
https://singularityhub.github.io/container-storage/vanessa/greeting/manifests
```

and then have subfolders with the tags of interest, for example. latest:

```
https://singularityhub.github.io/container-storage/vanessa/greeting/manifests/latest
```

Let's (for now) create this manually (this would be done programatically)

```bash
mkdir -p vanessa/greeting/manifests/latest
```

How would this work? We would want to return json, but we also need the URL to
render correctly on Github pages.

## Blobs

This is the first issue - the blobs are intended to be served by the same
base url (of the registry) based on the shasum. What if we just created
redirect download links instead? So let's say our first blob is the entire
container, in storage, named by a hash. The url would be:

```bash
https://singularityhub.github.io/container-storage/vanessa/greeting/blobs/<digest>
```

Let's try this out! I'm going to walk through an example next using Google Cloud
storage (and containers that already exist there).

# Example: Singularity Images

[Here is a direct link](https://storage.googleapis.com/singularityhub/singularityhub/github.com/vsoch/singularity-images/130504089d5b2b44e2788992d0de75b625da6796/a1025471b564766d08bdf2cb062c795c/a1025471b564766d08bdf2cb062c795c.simg) to download a container. Let's say that the
blob is the hash of the container, `a1025471b564766d08bdf2cb062c795c` so we need to
have a manifest layer like:

```
        {
            "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
            "size": 2065537,
            "digest": "md5:a1025471b564766d08bdf2cb062c795c"
        },
```

With an address like:

```
https://singularityhub.github.io/container-storage/vanessa/greeting/blobs/a1025471b564766d08bdf2cb062c795c
```


Meaning a folder in this repository:

```bash
$ mkdir -p vanessa/greeting/blobs/a1025471b564766d08bdf2cb062c795c
```

And the folder within (index.html) redirecting to the true url.


## Step 1: Get the Manifest

For demonstration I'll present this in Python. First, we get the image manifest.

```python
import requests

registry = "https://singularityhub.github.io/container-storage"
namespace = "vanessa/greeting"
tag = "latest"

manifest_url = "%s/%s/manifests/%s" %(registry, namespace, tag)
manifest = requests.get(manifest_url)

print(manifest.json())

{'config': {'digest': 'sha256:8c7ad11d488a8dd933239b9543a81dbe226416e96dc2f441d3bd038d664c1c92',
  'mediaType': 'application/vnd.docker.container.image.v1+json',
  'size': 5539},
 'layers': [{'digest': 'md5:a1025471b564766d08bdf2cb062c795c',
   'mediaType': 'application/vnd.docker.image.rootfs.diff.tar.gzip',
   'size': 35300}],
 'mediaType': 'application/vnd.docker.distribution.manifest.v2+json',
 'schemaVersion': 2}
```


## Step 2: Download Layers

The layers are in the manifest "layers" key, so we just need to download
one to the filesystem.

```python
layers = manifest.json()['layers']

# [{'digest': 'md5:a1025471b564766d08bdf2cb062c795c',
#  'mediaType': 'application/vnd.docker.image.rootfs.diff.tar.gzip',
#  'size': 35300}]

for layer in layers:
    digest = layer['digest']
    layer_url = "%s/%s/blobs/%s" %(registry, namespace, digest)

```


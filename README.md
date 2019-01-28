# Container Storage

Here I want to explore how we can generate a static registry for some kind
of container (a binary or set of layers) using Github Pages and some storage.

# Why do we need a static registry?

It's not always affordable to host an entire registry server, meaning somewhere
to run a Docker Registry that hosts an API plus blobs. It's much more realistic
today (or desired) to want to have some API to serve metadata (and there is no reason
this couldn't be statically hosted) and then a storage of choice such as S3, 
Google Storage, etc. This would make all kinds of build and deploy pipelines possible,
sort of like a "Choose your own adventure" for registries. For example:

 1. Maintain registry API statically on Github pages
 2. Build, check, update containers with Github Actions, TravisCI, CircleCI, or other continuous integration service
 3. On successful CI (tests pass hooray!) update record in registry (static content) and push to storage.


# Proof of Concept for a Static Registry

## 1. API and Organization

For this task, we will do the following:

 1. Manifests will be stored in Github Pages.
 2. Container binaries will be in Google Storage

Looking at the [distribution spec](https://github.com/opencontainers/distribution-spec/blob/master/spec.md#detail) it seems like the primary endpoints for a registry are to serve the
tags, (optionally) an exposed catalog, and then blobs. I want to argue that we should
remove the blobs from the registry and have them pointed to (with some method, urls?)
from the manifests. This means that the registry itself serves to:

  - organize the namespace
  - provide an API an interface to explore it
  - for each entry (container) provide manifests, and tags

And that's really it. This model is akin to a registry "slim" version, because 
there is no advanced permissions model beyond what Github offers, and 
updates are completely done via pull requests. In other words, it's a completely
simplified and open source registry model. For this to work, we map the following 
OCI conventions to Github Pages:

### Registry

Since the content will be served on Github pages (via the master branch)
we can assert that the registry base address is the Github pages 
address. This means for the repository "singularityhub/container-storage"
we use the address "https://singularityhub.github.io/container-storage/.

### Namespace

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


### Manifest

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

In this model we lose "request this version of a manifest" from a repository - the
most that might be done is to provide different versions on different branches of
the repository.

How would this work? We would want to return json, but we also need the URL to
render correctly on Github pages.

### Tags
 
It follows that tags are simply the named folders listed under the manifests folder!
It would make sense for each new namespace to have a "permalink" rendered at:

```
https://singularityhub.github.io/container-storage/vanessa/greeting/tags
```

That would serve the listing of tags. This isn't hard to do, we simply can 
add a template to do this too.


```bash
mkdir -p vanessa/greeting/tags
```

with an index.html in that folder that has the listing of tags:

```html
{
  "name": "vanessa/greeting",
  "tags": [
    "latest"
  ]
}
```

This would also be updated with any changes to the repository. 

### Blobs

This is the first issue - the blobs are intended to be served by the same
base url (of the registry) based on the shasum. My first thought was to create
redirect download links, but realizing there is a [urls](https://github.com/opencontainers/image-spec/blob/master/descriptor.md#registered-algorithms) attribute it would
be more direct to use this instead. I don't want to store any kind of
a blob here, I want to push this responsibility one level down to the 
storage. The manifest goes directly to the content to download.

### Example: Singularity Images

[Here is a direct link](https://storage.googleapis.com/singularityhub/singularityhub/github.com/vsoch/singularity-images/130504089d5b2b44e2788992d0de75b625da6796/a1025471b564766d08bdf2cb062c795c/a1025471b564766d08bdf2cb062c795c.simg) to download a container. Let's say that the
blob is the hash of the container, `a1025471b564766d08bdf2cb062c795c` so we need to
have a manifest layer like:

```
        {
            "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
            "size": 2065537,
            "digest": "md5:a1025471b564766d08bdf2cb062c795c",
            "urls": ["https://storage.googleapis.com/singularityhub/singularityhub/github.com/vsoch/singularity-images/130504089d5b2b44e2788992d0de75b625da6796/a1025471b564766d08bdf2cb062c795c/a1025471b564766d08bdf2cb062c795c.simg"]

        },
```

While the [md5 is not registered](https://github.com/opencontainers/image-spec/blob/master/descriptor.md#registered-algorithms) and thus a valid type, I'm using it just for this example.


#### Step 1: Get the Manifest

For demonstration I'll present this in Python. First, we get the image manifest.

```python
import requests

registry = "https://singularityhub.github.io/container-storage"
namespace = "vanessa/greeting"
tag = "latest"

manifest_url = "%s/%s/manifests/%s" %(registry, namespace, tag)
manifest = requests.get(manifest_url).json()

print(json.dumps(manifest, indent=4))
{
    "schemaVersion": 2,
    "mediaType": "application/vnd.singularity.distribution.manifest.v2+json",
    "config": {
        "mediaType": "application/vnd.singularity.container.image.v1+json",
        "size": 5539,
        "digest": "sha256:8c7ad11d488a8dd933239b9543a81dbe226416e96dc2f441d3bd038d664c1c92"
    },
    "layers": [
        {
            "mediaType": "application/vnd.singularity.image.squashfs",
            "size": 2065537,
            "digest": "md5:a1025471b564766d08bdf2cb062c795c",
            "urls": [
                "https://storage.googleapis.com/singularityhub/singularityhub/github.com/vsoch/singularity-images/130504089d5b2b44e2788992d0de75b625da6796/a1025471b564766d08bdf2cb062c795c/a1025471b564766d08bdf2cb062c795c.simg"
            ]
        }
    ]
}
```

#### Step 2: Download Image URLs

This ignores the config and content type for now, and just downloads the image url.
I would want to assume that the client knows that given a singularity squashfs,
the correct thing to do is download the single binary. 
Let's write a function to stream it to the filesystem:

```python
def stream_file(url, download_to):
    response = requests.get(url, stream=True)
    with open(download_to, 'wb') as filey:
        for chunk in response.iter_content(chunk_size=1024): 
            if chunk: 
                filey.write(chunk)
    return download_to
```

```python
layers = manifest['layers']

# {'digest': 'md5:a1025471b564766d08bdf2cb062c795c',
# 'mediaType': 'application/vnd.singularity.image.squashfs',
# 'size': 2065537,
# 'urls': ['https://storage.googleapis.com/singularityhub/singularityhub/github.com/vsoch/singularity-images/130504089d5b2b44e2788992d0de75b625da6796/a1025471b564766d08bdf2cb062c795c/a1025471b564766d08bdf2cb062c795c.simg']}

for layer in layers:
    url = layer['urls'][0]
    download_to = stream_file(url, 'mycontainer.simg')    
```

#### Step 3: Run the Container

Does it work?

```bash
$ singularity run mycontainer.simg
You say please, but all I see is pizza..
```

Yep!

Here is the md5sum:


```bash
$ md5sum mycontainer.simg
a1025471b564766d08bdf2cb062c795c  mycontainer.simg
```

There are a couple of things to discuss here:

 - The content type for Singularity I don't think exists. Can it exist and require a single binary (via a url) and then just be validated using a digest?
 - What goes in the config section then?
 - The storage needs to have an organizational standard. Given being stored in a Github repository, to me the logical answer is:

```
<github.com>/<username>/<reponame>/<commit>/<hash>/ [container]
```


## 2. Web Interface

The web interface, akin to the API, is rendered on Github pages according to
the organization of the files. Let's again look at our collection folder:

```
├── vanessa
│   └── greeting
│       ├── manifests
│       │   └── latest
│       │       ├── README.md
│       │       └── Singularity
│       ├── README.md
│       └── tags
│           └── index.md
```

The collection "vanessa/greeting" has all of its containers defined under the manifests folder.
This means that if I want to add a new container,  I create the tag for it as a folder under "manifests."
If I want

# Next Steps

 1. I will create GitHub Actions to interact with storage, and build.
 2. I'll create a front end interface for the Github Pages registry [see this issue](https://github.com/singularityhub/container-storage/issues/1)
 3. I'll connect the two so that there is a workflow to update the GitHub repository, and it will build and deploy a new container to storage and the API.

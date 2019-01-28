---
layout: home
---

# Container Storage

Welcome to container-storage, a static container registry! Here I am exploring
how we can generate a static registry for some kind of container (a binary or set of layers) 
using Github Pages and some storage.

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


# Getting Started

Following the links below to read the documentation on the repository wiki to learn more.

 - [Documentation](https://github.com/singularityhub/container-storage/wiki) home on the respository wiki.
 - [Deploy!](https://github.com/singularityhub/container-storage/wiki/deploy-container-storage) your own container storage.
 - [Example API Interaction](https://github.com/singularityhub/container-storage/wiki/Example-API-Interaction)
 - [Technical Specification](https://github.com/singularityhub/container-storage/wiki/Technical-Specification) or specifically, the logic behind the files and folder organization here.

## Support

Please [open an issue](https://www.github.com/singularityhub/container-storage/) if you
have any questions, preguntas, dilemas, asuntos... 

## License

This code is licensed under the Affero GPL, version 3.0 or later [LICENSE](LICENSE). 
The power of open source compels you!!

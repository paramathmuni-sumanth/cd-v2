# Projects in Argocd
### Uses
- Projects in argocd are used to restrict and application that where they can sync from ie., repositories.
- Also we can restrict applications to particular server,namespace etc.,
- We can also restrict applications from certain resources of cluster with help of these Projects
# Projects for our cluster
### Manifest
- WE stored the configured manifest for our cluster in a manifests folder above.
### Creating Projects for cluster 
- clone this repository and navigate to this directory.
- run chmod +x create.sh in terminal
- run ./create.sh in terminal
- now it will ask you for argocd api token of bot_user ,please provide it to create projects.
- Once the script excutes successfully your projects are created.


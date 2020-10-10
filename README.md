# License server for Rizom Lab products, as Docker container

This container contains the LM-X server, plus the Rizom Lab vendor plugin. It allows you to run a license server for RizomUV from a container.

When deploying this, lock the container's MAC address to a fixed, unique address. Then use that address when purchasing floating licenses.

The image comes in two flavors; `minimal` and `regular`. The `minimal` version is built from the scratch base image, whereas the `regular` version uses Ubuntu as its base.


# Compile and Run:

```bash
docker build . -t custom-ubuntu:latest

docker run --rm --privileged -v "$(pwd)/output:/output" custom-ubuntu:latest
```
# Changelog

## 0.1

- GPU locking for 1-core, n-GPU jobs only

## 0.2

- GPU locking for m-core, n*m-GPU jobs added (needed if using a `smp` parallel environment)

## 0.3

- Switch from parsing `nvidia-smi -L` to checking `/proc/driver/nvidia/gpus` to determine the number of GPUs (much faster)

## 0.4

- Complete rewrite based on the [Wellcome Centre for Integrative Neuroscience (University of Oxford)'s gridengine scripts](https://git.fmrib.ox.ac.uk/fmribitprojects/gridengine-scripts):
  - Ensure group permissions are used to limit access to GPU(s) to the relevant jobs (don't just rely on the `CUDA_VISIBLE_DEVICES` env var to restrict visibility as that can be overridden).

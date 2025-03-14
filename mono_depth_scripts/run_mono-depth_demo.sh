#!/bin/bash
# Copyright 2025 DeepMind Technologies Limited
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================


evalset=(
  # swing
  # breakdance-flare
  lady-running
)

DATA_DIR=/home/wjh/projects/mega-sam/data
OUTPUTS_DIR=/home/wjh/projects/mega-sam/outputs
# Run DepthAnything
for seq in ${evalset[@]}; do
  echo "Running Depth-Anything on $seq"
  CUDA_VISIBLE_DEVICES=0 python Depth-Anything/run_videos.py --encoder vitl \
  --load-from Depth-Anything/checkpoints/depth_anything_vitl14.pth \
  --img-path $DATA_DIR/$seq \
  --outdir $OUTPUTS_DIR/$seq/Depth-Anything
done

# Run UniDepth
# export PYTHONPATH="${PYTHONPATH}:$(pwd)/UniDepth"

# for seq in ${evalset[@]}; do
#   CUDA_VISIBLE_DEVICES=0 python UniDepth/scripts/demo_mega-sam.py \
#   --scene-name $seq \
#   --img-path $DATA_DIR/$seq \
#   --outdir outputs/UniDepth/outputs
# done

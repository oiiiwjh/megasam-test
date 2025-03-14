#!/bin/bash
# put each evalset into python scripts (one by one) 
measure_time() {
    local step_number=$1
    shift
    local green="\e[32m"
    local red="\e[31m"
    local no_color="\e[0m"
    local yellow="\e[33m"
    
    start_time=$(date +%s)
    echo -e "${green}Step $step_number started at: $(date)${no_color}"

    "$@"

    end_time=$(date +%s)
    echo -e "${red}Step $step_number finished at: $(date)${no_color}"
    echo -e "${yellow}Duration: $((end_time - start_time)) seconds${no_color}"
    echo "---------------------------------------"
}
evalset=(
  # # lady-running
  # city_walk
  # # flower
  # forest_road
  # park
  # park_1
  # room
  # new vids
  # -ZXPb2xG9mg__scene-10
  # 3tiIryX0Mls__scene-8
  # 3tiIryX0Mls__scene-10
  # 3tiIryX0Mls__scene-40
  # 3tiIryX0Mls__scene-372
  # 8XJ7IYxNYqI__scene-8
  # 8XJ7IYxNYqI__scene-32
  # 773Qq6qG108__scene-5
  # 773Qq6qG108__scene-97
  # 773Qq6qG108__scene-126
  # AH_c9U2pFQ8__scene-46
  # AH_c9U2pFQ8__scene-12
  # 3tiIryX0Mls__scene-69
  # 3tiIryX0Mls__scene-124
  # 3tiIryX0Mls__scene-301

  AH_c9U2pFQ8__scene-64
  EutLw_LfS4M__scene-0
  EutLw_LfS4M__scene-4
  EutLw_LfS4M__scene-12
  EutLw_LfS4M__scene-27
  EutLw_LfS4M__scene-67
  EutLw_LfS4M__scene-127
  lWqXHU3t9-o__scene-3
  lWqXHU3t9-o__scene-12
  lWqXHU3t9-o__scene-42
  OFE5rR3ubWU__scene-3
  OFE5rR3ubWU__scene-38 
  OFE5rR3ubWU__scene-94
  PeFEJHuVOy8__scene-95
  PeFEJHuVOy8__scene-95
  qYK7uyT_QDQ__scene-6
  S6Eql9_pcOw__scene-126
  Y1LBSYANY8o__scene-67
)
WORK_DIR=$(pwd)
DATA_DIR=$WORK_DIR/data
OUTPUTS_DIR=$WORK_DIR/outputs
CUDA_LIST=6
# =======================================================
# ------------------- Depth Generation ------------------
# =======================================================
# ----------------- Run Depth-Anything -----------------
echo -e "\e[33mRunning Depth-Anything on evalset\e[0m"
for seq in ${evalset[@]}; do
  echo "Running Depth-Anything on $seq"
  CUDA_VISIBLE_DEVICES=$CUDA_LIST python Depth-Anything/run_videos.py --encoder vitl \
    --load-from Depth-Anything/checkpoints/depth_anything_vitl14.pth \
    --img-path $DATA_DIR/$seq \
    --outdir $OUTPUTS_DIR/$seq/depth-anything \
    --localhub # path: /home/wjh/.cache/torch/hub/facebookresearch_dinov2_main
done
# --------------------- Run UniDepth -------------------
# export PYTHONPATH="${PYTHONPATH}:$(pwd)/UniDepth"
# 考虑不使用 UniDepth 得到fov
echo -e "\e[33mRunning UniDepth on evalset\e[0m"
for seq in ${evalset[@]}; do
  CUDA_VISIBLE_DEVICES=$CUDA_LIST python UniDepth/demo_mega-sam.py \
    --scene-name $seq \
    --img-path $DATA_DIR/$seq \
    --outdir $OUTPUTS_DIR/$seq/unidepth
done
# =======================================================
# ----------------- Run Camera Tracking -----------------
# =======================================================
echo -e "\e[33mRunning Camera Tracking on evalset\e[0m"
for seq in ${evalset[@]}; do
  CUDA_VISIBLE_DEVICES=$CUDA_LIST python camera_tracking_scripts/test_demo.py \
    --datapath $DATA_DIR/$seq \
    --weights checkpoints/megasam_final.pth \
    --scene_name $seq \
    --output_dir $OUTPUTS_DIR/$seq \
    --disable_vis $@ 
done
# =======================================================
# ------ Run Consistent Video Depth Optimization --------
# =======================================================
# ------------------- Run Optical Flow ------------------
echo -e "\e[33mRunning Optical Flow on evalset\e[0m"
for seq in ${evalset[@]}; do
  CUDA_VISIBLE_DEVICES=$CUDA_LIST python cvd_opt/preprocess_flow.py \
    --datapath=$DATA_DIR/$seq \
    --model=cvd_opt/raft-things.pth \
    --mixed_precision \
    --cachedir $OUTPUTS_DIR/$seq/cache-flow
done
# ---------------- Run CVD optmization ------------------
# need flow(OF) and reconstructions(droid slam)
echo -e "\e[33mRunning CVD Optimization on evalset\e[0m"
for seq in ${evalset[@]}; do
  CUDA_VISIBLE_DEVICES=$CUDA_LIST python cvd_opt/cvd_opt.py \
    --scene_name $seq \
    --w_grad 2.0 --w_normal 5.0 \
    --output_dir $OUTPUTS_DIR/$seq
done
# =======================================================

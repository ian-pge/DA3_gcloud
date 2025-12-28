git clone --recurse-submodules git@github.com:ian-pge/DA3_gcloud.git
python -m pip install --upgrade pip
python -m pip install --ignore-installed "blinker>=1.9.0"
cd DA3_gcloud/
pip install xformers==0.0.24 --index-url https://download.pytorch.org/whl/cu121
pip install -r requirements_docker.txt
pip install --no-build-isolation git+https://github.com/nerfstudio-project/gsplat.git@0b4dddf04cb687367602c01196913cde6a743d70
cd Depth-Anything-3
pip install -e .
export HF_HOME=/workspace/hf_cache

da3 auto /workspace/datasets/hotel/images/ \
            --model-dir depth-anything/DA3-LARGE-1.1 \
            --export-dir /workspace/output/ \
            --export-format ply

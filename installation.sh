pip install --upgrade pip
pip install xformers==0.0.27.post2 --index-url https://download.pytorch.org/whl/cu121
pip install -r requirements.txt
pip install --no-build-isolation git+https://github.com/nerfstudio-project/gsplat.git@0b4dddf04cb687367602c01196913cde6a743d70
pip install -e .
export HF_HOME=/workspace/hf_cache

da3 auto /workspace/datasets/hotel/images/ \
            --model-dir depth-anything/DA3-LARGE-1.1 \
            --export-dir /workspace/output/ \
            --export-format ply
